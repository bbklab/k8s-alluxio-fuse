
### 环境准备
  - 1 master: 8C16G KVM CentOS-7 x86_64
  - 3 nodes:  8C16G KVM CentOS-7 x86_64
  - 每个主机上安装
```bash
# yum -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel
# yum -y install rsync
# yum -y install fuse-libs fuse-devel
```
  - 设置master到nodes的SSH信任登陆
  - 每个主机上配置主机IP映射/etc/hosts
  - 每个节点上下载alluxio-1.8.1安装包
```bash
# axel -n 20 http://downloads.alluxio.org/downloads/files//1.8.1/alluxio-1.8.1-bin.tar.gz
```

### 部署集群
**每个主机上安装**
```bash
# tar -C /usr/local -xf alluxio-1.8.1-bin.tar.gz
# workdir="/usr/local/alluxio-1.8.1"
# export PATH=$PATH:$workdir/bin:$workdir/integration/fuse/bin
```

**master主机上进行配置并同步到所有节点**
```bash
# cd /usr/local/alluxio-1.8.1/
# cp conf/alluxio-site.properties.template conf/alluxio-site.properties

# vi conf/alluxio-site.properties
alluxio.master.hostname=master
alluxio.worker.memory.size=7GB                  # 每个worker分配的内存
alluxio.worker.web.port=30001
alluxio.user.file.passive.cache.enabled=false   # note: mostly you should set this option, See: https://www.alluxio.org/docs/1.8/en/advanced/Performance-Tuning.html#client-tuning

# vi conf/workers
node1
node2
node3

# alluxio copyDir conf/                    # 通过ssh和rsync同步目录到所有worker节点
```

**集群启停**
master上执行
```bash
# alluxio-stop.sh all                  # 停止
# alluxio-start.sh all SudoMount       # 启动
```

**集群状态**
```bash
# alluxio fs ls -R /
# alluxio fs getCapacityBytes                                  # 所有空间
# alluxio fs getUsedBytes                                      # 使用空间
# curl http://localhost:19999/api/v1/master/info               # 集群信息
# curl http://localhost:19999/api/v1/master/worker_info_list   # worker信息
```

### 启用FUSE
**所有worker节点上**
```bash
# mkdir -p /mnt/alluxio-fuse
# alluxio-fuse mount /mnt/alluxio-fuse/   /
# alluxio-fuse stat
# mount -l | grep fuse
```

### 关闭FUSE
**所有worker节点上**
```bash
# alluxio-fuse umount /mnt/alluxio-fuse/
```

### 导入数据
这里提前从[tesseract-orc](https://github.com/tesseract-ocr/tessdata)准备了机器学习的数据  
放在`train-data`包含10个子目录: 从`ocr-testdata.0` 到 `ocr-testdata.9`,共计15GB,1850个文件  

导入
```bash
# alluxio fs rm  -R /train-data/
# alluxio fs mkdir /train-data/
# alluxio fs copyFromLocal train-data/  /train-data
# alluxio fs ls -R /  | grep -v -E "DIR|100%"    # ensure all files loaded
```

**查看空间占用情况**
```bash
# alluxio fs getCapacityBytes
Capacity Bytes: 22548578304
# alluxio fs getUsedBytes
Used Bytes: 15706851515
```

**查看数据在worker上的分布**
```
# alluxio fs ls -R /
# alluxio fs location /train-data/*/*       # 数据应该是均匀分布在所有worker上的 
```

### 测试通过FUSE的数据读取速度
注意:
  - 只测试**顺序读取完整文件**的性能表现，也是应用程序和Alluxio数据交换最常用的场景
  - 在所有alluxio worker节点上分别启动一个计算进程各自读取文件，模拟分布式学习计算的场景
  - 取所有alluxio worker节点上都完成数据读取的最大时间

**3个计算进程各自读取1/3数据**
```liquid
# node1
total:672 succ:672 fail:0
real    2m27.120s

# node2
total:672 succ:672 fail:0
real    2m10.104s

# node3
total:504 succ:504 fail:0
real    2m13.288s
```
耗时: `2m27s，平均102MB/s`

**4个计算进程各自读取1/4数据**  - 增加一个worker节点
```liquid
# node1
total:504 succ:504 fail:0
real	1m53.997s

# node2
total:504 succ:504 fail:0
real	1m57.114s

# node3
total:504 succ:504 fail:0
real	1m48.520s

# node4
total:336 succ:336 fail:0
real	1m29.631s
```
耗时: `1m57，平均128MB/s`

**结果上看数据读取比较稳定，没有数据读取失败的情况(需要继续加大样本数量进行测试)**

  
在数据完全加载的情况下, 根据[Alluxio DataFlow](https://www.alluxio.org/docs/1.8/en/Architecture-DataFlow.html#data-flow), 读取数据的速度应该介于
  - 最优情况: 所有Local Cache Hit，提供**完全内存级别**的访问速度
  - 最差情况: 所有Local Cache Miss，提供**本地网络级别**的访问速度
  - worker数量为N，Local Cache Hit的数据是1/N, Local Cache Miss的数据是N-1/N
  - 更多worker导致数据越分散，Local Cache Miss越多，但是在分布式计算场景下，因为有更多计算进程，每个计算进程所需处理的数据减少，反而提升了整体读取速度
