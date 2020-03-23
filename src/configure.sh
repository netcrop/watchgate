watchgate.substitution()
{
    local systemddir mandir seedprefix configdir queryscript cronscript prefix cmd i
    local cmdlist='sed basename cat id cut bash man mktemp egrep
    date env mv chpasswd pwgen hostname sudo cp chmod ln chown rm sha1sum
    sha512sum gpg shred mkdir systemctl tty stat head cut tr groups
    gpasswd'
    for cmd in $cmdlist;do
        i=($(\builtin type -afp $cmd))
        if [[ -z $i ]];then
            \builtin printf "\%s\n" "${FUNCNAME} missing $cmd"
            return
        fi
        \builtin eval "local ${cmd//-/_}=${i:-:}"
    done
    prefix=/usr/local/bin/
    cronscript=watchgate.cron
    queryscript=watchgate
    configdir=/etc/watchgate/
    seedprefix=watchgate_$($hostname)
    mandir=/usr/local/man/man1/
    systemddir=/usr/lib/systemd/system/
    builtin source <($cat<<-SUB

watchgate()
{
    local help="\${FUNCNAME}:[user][optional: stored seed asc file]"
    local user=\${1:?"\${help}"}
    local seed=\${2:-"${configdir}${seedprefix}"}
    seed=\${seed%.asc}
    $egrep -q "^\${user}:" /etc/passwd
    if [[ \$? != 0 ]];then
        \builtin printf \${help}
        return
    fi
    if [[ -r \${2} || -a \$seed && -r \$seed.asc ]];then
    #    \builtin set -o xtrace
        \builtin declare -x GPG_TTY="\$($tty)"
        local owner=\$($stat -c %U \$GPG_TTY)
        if [[ "\${owner}" != "\${USER}" ]];then
            \builtin printf "User: \"\${USER}\" isn't the owner of \${GPG_TTY}.\n"
            return
        fi
        \builtin \shopt -s extdebug
        \builtin trap "watchgate.delocate" SIGHUP SIGTERM SIGINT RETURN
        watchgate.delocate()
        {
            [[ -r \${tmpfile} ]] && $shred -fu \$tmpfile
            \builtin trap - SIGHUP SIGTERM SIGINT RETURN
            \builtin shopt -u extdebug
            \builtin unset -f watchgate.delocate
            \builtin set +o xtrace
        }
        local tmpfile=\$($mktemp)
        $gpg --homedir \$HOME/.gnupg --no-tty \
            --decrypt --no-verbose --quiet \$seed.asc >\$tmpfile
        [[ \$? != 0 ]] && return
        $pwgen --capitalize --numerals --num-passwords=1 \
            --secure --sha1=\$tmpfile#"\$user\$($date -u +"%Y%m%d%H%M")" 8
        return
    fi
    builtin printf "Seed missing!\n"
    $pwgen --capitalize --numerals --num-passwords=1 \
        --secure --sha1=/dev/null#"\$user\$($date -u +"%Y%m%d%H%M")" 8
}
watchgate.cron()
{
#set -o xtrace
    [[ \$($id -u) != 0 ]] && return
    local seed="${configdir}${seedprefix}"
    local loginuser=\${1:?[login user]}
    local i user word timestamp
    local tmpfile=/tmp/\${RANDOM}
    if [[ ! -r \$seed || ! -r \$seed.asc ]];then
        seed=/dev/null
        builtin printf "Seed missing!\n"
    fi
    \builtin trap "[[ -r \$tmpfile ]] && $shred -fu \$tmpfile" SIGHUP SIGTERM SIGINT
    declare -a Users=(\$($egrep -v "\${loginuser}|nologin\$|false\$" /etc/passwd |\
    $cut -d':' -f1))
    timestamp=\$($date -u +"%Y%m%d%H%M")
    for user in \${Users[@]};do
        \builtin printf "\$user:" >>\$tmpfile
        $pwgen --capitalize --numerals \
            --num-passwords=1 --secure --sha1=\$seed#\$user\$timestamp 8 >>\$tmpfile
    done
    $chpasswd <\$tmpfile
    $shred -fu \$tmpfile
#set +o xtrace
}
watchgate.cron.install()
{
    local loginuser=\${1:?[login user]}
    local fun='watchgate.cron'
    local script="$prefix/\${fun}"
    \builtin type -t \${fun} || return
    $rm -f \${script}
    $cat <<-WATCHGATECRONINSTALL > \${script}
#!$env $bash
\$(\builtin declare -f \${fun})
\${fun} "\${loginuser}"
WATCHGATECRONINSTALL
    $sudo $chmod u=rx,go= \${script}
    $sudo $chown root:users \${script}
    \builtin unset -f \${fun}
}
watchgate.query()
{
    local fun='watchgate'
    local script="$prefix/\${fun}"
    \builtin type -t \${fun} || return
    $rm -f \${script}
    $cat <<-WATCHGATEQUERY > \${script}
#!$env $bash
\$(\builtin declare -f \${fun})
\${fun} "\\\$@"
WATCHGATEQUERY
    $chmod gu=rx,o= \${script}
    $chown $USER:users \${script}
    \builtin unset -f \${fun}
}
watchgate.install()
{ 
    local prefix
    [[ \$($basename \${PWD}) == watchgate ]] && prefix='src/'
    $egrep -q "^users:.*\${USER}" /etc/group 
    if [[ \$? -ne 0 ]];then
        $sudo $gpasswd -a ${USER} users
        \builtin printf "%s\n" "please logout,
        login and run watchgate.install again."
        return
    fi
    watchgate.uninstall
    watchgate.cron.install \${1:?[login user]}
    watchgate.query
    $sudo $mkdir -p $mandir
    $sudo $chmod 0755 $mandir
    $sudo $cp \${prefix}watchgate.1 \
    $mandir/watchgate.1
    $sudo $chmod 0644 $mandir/watchgate.1 
    $sudo $chown $USER:users \
    $mandir/watchgate.1
    $sudo $cp \${prefix}watchgate.service \
    $systemddir/watchgate.service
    $sudo $chmod 0644 \
    $systemddir/watchgate.service
    $sudo $cp \${prefix}watchgate.timer \
    $systemddir/watchgate.timer
    $sudo $chmod 0644 \
    $systemddir/watchgate.timer
    $sudo $ln -s $systemddir/watchgate.timer \
         $systemddir/timers.target.wants/watchgate.timer
}
watchgate.uninstall()
{
    $sudo $rm -f $systemddir/watchgate.service
    $sudo $rm -f $systemddir/watchgate.timer
    $sudo $rm -f \
    $systemddir/timers.target.wants/watchgate.timer
    $sudo $rm -f \
    /var/lib/systemd/timers/stamp-watchgate.timer
    $sudo $rm -f \
    $prefix$queryscript
    $sudo $rm -f \
    $prefix$cronscript
    $sudo $rm -f $mandir/watchgate.1 
    watchgate.seed.uninstall
}
watchgate.seed()
{
    local destdir=\${1:?[seed dest dir]}
    [[ -d \$destdir ]] || return
    local seed="${seedprefix}_\$($date -u +"%Y%m%d%H%M%S")"
    local tmpfile=\$($mktemp)
    \builtin trap "$shred -fu \$tmpfile;$sudo $chown \${owner}: \$GPG_TTY" \
    SIGHUP SIGTERM SIGINT
    $sha512sum <<<"\$RANDOM\$RANDOM\$RANDOM\$RANDOM" | $cut -d' ' -f1 >\$tmpfile
    \builtin declare -x GPG_TTY="\$($tty)"
    local owner=\$($stat -c %U \$GPG_TTY)
    $sudo $chown \$USER: \$GPG_TTY
    $gpg --symmetric --no-verbose --quiet \
    --output \$destdir/\$seed.asc --armor \$tmpfile
    $shred -fu \$tmpfile
    $chmod 0400 \$destdir/\$seed.asc
    $sudo $chown \${owner}: \$GPG_TTY
}
watchgate.seed.install()
{
    local seedasc=\${1:?[watchgate_\$hostname_\$date.asc file]}
    local seed=\$($basename \${seedasc%.asc})
    local destseed=$configdir/\$seed
    local owner=\$($stat -c %U \$GPG_TTY)
#    \builtin set -o xtrace
    \builtin \shopt -s extdebug
    \builtin declare -x GPG_TTY="\$($tty)"
    \builtin trap "watchgate.delocate" SIGHUP SIGTERM SIGINT RETURN
    watchgate.delocate()
    {
        [[ -r \${tmpfile} ]] && $shred -fu \$tmpfile
        [[ "\${owner}" == "\${USER}" ]] || $sudo $chown \${owner}: \$GPG_TTY
        \builtin trap - SIGHUP SIGTERM SIGINT RETURN
        \builtin shopt -u extdebug
        \builtin unset -f watchgate.delocate
        \builtin set +o xtrace
    }
    local tmpfile=\$($mktemp)
    $sudo $chown \$USER: \$GPG_TTY
    $gpg --no-tty --decrypt --no-verbose --quiet \$seedasc >\$tmpfile
    [[ \$? != 0 ]] && return
    $sudo $mkdir -p $configdir
    $sudo $chmod ug=rx,o= $configdir
    $sudo $chown root:users $configdir
    [[ -a \$destseed ]] && $sudo $shred -fu \$destseed
    [[ -a \$destseed.asc ]] && $sudo $shred -fu \$destseed.asc
    $sudo $cp -f \$seedasc \$destseed.asc 
    $sudo $mv -f \$tmpfile \$destseed
    $sudo $chmod 0440 \$destseed.asc
    $sudo $chown root:users \$destseed.asc
    $sudo $chmod 0400 \$destseed
    $sudo $chown root:root \$destseed
    $sudo $ln -fs \$destseed ${configdir}${seedprefix}
    $sudo $ln -fs \$destseed.asc $configdir$seedprefix.asc
}
watchgate.seed.uninstall()
{
    $sudo $rm -f $configdir$seedprefix.asc
    $sudo $rm -f $configdir$seedprefix
    $sudo $rm -f $configdir$seedprefix_*.asc
    $sudo $rm -f $configdir$seedprefix_*
}
watchgate.enable()
{
    $sudo $systemctl enable watchgate.timer
}
watchgate.start()
{
    $sudo $systemctl start watchgate.timer
    watchgate.timer
}
watchgate.stop()
{
    $sudo $systemctl stop watchgate.timer
    watchgate.timer
}
watchgate.disable()
{
    $sudo $systemctl disable watchgate.timer
    watchgate.timer
}
watchgate.mask()
{
    $sudo $systemctl mask watchgate.timer
    watchgate.timer
}
watchgate.unmask()
{
    $sudo $systemctl unmask watchgate.timer
    watchgate.timer
}
watchgate.reload()
{
    $sudo $systemctl daemon-reload
}
watchgate.units()
{
    $sudo $systemctl list-units
}
watchgate.timer()
{
    $sudo $systemctl list-timers --all
}
SUB
    )
}
watchgate.substitution
builtin unset -f watchgate.substitution

