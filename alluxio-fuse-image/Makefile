default: image

TARNAME := "alluxio-1.8.1-bin.tar.gz"
# TARNAME := "alluxio-1.7.0-bin.tar.gz"

IMAGE := "bbklab/alluxio-fuse:latest"
IMAGETF := "bbklab/alluxio-fuse-tensorflow:latest"

DOCKERFILE := "Dockerfile.fuse"
DOCKERFILETF := "Dockerfile.fuse.tensorflow"

image:
	@cp -avf tar/$(TARNAME) src/
	@pushd src && docker build -f $(DOCKERFILE) --build-arg ALLUXIO_TARBALL=$(TARNAME) -t $(IMAGE) . && popd
	@rm -f src/$(TARNAME)

image-tensorflow:
	@cp -avf tar/$(TARNAME) src/
	@pushd src && docker build -f $(DOCKERFILETF) --build-arg ALLUXIO_TARBALL=$(TARNAME) -t $(IMAGETF) . && popd
	@rm -f src/$(TARNAME)

push:
	docker push $(IMAGE)
	docker push $(IMAGETF)

all: image image-tensorflow push
