# Review sheet gap summary

作成日: 2026-05-24

`review_sheet.md` の必須項目を、現在の実装に対して軽く OK / NG / 要確認 で整理したものです。bonusは除外しています。subjectとreview sheetが食い違う場合はsubjectを優先します。

## 判定サマリ

| Review項目 | 判定 | 理由 |
|---|---:|---|
| Preliminary tests | 要確認 | 作業ディレクトリがGitリポジトリではないため、提出物・`.env` のGit管理状態を確認できない。 |
| General instructions | NG | `FROM debian:latest` があり、penultimate stable固定ではない。Makefile実行は可能だが、評価上ここで止まる可能性が高い。 |
| Activity overview | 要確認 | 実装からは判断不可。口頭説明が必要。 |
| README check | NG | `README.md` はあるが、1行目形式・必須セクション・AI利用説明を満たしていない。 |
| Documentation check | NG | `USER_DOC.md` と `DEV_DOC.md` が存在しない。 |
| Simple setup | NG | 443/HTTPS自体は動くが、`yutakagi.42.fr` が名前解決できない。 |
| Docker Basics | NG | Dockerfileは各サービスにあるが、全て `debian:latest`。 |
| Docker Network | OK | `networks` があり、実際にCompose networkも作成されている。 |
| NGINX with SSL/TLS | 要確認 / NG寄り | 443とTLSv1.2/TLSv1.3はOK。`login.42.fr` で開けないため評価手順ではNG。 |
| WordPress with php-fpm and its volume | NG | volume pathが `/home/login/data/` ではない。admin名が `wp_admin` で禁止。通常WPユーザーも不足。 |
| MariaDB and its volume | NG | DBは動いて空ではないが、volume pathが `/home/login/data/` ではない。 |
| Persistence | 要確認 / NG寄り | 永続化自体はありそうだが、volume方式・pathがsubject/review条件から外れている。VM reboot未確認。 |
| Configuration modification | 要確認 | 評価中に実際に変更・rebuild・restartできるかは未確認。 |

## Review項目別メモ

### Preliminary tests: 要確認

OKになりそうな点:

- `srcs/.env` は存在する。

NG/リスク:

- 現在のディレクトリは `git status` が `fatal: not a git repository` になった。
- そのため、提出Gitリポジトリにパスワード入り `.env` が含まれているか確認できない。
- `.gitignore` が見当たらないため、提出時に認証情報をGit管理してしまうリスクがある。

### General instructions: NG

OKになりそうな点:

- rootに `srcs/` がある。
- rootに `Makefile` がある。
- `docker-compose.yml` に `network: host` と `links:` は見当たらない。
- `docker-compose.yml` に `networks` はある。
- `--link` は見当たらない。
- `tail -f`, `sleep infinity` は見当たらない。

NG/リスク:

- Dockerfileが全て `FROM debian:latest`。
- subjectで `latest` は禁止。
- review sheetでも penultimate stable version でない場合は評価終了。
- `mariadb/script.sh` に `mysqld_safe --skip-networking & sleep 10` があり、background実行として指摘される可能性がある。

### Activity overview: 要確認

実装だけでは判定できない。評価時に本人が以下を説明できればOK:

- DockerとDocker Composeの仕組み。
- Composeあり/なしでDocker imageを使う違い。
- VMとDockerの違い。
- subject指定のディレクトリ構造の意味。

### README check: NG

NG:

- `README.md` の最初の行が指定形式ではない。
- `Description`, `Instructions`, `Resources` がない。
- AIをどう使ったかの説明がない。
- subjectで要求される比較説明もない。

review sheet上は、この項目で評価終了になる。

### Documentation check: NG

NG:

- `USER_DOC.md` がない。
- `DEV_DOC.md` がない。

review sheet上は、この項目で評価終了になる。

### Simple setup: NG

OKになりそうな点:

- `nginx` は `443:443` のみ公開。
- `http://localhost` は接続不可。
- `https://localhost` は `HTTP/1.1 200 OK`。
- SSL/TLS証明書は使われている。
- WordPressはインストール済みで表示できる状態。

NG:

- `https://yutakagi.42.fr` が名前解決できない。
- review sheetは `https://login.42.fr` で開くため、現状では失敗する。

### Docker Basics: NG

OKになりそうな点:

- nginx / wordpress / mariadb それぞれにDockerfileがある。
- Dockerfileは空ではない。
- service名とimage名は一致している。
- Composeでbuildする設定がある。

NG:

- すべて `FROM debian:latest`。
- `FROM debian:XXXXX` のような固定版ではない。
- penultimate stable versionではない可能性が高い。

review sheet上は、この項目で評価終了になる。

### Docker Network: OK

OK:

- `srcs/docker-compose.yml` に `networks` がある。
- `docker network ls` で `srcs_42-inception-network` が確認できた。
- `network: host` / `links:` は使っていない。

要確認:

- 評価時にはDocker networkの説明が必要。

### NGINX with SSL/TLS: 要確認 / NG寄り

OKになりそうな点:

- nginx用Dockerfileがある。
- `docker compose ps` で `nginx` コンテナは起動している。
- HTTP port 80は接続不可。
- HTTPS port 443は応答する。
- TLSv1.2 / TLSv1.3 は接続可能。
- TLSv1.1 は接続不可。

NG:

- `https://yutakagi.42.fr/` が名前解決できない。

修正すればOKに近い:

- `/etc/hosts` で `yutakagi.42.fr` をVMのIPまたは `127.0.0.1` に向ける。

### WordPress with php-fpm and its volume: NG

OKになりそうな点:

- WordPress用Dockerfileがある。
- WordPress Dockerfileにnginxは入っていない。
- `wordpress` コンテナは起動している。
- php-fpmでnginxから接続できている。

NG:

- WordPress volume inspectのpathが `/home/yutakagi/data/` ではなく `/Users/yutakagi/data/wordpress`。
- `o: bind` を使っており、subjectの「bind mounts are not allowed」と衝突する可能性がある。
- WordPress admin usernameが `wp_admin` で、`admin` を含む。
- 通常WordPressユーザーが見当たらず、コメント追加確認に対応できない可能性が高い。

### MariaDB and its volume: NG

OKになりそうな点:

- MariaDB用Dockerfileがある。
- MariaDB Dockerfileにnginxは入っていない。
- `mariadb` コンテナは起動している。
- DB `wordpress` とWordPressテーブルは存在する。
- DBログインは確認できた。

NG:

- MariaDB volume inspectのpathが `/home/yutakagi/data/` ではなく `/Users/yutakagi/data/mariadb`。
- `o: bind` を使っており、subjectの「bind mounts are not allowed」と衝突する可能性がある。

### Persistence: 要確認 / NG寄り

OKになりそうな点:

- WordPress filesとMariaDB dataにvolumeはある。
- startup scriptは再起動時に既存データを壊しにくいよう修正されている。

NG/未確認:

- VM reboot後の確認は未実施。
- volume pathがreview sheet条件と異なる。
- subject上のbind mount禁止に抵触する可能性がある。

### Configuration modification: 要確認

未確認:

- 評価中に指定されたサービス設定を変更し、rebuild/restart後に動くかは実施していない。

リスク:

- `Makefile` のdefault targetはbuildのみで、起動まで一発ではない。
- portやdomain変更時にnginx設定、Compose、WordPress URL、証明書CNのどこまで直すべきか説明できる必要がある。

## 先に直すべきNG項目

1. `FROM debian:latest` を固定版にする。
2. `README.md` を指定形式で書き直す。
3. `USER_DOC.md` と `DEV_DOC.md` を追加する。
4. WordPress admin usernameから `admin` を消す。
5. 通常WordPressユーザーを追加する。
6. volume保存先を `/home/yutakagi/data/...` にする。
7. `yutakagi.42.fr` を名前解決できるようにする。
8. `.env` をGit管理しない設定を明確にする。
