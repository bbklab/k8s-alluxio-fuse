### TODO
  - K8S UI
  - Alluxio UI
  - Integration with TF
  - 定期清理数据
  - 预定义时间提前加载数据

### 自行实现一个类alluxio
   - fuse:  https://github.com/hanwen/go-fuse
   - load:  s3/oss/aws storage

### FAQ
  - 支持的UFS都有哪些?
    - OSS:   fs.oss.accessKeyId, fs.oss.accessKeySecret, fs.oss.endpoint
    - AWS S3:   aws.accessKeyId, aws.secretKey
    - Other S3:  additional option `alluxio.underfs.s3.endpoint`
    - HDFS/Azure Blob Store/Google Cloud Storage/Ceph/GlusterFS/MapR-FS/Minio/NFS/Swift ...
  - API使用方式都有哪些?
    - Alluxio Jave Client: Hadoop, Spark, HBase, Hive ...  using `alluxio-1.8.1-client.jar`
    - Alluxio REST API: Go/Python Client, Any other third party implementions
    - Alluxio FUSE: POSIX FileSystem, open/read/write
  - Fuse使用限制: 不能修改文件; 不支持软硬链接; 不支持chown/chgrp; fuse.maxwrite.bytes=128KB; lower performance than Alluxio Jave Client
  - 数据流向
    - 读数据: 首先location查询数据落在哪个worker上
      - Local Cache Hit: if `short-circuit` enabled, read the local file directly, otherwise transfer over local TCP socket. Short-circuit is the most performant way
      - Remote Cache Hit:  provide network-speed data reads
      - Cache Miss: delegates a local worker reads and caches the data from the under storage, the largest delay, always at the first time.
    - 写数据: 默认写入到 Memory Storage, 需要手动Persist才能落地到UFS
      - MUST_CACHE: Write to Alluxio only, (default write type)
      - CACHE_THROUGH: Write through to UFS, data is written synchronously to an Alluxio worker and the under storage system
      - ASYNC_THROUGH: Write back to UFS, data is written synchronously to an Alluxio worker and asynchronously to the under storage system
  - 空间不够用如何扩容节点?
      - 扩容直接启动一个新的worker即可,配置保持和其他woker一致。 http://www.alluxio.org/docs/1.8/en/deploy/Running-Alluxio-On-a-Cluster.html#addremove-workers
  - FUSE使用方式要求数据使用的进程必须和alluxio fuse进程在同一个容器空间内，因为fuse mount是用户态的文件系统，依赖一个用户态的fuse进程提供服务.见说明:
      - https://github.com/Alluxio/alluxio/blob/master/integration/docker/README.md#extending-docker-image-with-applications

### TroubleShoot
在`/alluxio-fuse/`下尝试执行 `cp file1 file2` 遇到报错:
```liquid
cp: failed to extend '20M.10': File exists
```
同时`fuse.log`日志中报错:
```liquid
ERROR AlluxioFuseUtils - Failed to get id from  with option -u
ERROR AlluxioFuseUtils - Failed to get id from  with option -g
ERROR AlluxioFuseFileSystem - File /mnt/oss/bigdata/20M.10 exists and cannot be overwritten. Please delete the file first
```
因为`file1`文件所在的文件系统(本地/对象存储)的属主和属组不明  
尝试把文件拷贝到本地磁盘，修改属主属组后，重新从本地磁盘拷入  
