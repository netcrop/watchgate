# watchgate
Time based One Time Password - TOTP written as Bash/SHELL Cron service.  

  It can be used to auto generate TOTP within one minute interval for local, remote computers and Virtual machines.  
the administrator seating behind a single user account can remote login to all other nodes and user accounts for maintenance purpose.  
## Install, maintain and uninstall

* For BSD/Unix system:  
required commands:  
Bash version 4+  
encrypt
pwgen  
OpenPGP version 2+  

* Checkout distro specific branch
```
eva@node: git branch -avv
  alpha
*  arch
  debian
  openbsd
  master
eva@node: git checkout openbsd
Switched to branch openbsd

# Following Bash functions use sudo
eva@node: cd watchgate/
eva@node: source src/configure.sh

# Install Bash scripts.
eva@node: watchgate.install

# Generate a secret "seed" file using sha512 of a random number,
# encrypt/sign it with OpenPGP DES 128.
eva@node: watchgate.seed $directory/store/secret/seed/

# Install/Uninstall both the secret seed and encrypted seed.asc into /etc/watchgate/.
eva@node: watchgate.seed.install $directory/store/secret/seed/watchgate_$HOSTNAME_201708XXXXXX.asc

# Install as a Cron job.
eva@node: sudo crontab -u root -e

# Add this line into the root crontab file
* * * * * /usr/local/bin/watchgate.cron
```
## Using watchgate
```
eva@node: watchgate adam
```
## Examples
```
# From console prompt at Aug 03 22:33:05 node: 
eva@node: watchgate adam
LeKy3QVU
eva@node: su -l adam
Password:
adam@node:

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

github.com/netcrop/watchgate/issues

## License

[GNU General Public License version 2 (GPLv2)](https://github.com/netcrop/watchgate/COPYING)
