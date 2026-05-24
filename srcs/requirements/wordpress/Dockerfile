FROM debian:12

RUN apt-get update && \
    apt-get install -y --no-install-recommends php-fpm php-mysqli curl mariadb-client ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY www.conf /tmp/www.conf
RUN cp /tmp/www.conf /etc/php/*/fpm/pool.d/www.conf
COPY script.sh .
RUN chmod +x script.sh

CMD ["./script.sh"]
