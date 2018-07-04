declare -Ax Watchgate

watchgate.substitution()
{
  local cmd i cmdlist='sed basename cat id cut bash man mktemp egrep
  date env mv chpass pwgen hostname sudo cp chmod ln chown rm
  sha512 gpg shred mkdir tty head cut tr encrypt'
  for cmd in $cmdlist;do
    i="$(which $cmd)"
    if [[ -z $i ]];then
      \builtin echo "missing $cmd"
    fi
    Watchgate["$cmd"]="${i:-:}"
  done
  Watchgate[prefix]=/usr/local/bin/
  Watchgate[cronscript]=watchgate.cron
  Watchgate[queryscript]=watchgate
  Watchgate[configdir]=/etc/watchgate/
  Watchgate[seedprefix]=watchgate_$(${Watchgate[hostname]})
  Watchgate[mandir]=/usr/local/man/man1/
  builtin source <(${Watchgate[cat]}<<-SUB

watchgate()
{
#  set -o xtrace
  local user=\${1:?[user][optional: stored seed asc file]}
  local seed=\${2:-"${Watchgate[configdir]}${Watchgate[seedprefix]}"}
  seed=\${seed%.asc}
  if [[ -r \${2} || -a \$seed && -r \$seed.asc ]];then
    local tmpfile=\$(${Watchgate[mktemp]})
    builtin trap "${Watchgate[shred]} -fu \$tmpfile" SIGHUP SIGTERM SIGINT
    builtin declare -x GPG_TTY="\$(${Watchgate[tty]})"
    ${Watchgate[gpg]} --homedir \$HOME/.gnupg --no-tty \
    --decrypt --no-verbose --quiet \$seed.asc >\$tmpfile
    if [[ \$? != 0 ]];then
      builtin printf "User \${USER} needs to become the owner of \${GPG_TTY}.\n"
      return
    fi
    ${Watchgate[pwgen]} --capitalize --numerals --num-passwords=1 \
      --secure --sha1=\$tmpfile#"\$user\$(${Watchgate[date]} +"%Y%m%d%H%M")" 8
    ${Watchgate[shred]} -fu \$tmpfile
    return
  fi
  builtin printf "Seed missing!\n"
  ${Watchgate[pwgen]} --capitalize --numerals --num-passwords=1 \
    --secure --sha1=/dev/null#"\$user\$(${Watchgate[date]} +"%Y%m%d%H%M")" 8
#  set +o xtrace
}
watchgate.query()
{
  local fun='watchgate'
  local script="${Watchgate[prefix]}/\${fun}"
  \builtin type -t \${fun} || return
  ${Watchgate[rm]} -f \${script}
  ${Watchgate[cat]} <<-WATCHGATEQUERY > \${script}
#!${Watchgate[env]} ${Watchgate[bash]}
\$(\builtin declare -f \${fun})
\${fun} "\\\$@"
WATCHGATEQUERY
  ${Watchgate[chmod]} gu=rx,o= \${script}
  ${Watchgate[chown]} $USER:wheel \${script}
  \builtin unset -f \${fun}
}
watchgate.cron()
{
# set -o xtrace
#  [[ \$(${Watchgate[id]} -u) != 0 ]] && return
  local seed="${Watchgate[configdir]}${Watchgate[seedprefix]}"
  local excludeuser=\${1:?[exclude user]}
  if [[ ! -r \$seed || ! -r \$seed.asc ]];then
    seed=/dev/null
    builtin printf "Seed missing!\n"
  fi
#  local tmpfile=\$(${Watchgate[mktemp]})
#  builtin trap "${Watchgate[shred]} -fu \$tmpfile" SIGHUP SIGTERM SIGINT
  local oldifs=\${IFS}
  declare -a Entry=()
  IFS=\$'\n'
  declare -a Users=(\$(${Watchgate[egrep]} -v "nologin" /etc/master.passwd|\
    ${Watchgate[egrep]} -v ^"\${excludeuser}"))
  local len=\${#Users[@]}
  IFS=\${oldifs}
  local str i user timestamp word
  timestamp=\$(${Watchgate[date]} +"%Y%m%d%H%M")
  for((i=0;i<\${len};i++));do
    user="\${Users[\$i]%%:*}"
    str="\$(${Watchgate[encrypt]} \
    <<<\$(${Watchgate[pwgen]} --capitalize --numerals --num-passwords=1 \
    --secure --sha1=\${seed}#\${user}\${timestamp} 8))"
    ${Watchgate[chpass]} -a \
  "\$(${Watchgate[sed]} "s;^\([^:]*:\)\([^:]*\):;\1\${str}:;" <<<"\${Users[\$i]}")"
  done
# set +o xtrace
}
watchgate.cron.install()
{
  local excludeuser=\${1:?[exlucde user]}
  local fun='watchgate.cron'
  local script="${Watchgate[prefix]}/\${fun}"
  \builtin type -t \${fun} || return
  ${Watchgate[rm]} -f \${script}
  ${Watchgate[cat]} <<-WATCHGATECRONINSTALL > \${script}
#!${Watchgate[env]} ${Watchgate[bash]}
\$(\builtin declare -f \${fun})
\${fun} "\${excludeuser}"
WATCHGATECRONINSTALL
  ${Watchgate[sudo]} ${Watchgate[chmod]} u=rx,go= \${script}
  ${Watchgate[sudo]} ${Watchgate[chown]} root:wheel \${script}
  \builtin unset -f \${fun}
}
watchgate.install()
{
  local prefix
  [[ \$(${Watchgate[basename]} \${PWD}) == watchgate ]] && prefix='src/'
  watchgate.uninstall
  watchgate.cron.install \${1:?[exclude user]}
  watchgate.query
  ${Watchgate[sudo]} ${Watchgate[mkdir]} -p ${Watchgate[mandir]}
  ${Watchgate[sudo]} ${Watchgate[chmod]} 0755 ${Watchgate[mandir]}
  ${Watchgate[sudo]} ${Watchgate[cp]} \${prefix}watchgate.1 \
  ${Watchgate[mandir]}/watchgate.1
  ${Watchgate[sudo]} ${Watchgate[chmod]} 0644 ${Watchgate[mandir]}/watchgate.1 
  ${Watchgate[sudo]} ${Watchgate[chown]} $USER:wheel \
  ${Watchgate[mandir]}/watchgate.1
}
watchgate.uninstall()
{
  ${Watchgate[sudo]} ${Watchgate[rm]} -f \
  ${Watchgate[prefix]}${Watchgate[queryscript]}
  ${Watchgate[sudo]} ${Watchgate[rm]} -f \
  ${Watchgate[prefix]}${Watchgate[cronscript]}
  ${Watchgate[sudo]} ${Watchgate[rm]} -f ${Watchgate[mandir]}/watchgate.1 
  watchgate.seed.uninstall
}
watchgate.seed()
{
  local destdir=\${1:?[seed dest dir]}
  [[ -d \$destdir ]] || return
  local seed="${Watchgate[seedprefix]}_\$(${Watchgate[date]} +"%Y%m%d%H%M%S")"
  local tmpfile=\$(${Watchgate[mktemp]})
  builtin trap "${Watchgate[shred]} -u $tmpfile" SIGHUP SIGTERM SIGINT
  ${Watchgate[sha512]} <<<"\$(${Watchgate[head]} -n 1000 \
  /dev/random|${Watchgate[tr]} '\0' ' ')" |\
    ${Watchgate[cut]} -d' ' -f1 >\$tmpfile
  builtin declare -x GPG_TTY="\$(${Watchgate[tty]})"
  ${Watchgate[gpg]} --symmetric --no-verbose --quiet \
  --output \$destdir/\$seed.asc --armor \$tmpfile
  ${Watchgate[shred]} -fu \$tmpfile
  ${Watchgate[chmod]} 0400 \$destdir/\$seed.asc
}
watchgate.seed.install()
{
  local seedasc=\${1:?[watchgate_hostname_date.asc file]}
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
  ${Watchgate[sudo]} ${Watchgate[chown]} root:wheel ${Watchgate[configdir]}
  [[ -a \$destseed ]] && ${Watchgate[sudo]} ${Watchgate[shred]} -fu \$destseed
  [[ -a \$destseed.asc ]] && \
  ${Watchgate[sudo]} ${Watchgate[shred]} -fu \$destseed.asc
  ${Watchgate[sudo]} ${Watchgate[cp]} -f \$seedasc \$destseed.asc 
  ${Watchgate[sudo]} ${Watchgate[mv]} -f \$tmpfile \$destseed
  ${Watchgate[sudo]} ${Watchgate[chmod]} 0440 \$destseed.asc
  ${Watchgate[sudo]} ${Watchgate[chown]} root:wheel \$destseed.asc
  ${Watchgate[sudo]} ${Watchgate[chmod]} 0400 \$destseed
  ${Watchgate[sudo]} ${Watchgate[chown]} root:wheel \$destseed
  ${Watchgate[sudo]} ${Watchgate[ln]} -fs \$destseed \
  ${Watchgate[configdir]}${Watchgate[seedprefix]}
  ${Watchgate[sudo]} ${Watchgate[ln]} -fs \$destseed.asc \
  ${Watchgate[configdir]}${Watchgate[seedprefix]}.asc
}
watchgate.seed.uninstall()
{
  ${Watchgate[sudo]} ${Watchgate[rm]} -f \
  ${Watchgate[configdir]}${Watchgate[seedprefix]}.asc
  ${Watchgate[sudo]} ${Watchgate[rm]} -f \
  ${Watchgate[configdir]}${Watchgate[seedprefix]}
  ${Watchgate[sudo]} ${Watchgate[rm]} -f \
  ${Watchgate[configdir]}${Watchgate[seedprefix]}_*.asc
  ${Watchgate[sudo]} ${Watchgate[rm]} -f \
  ${Watchgate[configdir]}${Watchgate[seedprefix]}_*
}
SUB
  )
}
watchgate.substitution
builtin unset -f watchgate.substitution
builtin unset Watchgate
