# Setup Memo

## 2026-05-24: `make up` retry errors

- MariaDB container failed on repeated `make up` because `script.sh` always ran `CREATE DATABASE wordpress` and `CREATE USER ...` even when the bind-mounted DB data already existed.
- Updated `srcs/requirements/mariadb/script.sh` so database/user creation is idempotent:
  - skip `mysql_install_db` when `/var/lib/mysql/mysql` already exists
  - use `CREATE DATABASE IF NOT EXISTS`
  - use `CREATE USER IF NOT EXISTS`
  - run `ALTER USER` so passwords match `.env`
  - stop the temporary server with `mysqladmin shutdown`
- WordPress startup also needed to be idempotent because it removed `/var/www/html` on every boot and attempted a fresh install every time.
- Updated `srcs/requirements/wordpress/script.sh` so it:
  - no longer deletes existing WordPress files
  - downloads WP-CLI only when missing
  - creates `wp-config.php` only when missing
  - runs `wp core install` only when WordPress is not already installed
  - passes `WORDPRESS_ADMIN_EMAIL` to WP-CLI
- Removed an accidental command fragment from `srcs/.env`:
  - `--admin_email="$WORDPRESS_ADMIN_EMAIL"`
- Debian `latest` currently installs PHP 8.4, while the original WordPress files were hard-coded for PHP 8.2.
- Updated the WordPress Dockerfile/script so the FPM pool config is copied to the installed PHP version and startup uses the available `php-fpm8.x` binary.
- MariaDB was bound to `127.0.0.1`, so WordPress could not connect from another container and stayed at `waiting for mariadb to start`.
- Updated `srcs/requirements/mariadb/50-server.cnf` to `bind-address = 0.0.0.0` for Docker network access.
- MariaDB originally exposed its temporary initialization server before shutting it down and starting the real server. WordPress could connect during that window and then fail with `Database connection error (2002) Connection refused`.
- Updated MariaDB startup so initialization runs only when `/var/lib/mysql/mysql` does not exist, and the temporary server uses `--skip-networking`.
- WordPress can be left with partial files after an interrupted install, so `wp core download` now uses `--force` when `wp-config.php` is missing.

After these changes, rebuild images before starting:

```sh
make build
make up
```


主な通常ターゲット(42 環境)

make prepare   # /home/yutakagi/data/... を作成
make build     # 42VM用構成でビルド
make up        # 42VM用構成で build + 起動
make down      # コンテナ停止・削除、volumeは残す
make clean     # コンテナ停止・削除、volumeとlocal imageも削除
make fclean    # clean + /home/yutakagi/data/... も削除
make re        # fclean してから up

macos の確認用のコマンド

make mac-prepare  # /Users/yutakagi/data/... を作成し、macOS overrideを用意
make mac-up       # macOS用構成で build + 起動
make mac-down     # macOS用構成で停止・削除、volumeは残す
make mac-clean    # macOS用構成で停止・削除、volumeとlocal imageも削除
make mac-fclean   # mac-clean + /Users/yutakagi/data/... も削除
make mac-re       # mac-fclean してから mac-up