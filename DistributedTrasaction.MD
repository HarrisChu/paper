# Percolator
2010年Google为了解决大规模索引系统data和secondary index的原子同步问题而设计出来的协议, 支持Snapshot Isolation, 原理为通过悲观锁发现写写冲突的情况，写不阻塞读，存在SI隔离的Write Skew问题。

论文：Large-scale Incremental Processing Using Distributed Transactions and Notifications

# Omid
Yahoo研发的大规模分布式存储之上提供事务功能的组件，最初的论文是A Critique of Snapshot Isolation这篇，论文观点认为Percolator的写写冲突不够好，定义了Write Snapshot Isolation（WSI）, Percolater被定义为Read Snapshot, 检测冲突的方式为检测读写冲突，需要引入中心节点；支持Serializable;
在后续的三篇论文中，不知为何变成了Snapshot Isolation, Apache Phonenix omid，Phonenix是Hbase的SQL层，为Hbase提供ACID支持；目前还在孵化中，看code history活跃度一半

##### 开源代码
- Yahoo：https://github.com/YahooArchive/omid
- Apache Phonenix omid: https://github.com/apache/phoenix-omid

#### 相关论文
- A Critique of Snapshot Isolation
- Omid: Lock-free Transactional Support for Distributed Data Stores, 2014
- Omid, Reloaded: Scalable and Highly-Available Transaction Processing, 2017
- Taking omid to the clouds: fast, scalable transactions for real-time cloud analytics, 2018

# TiDB

对Percolator的开源实现，有单点的Timestamp Oracle, 理论上性能不会好；

# Spanner

采用了TrueTime的基础设施，由于不同节点间，在时间戳上的最大误差就是7ms，因此其采用了commit wait的方式，来保证完全的strict serializability。（google称为外部一致性，表示系统能够遵从系统外部的因果事件的先后顺序，也是很贴切的术语）

# CockroachDB

从网上CRDB的技术讨论中得知，受到了A Critique of Snapshot Isolation这篇论文的启发，所以和Omid有一些同源, 同时学习Google的TrueTime的思路，搞了NTP+HLC混合时钟方案；

以下载录了CRDB论坛的一段话：

```
CockroachDB does not perform any locking during reads, only during writes. Instead, when performing reads CockroachDB bumps an in-memory data structure (backed by a concurrent skiplist) that records the largest timestamp of reads over arbitrary spans of rows. This “timestamp cache” is then consulted during write operations to prevent a write in a different transaction from invalidating a previous read at a higher timestamp. Remember that CockroachDB is an MVCC database, so reads and writes only interact if a write has a lower timestamp than a read. So the rules are that:

- If a write finds that it overlaps with any prior reads at higher timestamps then it is forced to move its write timestamp forward, which may induce a transaction restart if we’re not able to prevent it.
- If a finds that it overlaps only with reads at earlier timestamps then it is free to proceed without issue.

For more on this approach, you can read Maysam Yabandeh’s A critique of snapshot isolation, which uses a similar structure (called a status oracle in the paper) to achieve serializability.
```


# FoundationDB
2018年Apple开源, 2021年发了一篇论文讲了整个系统，开源， c++， 可研究；
亮点： 
- 对了strict serializable的支持；
- 极强的稳定性，包括Apple内部和snowflake应用场景的广泛验证；

摘录自论文：
```
Jepsen refuses to test FDB because FDB's simulation testing is much more rigorous than anything Jepsen does
```
论文： FoundationDB: A Distributed Unbundled Transactional Key Value Store

# RAMP/RAMP-TAO
RAMP：2014年，学术界论文Visualization of RAMP transactions定义的Read Atomic（RA），提供了Read Commted（RC）进一步，但未到SI的协议，更轻量级；

RAMP-TAO: 2021 VLDB最佳工业论文，从问题的解析论文到怎么把RAMP应用到TAO这样的生产环境时，从性能、稳定性、灰度能力等多方面的考量；


#### 相关论文
- RAMP-TAO: layering atomic transactions on Facebook's online TAO data store
- Scalable Atomic Visibility with RAMP Transactions


# 参考资料
- Database of Research Databases https://github.com/jackwaudby/dbordb
- awesome-distributed-transactions https://github.com/rystsov/awesome-distributed-transactions
- How CockroachDB Does Distributed, Atomic Transactions https://news.ycombinator.com/item?id=10160797
- https://forum.cockroachlabs.com/t/phantom-reads-secondary-index-locks/2843
- [笔记] Omid: Lock-free transactional support for distributed data stores
https://fuzhe1989.github.io/2021/04/17/omid-lock-free-transactional-support-for-distributed-data-stores/
- A New Chapter for Omid https://yahooeng.tumblr.com/post/180867271141/a-new-chapter-for-omid
- 《A Critique of Snapshot Isolation》https://zhuanlan.zhihu.com/p/404876370
- Snapshot Isolation 综述 http://mysql.taobao.org/monthly/2019/02/03/
- 从CockroachDB理解分布式数据库系统的一致性 https://zhuanlan.zhihu.com/p/405887567
- For Anyone with experience with FoundationDB! How does it compare to CockroachDB ? https://news.ycombinator.com/item?id=30644918
- Apple open-sources FoundationDB https://news.ycombinator.com/item?id=16877395
- FoundationDB: A Distributed Unbundled Transactional Key Value Store (Sigmod 2021) http://muratbuffalo.blogspot.com/2022/03/foundationdb-distributed-unbundled.html
- jepsen https://jepsen.io/
