# Awesome Elixir
### List of awesome Elixir and Erlang libraries

## Requirements
- Latest elixir and erlang/OTP installed
- Installed and runnig PostgreSQL
- Installed inotify-tools for linux

## Install
```Bash
$ git clone https://github.com/ddidwyll/awesome-elixir.git
$ cd awesome-elixir
# or
$ unzip awesome-elixir-master.zip
$ cd awesome-elixir-master
# get deps
$ mix deps.get
# run migration (you may change postgres user and pass in config/*.ex)
$ mix ecto.setup
# get assets
$ cd assets; npm i; cd -
```

## Run
```Bash
$ mix phx.server
```
Before second run you should kill rollup watcher
```Bash
$ pkill node
```

## Github api rate limits
You can pass your login and password on env vars, to bypass the limit of 60 requests per hour
```Bash
$ GITHUB_LOGIN=pass GITHUB_PASS=pass
```
