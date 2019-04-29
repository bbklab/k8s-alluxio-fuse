# k8s-alluxio-fuse

### 镜像
  - 查看[构建alluxio-fuse镜像](alluxio-fuse-image) 进行构建
  - 或 直接使用构建好的镜像:
    + `docker pull bbklab/alluxio-fuse`
    + `docker pull bbklab/alluxio-fuse-tensorflow`

### docker单机
  [docker单机测试](docker)

### k8s集群
  [k8s集群部署和使用](k8s)

### 主机集群
  [主机集群部署和速度测试](host)

### REST API
  - [Master](http://www.alluxio.org/restdoc/1.8/master/index.html)    - `http://{master_ip}:19999`
  - [Worker](http://www.alluxio.org/restdoc/1.8/worker/index.html)    - `http://{worker_ip}:30000`
  - [Proxy](http://www.alluxio.org/restdoc/1.8/proxy/index.html)      - `http://{proxy_ip}:39999`

### SDK
  - [Alluxio SDK](http://www.alluxio.org/docs/1.8/en/api/FS-API.html)  - Jave,Python,Go

### FUSE
  - 镜像已封装,容器启动默认已挂载到路径 `/alluxio-fuse`

### CLI
  - [Alluxio CLI](http://www.alluxio.org/docs/1.8/en/basic/Command-Line-Interface.html)

### Refers
  - http://www.alluxio.org/docs/1.8/en/Overview.html
  - **Data Flow**: http://www.alluxio.org/docs/1.8/en/Architecture-DataFlow.html
  - **FUSE**: http://www.alluxio.org/docs/1.8/en/api/FUSE-API.html
  - https://github.com/Alluxio/alluxio/tree/master/integration/docker
  - https://github.com/Alluxio/alluxio/tree/master/integration/fuse
  - https://github.com/Alluxio/alluxio/tree/master/integration/kubernetes
