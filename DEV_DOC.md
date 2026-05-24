# Developer Documentation

## Prerequisites

- Docker Engine and Docker Compose.
- A 42 evaluation VM for the canonical run.
- A local `srcs/.env` file created from `srcs/.env.example`.
- The domain `yutakagi.42.fr` mapped to the VM local address.

## Project layout

Mandatory configuration lives in `srcs/`. Each service has its own Dockerfile:

- `srcs/requirements/nginx/Dockerfile`
- `srcs/requirements/wordpress/Dockerfile`
- `srcs/requirements/mariadb/Dockerfile`

The default Compose file is `srcs/docker-compose.yml`. The macOS override example is `srcs/docker-compose.macos.yml.example` and must not be used for evaluation.

## Build and run

42 VM:

```sh
make
make up
make down
make clean
make fclean
make re
```

macOS local verification:

```sh
cp srcs/docker-compose.macos.yml.example srcs/docker-compose.macos.yml
make mac-up
make mac-down
make mac-clean
make mac-fclean
make mac-re
```

## Docker Compose commands

Canonical configuration:

```sh
docker compose -f srcs/docker-compose.yml config
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs
```

macOS verification configuration:

```sh
docker compose -f srcs/docker-compose.yml -f srcs/docker-compose.macos.yml config
docker compose -f srcs/docker-compose.yml -f srcs/docker-compose.macos.yml ps
```

## Persistence

The mandatory stack uses Docker named volumes:

- `wp_files` mounted at `/var/www/html`
- `db_data` mounted at `/var/lib/mysql`

On the 42 VM, their host data lives under:

```txt
/home/yutakagi/data/wordpress
/home/yutakagi/data/mariadb
```

On macOS verification only, the override maps them to:

```txt
/Users/yutakagi/data/wordpress
/Users/yutakagi/data/mariadb
```

## Database access

From the MariaDB container:

```sh
docker exec -it mariadb mariadb -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" wordpress
```

Then check tables:

```sql
SHOW TABLES;
```

## Validation notes

Before final validation, start from clean Docker resources and clean data directories if old invalid WordPress state exists.

The evaluated path is always:

```sh
make
```

Do not use `make mac-up` during peer evaluation unless the reviewer explicitly agrees that the machine is only being used for local macOS verification.
