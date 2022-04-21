# 计算相关
- 向量化
	- clickhouse, 没有论文，不过很有多会议的presentation可以看， https://github.com/ClickHouse/clickhouse-presentations
		- firebolt, clickhouse魔改版本， CMU Vaccination Database Tech Talks 讲Firebolt这期讲了不少细节，https://www.youtube.com/watch?v=9rW9uEJ15tU&t=743s， Vaccination Database Tech Talks 这个系列有很多干货， 每期一个系统；

	- starrocks, 从它的发展路径看， 有很多学clickhoues的影子；

	- velox, 近期facebook对presto的c++重写版本，还快速迭代中， 可以关注看看， 肯定会有向量化相关的地方, Orri Erling这个人好像挺牛的，是下面这篇文章的作者之一；
		- TPC-H Analyzed: Hidden Messages and Lessons Learned from an Infuential Benchmark, 这篇论文的作者非常牛，AP方向上，这篇论文在内部也是被研究的很多；

	- MonetDB/VectorWise，CWI，践行列存储和向量化先行者，snowflake的创始人就有来自CWI的， 目前snowflake也是走的这个路线，应该还没有codegen;
		- 2005-MonetDB-MonetDB/X100- Hyper-Pipelining Query Execution

	- Spark photon, 去年spark搞的c++向量化引擎，据说性能好，去年打榜口水战，spark从codegen这条路走到了向量化
		- https://docs.databricks.com/runtime/photon.html

- Codegen，
	- 德国慕尼黑工业大学
		- 他们之前的系统Hyper的runtime使用了基于LLVM的技术
			- 2011-Hyper-Compiler-Efficiently Compiling Efficient Query Plans for Modern Hardware
		- 后来他们又做了Umbra，迭代开发compile时间更短的方法， 论文
			- 2020-Umbra-Compiler-Tidy Tuples and Flying Start Fast Compilation and Fast Execution of Relational Queries in Umbra，编译时间只需要几毫秒，使用asmjit直接产出x86机器码， 相较于LLVM的快很多， 而且做到执行计划Flying start, 即开始是解释执行，等编译就绪了，无缝切换编译执行；
			- 2021-Umbra-Compiler-Building Advanced SQL Analytics From Low-Level Plan Operators；
	
	- 普渡大学
		- 他们搞的Lightweight Modular Staging， 通过scala去生成c代码， 在用gcc compile（这个编译很耗时）, 比较学术，实用价值不太，但理论很先进，好像Umbra的Tidy Tuples是借鉴的LB2，用c++重写
			- 2010-Lightweight Modular Staging-A Pragmatic Approach to Runtime Code Generation and Compiled DSLs
			- 2018-LB2-How to Architect a Query Compiler, Revisited
			- 2019-Purdue-Towards Compiling Graph Queries in Relational Engines

	- CMU也做了很多这方面的事情， 可以翻翻论文看；

	- Clickhouse
		- clickhouse以向量化为主， 但后期引入的使用LLVM进行codegen, 代码开源可看；

	- Arrow gandiva
		- dremio搞的，使用LLVM对Filter/Projection进行codegen加速，arrow的layout比较适合做这种，gandiva快的原因， 除了通过codegen去掉了很多解释执行的开销， 还有codegen本身在arrow格式上可以进行自动向量化；

	- CMU/TUM/CWI几个数据库的大佬都署名了，这篇论文比较有名，可以看看， 讲compile和vecterized的方方面面：2018-Compiler-Everything You Always Wanted to Know About Compiled and Vectorized Queries But Were Afraid to Ask

	- TU Ilmenau, 也是德国的一个大学，不太有名，近期发了不少图上的论文
		- 2021-Adaptive Query Compilation in Graph Databases， 讲怎么对图的查询引擎做codegen，也讲了怎么做类似Tidy Tuples and Flying Start的先解释执行，后编译执行的方式，质量很高，有代码实现可看：https://dbgit.prakinf.tu-ilmenau.de/code/poseidon_core/-/tree/master/src/qcomp
		- 2021-JIT happens- Transactional Graph Processing in Persistent Memory meets Just-In-Time Compilation


# 索引
	- b+树索引，还是各大数据库的标配，历史悠久，开源实现，https://panthema.net/2007/stx-btree/， kudu的实现等，历史原因，btree是面向磁盘， 所以在全内存的对比场景， 它对cache的考虑不足， 可能比ART这样的考虑不够，导致它在内存越来越大的今天有点吃亏， 但一个好的b+tree设计依然可以做到很均衡的性能；
	- ART索引， hyper使用的索引，基数树，性能很大， 点查性能， range查询比不上btree；
		- The Adaptive Radix Tree: ARTful Indexing for Main-Memory Databases；
		- 对ART后续的一些改进；
			- 2018-HOT- A Height Optimized Trie Index for Main-Memory Database Systems
			- START – Self-Tuning Adaptive Radix Tree
	- Masstree， B+tree和Ties的结合
		- 貌似hologress使用了这个；
		- 有一些开源实现， 比如 https://github.com/rmind/masstree
	- BW-Tree, 微软
		- 2013-Bw-tree-Microsoft-The Bw-Tree-A B-tree for New Hardware Platforms 
		- 2018-Building a Bw-Tree Takes More Than Just Buzz Words CMU的论文，有个开源的open bwtree实现， 性能一般， 目前没有特别好的实现，要么微软的论文并没有把insight讲出来？

	- 这个项目可以不错，它的论文其实一开始是对learned index和传统的数据库索引进行benchmark, 但其中几乎把所有的内存索引都加进去做比较 https://github.com/learnedsystems/SOSD

	- LSM
		- 学术界，2016-Wisconsin-WiscKey Separating Keys from Values in SSD-conscious Storage, 大value分离， rocksdb已经继承进去;
		- 学术界，2020-From WiscKey to Bourbon- A Learned Index for Log-Structured Merge Trees，讲的使用ML来提升查询效率
		- 工业界：cochroachdb的实现， https://github.com/cockroachdb/pebble ， 用go写， 因为coachroachdb的go runtime用rocksdb比较蛋疼， tidb好像也有自己的实现？
		- 工业界：字节的terarkdb, 收购来的，做了很多优化，从index到remote compact之类的，https://github.com/bytedance/terarkdb， 后来terark的创始人出走了， 搞了topling, 也是基于rocksdb改， https://github.com/topling/toplingdb

# 其他
	- 综述性的论文，随便看看；
		- 2021-The Future Is Big Graphs- A Community View on Graph Processing Systems
		- 2021-Demystifying Graph Databases-Analysis and Taxonomy of Data Organization, System Designs, and Graph Queries

