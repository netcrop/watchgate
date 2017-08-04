cmdlist='sed basename cat id cut mktemp egrep date env mv chpasswd pwgen hostname sudo cp chmod ln chown rm sha1sum sha512sum gpg2 shred mkdir systemctl'
unset Watchgate
declare -Ax Watchgate
for cmd in $cmdlist;do
  i="$(which $cmd)"
  [[ X$i == X ]] && return
  Watchgate["$cmd"]="$i"
done
unset cmdlist cmd i
source watchgate.sh
