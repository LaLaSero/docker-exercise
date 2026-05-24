#!/bin/bash

set -e

cd /var/www/html

echo "waiting for mariadb to start"
until mysqladmin ping -h "mariadb" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" --silent; do
    sleep 1
done

if [ ! -f wp-cli.phar ]; then
    curl -o wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
fi

if [ ! -f wp-config.php ]; then
    ./wp-cli.phar core download --allow-root --force
    ./wp-cli.phar config create --dbname=wordpress --dbuser="$WORDPRESS_DB_USER" --dbpass="$WORDPRESS_DB_PASSWORD" --dbhost=mariadb --allow-root
fi

./wp-cli.phar config set DISALLOW_FILE_EDIT false --allow-root
./wp-cli.phar config set DISALLOW_FILE_MODS false --allow-root
./wp-cli.phar config set FS_METHOD direct --allow-root

if ! ./wp-cli.phar core is-installed --allow-root; then
    ./wp-cli.phar core install --url="$DOMAIN_NAME" --title=inception --admin_user="$WORDPRESS_ADMIN_USER" --admin_password="$WORDPRESS_ADMIN_PASSWORD" --admin_email="$WORDPRESS_ADMIN_EMAIL" --allow-root
fi

if ! ./wp-cli.phar user get "$WORDPRESS_USER" --allow-root >/dev/null 2>&1; then
    ./wp-cli.phar user create "$WORDPRESS_USER" "$WORDPRESS_USER_EMAIL" --user_pass="$WORDPRESS_USER_PASSWORD" --role=author --allow-root
fi

chown -R www-data:www-data /var/www/html
exec "$(command -v php-fpm8.2)" -F
