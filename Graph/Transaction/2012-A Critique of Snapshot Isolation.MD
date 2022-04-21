#SI
- 要解决的冲突场景是写写冲突，不能解决write skew的问题；
- 分布式实现
	- lock实现方式: percolator Large-scale incremental processing using distributed transactions and notifications.2010
	- lock-free实现方式：Lock-free Transactional Support for Large-scale Storage Systems.2011

#WSI (write snapshot)
- 检测read-write冲突，实现serializility;
- centralized server: timestamp oracle（TO）用来发现冲突， 提供全局的commit order;
	- trasaction会分配的到两个timestamp:
		- read timestamp(RT): 从mvcc storage读取通过read timestamp为准；
		- commit timestamp(CT): 要commit的时刻获得，并检测读的行是否在[CT,RT]时间段内有其他的事务commit了读过的行；
	- insight: 其实是希望得到这样一个结果， 即读写都在CT发生， 但是真正的读是发生在RT， 所有需要检测， 我读的数据是否被别的事务修改了；
	- 只读事务：事务发生在RT, 不会有任何冲突；
	- 只写事务：需要把写了哪些行告知TO， 用于做前面的读写冲突检测；

- 实现
	- foundationdb的实现，事务的过程包括Proxy, Sequencer, Resolver， LogServer, StorageServer角色完成；
		- Proxy: 多个，水平扩展，一个事务有一个Proxy来代理完成；
		- Sequencer: 单例，全局的timestamp产生器， 提供read timestamp和commit timestamp， 定义全局的LSN（Log Sequence Number）;
		- Resolver: 多个，水平扩展， 一个负责一段key range, 一个事务可能touch多个range, Proxy把事务中与该Resolver相关的部分发过去，做读写检测，Resolver维护了最近一段时间的commit的key；
		- LogServer: 多个，水平扩展，如果Proxy通过Resolver确定可以commit,则把对应key发给LogServer,LogServer存的是redo log;
		- StorageServer: 多个，水平扩展，异步从LogServer拉取数据，batch commit来提升throughput；
			- 有可能出现，commit的数据还未apply到SS的情况， 这时需要等，或者发给另一个replica;
		- Recovery: 
			- Proxy/Resolver无状态；
			- LogServer有状态， recover的时候需要确保已经commit的不能少（因为已经回复client commit）
				- KCV (known Commited Version)
				- DV (Durable Version)
			- The essence of the recovery of old LogServers is to determine the end of redo log, i.e., a Recovery Version (RV). 

	- cockroachdb的实现