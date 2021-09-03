# What's this

The `NHK News Web` provides valuable(in historic or journalistic meaning) live broadcasts occasionally.
`nnwl-tools` is a comprehensive set of tools that monitors and downloads such live broadcasts.

## Usage

### monitor_nnw.bash

This tool monitors the `NHK News Web`'s live broadcast notification page periodically (default is 60 sec). Once it founds, this tool will call the download tool -- `get_nnw_hls.bash`.

```sh
./watch_nhk_news_live.bash >> watch.log 2>&1 &
```

#### ToDo

- Chnge its own filename.
- Option handling
  - monitor period
  - monitor url
  - call-up program

### get_nnw_hls.bash

This tool tries to download HLS based on given URL.

```sh
get_nnw_hls.bash https://live.broadcasting.url/of/nhk
```

#### ToDo

- Change its own filename
- Http client rather than curl
  - wget


