# Inception implementation gap report

作成日: 2026-05-24

このレポートは、`inception_subject.pdf` を正とし、`review_sheet.md` を評価時の確認手順として扱って、現在の実装との差分をまとめたものです。`review_sheet.md` と subject が食い違う場合は subject を優先しています。

## 結論

現在の実装は、3サービス構成の起動自体はできていますが、subject / review sheet の必須条件に対してはまだ不合格になる可能性が高いです。

特に修正優先度が高いものは以下です。

- すべてのDockerfileが `FROM debian:latest` を使っている。`latest` はsubjectで明示禁止。
- ベースOSが「penultimate stable version」の固定タグになっていない。
- named volume の保存先が `/home/<login>/data` ではなく `/Users/yutakagi/data`。
- volume設定が `o: bind` を使っており、subjectの「bind mounts are not allowed」と衝突する可能性がある。
- `README.md` が指定フォーマットと必須セクションを満たしていない。
- `USER_DOC.md` と `DEV_DOC.md` が存在しない。
- WordPressの管理者ユーザー名が `wp_admin` で、`admin` を含むため禁止条件に違反。
- WordPress側の通常ユーザーが作成されていないように見える。
- `yutakagi.42.fr` が現環境で名前解決できていない。
- 認証情報を含む `.env` が作業ツリー内にあり、Git管理から除外されている保証が見えない。

## 現在確認できた実装

### ファイル構成

現在の主要ファイル:

- `Makefile`
- `README.md`
- `srcs/.env`
- `srcs/docker-compose.yml`
- `srcs/requirements/nginx/Dockerfile`
- `srcs/requirements/nginx/default`
- `srcs/requirements/wordpress/Dockerfile`
- `srcs/requirements/wordpress/script.sh`
- `srcs/requirements/wordpress/www.conf`
- `srcs/requirements/mariadb/Dockerfile`
- `srcs/requirements/mariadb/script.sh`
- `srcs/requirements/mariadb/50-server.cnf`
- `srcs/requirements/mariadb/init.sql`

不足している必須ファイル:

- `USER_DOC.md`
- `DEV_DOC.md`
- `.gitignore`

また、現在のディレクトリは `git status` が `fatal: not a git repository` になりました。提出時は42のGitリポジトリ上の内容だけが評価対象なので、実際の提出リポジトリで同じ内容が管理されているか確認が必要です。

### 起動状態

`docker compose -f srcs/docker-compose.yml ps` では以下の3コンテナが起動していました。

- `nginx`
- `wordpress`
- `mariadb`

公開ポート:

- `nginx`: `0.0.0.0:443->443/tcp`
- `mariadb`: ホストには公開されていない。コンテナ内で `3306/tcp`
- `wordpress`: ホストには公開されていない。

確認結果:

- `http://localhost` は接続不可。80番が閉じている点は良い。
- `https://localhost` は `HTTP/1.1 200 OK` を返した。443番で応答している点は良い。
- TLSv1.2 と TLSv1.3 はどちらも接続可能。
- TLSv1.1 は接続不可。
- `http://yutakagi.42.fr` / `https://yutakagi.42.fr` は現環境で名前解決できなかった。

## 必須要件との差分

### 1. ベースイメージ

現在:

- `srcs/requirements/nginx/Dockerfile:1`
  - `FROM debian:latest`
- `srcs/requirements/wordpress/Dockerfile:1`
  - `FROM debian:latest`
- `srcs/requirements/mariadb/Dockerfile:1`
  - `FROM debian:latest`

subject上の正解:

- `latest` タグは禁止。
- Alpine または Debian の penultimate stable version を固定タグで使う。
- 既製の nginx / wordpress / mariadb イメージをpullしてはいけない。

差分:

- `debian:latest` は明確に不合格要因。
- 現在の `latest` はビルド時点で変わるため、評価環境・評価時期で中身が変わる。
- 実ログ上、MariaDBは Debian 13 系パッケージから入っているため、penultimate stable ではない可能性が高い。

修正:

- すべてのDockerfileを固定タグにする。
- 2026-05-24時点でDebian公式情報では Debian 13/Trixie が stable、Debian 12/Bookworm が oldstable なので、Debianを選ぶなら `debian:12` またはより具体的な `debian:12.x` 系を検討する。
- 評価時期が変わると「penultimate stable」も変わるため、提出直前にDebian/Alpine公式のリリース状態を確認する。

### 2. Dockerfileごとのサービス分離

現在:

- nginx、wordpress、mariadb それぞれにDockerfileがある。
- `docker-compose.yml` で各サービスの `build` が指定されている。
- `image` 名は `nginx`, `wordpress`, `mariadb` でサービス名と一致している。

subject上の正解:

- サービスごとに専用コンテナ。
- 各サービスごとに自作Dockerfile。
- image名は対応するservice名と同じ。
- WordPressコンテナにnginxを含めない。
- MariaDBコンテナにnginxを含めない。

判定:

- この項目は概ねOK。
- ただしベースイメージの `latest` 違反があるため、Dockerfile全体としては不合格。

### 3. docker compose / network

現在:

- `srcs/docker-compose.yml` に `networks` がある。
- `network: host` は使っていない。
- `links:` は使っていない。
- `docker network ls` で `srcs_42-inception-network` が確認できた。

subject上の正解:

- docker compose を使う。
- docker networkでコンテナ間接続する。
- `network: host`, `links:`, `--link` は禁止。

判定:

- この項目は概ねOK。

修正候補:

- ネットワーク名は現状でもComposeのprefix付きで作られるため評価上は通常問題ない。
- 明示名が必要なら `name: 42-inception-network` を追加してもよいが、必須ではない。

### 4. NGINX / TLS / 443のみ

現在:

- `srcs/docker-compose.yml:7-8` で `443:443` のみ公開。
- `srcs/requirements/nginx/default:27-33` で443/TLS設定。
- `ssl_protocols TLSv1.2 TLSv1.3;` がある。
- `curl http://localhost` は失敗。
- `curl -k https://localhost` は成功。
- TLSv1.2 / TLSv1.3 は成功。
- TLSv1.1 は失敗。

subject上の正解:

- NGINXが唯一の外部入口。
- 443番のみ。
- TLSv1.2またはTLSv1.3のみ。
- `https://<login>.42.fr` でWordPressが表示される。
- `http://<login>.42.fr` ではアクセスできない。

差分:

- `localhost` ではHTTPS応答するが、`yutakagi.42.fr` が名前解決できない。
- subjectの要求は `login.42.fr` でアクセスできることなので、現状のままだと評価手順で失敗する。

修正:

- VM側で `/etc/hosts` に `127.0.0.1 yutakagi.42.fr` またはVMのローカルIPに対応するエントリを追加する。
- 評価環境がVMなら、ブラウザから `https://yutakagi.42.fr` で到達できることを確認する。
- `DOMAIN_NAME`, nginx `server_name`, 証明書CN, WordPress siteurl/home をすべて同じ `yutakagi.42.fr` に揃える。

### 5. WordPress + php-fpm

現在:

- WordPressコンテナは `php-fpm`, `php-mysqli`, `curl`, `mariadb-client` を入れている。
- nginxは入っていない。
- php-fpmは `0.0.0.0:9000` でlistenしている。
- `nginx` は `fastcgi_pass wordpress:9000;` で接続している。
- `wp core install` は実行され、WordPressはインストール済み。

subject上の正解:

- WordPress + php-fpm のみ。
- nginxを含めない。
- WordPressはインストール済み・設定済み。
- WordPress DB内に2ユーザーが必要で、そのうち1人が管理者。
- 管理者ユーザー名に `admin`, `Admin`, `administrator`, `Administrator` を含めてはいけない。
- review sheetでは、通常ユーザーでコメント追加、管理者で管理画面ログインとページ編集ができることを確認される。

差分:

- 実行確認ではWordPressユーザーが `wp_admin` の1件だけだった。
- `wp_admin` は `admin` を含むため禁止条件に違反。
- 通常ユーザーが見当たらないため、review sheetの「available WordPress userでコメント追加」を満たせない可能性が高い。

修正:

- `.env` に管理者とは別の通常ユーザー用変数を追加する。
- 管理者名を `admin` を含まない名前に変更する。例: `yutakagi_owner`, `site_owner`, `rootuser` など。ただし `administrator` や `admin` を含めない。
- `wordpress/script.sh` で `wp user create` を使い、通常ユーザーを1人作成する。
- 既存volumeで検証する場合は、WordPressの既存ユーザーも更新またはvolumeを初期化して再インストールする。

例:

```sh
wp user create "$WORDPRESS_USER" "$WORDPRESS_USER_EMAIL" \
  --user_pass="$WORDPRESS_USER_PASSWORD" \
  --role=author \
  --allow-root
```

### 6. MariaDB

現在:

- MariaDBコンテナは `mariadb-server` をインストールしている。
- nginxは入っていない。
- `bind-address = 0.0.0.0` でDocker network越しに接続可能。
- DB `wordpress` とWordPressテーブルは存在した。
- DBユーザーは `WORDPRESS_DB_USER` と `WORDPRESS_DB_USER2` を作成している。

subject上の正解:

- MariaDBのみ。
- WordPress用DBが空でない。
- DBへログインできる。
- DB volumeが永続化される。

判定:

- DB自体は動作しており、WordPressテーブルも確認済み。
- ただしベースイメージとvolume設定の問題により、総合では不合格要因が残る。

修正候補:

- rootパスワードやrootユーザーの扱いを明確化する。
- review時にDBログイン方法を説明できるよう、`USER_DOC.md` / `DEV_DOC.md` にコマンドを書く。
- `GRANT ALL PRIVILEGES ON *.*` は広すぎるため、可能なら `wordpress.*` に限定する。

### 7. volumes / 永続化

現在:

`srcs/docker-compose.yml:48-60`

```yaml
volumes:
  wp_files:
    driver: local
    driver_opts:
      type: none
      device: /Users/yutakagi/data/wordpress
      o: bind
  db_data:
    driver: local
    driver_opts:
      type: none
      device: /Users/yutakagi/data/mariadb
      o: bind
```

実際の `docker volume inspect`:

- `srcs_wp_files`
  - device: `/Users/yutakagi/data/wordpress`
  - `o: bind`
- `srcs_db_data`
  - device: `/Users/yutakagi/data/mariadb`
  - `o: bind`

subject上の正解:

- WordPress DB用のvolume。
- WordPress website files用のvolume。
- Docker named volumesを使う。
- その2つの永続化ストレージにbind mountは使わない。
- どちらもhost上の `/home/<login>/data` 配下に保存する。

review sheet上の確認:

- `docker volume ls`
- `docker volume inspect <volume name>`
- 標準出力に `/home/login/data/` が含まれること。

差分:

- 現在のパスは `/Users/yutakagi/data/...` で、subject/reviewの `/home/yutakagi/data/...` と違う。
- `o: bind` を使っているため、subjectの「Bind mounts are not allowed」に対して危険。
- 42評価はVM上で行う前提なので、Mac用パスのままでは評価環境で落ちる。

修正:

- 評価用には `/home/yutakagi/data/wordpress` と `/home/yutakagi/data/mariadb` を使う。
- `Makefile` で事前に `mkdir -p /home/yutakagi/data/wordpress /home/yutakagi/data/mariadb` する。
- subjectの文言を厳密に読むなら、サービス定義で直接host pathを指定するbind mountは避ける。
- ただし review sheet は `docker volume inspect` に `/home/login/data/` が出ることを期待しているため、42の一般的な採点では `driver_opts` 方式が受け入れられる可能性がある。この点はsubject優先なら要注意。

### 8. restart policy / PID 1 / 無限ループ禁止

現在:

- 各サービスに `restart: always` がある。
- nginxは `CMD ["nginx", "-g", "daemon off;"]`。
- wordpressは最後に `exec php-fpm... -F`。
- mariadbは最後に `exec mysqld`。
- DockerfileのENTRYPOINT/CMDに `tail -f` はない。

問題点:

- `wordpress/script.sh:8-10` はMariaDB待機のため `while` と `sleep 1` を使っている。
- `mariadb/script.sh:8` は一時起動で `mysqld_safe --skip-networking & sleep 10` を使っている。

subject上の正解:

- コンテナを生かす目的の `tail -f`, `sleep infinity`, `while true` などは禁止。
- entrypoint scriptでも、無限ループやバックグラウンド常駐ハックは禁止。

判定:

- WordPressの待機ループは `while true` ではなく、DB起動待ちが終われば抜けるため、目的としては許容される可能性が高い。
- MariaDB初期化時の `mysqld_safe ... &` は、一時初期化用とはいえ「program in background」の指摘対象になる可能性がある。

修正:

- MariaDB初期化は可能なら `mysqld --bootstrap`、`mariadb-install-db` 後の明確な初期化手順、または一時サーバーのPIDを管理して確実に終了する方式にする。
- 少なくとも評価時に「コンテナ維持目的ではなく、初回DB初期化のために一時起動してshutdownしている」と説明できるようにする。

### 9. `.env` / secrets / 認証情報

現在:

- `srcs/.env` は存在する。
- 変数名として以下が確認できた。
  - `DOMAIN_NAME`
  - `WORDPRESS_DB_USER`
  - `WORDPRESS_DB_PASSWORD`
  - `WORDPRESS_DB_USER2`
  - `WORDPRESS_DB_PASSWORD2`
  - `WORDPRESS_ADMIN_USER`
  - `WORDPRESS_ADMIN_PASSWORD`
  - `WORDPRESS_ADMIN_EMAIL`
- `.gitignore` は見当たらない。
- `secrets/` ディレクトリも見当たらない。

subject上の正解:

- 環境変数を使うことは必須。
- `.env` を使うことも必須。
- Docker secretsの利用が強く推奨される。
- credentials, API keys, passwords がGit管理下にあると失敗。

review sheet上の補足:

- 評価中に作るローカル `.env` や Docker secrets は許容。
- Git repository内に、secrets用ファイル以外で認証情報があると0点。

差分:

- `.env` 自体はあるが、認証情報がGit管理から外れている保証がない。
- このディレクトリはGitリポジトリとして認識されなかったため、提出時に `.env` が追跡されているか判断できない。

修正:

- `.gitignore` を追加し、少なくとも以下を除外する。

```gitignore
srcs/.env
secrets/*
```

- 提出リポジトリでは、`.env` のサンプルが必要なら `.env.example` を用意し、実パスワードは含めない。
- secretsを使うなら `secrets/db_password.txt` などは評価時にローカル生成し、Git管理しない。

### 10. README

現在:

`README.md` は以下のみ。

```md
# Inception

This project is part of the Ecole 42 curriculum.

Deploy a WordPress service using Docker containers.
```

subject上の正解:

- rootに `README.md` が必要。
- 最初の行はイタリックで以下の形式。
  - `This project has been created as part of the 42 curriculum by <login...>`
- 英語で書く。
- 少なくとも以下のセクションが必要。
  - `Description`
  - `Instructions`
  - `Resources`
- `Resources` には通常の参考資料と、AIをどう使ったかの説明が必要。
- `Project description` で以下を説明。
  - Dockerと含まれるsource
  - main design choices
  - Virtual Machines vs Docker
  - Secrets vs Environment Variables
  - Docker Network vs Host Network
  - Docker Volumes vs Bind Mounts

差分:

- 1行目の指定形式を満たしていない。
- 必須セクションがない。
- AI利用説明がない。
- 比較説明がない。
- review sheet上は、これらが欠けているとそこで評価終了。

修正:

- READMEを英語で全面的に書き直す。
- 1行目は必ずイタリック指定にする。

例:

```md
*This project has been created as part of the 42 curriculum by yutakagi.*
```

### 11. USER_DOC.md / DEV_DOC.md

現在:

- `USER_DOC.md` が存在しない。
- `DEV_DOC.md` が存在しない。

subject上の正解:

- rootに `USER_DOC.md` が必要。
- rootに `DEV_DOC.md` が必要。
- Markdown形式。

`USER_DOC.md` に必要な内容:

- stackが提供するサービスの説明。
- start / stop方法。
- websiteとadmin panelへのアクセス方法。
- credentialsの場所と管理方法。
- サービスが正常稼働しているか確認する方法。

`DEV_DOC.md` に必要な内容:

- prerequisites。
- 初期セットアップ。
- config filesとsecrets。
- MakefileとDocker Composeでbuild / launchする方法。
- container / volume管理コマンド。
- データ保存場所と永続化の仕組み。

差分:

- どちらも未作成のため、review sheet上はここで評価終了。

修正:

- rootに2ファイルを追加する。
- 実際のコマンド、ドメイン、volumeパス、秘密情報の扱いを明記する。

### 12. Makefile

現在:

```make
build:
	docker compose -f srcs/docker-compose.yml build 

up:
	docker compose -f srcs/docker-compose.yml up

down:
	docker compose -f srcs/docker-compose.yml down

restart: down up

clean:
	docker compose -f srcs/docker-compose.yml down -v --rmi local

.PHONY: build up down restart clean
```

subject上の正解:

- rootにMakefile。
- Makefileで全体をセットアップする。
- docker-compose.ymlを使ってDocker imagesをbuildする。

差分:

- rootにある点はOK。
- build/up/downは最低限ある。
- ただし `/home/yutakagi/data/...` の事前作成がない。
- `make up` がbuildを含まないため、初回評価で `make` または `make up` だけを期待された場合に不足する可能性がある。
- default targetが `build` なので `make` はbuildのみで起動まではしない。

修正:

- `all` またはdefault targetで、ディレクトリ作成、build、upを実行する構成にする。
- 例:

```make
LOGIN := yutakagi
DATA_DIR := /home/$(LOGIN)/data
COMPOSE := docker compose -f srcs/docker-compose.yml

all: up

$(DATA_DIR):
	mkdir -p $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb

build: $(DATA_DIR)
	$(COMPOSE) build

up: $(DATA_DIR)
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down -v --rmi local

.PHONY: all build up down clean
```

### 13. Domain configuration

現在:

- nginxの `server_name` は `yutakagi.42.fr`。
- 証明書CNも `yutakagi.42.fr`。
- WordPressのURLも `DOMAIN_NAME` を使っている。
- ただし、現ホストでは `yutakagi.42.fr` が解決できなかった。

subject上の正解:

- `login.42.fr` がローカルIPを指すように設定する。
- 例: `wil.42.fr`。

差分:

- アプリ側設定は概ね揃っているが、OS側名前解決が未設定。

修正:

- 評価VMで `/etc/hosts` を設定する。

```txt
127.0.0.1 yutakagi.42.fr
```

または、VMのIPへ向ける。

### 14. Bonus

現在:

- Redis, FTP, static website, Adminer, 任意サービスは見当たらない。

subject上の正解:

- bonusはmandatoryが完全に通った場合だけ評価される。

判定:

- まずmandatoryの修正を優先するべき。
- 現状ではbonus評価対象にならない。

## review sheetとsubjectの食い違い・注意点

大きな完全矛盾はありませんが、解釈注意点があります。

### `.env` と認証情報

- subject:
  - `.env` は必須。
  - 認証情報はGitに置くと失敗。
  - Docker secretsを強く推奨。
- review sheet:
  - 評価中に使うローカル `.env` は許容。
  - Git repository内に、secrets用ファイル以外で認証情報があれば0点。

実務上の判断:

- `.env` はローカルに作る。
- Gitには入れない。
- `.env.example` は値を空またはダミーにして入れる。

### volumes

- subject:
  - Docker named volumesを使う。
  - bind mountsは不可。
  - ただしhost上の `/home/<login>/data` に保存する必要がある。
- review sheet:
  - `docker volume inspect` の出力に `/home/login/data/` が含まれることを確認する。

実務上の判断:

- subjectを最優先するなら、サービス定義に直接host pathをマウントするのは避ける。
- review sheetの確認に通すためには、named volumeのinspect結果に `/home/yutakagi/data/...` が出る必要がある。
- 現在の `/Users/yutakagi/data/...` はどちらの観点でも評価VM向けではない。

## 修正優先順位

### Priority 0: これがあると即終了・0点級

1. `debian:latest` をやめる。
2. `README.md` を指定形式で書き直す。
3. `USER_DOC.md` と `DEV_DOC.md` を追加する。
4. WordPress管理者名から `admin` を消す。
5. 通常WordPressユーザーを追加する。
6. `/home/yutakagi/data/...` に永続化先を変更する。
7. `yutakagi.42.fr` を名前解決できるようにする。
8. 認証情報がGit管理されないよう `.gitignore` と運用を整える。

### Priority 1: 評価時に詰まりやすい

1. `Makefile` のdefault targetを `up` または `all` にして、buildと起動まで行う。
2. host data directoryをMakefileで作成する。
3. MariaDBの初期化でバックグラウンド起動している部分を説明可能またはより明確な方式にする。
4. `GRANT ALL PRIVILEGES ON *.*` を必要最小限にする。
5. `apt upgrade -y` はビルドの再現性を下げるため、必要なinstallのみに寄せる。

### Priority 2: 品質改善

1. nginx設定からDebianデフォルトコメントを削り、課題に必要な設定だけにする。
2. `init.sql` が未使用なら削除するか、使うなら正しい初期化方式に統一する。
3. `.dockerignore` を各serviceに追加する。
4. `docker compose config` で実効設定を確認する手順をdocsに書く。

## 最終的な正解実装の形

最低限、以下の状態を目指すべきです。

- root:
  - `Makefile`
  - `README.md`
  - `USER_DOC.md`
  - `DEV_DOC.md`
  - `.gitignore`
  - 必要なら `secrets/` ただし実秘密情報はGit管理しない。
- `srcs/`:
  - `docker-compose.yml`
  - `.env` ただしGit管理しない。
  - `requirements/nginx/Dockerfile`
  - `requirements/nginx/conf/...`
  - `requirements/wordpress/Dockerfile`
  - `requirements/wordpress/tools/...`
  - `requirements/mariadb/Dockerfile`
  - `requirements/mariadb/conf/...`
  - `requirements/mariadb/tools/...`
- `docker-compose.yml`:
  - services: `nginx`, `wordpress`, `mariadb`
  - images: `nginx`, `wordpress`, `mariadb`
  - only nginx has `ports: ["443:443"]`
  - named volumes: WordPress files and DB data
  - network present
  - no `network: host`
  - no `links`
- Dockerfiles:
  - fixed penultimate stable Debian/Alpine tag
  - no `latest`
  - no ready-made service image
  - no passwords
  - no `tail -f`, `sleep infinity`, `while true` keepalive hack
- runtime:
  - `https://yutakagi.42.fr` displays installed WordPress.
  - `http://yutakagi.42.fr` is inaccessible.
  - TLSv1.2 or TLSv1.3 works.
  - WordPress admin user does not contain `admin`.
  - A second normal WordPress user exists.
  - DB is non-empty.
  - WordPress edit/comment changes persist after VM reboot and `docker compose` restart.

## 参照

- Local: `inception_subject.pdf`
- Local: `review_sheet.md`
- Debian official releases: https://www.debian.org/releases/
- Debian oldstable / Bookworm release information: https://www.debian.org/releases/oldstable/
