# User Documentation

## Services

This stack provides a WordPress website served through NGINX with HTTPS. MariaDB stores the WordPress database. Only NGINX is reachable from the host, and only through port 443.

## Start and stop

On the 42 VM:

```sh
cp srcs/.env.example srcs/.env
make
make down
make re
```

Before the first start, edit `srcs/.env` and replace all placeholder passwords.

## Access

Add the local domain on the VM:

```sh
sudo sh -c 'echo "127.0.0.1 yutakagi.42.fr" >> /etc/hosts'
```

Website:

```txt
https://yutakagi.42.fr
```

Administration panel:

```txt
https://yutakagi.42.fr/wp-admin/
```

HTTP access is not expected to work:

```txt
http://yutakagi.42.fr
```

## Credentials

Credentials are stored locally in `srcs/.env`. This file is ignored by Git and must not be committed.

Use `srcs/.env.example` as the template. The admin username must not contain `admin`, `Admin`, `administrator`, or `Administrator`.

## Basic checks

Check containers:

```sh
docker compose -f srcs/docker-compose.yml ps
```

Check volumes:

```sh
docker volume ls
docker volume inspect srcs_wp_files
docker volume inspect srcs_db_data
```

Check HTTPS:

```sh
curl -k -I https://yutakagi.42.fr
```

Check that HTTP is closed:

```sh
curl -I http://yutakagi.42.fr
```

## macOS local verification

macOS verification is only a local convenience path. It does not replace the 42 VM evaluation configuration.

```sh
cp srcs/docker-compose.macos.yml.example srcs/docker-compose.macos.yml
sudo sh -c 'echo "127.0.0.1 yutakagi.42.fr" >> /etc/hosts'
make mac-up
make mac-fclean
```

On macOS, the local data directories are:

```txt
/Users/yutakagi/data/wordpress
/Users/yutakagi/data/mariadb
```
