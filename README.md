# torrserver-plus
This is unofficial docker image with latest versions TorrServer and qBittorrent.
Version without qBittorrent here - https://github.com/MrKsey/torrserver

![TorrServer Plus](https://raw.githubusercontent.com/MrKsey/torrserver-plus/master/ts.png)

### More info:
More info (only TorrServer):
- https://github.com/YouROK/TorrServer
- https://4pda.to/forum/index.php?showtopic=889960

### Key futures:
- autoupdates OS, TorrServer, qBittorrent and ip blocklist
- built-in torrent client qBittorrent
- automatic measurement of the Internet connection speed and setting up download/upload speed restrictions for the day and night in qBittorrent configuration
- automatic adding a torrent for downloading if more than 30% of the torrent is viewed
- seeding of viewed torrents
- flexible configuration using ts.ini
- support x86-64, arm64 and armv7

### defaults:
- TorrServer WebUI: http://<your_server_ip>:8090
- TorrServer automatic updates turned ON
- qBittorrent enabled
- qBittorrent WebUI port: http://<your_server_ip>:8888
- qBittorrent local retracker: http://<your_server_ip>:9999/announce
- qBittorrent default login / password: admin / adminadmin
- Automatic adding a torrent for downloading to qBittorrent if more than 30% of the torrent is viewed (loaded to TorrServer cache) 
- Torrents are added to QBittorrent in a PAUSED state
- Torrents resume loading at 2 a.m.
ℹ See QBittorrent and TS.ini settings for additional parameters


### Installing
- сreate "/docker/torrserver-plus" directory (for example) on your host
- run container (set correct time zone TZ):
```
docker run --name torrserver-plus -e TZ=Europe/London -d --restart=unless-stopped --net=host -v /docker/torrserver-plus:/TS/db ksey/torrserver-plus
```
If you want to download torrents to another folder, then run like this:
```
docker run --name torrserver-plus -e TZ=Europe/London -d --restart=unless-stopped --net=host -v /docker/torrserver-plus:/TS/db -v /your/path/to/downloads:/TS/db/torrents ksey/torrserver-plus
```
