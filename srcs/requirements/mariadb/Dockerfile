FROM debian:12

RUN apt-get update && \
    apt-get install -y --no-install-recommends mariadb-server && \
    rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND=noninteractive

COPY 50-server.cnf /etc/mysql/mariadb.conf.d/.
# COPY init.sql /etc/mysql/init.sql
COPY script.sh .

RUN mkdir /run/mysqld && chmod +x script.sh

EXPOSE 3306

CMD [ "./script.sh" ]
