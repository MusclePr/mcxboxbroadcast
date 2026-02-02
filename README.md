# Dockerized MCXboxBroadcast

[MCXboxBroadcast](https://github.com/MCXboxBroadcast/Broadcaster) の[スタンドアロン](https://github.com/MCXboxBroadcast/Broadcaster/tree/master/bootstrap/standalone)を Docker で実行するための環境です。

本家の Docker イメージとは以下の点で異なります。

- 起動時に GitHub Releases から最新の Standalone JAR を取得して実行します。
- デフォルトで 4 時間毎に最新版のダウンロードチェックを行います。
- 最低限のパラメータは、環境変数で設定可能にしました。

## 使い方

### docker run 使用

- 起動

  ```bash
  docker run --rm -it -e PUBLIC_HOST=mcbe.a-b-c-d.com:19132 -v ./data:/data ghcr.io/musclepr/mcxboxbroadcast:latest
  ```

  初回だけ、ログから URL とキーを取得し、ブラウザ経由で認証を手動で完了してください。

### compose 使用

- compose.yml
  
  ご自身の環境に合わせて変更してください。

  ```yaml
  services:
    mcxboxbroadcast:
      image: ghcr.io/musclepr/mcxboxbroadcast:latest
      volumes:
        - "./data:/data"
      environment:
        - "AUTO_UPDATE=true"
        - "AUTO_UPDATE_CRON=0 */4 * * *"
        - "SERVER_NAME=A-B-C-D Minecraft Server"
        - "WORLD_NAME=HUB Entrance"
        - "MAX_PLAYERS=100"
        - "PUBLIC_HOST=mcbe.a-b-c-d.com:19132"
      tty: true
      stdin_open: true
  ```

- 起動（-d デーモン起動）

  ```bash
  docker compose up -d
  ```

  初回起動時に `./data` が作成され、コンテナ内の `/data` にマウントされます。
  初回だけ、ログ（`docker compose logs`）から URL とキーを取得し、ブラウザ経由で認証を手動で完了してください。

- 終了

  ```bash
  docker compose down
  ```

## 環境変数

- `PUID` / `PGID` : /data の所有ユーザー（既定: 1000）
- `REPO` : GitHub リポジトリ（既定: `MCXboxBroadcast/Broadcaster`）
- `VERSION` : リリースタグ（既定: `latest`）
- `DOWNLOAD_URL` : 直接ダウンロード URL（指定時は `VERSION` を無視）
- `JAVA_OPTS` : Java プロセスへの追加オプション（例: `-Xmx1G`）
- `AUTO_UPDATE` : 自動アップデートの有効/無効を設定します（既定: `true`）
- `AUTO_UPDATE_CRON` : 自動アップデートのスケジュール（既定: `0 */4 * * *`）
- `SERVER_NAME` : 公開するサーバー名
- `WORLD_NAME` : 公開するワールド名
- `MAX_PLAYERS` : 公開する最大参加可能人数
- `PUBLIC_HOST` : 公開するアドレス (e.g. "mcbe.a-b-c-d.com:19132")

## 設定の更新

以下の環境変数により、`/data/config.yml` に対応する項目内容が上書きされます。

- `SERVER_NAME` ---> `.session.session-info.host-name`
- `WORLD_NAME`  ---> `.session.session-info.world-name`
- `MAX_PLAYERS` ---> `.session.session-info.max-players`
- `PUBLIC_HOST` ---> `.session.session-info.ip` : `.session.session-info.port`

更新があった場合、java を再起動します。

```yaml
# Core session settings
session:
  # The amount of time in seconds to update session information
  # Warning: This can be no lower than 20 due to Xbox rate limits
  update-interval: 30

  # Should we query the bedrock server to sync the session information
  query-server: true

  # This uses checker.geysermc.org for querying if the native ping fails
  # This can be useful in the case of docker networks or routing problems causing the native ping to fail
  web-query-fallback: false

  # Fallback to config values if all other server query methods fail
  config-fallback: false

  # The data to broadcast over xbox live, this is the default if querying is enabled
  session-info:
    # The host name to broadcast
    # SERVER_NAME によって上書きされます
    host-name: Geyser Test Server

    # The world name to broadcast
    # WORLD_NAME によって上書きされます
    world-name: GeyserMC Demo & Test Server

    # The current number of players
    players: 0

    # The maximum number of players
    # MAX_PLAYERS によって上書きされます
    max-players: 20

    # The IP address of the server
    # PUBLIC_HOST のホスト名によって上書きされます
    ip: test.geysermc.org

    # The port of the server
    # PUBLIC_HOST のポート番号によって上書きされます
    port: 19132

# Friend/follower list sync settings
friend-sync:
  # The amount of time in seconds to update session information
  # Warning: This can be no lower than 20 due to Xbox rate limits
  update-interval: 60

  # Should we automatically follow people that follow us
  auto-follow: true

  # Should we automatically unfollow people that no longer follow us
  auto-unfollow: true

  # Should we automatically send an invite when a friend is added
  initial-invite: true

  # Friend expiry settings
  expiry:
    # Should we unfriend people that haven't joined the server in a while
    enabled: true

    # The amount of time in days before a friend is considered expired
    days: 15

    # How often to check in seconds for expired friends
    check: 1800

# Notification settings (e.g., Slack/Discord webhook)
notifications:
  # Should we send a message to a slack webhook when the session is updated
  enabled: false

  # The webhook url to send the message to
  # If you are using discord add "/slack" to the end of the webhook url
  webhook-url: ''

  # The message to send when the session is expired and needs to be updated
  session-expired-message: |-
    <!here> Xbox Session expired, sign in again to update it.

    Use the following link to sign in: %s
    Enter the code: %s

  # The message to send when a friend has restrictions in place that prevent them from being friends with our account
  friend-restriction-message: '%s (%s) has restrictions in place that prevent them from being friends with our account.'

# Enable debug logging
debug-mode: false

# Suppresses "Updated session!" log into debug
suppress-session-update-message: false

# Do not change!
config-version: 2
```

## ボリューム

- `/data`

## 補足

- Java 実行環境は JRE 21 を使用します。
- ダウンロード済み JAR がある場合、HTTP の If-Modified-Since を利用して再取得を最小化します。
- `AUTO_UPDATE` が有効な場合、最新の JAR がダウンロードされるとプロセスが自動的に再起動します。
- JAR の起動に失敗した場合（かつ直近で正常起動していた場合）、`.bak` ファイルからのフォールバックを試みます。
