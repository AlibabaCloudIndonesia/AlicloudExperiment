sudo yum install -y yum-utils

sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

sudo yum install -y --nobest docker-ce docker-ce-cli containerd.io

sudo systemctl start docker

sudo docker run -d -p 8888:80 nginx:latest
