watchgate()
{
  local user=${1:?[user]}
  local seed=${2:-"/etc/watchgate/watchgate_$(${Watchgate[hostname]})"}
  if [[ -a $seed && -r $seed.asc ]];then
    local tmpfile=$(mktemp)
    builtin trap "${Watchgate[shred]} -u $tmpfile" SIGHUP SIGTERM SIGINT
    ${Watchgate[gpg2]} --homedir $HOME/.gnupg --no-tty --decrypt --no-verbose --quiet $seed.asc >$tmpfile
    if [[ $? != 0 ]];then
      builtin printf "Try using same gpg-agent to login all account.\n"
      return
    fi
    ${Watchgate[pwgen]} --capitalize --numerals --num-passwords=1 \
      --secure --sha1=$tmpfile#"$user$(${Watchgate[date]} +"%Y%m%d%H%M")" 8
    ${Watchgate[shred]} -u $tmpfile
    return
  fi
  builtin printf "Seed missing!\n"
  ${Watchgate[pwgen]} --capitalize --numerals --num-passwords=1 \
    --secure --sha1=/dev/null#"$user$(${Watchgate[date]} +"%Y%m%d%H%M")" 8
}
watchgate.gen()
{
  local destfile=/usr/local/bin/watchgate.cron
  [[ -a $destfile ]] && ${Watchgate[sudo]} ${Watchgate[rm]} -f ${Watchgate[prefix]}${Watchgate[cronscript]}
  ${Watchgate[sudo]} ${Watchgate[cat]}<<-EOF> ${Watchgate[prefix]}${Watchgate[cronscript]}
#!${Watchgate[env]} ${Watchgate[bash]}
${Watchgate[cronscript]}(){
#set -o xtrace
  [[ \$(${Watchgate[id]} -u) != 0 ]] && return
  local seed="${Watchgate[configdir]}${Watchgate[seedprefix]}"
  if [[ ! -r \$seed || ! -r \$seed.asc ]];then
    seed=/dev/null
    builtin printf "Seed missing!\n"
  fi
  local tmpfile=\$(${Watchgate[mktemp]})
  builtin trap "${Watchgate[shred]} -fu \$tmpfile" SIGHUP SIGTERM SIGINT
  declare -a Users=(\$(${Watchgate[cut]} -d':' -f1,3 /etc/passwd|\
    ${Watchgate[egrep]} ":[[:digit:]]{4}|:0"|\
    ${Watchgate[cut]} -d':' -f1|\
    ${Watchgate[egrep]} -v ${Watchgate[excludeuser]}))
  local i user word timestamp
  timestamp=\$(${Watchgate[date]} +"%Y%m%d%H%M")
  for user in \${Users[@]};do
    builtin printf "\$user:" >>\$tmpfile
    ${Watchgate[pwgen]} --capitalize --numerals \
      --num-passwords=1 --secure --sha1=\$seed#\$user\$timestamp 8 >>\$tmpfile
  done
  ${Watchgate[chpasswd]} <\$tmpfile
  ${Watchgate[shred]} -fu \$tmpfile
#set +o xtrace
}
${Watchgate[cronscript]}
EOF
  ${Watchgate[sudo]} ${Watchgate[chmod]} u=rx,go= $destfile
  ${Watchgate[sudo]} ${Watchgate[chown]} root:users $destfile
}
watchgate.install()
{
  watchgate.uninstall
  watchgate.gen
  ${Watchgate[sudo]} ${Watchgate[mkdir]} -p /usr/local/man/man1/
  ${Watchgate[sudo]} ${Watchgate[cp]} watchgate.1 /usr/local/man/man1/watchgate.1
  ${Watchgate[sudo]} ${Watchgate[chmod]} 0644 /usr/local/man/man1/watchgate.1 
  ${Watchgate[sudo]} ${Watchgate[chown]} $USER:users /usr/local/man/man1/watchgate.1
  ${Watchgate[sudo]} ${Watchgate[cp]} watchgate.service /usr/lib/systemd/system/watchgate.service
  ${Watchgate[sudo]} ${Watchgate[chmod]} 0644 /usr/lib/systemd/system/watchgate.service
  ${Watchgate[sudo]} ${Watchgate[cp]} watchgate.timer /usr/lib/systemd/system/watchgate.timer
  ${Watchgate[sudo]} ${Watchgate[chmod]} 0644 /usr/lib/systemd/system/watchgate.timer
  ${Watchgate[sudo]} ${Watchgate[ln]} -s /usr/lib/systemd/system/watchgate.timer \
    /usr/lib/systemd/system/timers.target.wants/watchgate.timer
}
watchgate.uninstall()
{
  ${Watchgate[sudo]} ${Watchgate[rm]} -f /usr/lib/systemd/system/watchgate.service
  ${Watchgate[sudo]} ${Watchgate[rm]} -f /usr/lib/systemd/system/watchgate.timer
  ${Watchgate[sudo]} ${Watchgate[rm]} -f /usr/lib/systemd/system/timers.target.wants/watchgate.timer
  ${Watchgate[sudo]} ${Watchgate[rm]} -f /var/lib/systemd/timers/stamp-watchgate.timer
  ${Watchgate[sudo]} ${Watchgate[rm]} -f /usr/local/bin/watchgate
  watchgate.seed.uninstall
}
watchgate.seed()
{
  local destdir=${1:?[seed dest dir]}
  local seed="watchgate_$(${Watchgate[hostname]})_$(${Watchgate[date]} +"%Y%m%d%H%M%S")"
  local tmpfile=$(${Watchgate[mktemp]})
  builtin trap "${Watchgate[shred]} -u $tmpfile" SIGHUP SIGTERM SIGINT
  ${Watchgate[sha512sum]} <<<$RANDOM|${Watchgate[cut]} -d' ' -f1 > $tmpfile
  ${Watchgate[gpg2]} --symmetric --no-verbose --quiet --output $destdir/$seed.asc --armor $tmpfile
  ${Watchgate[shred]} -fu $tmpfile
}
watchgate.seed.install()
{
  local hostname=$(${Watchgate[hostname]})
  local seedasc=${1:?[watchgate_$hostname_\$date.asc file]}
  local seed=$(${Watchgate[basename]} ${seedasc%.asc})
  local destseed=/etc/watchgate/$seed
  local tmpfile=$(mktemp)
  builtin trap "${Watchgate[shred]} -u $tmpfile" SIGHUP SIGTERM SIGINT
  ${Watchgate[gpg2]} --no-tty --decrypt --no-verbose --quiet $seedasc >$tmpfile
  if [[ $? != 0 ]];then
    ${Watchgate[shred]} -fu $tmpfile
    return
  fi
  ${Watchgate[sudo]} ${Watchgate[mkdir]} -p /etc/watchgate
  ${Watchgate[sudo]} ${Watchgate[chmod]} ug=rx,o= /etc/watchgate
  ${Watchgate[sudo]} ${Watchgate[chown]} root:users /etc/watchgate
  [[ -a $destseed ]] && ${Watchgate[sudo]} ${Watchgate[shred]} -fu $destseed
  [[ -a $destseed.asc ]] && ${Watchgate[sudo]} ${Watchgate[shred]} -fu $destseed.asc
  ${Watchgate[sudo]} ${Watchgate[cp]} -f $seedasc $destseed.asc 
  ${Watchgate[sudo]} ${Watchgate[mv]} -f $tmpfile $destseed
  ${Watchgate[sudo]} ${Watchgate[chmod]} 0440 $destseed.asc
  ${Watchgate[sudo]} ${Watchgate[chown]} root:users $destseed.asc
  ${Watchgate[sudo]} ${Watchgate[chmod]} 0400 $destseed
  ${Watchgate[sudo]} ${Watchgate[chown]} root:root $destseed
  ${Watchgate[sudo]} ${Watchgate[ln]} -fs $destseed /etc/watchgate/watchgate_$(${Watchgate[hostname]})
  ${Watchgate[sudo]} ${Watchgate[ln]} -fs $destseed.asc /etc/watchgate/watchgate_$(${Watchgate[hostname]}).asc
}
watchgate.seed.uninstall()
{
  local seed="watchgate_$(${Watchgate[hostname]})_*"
  ${Watchgate[sudo]} ${Watchgate[rm]} -f /etc/watchgate/watchgate_$(${Watchgate[hostname]}).asc
  ${Watchgate[sudo]} ${Watchgate[rm]} -f /etc/watchgate/watchgate_$(${Watchgate[hostname]})
  ${Watchgate[sudo]} ${Watchgate[rm]} -f /etc/watchgate/$seed.asc
  ${Watchgate[sudo]} ${Watchgate[rm]} -f /etc/watchgate/$seed
}
watchgate.enable()
{
  ${Watchgate[sudo]} ${Watchgate[systemctl]} enable watchgate.timer
}
watchgate.start()
{
  ${Watchgate[sudo]} ${Watchgate[systemctl]} start watchgate.timer
  watchgate.timer
}
watchgate.stop()
{
  ${Watchgate[sudo]} ${Watchgate[systemctl]} stop watchgate.timer
  watchgate.timer
}
watchgate.disable()
{
  ${Watchgate[sudo]} ${Watchgate[systemctl]} disable watchgate.timer
  watchgate.timer
}
watchgate.mask()
{
  ${Watchgate[sudo]} ${Watchgate[systemctl]} mask watchgate.timer
  watchgate.timer
}
watchgate.unmask()
{
  ${Watchgate[sudo]} ${Watchgate[systemctl]} unmask watchgate.timer
  watchgate.timer
}
watchgate.reload()
{
  ${Watchgate[sudo]} ${Watchgate[systemctl]} daemon-reload
}
watchgate.units()
{
  ${Watchgate[sudo]} ${Watchgate[systemctl]} list-units
}
watchgate.timer()
{
  ${Watchgate[systemctl]} list-timers --all
}

