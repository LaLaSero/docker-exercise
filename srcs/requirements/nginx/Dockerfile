FROM debian:12

RUN apt-get update && apt-get install -y --no-install-recommends nginx openssl && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/nginx 
RUN mkdir -p /etc/nginx/ssl
RUN chown -R www-data:www-data /run/nginx

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/server.key \
    -out /etc/nginx/ssl/server.crt \
    -subj "/CN=yutakagi.42.fr"

COPY default /etc/nginx/sites-available/.
RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
