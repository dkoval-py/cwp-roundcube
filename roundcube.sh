#!/bin/bash
yum install wget curl -y
current_version=`cat /usr/local/cwpsrv/var/services/roundcube/index.php | grep Version | cut -d " " -f 4`
echo

echo -n "Enter new Roundcube version (ex. 1.4.11): "
read user_version

url="https://github.com/roundcube/roundcubemail/releases/download/$user_version/roundcubemail-$user_version-complete.tar.gz"

new_version=`echo $url | cut -d "/" -f 8`
Date=`date "+%d-%m-%Y"`
current_version_1=`echo $current_version | cut -d "." -f 1`
current_version_2=`echo $current_version | cut -d "." -f 2`
current_version_3=`echo $current_version | cut -d "." -f 3`
new_version_1=`echo $new_version | cut -d "." -f 1`
new_version_2=`echo $new_version | cut -d "." -f 2`
new_version_3=`echo $new_version | cut -d "." -f 3`
roundcubezip=$(echo $url | cut -d "/" -f 9)
roundcube=$(basename $(echo $url | cut -d "/" -f 9) -complete.tar.gz)


vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

testvercomp () {
    vercomp $1 $2
    case $? in
        0) op='=';;
        1) op='>';;
        2) op='<';;
    esac
    if [[ $op == $3 ]]
    then
        echo "#############################"
        echo "Roundcube version is the same"
        echo "#############################"
    else
        echo "Updating Roundcube to version $new_version"
        cp -R /usr/local/cwpsrv/var/services/roundcube /usr/local/cwpsrv/var/services/roundcube_$Date.bak
        cd /usr/local/cwpsrv/var/services/
        wget $url
        tar -xvzf $roundcubezip
        rm -rf $roundcubezip

        # version  0.9.8.764 fix for new roundcube update if user has disabled system in default server php
        sed -i "s@\/usr\/bin\/env php@\/usr\/bin\/env \/usr\/local\/cwp\/php71\/bin\/php@g" /usr/local/cwpsrv/var/services/roundcube/bin/installto.sh

	# Commend check version error string        
	sed -i '/rcube::raise_error("Target installation/s/^/#/' /usr/local/cwpsrv/var/services/$roundcube/bin/installto.sh
        sed -i '/rcube::raise_error("Installation at target location is up-to-date/s/^/#/' /usr/local/cwpsrv/var/services/$roundcube/bin/installto.sh


        echo Y | /usr/local/cwpsrv/var/services/$roundcube/bin/installto.sh /usr/local/cwpsrv/var/services/roundcube
        chown -R cwpsvc:cwpsvc /usr/local/cwpsrv/var/services/roundcube 
        rm -rf /usr/local/cwpsrv/var/services/roundcube/installer

        if [ "$roundcube" != "/" ];then
                rm -rf $roundcube
        fi

        # elastic skin setup
        if [ -e "/usr/local/cwpsrv/var/services/roundcube/skins/elastic" ];then
            sed -i "s/larry/elastic/g" /usr/local/cwpsrv/var/services/roundcube/config/config.inc.php
        fi
        
        #service httpd restart
        echo "###################################"
        echo "Roundcube is updated to new version"
        echo "###################################"
    fi
}

testvercomp "$new_version" "$current_version" "="
