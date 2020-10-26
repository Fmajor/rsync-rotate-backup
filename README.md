# rsync-rotate-backup
A python script to do rotation backups using rsync. Just like the Time Machine in OSX.

# Requirements
* rsync
* a file system that suport `hard link`, e.g.
  * `ext4`, `zfs` and other file systems used by unix-like OS are supported
  * `NTFS`, `FAT32` and `exFAT` are not supported!

# Parameters and Behaviors
* `src`: the folder you want to backup
* `dest`: the place you want to put your rotated backups and backup config files

For example: `src` is `/` and `dest` is `/mount/backup`, that means we want to make a full backup for our linux system
* After you run the `init` command, you will get
  * `/mount/backup/config.yml`: the backup config file, see details below
  * `/mount/backup/backupExclude.conf`: list the file inside `src` that you want to skip when doing backup
    * the default file contains `sys`, `mount`, `proc`...
* After the first time you run the `backup` command, you will get
  * `/mount/backup/YYYY-mm-ddTHH:MM:SS`
  * `/mount/backup/current -> /mount/backup/YYYY-mm-ddTHH:MM:SS`
* After later `backup` commands, you will get
  * `/mount/backup/YYYY-mm-ddTHH:MM:SS`
  * `/mount/backup/YYYY-mm-ddTHH:MM:SS`
  * `/mount/backup/YYYY-mm-ddTHH:MM:SS`
  * `/mount/backup/YYYY-mm-ddTHH:MM:SS`
  * `/mount/backup/current -> /mount/backup/YYYY-mm-ddTHH:MM:SS` # to the latest version
* the backups are incremental backups (it's complex to estimate the actual used space for each new backup), so you should by yourself take care of the disk usage and manual delete some old backups when needed (if `rsync` report a `no space` error)
* You can get all backup histories in dest/log.log

# Criterions to clean old backups
The script use 3 criterions to clean old backups
1. min interval:
  * if two backups are too close, will delete the old one
  * default value: `interval: 1m`
2. max age:
  * if the backups are too old, delete them
  * default value: `max-age: 10y`
3. a multi-level criterions
  * levels are: year, month, week, day, hour, minute, second
  * each level have three related parameters:
    * max-xx: the max time for backups to stay on this level
    * interval-xx: the interval time of this level
    * start-xx: the start tiem of this time
  * e.g.: `max-hour: 18`, `interval-hour: 2`, `start-minute: 0`, `start-second: 0`
    * if now is 20:10:10, we will get several intervals (minute and second start at 00:00 of each hour, max-age is 18 hour and interval is 2 hour):
      * `19:00:00 ~ 21:00:00` # the latest interval that contains current time
      * `17:00:00 ~ 19:00:00`
      * `15:00:00 ~ 17:00:00`
      * `13:00:00 ~ 15:00:00`
      * `9:00:00 ~ 11:00:00`
      * `7:00:00 ~ 9:00:00`
      * `5:00:00 ~ 7:00:00`
      * `3:00:00 ~ 5:00:00` # the last interval that NOT contain 2:10:10 (now - max_hour)
    * in each interval, we only resive the latest backup and delete others, if they exist.

# Default configs
```
interval: 1m # min interval of two rotate backups
max-age: 3y # max age of a rotate backup

# how long will backup stay at xx level. if 0, will stay forever
max-year: 5
max-month: 12
max-week: 6
max-day: 7
max-hour: 24
max-minute: 60
max-second: 60

# the interval in xx level. if 0, do not delete old backups at this level. Should be less than max-xx.
interval-year: 1
interval-month: 1
interval-week: 1
interval-day: 1
interval-hour: 3
interval-minute: 1
interval-second: 0

# the start value of each xx
start-month:     1 # 1~12
start-day-month: 1 # -27~28
start-day-week:  1 # 1~7
start-hour:      0 # 0~59
start-minute:    0 # 0~59
start-second:    0 # 0~59
```

# Install
```
python setup.py install
```

# Usage
Example: backup `/` to `/mount/backup/myLaptop`
```
# init the backup container
rsync-rotate-backup init /mount/backup/myLaptop
cd /mount/backup/myLaptop
# modify the backup configs and exclude files

vim config.yml # modify `src:` to `src:/`
# notice that the `src` can also be a remote path, like `remote.com:/root/` (but you should copy the ssh pub key to the remote host)

vim backupExclude.conf # add your own exclude positions
# notice that we should add /mount into the backupExclude.conf
# or we will have a cyclic backup
```
After these, run `rsync-rotate-backup backup-to /mount/backup/myLaptop` and add it to `cron` with a frequence of `1h`

After 3 years, we will get these backups
* 8 backups in hour level:
  * 3 hour is the interval, for last 24 hours
* 7 backups in day level:
  * 1 day is the interval, for last 7 days
* 6 backups in week level:
  * 1 week is the interval, for last 6 weeks
* 12 backups in month level:
  * 1 month is the interval, for last 12 months
* 3 backups in year level:
  * 1 year is the interval, for last 3 yeas
# Examples
See doc/examples.md
