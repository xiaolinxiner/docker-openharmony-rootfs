# Docker-openharmony-rootfs
Because the userland of OpenHarmony can run on the Linux kernel, containerization of OpenHarmony is feasible.

This project has turned OpenHarmony's mini rootfs into a Docker image, which allows us to use Linux servers instead of physical OpenHarmony devices to run and test our command-line programs.

## Architecture support
arm64 only

## Get image
Pull from GitHub Container Registry
```sh
docker pull ghcr.io/hqzing/docker-openharmony-rootfs:latest

# chinese mirror site
# docker pull ghcr.nju.edu.cn/hqzing/docker-openharmony-rootfs:latest
```

Or build image yourself (Use an ARM server or Docker Buildx on a non ARM server)
```sh
git clone https://github.com/hqzing/docker-openharmony-rootfs
cd docker-openharmony-rootfs

# Use an ARM server
docker build -t docker-openharmony-rootfs:latest .

# Use Docker Buildx on a non ARM server
# DOCKER_BUILDKIT=1 docker buildx build -t docker-openharmony-rootfs:latest --platform linux/arm64 .
```

## Usage
Run the container with default command
```sh
docker run -itd --name=ohos ghcr.io/hqzing/docker-openharmony-rootfs:latest
docker exec -it ohos sh
```

## Need more command-line tools?
The rootfs of OpenHarmony is mainly composed of three parts: [musl libc](https://musl.libc.org/), [toybox](https://landley.net/toybox), and [mksh](https://github.com/MirBSD/mksh).

In this rootfs, the command-line tools are provided by `toybox`, which offers a very limited number of command-line tools.

Additionally, OpenHarmony has not yet provided a package manager. It's difficult for us to increase command-line tools. 

In order to provide the possibility of expanding more tools, I pre-set a `curl` in the system, which users can use to download more software.

Many open-source software for the linux-arm64-musl platform can run in this container, such as busybox here.
```sh
curl https://dl-cdn.alpinelinux.org/v3.22/main/aarch64/busybox-static-1.37.0-r18.apk -o busybox-static-1.37.0-r18.apk
tar -zxf busybox-static-1.37.0-r18.apk
cp ./bin/busybox.static /bin/busybox
ln -s /bin/busybox /bin/vi
# now you can use 'vi' command
```

# Use it on GitHub workflow

