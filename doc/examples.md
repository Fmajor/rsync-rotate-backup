# full disk backup
```backupExclude.conf
lost+found
home/*/.cache
root/.cache
home/*/.gvfs
home/*/.mozilla/firefox/*/Cache
home/*/.cache/chromium
home/*/.thumbnails
home/*/.npm/_cacache
var/tmp
var/cache
proc
sys
dev
run
tmp
media
mnt
swapadd
swapfile
<Mount point for your backup disk>
```
```config.yml
src: /
```

# multiple folder backup
* this example will only backup `${HOME}/git.repos`, `${HOME}/git` and `${HOME}/servers`
```backupExclude.conf
+ git.repos/
+ git.repos/**
+ git/
+ git/**
+ servers/
+ servers/**
- /**
```
```config.yml
src: <full path of your home dir>/
```
