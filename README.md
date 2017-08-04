# watchgate
Time based One Time Password - TOTP written as Bash/SHELL Cron service.

## Install, maintain and uninstall

* For linux/unix system:  
required commands:  
Bash version 4+  
coreutils  
pwgen  
OpenPGP version 2+  

```
Following Bash functions use sudo
> cd src/
> source configure.sh

Install/Uninstall the systemd timer service (alt. Cron service),
which include $prefix/watchgate.cron (a TOTP Bash script run by Cron service),
$prefix/watchgate (password query script, run by login user),
watchgate.timer (systemd timer), watchgate.service (systemd service)
and watchgate.1 (the Man page).
> watchgate.install

Generate a secret "seed" file using sha512sum of a random number,
encrypt/sign it with OpenPGP DES 128.
> watchgate.seed $directory/store/secret/seed/

Install/Uninstall both the secret seed and encrypted seed.asc into /etc/watchgate/.
The secret seed will only be visible for root user (User=root in systemd timer service).
> watchgate.seed.install $directory/store/secret/seed/watchgate_$HOSTNAME_201708XXXXXX.asc

Manage systemd timer service.
> watchgate.enable
> watchgate.start
```
## Using watchgate
```
> watchgate $USER
```
## Examples
```
  From journalctl log file
  Aug 03 22:33:00 node systemd[1]: Starting watchgate.service...
  Aug 03 22:33:00 node chpasswd[7311]: pam_unix(chpasswd:chauthtok): password changed for adam
  Aug 03 22:33:00 node systemd[1]: Started watchgate.service.
  
  From console prompt at Aug 03 22:33:05 node: 
  eva > watchgate adam
  LeKy3QVU
  eva > su -l adam
  Password:
  adam >

  From journalctl log file
  Aug 03 22:34:00 node systemd[1]: Starting watchgate.service...
  Aug 03 22:34:00 node chpasswd[7421]: pam_unix(chpasswd:chauthtok): password changed for adam
  Aug 03 22:34:00 node systemd[1]: Started watchgate.service.
  
  From console prompt at Aug 03 22:34:20 node: 
  eva > watchgate adam
  IekIa3w9
  eva > su -l adam
  Password:
  adam >
```
## For developers


* Releases

  [incompatible API].[new functionality/documentation].[bugfix/securityfix]  
**alpha** denotes a **pre-release** tag .  
**beta** denotes a testing **release** tag.  
e.g. v0.2a is a alpha pre-release, v0.2b is a testing release,  
and v1.0 is a stable release.  


## Reporting a bug and security issues

github.com/netcrop/watchgate/issues

## License

[GNU General Public License version 2 (GPLv2)](https://github.com/netcrop/watchgate/COPYING)
