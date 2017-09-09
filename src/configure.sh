declare -Ax Watchgate

watchgate.substitution()
{
  local cmd i cmdlist='sed basename cat id cut bash man mktemp egrep
  date env mv chpasswd pwgen hostname sudo cp chmod ln chown rm sha1sum
  sha512sum gpg shred mkdir systemctl tty'
  for cmd in $cmdlist;do
    i="$(which $cmd)"
    if [[ -z $i ]];then
      printf "missing $cmd"
      return
    fi
    Watchgate["$cmd"]="$i"
  done
  Watchgate[prefix]=/usr/local/bin/
  Watchgate[cronscript]=watchgate.cron
  Watchgate[queryscript]=watchgate
  Watchgate[configdir]=/etc/watchgate/
  Watchgate[seedprefix]=watchgate_$(${Watchgate[hostname]})
  Watchgate[mandir]=/usr/local/man/man1/
  Watchgate[excludeuser]=www

  builtin source <(${Watchgate[cat]}<<-SUB

watchgate.query()
{
#  set -o xtrace
  [[ -a ${Watchgate[prefix]}${Watchgate[queryscript]} ]] \
    && ${Watchgate[sudo]} ${Watchgate[rm]} -f ${Watchgate[prefix]}${Watchgate[queryscript]}
   ${Watchgate[sudo]} ${Watchgate[cat]}<<-QUERY> ${Watchgate[prefix]}${Watchgate[queryscript]}
#!${Watchgate[env]} ${Watchgate[bash]}
${Watchgate[queryscript]}()
{
#  set -o xtrace
  local user=\\\${1:?[user]}
  local seed=\\\${2:-"${Watchgate[configdir]}${Watchgate[seedprefix]}"}
  seed=\\\${seed%.asc}
  if [[ -r \\\${2} || -a \\\$seed && -r \\\$seed.asc ]];then
    local tmpfile=\\\$(${Watchgate[mktemp]})
    builtin trap "${Watchgate[shred]} -u \\\$tmpfile" SIGHUP SIGTERM SIGINT
    builtin declare -x GPG_TTY="\\\$(${Watchgate[tty]})"
    ${Watchgate[gpg]} --homedir \\\$HOME/.gnupg --no-tty --decrypt --no-verbose --quiet \\\$seed.asc >\\\$tmpfile
    if [[ \\\$? != 0 ]];then
      builtin printf "Try using same gpg-agent and tty to query password.\n"
      return
    fi
    ${Watchgate[pwgen]} --capitalize --numerals --num-passwords=1 \
      --secure --sha1=\\\$tmpfile#"\\\$user\\\$(${Watchgate[date]} +"%Y%m%d%H%M")" 8
    ${Watchgate[shred]} -u \\\$tmpfile
    return
  fi
  builtin printf "Seed missing!\n"
  ${Watchgate[pwgen]} --capitalize --numerals --num-passwords=1 \
    --secure --sha1=/dev/null#"\\\$user\\\$(${Watchgate[date]} +"%Y%m%d%H%M")" 8
#  set +o xtrace
}
${Watchgate[queryscript]} "\\\$@"
QUERY
  ${Watchgate[sudo]} ${Watchgate[chmod]} u=rx,g=rx,o= ${Watchgate[prefix]}${Watchgate[queryscript]}
  ${Watchgate[sudo]} ${Watchgate[chown]} root:users ${Watchgate[prefix]}${Watchgate[queryscript]}
#  set +o xtrace
}
watchgate.cron()
{
  [[ -a ${Watchgate[prefix]}${Watchgate[cronscript]} ]] \
    && ${Watchgate[sudo]} ${Watchgate[rm]} -f ${Watchgate[prefix]}${Watchgate[cronscript]}
  ${Watchgate[sudo]} ${Watchgate[cat]}<<-CRON> ${Watchgate[prefix]}${Watchgate[cronscript]}
#!${Watchgate[env]} ${Watchgate[bash]}
${Watchgate[cronscript]}()
{
#set -o xtrace
  [[ \\\$(${Watchgate[id]} -u) != 0 ]] && return
  local seed="${Watchgate[configdir]}${Watchgate[seedprefix]}"
  if [[ ! -r \\\$seed || ! -r \\\$seed.asc ]];then
    seed=/dev/null
    builtin printf "Seed missing!\n"
  fi
  local tmpfile=\\\$(${Watchgate[mktemp]})
  builtin trap "${Watchgate[shred]} -fu \\\$tmpfile" SIGHUP SIGTERM SIGINT
  declare -a Users=(\\\$(${Watchgate[cut]} -d':' -f1,3 /etc/passwd|\
    ${Watchgate[egrep]} ":[[:digit:]]{4}|:0"|\
    ${Watchgate[cut]} -d':' -f1|\
    ${Watchgate[egrep]} -v ${Watchgate[excludeuser]}))
  local i user word timestamp
  timestamp=\\\$(${Watchgate[date]} +"%Y%m%d%H%M")
  for user in \\\${Users[@]};do
    builtin printf "\\\$user:" >>\\\$tmpfile
    ${Watchgate[pwgen]} --capitalize --numerals \
      --num-passwords=1 --secure --sha1=\\\$seed#\\\$user\\\$timestamp 8 >>\\\$tmpfile
  done
  ${Watchgate[chpasswd]} <\\\$tmpfile
  ${Watchgate[shred]} -fu \\\$tmpfile
#set +o xtrace
}
${Watchgate[cronscript]}
CRON
  ${Watchgate[sudo]} ${Watchgate[chmod]} u=rx,go= ${Watchgate[prefix]}${Watchgate[cronscript]}
  ${Watchgate[sudo]} ${Watchgate[chown]} root:users ${Watchgate[prefix]}${Watchgate[cronscript]}
}
watchgate.install()
{
  [[ \$(${Watchgate[basename]} \$PWD) == watchgate ]] && local prefix='src/'
  watchgate.uninstall
  watchgate.cron
  watchgate.query
  ${Watchgate[sudo]} ${Watchgate[mkdir]} -p ${Watchgate[mandir]}
  ${Watchgate[sudo]} ${Watchgate[chmod]} 0755 ${Watchgate[mandir]}
  ${Watchgate[sudo]} ${Watchgate[cp]} \${prefix}watchgate.1 ${Watchgate[mandir]}/watchgate.1
  ${Watchgate[sudo]} ${Watchgate[chmod]} 0644 ${Watchgate[mandir]}/watchgate.1 
  ${Watchgate[sudo]} ${Watchgate[chown]} $USER:users ${Watchgate[mandir]}/watchgate.1
  ${Watchgate[sudo]} ${Watchgate[cp]} \${prefix}watchgate.service /lib/systemd/system/watchgate.service
  ${Watchgate[sudo]} ${Watchgate[chmod]} 0644 /lib/systemd/system/watchgate.service
  ${Watchgate[sudo]} ${Watchgate[cp]} \${prefix}watchgate.timer /lib/systemd/system/watchgate.timer
  ${Watchgate[sudo]} ${Watchgate[chmod]} 0644 /lib/systemd/system/watchgate.timer
  ${Watchgate[sudo]} ${Watchgate[ln]} -s /lib/systemd/system/watchgate.timer \
    /lib/systemd/system/timers.target.wants/watchgate.timer
}
watchgate.uninstall()
{
  ${Watchgate[sudo]} ${Watchgate[rm]} -f /lib/systemd/system/watchgate.service
  ${Watchgate[sudo]} ${Watchgate[rm]} -f /lib/systemd/system/watchgate.timer
  ${Watchgate[sudo]} ${Watchgate[rm]} -f /lib/systemd/system/timers.target.wants/watchgate.timer
  ${Watchgate[sudo]} ${Watchgate[rm]} -f /var/lib/systemd/timers/stamp-watchgate.timer
  ${Watchgate[sudo]} ${Watchgate[rm]} -f ${Watchgate[prefix]}${Watchgate[queryscript]}
  ${Watchgate[sudo]} ${Watchgate[rm]} -f ${Watchgate[prefix]}${Watchgate[cronscript]}
  ${Watchgate[sudo]} ${Watchgate[rm]} -f ${Watchgate[mandir]}/watchgate.1 
  watchgate.seed.uninstall
}
watchgate.seed()
{
  local destdir=\${1:?[seed dest dir]}
  local seed="${Watchgate[seedprefix]}_\$(${Watchgate[date]} +"%Y%m%d%H%M%S")"
  local tmpfile=\$(${Watchgate[mktemp]})
  builtin trap "${Watchgate[shred]} -u $tmpfile" SIGHUP SIGTERM SIGINT
  ${Watchgate[sha512sum]} <<<\$RANDOM|${Watchgate[cut]} -d' ' -f1 > \$tmpfile
  builtin declare -x GPG_TTY="\$(${Watchgate[tty]})"
  ${Watchgate[gpg]} --symmetric --no-verbose --quiet --output \$destdir/\$seed.asc --armor \$tmpfile
  ${Watchgate[shred]} -fu \$tmpfile
  ${Watchgate[chmod]} 0400 \$destdir/\$seed.asc
}
watchgate.seed.install()
{
  local seedasc=\${1:?[watchgate_\$hostname_\$date.asc file]}
  local seed=\$(${Watchgate[basename]} \${seedasc%.asc})
  local destseed=${Watchgate[configdir]}/\$seed
  local tmpfile=\$(${Watchgate[mktemp]})
  builtin trap "${Watchgate[shred]} -u \$tmpfile" SIGHUP SIGTERM SIGINT
  builtin declare -x GPG_TTY="\$(${Watchgate[tty]})"
  ${Watchgate[gpg]} --no-tty --decrypt --no-verbose --quiet \$seedasc >\$tmpfile
  if [[ \$? != 0 ]];then
    ${Watchgate[shred]} -fu \$tmpfile
    return
  fi
  ${Watchgate[sudo]} ${Watchgate[mkdir]} -p ${Watchgate[configdir]}
  ${Watchgate[sudo]} ${Watchgate[chmod]} ug=rx,o= ${Watchgate[configdir]}
  ${Watchgate[sudo]} ${Watchgate[chown]} root:users ${Watchgate[configdir]}
  [[ -a \$destseed ]] && ${Watchgate[sudo]} ${Watchgate[shred]} -fu \$destseed
  [[ -a \$destseed.asc ]] && ${Watchgate[sudo]} ${Watchgate[shred]} -fu \$destseed.asc
  ${Watchgate[sudo]} ${Watchgate[cp]} -f \$seedasc \$destseed.asc 
  ${Watchgate[sudo]} ${Watchgate[mv]} -f \$tmpfile \$destseed
  ${Watchgate[sudo]} ${Watchgate[chmod]} 0440 \$destseed.asc
  ${Watchgate[sudo]} ${Watchgate[chown]} root:users \$destseed.asc
  ${Watchgate[sudo]} ${Watchgate[chmod]} 0400 \$destseed
  ${Watchgate[sudo]} ${Watchgate[chown]} root:root \$destseed
  ${Watchgate[sudo]} ${Watchgate[ln]} -fs \$destseed ${Watchgate[configdir]}${Watchgate[seedprefix]}
  ${Watchgate[sudo]} ${Watchgate[ln]} -fs \$destseed.asc ${Watchgate[configdir]}${Watchgate[seedprefix]}.asc
}
watchgate.seed.uninstall()
{
  ${Watchgate[sudo]} ${Watchgate[rm]} -f ${Watchgate[configdir]}${Watchgate[seedprefix]}.asc
  ${Watchgate[sudo]} ${Watchgate[rm]} -f ${Watchgate[configdir]}${Watchgate[seedprefix]}
  ${Watchgate[sudo]} ${Watchgate[rm]} -f ${Watchgate[configdir]}${Watchgate[seedprefix]}_*.asc
  ${Watchgate[sudo]} ${Watchgate[rm]} -f ${Watchgate[configdir]}${Watchgate[seedprefix]}_*
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
  ${Watchgate[sudo]} ${Watchgate[systemctl]} list-timers --all
}
SUB
  )
}
watchgate.substitution
builtin unset -f watchgate.substitution
builtin unset Watchgate
