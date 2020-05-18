# watchgate
Time based One Time Password - TOTP written as Bash/SHELL Cron service.  

  It can be used to auto generate TOTP within one minute interval for local, remote Computers, Virtual Machines and Dockers.
Administrator with one user account can remote login to all other nodes and user accounts for maintenance purpose.
## Install, maintain and uninstall

* For linux/unix system:
required commands:
Bash version 4+
coreutils
pwgen
OpenPGP version 2+

```
* Checkout distro specific Releases
eva@node: git branch -avv
  arch
* debian
  master
eva@node: git checkout arch
Switched to branch arch

# Following Bash functions use sudo
eva@node: cd watchgate/
eva@node: source watchgate.sh

# Install/Uninstall the systemd timer service (alt. Cron service),
# which include $prefix/watchgate.cron (a TOTP Bash script run by Cron service),
# $prefix/watchgate (password query script, run by login user),
# watchgate.timer (systemd timer), watchgate.service (systemd service)
# and watchgate.1 (the Man page).
eva@node: watchgate.install

# Generate a secret "seed" file using sha512sum of a random number,
# encrypt/sign it with OpenPGP DES 128.
eva@node: watchgate.seed $directory/store/secret/seed/

# Install/Uninstall both the secret seed and encrypted seed.asc into /etc/watchgate/.
# The secret seed will only be visible for root user (User=root in systemd timer service).
eva@node: watchgate.seed.install $directory/store/secret/seed/watchgate_$HOSTNAME_201708XXXXXX.asc

# Manage systemd timer service.
eva@node: watchgate.enable
eva@node: watchgate.start
```
## Using watchgate
```
eva@node: watchgate adam
```
## Examples
```
# From journalctl log file
Aug 03 22:33:00 node systemd[1]: Starting watchgate.service...
Aug 03 22:33:00 node chpasswd[7311]: pam_unix(chpasswd:chauthtok): password changed for adam
Aug 03 22:33:00 node systemd[1]: Started watchgate.service.

# From console prompt at Aug 03 22:33:05 node: 
eva@node: watchgate adam
LeKy3QVU
eva@node: su -l adam
Password:
adam@node:

# From journalctl log file
Aug 03 22:34:00 node systemd[1]: Starting watchgate.service...
Aug 03 22:34:00 node chpasswd[7421]: pam_unix(chpasswd:chauthtok): password changed for adam
Aug 03 22:34:00 node systemd[1]: Started watchgate.service.

# From console prompt at Aug 03 22:34:20 node: 
eva@node: watchgate adam
IekIa3w9
eva@node: su -l adam
Password:
adam@node:
```
## For developers

We use rolling releases.

## Reporting a bug and security issues

github.com/netcrop/watchgate/pulls

## License

[GNU General Public License version 2 (GPLv2)](https://github.com/netcrop/watchgate/COPYING)
