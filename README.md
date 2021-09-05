# これはなにか


`NHK News Web` では価値のあるライブ放送を行っています。`nnwl-tools` はそれらのライブ放送の監視とダウンロードを行う包括的なツール群です。

## Usage

### monitor_nhk_news_live.bash

このツールは `NHK News Web`のライブ放送通知を定期的に監視します(デフォルトでは15秒)。発見したらダウンロードツールの `get_nnw_hls.bash` を起動します。

```sh
./monitor_nhk_news_live.bash >> nhk-news-live.log 2>&1 &
tail -f nhk-news-live.log
```

#### ToDo

- オプション
  - 監視周期
  - 監視対象URL
  - 起動するプログラム

### get_nnw_hls.bash

This tool tries to download HLS based on given URL.

```sh
get_nnw_hls.bash <URL>
```

#### ToDo

- Http client rather than curl
  - wget
- Error handling

### monitor_nhk_tv_simultaneous.bash

This tool monitors the `NHK News Web`'s simultaneous broadcasting which is occured in major incidents.

```sh
./monitor_nhk_tv_simultaneous.bash >> nhk-news-simul.log 2>&1 &
tail -f nhk-news-simul.log
```

### get_hls_nhk_simul.bash

This tool downloads `NHK News Web`'s simultaneous broadcasting HLS video.

```sh
get_hls_nhk_simul.bash <URL>
```

----------

# What's this

The `NHK News Web` provides valuable(in historic or journalistic meaning) live broadcasts occasionally.
`nnwl-tools` is a comprehensive set of tools that monitors and downloads such live broadcasts.

## Usage

### monitor_nhk_news_live.bash

This tool monitors the `NHK News Web`'s live broadcast notification page periodically (default is 15 sec). Once it founds, this tool will call the download tool -- `get_nnw_hls.bash`.

```sh
./monitor_nhk_news_live.bash >> nhk-news-live.log 2>&1 &
tail -f nhk-news-live.log
```

### get_nnw_hls.bash

This tool tries to download HLS based on given URL.

```sh
get_nnw_hls.bash <URL>
```

### monitor_nhk_tv_simultaneous.bash

This tool monitors the `NHK News Web`'s simultaneous broadcasting which is occured in major incidents.

```sh
./monitor_nhk_tv_simultaneous.bash >> nhk-news-simul.log 2>&1 &
tail -f nhk-news-simul.log
```

### get_hls_nhk_simul.bash

This tool downloads `NHK News Web`'s simultaneous broadcasting HLS video.

```sh
get_hls_nhk_simul.bash <URL>
```

