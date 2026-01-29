# Dockerized MCXboxBroadcast

MCXboxBroadcast のスタンドアロンを Docker で実行するための最小構成です。

起動時に GitHub Releases から最新の Standalone JAR を取得して実行します。

## 使い方

### compose なし

  ```bash
  docker run --rm -it -v ./data:/data ghcr.io/musclepr/mcxboxbroadcast:latest
  ```

### compose 使用

- compose.yml

  ```yaml
  services:
    mcxboxbroadcast:
      image: ghcr.io/musclepr/mcxboxbroadcast:latest
      volumes:
        - "./data:/data"
      tty: true
      stdin_open: true
  ```

- 起動

  ```bash
  docker compose up -d
  ```

  初回起動時に ./data が作成され、コンテナ内の /data にマウントされます。

- 終了

  ```bash
  docker compose down
  ```

## 環境変数

- `REPO` : GitHub リポジトリ（既定: `MCXboxBroadcast/Broadcaster`）
- `VERSION` : リリースタグ（既定: `latest`）
- `DOWNLOAD_URL` : 直接ダウンロード URL（指定時は `VERSION` を無視）
- `JAR` : 保存先 JAR パス（既定: `./bin/MCXboxBroadcastStandalone.jar`）
- `PUID` / `PGID` : /data の所有ユーザー（既定: 1000）

## ボリューム

- `./data:/data`

## 補足

- Java 実行環境は JRE 21 を使用します。
- ダウンロード済み JAR がある場合、HTTP の If-Modified-Since を利用して再取得を最小化します。
