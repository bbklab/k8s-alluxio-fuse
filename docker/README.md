

### 环境准备
```bash
mkdir /mnt/ramdisk1G
mount -t ramfs -o size=1G ramfs /mnt/ramdisk1G
chmod a+w /mnt/ramdisk1G
service docker restart

mkdir -p /data/alluxio-local-ufs
```

### 启动1master/1worker

```bash
img="bbklab/alluxio-fuse:latest" # built with fuse feature supported
master_hostname="localhost"
# oss
fs_oss_accessKeyId="{your_oss_access_key}"
fs_oss_accessKeySecret="{your_oss_access_secret}"
fs_oss_endpoint="{your_oss_endpoint_fqdn}"
# aws s3
aws_accesskeyid="{your_aws_access_keyid}"
aws_secretkey="{your_aws_secret_key}"


# clean up previous
docker stop alluxio-master alluxio-node
docker rm alluxio-master alluxio-node


# launch a master
# port: 19998  19999(WebUI)
docker run -d --name=alluxio-master \
	--net=host \
	--cap-add SYS_ADMIN \
	--device /dev/fuse \
	-e ALLUXIO_MASTER_HOSTNAME=${master_hostname} \
	-e FS_OSS_ACCESSKEYID="${fs_oss_accessKeyId}" \
	-e FS_OSS_ACCESSKEYSECRET="${fs_oss_accessKeySecret}" \
	-e FS_OSS_ENDPOINT="${fs_oss_endpoint}" \
	-e AWS_ACCESSKEYID=${aws_accesskeyid} \
	-e AWS_SECRETKEY=${aws_secretkey} \
	-w /opt/alluxio \
	-v /data/alluxio-local-ufs:/opt/alluxio/underFSStorage \
	$img master --no-format
	# $img master 

# launch a worker
# port: 29998  29999  30000(WebUI)
docker run -d --name=alluxio-node \
	--net=host \
	--cap-add SYS_ADMIN \
	--device /dev/fuse \
	-e ALLUXIO_MASTER_HOSTNAME=${master_hostname} \
	-e ALLUXIO_RAM_FOLDER=/ramdisk \
	-e ALLUXIO_WORKER_MEMORY_SIZE=1G \
	-e FS_OSS_ACCESSKEYID="${fs_oss_accessKeyId}" \
	-e FS_OSS_ACCESSKEYSECRET="${fs_oss_accessKeySecret}" \
	-e FS_OSS_ENDPOINT="${fs_oss_endpoint}" \
	-e AWS_ACCESSKEYID=${aws_accesskeyid} \
	-e AWS_SECRETKEY=${aws_secretkey} \
	-w /opt/alluxio \
	-v /data/alluxio-local-ufs:/opt/alluxio/underFSStorage \
	-v /mnt/ramdisk1G:/ramdisk \
	$img worker --no-format
	# $img worker
```

### Dashboard
  - master : http://localhost:19999
  - worker : http://localhost:30000

### Alluxio REST API
  - [Master](http://www.alluxio.org/restdoc/1.8/master/index.html)    - `http://{master_ip}:19999`
  - [Worker](http://www.alluxio.org/restdoc/1.8/worker/index.html)    - `http://{worker_ip}:30000`
  - [Proxy](http://www.alluxio.org/restdoc/1.8/proxy/index.html)      - `http://{proxy_ip}:39999`

### Alluxio CLI
```bash
## run test
docker exec -it alluxio-master /bin/bash
bin/alluxio runTests

## create alluxio file 
docker exec -it alluxio-master /bin/bash
bin/alluxio fs mkdir /demo /xxxx
bin/alluxio fs touch /demo/f1
bin/alluxio fs touch /demo/f2

## copy local files to alluxio
bin/alluxio fs copyFromLocal LICENSE /LICENSE
bin/alluxio fs cat /LICENSE
bin/alluxio rm /LICENSE

## load file into alluxio
bin/alluxio fs load /LICENSE

## persist all of alluxio file to UFS (Under FS Storage)
bin/alluxio fs persist /
ls -R underFSStorage/

## leader info
bin/alluxio fs leader

## space info
bin/alluxio fs getCapacityBytes
bin/alluxio fs getUsedBytes

# mkdir
bin/alluxio fs mkdir /mnt

## mount oss (RO) 
## note: use the env `FS_OSS_*`
bin/alluxio fs mount -readonly /mnt/oss oss://alluxio

## mount oss (RW)
## note: use specified `FSS_OSS_*` options
bin/alluxio fs mount \
  --option fs.oss.accessKeyId=${fs_oss_accessKeyId} \
  --option fs.oss.accessKeySecret=${fs_oss_accessKeySecret} \
  --option fs.oss.endpoint=${fs_oss_endpoint} \
  /mnt/oss oss://alluxio
bin/alluxio fs ls -R /mnt/oss                                 # not In-Alluxio
bin/alluxio fs load  /mnt/oss                                 # now In-Alluxio
bin/alluxio fs free  /mnt/oss                                 # now out of Alluxio
bin/alluxio fs cat   /mnt/oss/0.mmkv.default                  # after once read
bin/alluxio fs ls    /mnt/oss/0.mmkv.default                  # now this file In-Alluxio
cp /alluxio-fuse/mnt/oss/axel  /tmp/a                         # after once read via FUSE
bin/alluxio fs ls    /mnt/oss/axel                            # now this file In-Alluxio
bin/alluxio fs mkdir   /mnt/oss/newdir                        # create new dir
bin/alluxio fs copyFromLocal LICENSE /mnt/oss/newdir/LICENSE  # copy local file to new directory via CLI
bin/alluxio fs ls -R   /mnt/oss/newdir                        # new copied files are NOT-PERSISTED
bin/alluxio fs persist /mnt/oss/newdir                        # login your oss to see the new file: `newdir/LICENSE`

## mount s3 
## note: use the env `AWS_ACCESSKEYID` `AWS_SECRETKEY`
bin/alluxio fs mount -readonly /mnt/s3 s3a://alluxio-quick-start/data

## mount s3 (RW)
bin/alluxio fs mkdir /mnt
bin/alluxio fs mount \
  --option aws.accessKeyId=${aws_accesskeyid} \
  --option aws.secretKey=${aws_secretkey} \
  /mnt/s3 s3a://alluxio-quick-start/data
bin/alluxio fs ls -R /mnt/s3                            # not In-Alluxio
time bin/alluxio fs cat /mnt/s3/sample_tweets_1m.csv    # 14s, first read, cost a long time
bin/alluxio fs ls -R /mnt/s3                            # after once read, the file sample_tweets_1m.csv is In-Alluxio now
time bin/alluxio fs cat /mnt/s3/sample_tweets_1m.csv    # 1s, second read, 14 times faster than first read

## umount
bin/alluxio fs unmount /mnt/oss
bin/alluxio fs unmount /mnt/s3

## location
bin/alluxio fs location /\*                             # all files are randomly located at multi nodes
bin/alluxio fs location /os-release                     # firstly this file located at `alluxio-node1`
bin/alluxio fs cat      /os-release                     # then we read this file from `alluxio-node2`
bin/alluxio fs location /os-release                     # then this file will located at both `alluxio-node1` and `alluxio-node2`

## fuse
## note: all newly write files to fuse default not write to actually file storage, only in the alluxio memory storage
integration/fuse/bin/alluxio-fuse stat
cd /alluxio-fuse/mnt/oss/newdir                               # copy some local files to alluxio via FUSE
cp /opt/alluxio/conf/metrics.properties.template  .
cp /etc/pam.conf .
bin/alluxio fs persist /mnt/oss/newdir                        # new file will be write back to remote oss
touch append.file
echo line1 >> append.file                                     # append file is not supported: write error: File exists
```
> See More:  
> [Alluxio CLI](http://www.alluxio.org/docs/1.8/en/basic/Command-Line-Interface.html)  

### Refers
  - https://github.com/Alluxio/alluxio/tree/master/integration/docker
  - http://www.alluxio.org/docs/1.8/cn/api/FUSE-API.html
