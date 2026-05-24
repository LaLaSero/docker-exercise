*This project has been created as part of the 42 curriculum by yutakagi.*

# Inception

## Description

Inception is a small Docker Compose infrastructure that serves a configured WordPress website through NGINX over HTTPS. The stack contains three mandatory services:

- NGINX with TLSv1.2/TLSv1.3 only.
- WordPress with php-fpm only.
- MariaDB only.

NGINX is the only public entrypoint and exposes port 443. WordPress files and MariaDB data are persisted through Docker named volumes.

## Project description

The project uses Docker Compose to build and run one custom image per service. Each image is based on Debian 12 and is built locally from its own Dockerfile.

Main design choices:

- Virtual Machines vs Docker: the project runs inside a VM, while Docker containers isolate each service with less overhead than full VMs.
- Secrets vs Environment Variables: local runtime configuration is stored in `srcs/.env`, which is ignored by Git. `srcs/.env.example` documents the required keys without real credentials.
- Docker Network vs Host Network: services communicate through a private Docker network. Host networking and legacy container linking are not used.
- Docker Volumes vs Bind Mounts: the mandatory stack uses Docker named volumes for WordPress files and MariaDB data. On the 42 VM, their data is stored under `/home/yutakagi/data`.

## Instructions

Create the local environment file:

```sh
cp srcs/.env.example srcs/.env
```

Edit `srcs/.env` and replace the placeholder passwords. Then add the domain to the VM hosts file:

```sh
sudo sh -c 'echo "127.0.0.1 yutakagi.42.fr" >> /etc/hosts'
```

Build and start the mandatory stack:

```sh
make
```

Useful commands:

```sh
make up
make down
make clean
make fclean
make re
```

Open the website at:

```txt
https://yutakagi.42.fr
```

For macOS-only local verification, copy the override example and use the macOS targets:

```sh
cp srcs/docker-compose.macos.yml.example srcs/docker-compose.macos.yml
make mac-up
make mac-fclean
```

The macOS override is only for local testing. The evaluated configuration is the default `docker-compose.yml` and the normal `make` / `make up` commands.

## Resources

- Docker documentation: https://docs.docker.com/
- Docker Compose documentation: https://docs.docker.com/compose/
- NGINX documentation: https://nginx.org/en/docs/
- WordPress CLI documentation: https://wp-cli.org/
- MariaDB documentation: https://mariadb.com/kb/en/documentation/
- Debian releases: https://www.debian.org/releases/

AI was used to review the subject requirements, compare the current implementation with the review sheet, and draft documentation/checklists. All commands, configuration changes, and project behavior remain the responsibility of the project author.
