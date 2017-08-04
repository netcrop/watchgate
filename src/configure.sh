cmdlist='sed basename cat id cut bash man mktemp egrep date env mv chpasswd pwgen hostname sudo cp chmod ln chown rm sha1sum sha512sum gpg2 shred mkdir systemctl'
unset Watchgate
declare -Ax Watchgate
for cmd in $cmdlist;do
  i="$(which $cmd)"
  [[ X$i == X ]] && return
  Watchgate["$cmd"]="$i"
done
Watchgate[prefix]=/usr/local/bin
Watchgate[cronscript]=watchgate.cron
Watchgate[queryscript]=watchgate
Watchgate[configdir]=/etc/watchgate
Watchgate[seedprefix]=watchgate_${Watchgate[hostname]}
Watchgate[mandir]=/usr/local/man/man1
unset cmdlist cmd i
source watchgate.sh
