
## Build
```bash
axel -n 20 -o tar/alluxio-1.8.1-bin.tar.gz http://downloads.alluxio.org/downloads/files//1.8.1/alluxio-1.8.1-bin.tar.gz
make image
```
product image: `bbklab/alluxio-fuse:latest`  `bbklab/alluxio-fuse-tensorflow`   

说明:
> Alluxio官方没有提供**fuse enabled**的Docker镜像(带libfuse-dev)，需要自己Build  
> 原[Alluxio仓库](https://github.com/Alluxio/alluxio/blob/master/integration/docker/)中Fuse镜像构建和entrypoint.sh脚本有问题  
> 这里使用`src`目录下修改过的相关文件和脚本进行构建  


## Refers
  - https://github.com/Alluxio/alluxio/blob/master/integration/docker/README.md
