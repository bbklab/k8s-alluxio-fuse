### k8s环境准备

一个新的Namespace
```bash
kubectl create ns alluxio
```

假设4个节点: node1 - node4, 预期部署alluxio-master到node1，alluxio-worker到node2-node4  
```bash
# set node labels
kubectl label nodes node1 app=alluxio-master
kubectl label nodes node2 app=alluxio-worker
kubectl label nodes node3 app=alluxio-worker
kubectl label nodes node4 app=alluxio-worker
kubectl get nodes --show-labels
```

node1 (alluxio-master):
```bash
mkdir -p /tmp/alluxio-logs/
mkdir -p /tmp/alluxio-journal-data
```

node2-node4 (alluxio-worker):
```bash
mkdir -p /tmp/alluxio-logs/
mkdir -p /tmp/alluxio-worker-domain
chmod a+w /tmp/alluxio-worker-domain
```

### k8s上部署alluxio集群

修改Worker内存配置
  - 修改`yaml/alluxio-configs.env`配置`ALLUXIO_WORKER_MEMORY_SIZE`
  - 修改`yaml/alluxio-worker.yaml`配置`alluxio-ramdisk.emptyDir.sizeLimit`

部署
```bash
# config map 
kubectl -n alluxio create configmap alluxio-config --from-file=ALLUXIO_CONFIG=yaml/alluxio-configs.env
# persist volume
kubectl -n alluxio create -f yaml/alluxio-journal-volume.yaml
# alluxio master
kubectl -n alluxio create -f yaml/alluxio-master.yaml --record
# alluxio worker
kubectl -n alluxio create -f yaml/alluxio-worker.yaml --record
```

验证
```bash
kubectl -n alluxio get sts
kubectl -n alluxio get svc
kubectl -n alluxio get cm
kubectl -n alluxio get pvc
kubectl -n alluxio get pv
kubectl -n alluxio get ds
kubectl -n alluxio get pods  -o wide
kubectl -n alluxio describe statefulsets alluxio-master
kubectl -n alluxio describe daemonsets alluxio-worker
kubectl -n alluxio describe pod alluxio-master-0
kubectl -n alluxio logs -f alluxio-master-0
kubectl -n alluxio exec -it alluxio-master-0 bash
```

日志(server&fuse)
```bash
tail -f /tmp/alluxio-logs/*
```

### 挂载云对象存储
```bash
kubectl -n alluxio exec alluxio-master-0 mkdir /alluxio-fuse/mnt

// Aliyun OSS
kubectl -n alluxio exec alluxio-master-0 alluxio fs mount \
	--option fs.oss.accessKeyId={oss.accessid} \
	--option fs.oss.accessKeySecret={oss.accesssecret} \
	--option fs.oss.endpoint={oss.endpoint} \
	/mnt/oss oss://{bucket}/{directory}

// AWS S3
kubectl -n alluxio exec alluxio-master-0 alluxio fs mount \
	--option aws.accessKeyId={aws.accessid} \
	--option aws.secretKey={aws.accesssecret} \
	/mnt/s3 s3a://{bucket}/{directory}
```

[More UFS](http://www.alluxio.org/docs/1.8/en/ufs/S3.html)

(可选) 预加载数据到Alluxio Memory Storage, 耗时根据数据量和网络情况不等
```bash
kubectl -n alluxio exec alluxio-master-0 alluxio fs load /mnt/oss
kubectl -n alluxio exec alluxio-master-0 alluxio fs load /mnt/s3
```

查询空间占用
```bash
kubectl -n alluxio exec alluxio-master-0 alluxio fs getCapacityBytes
kubectl -n alluxio exec alluxio-master-0 alluxio fs getUsedBytes
```

查询数据落在哪个节点
```bash
kubectl -n alluxio exec alluxio-master-0 alluxio fs location /mnt/*/*
```

[More CLI](http://www.alluxio.org/docs/1.8/en/basic/Command-Line-Interface.html)

### 通过FUSE访问
通过POSIX文件操作访问任意一个alluxio 容器内的 `/alluxio-fuse` 来访问cache在Alluxio Worker中的数据
```bash
kubectl -n alluxio exec -it alluxio-master-0 ls /alluxio-fuse/
```
FUSE 使用限制:
  - 不支持软硬链接
  - 不支持chown/chgrp 
  - 只能在Alluxio容器内使用, fuse是用户态文件系统
  - 只允许一次性顺序写入，不支持修改，如需修改必须先删除再重新写入

写入数据注意:
> 注意:默认通过FUSE写入到Alluxio的数据，都是`MUST_CACHE`方式, 只存留在`Alluxio Memory Storage`
> 需要手动执行`alluxio fs persist <path>`来保证数据写入到底层存储设备  

Example:
```bash
cp /etc/mime.types  /alluxio-fuse/mnt/oss/mime.types
alluxio fs persist /mime.types
```

### k8s上删除alluxio集群
删除
```bash
kubectl -n alluxio delete -f yaml/alluxio-worker.yaml
kubectl -n alluxio scale --replicas=0 sts/alluxio-master
kubectl -n alluxio delete -f yaml/alluxio-master.yaml
kubectl -n alluxio delete configmaps alluxio-config
kubectl -n alluxio delete -f yaml/alluxio-journal-volume.yaml # must
```

验证
```bash
kubectl -n alluxio get all
kubectl -n alluxio get cm
kubectl -n alluxio get pvc
kubectl -n alluxio get pv alluxio-journal-volume
```
