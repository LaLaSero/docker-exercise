修正点
元々、docker-compose.ymlにおいて、
device: /home/$(whoami)/data/mariadb
      device: /home/$(whoami)/data/wordpress
であったが、
mac os上では、
device: /Users/yutakagi/data/mariadb
にする。

device: /Users/yutakagi/data/wordpress


mkdir -p /Users/yutakagi/data/mariadb
mkdir -p /Users/yutakagi/data/wordpress
これをする必要がある


docker 一覧
docker ps -a --filter name=nginx


/Users/yutakagi/dev/inception/Inception/srcs/requirements/wordpress/Dockerfile
に、
RUN apt update && apt upgrade -y && apt install -y php-fpm php-mysqli curl mariadb-client
を追加