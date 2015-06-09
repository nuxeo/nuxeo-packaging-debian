#!/bin/bash -e

ACTION=$1
V1=$2
V2=$3

usage() {
    echo "Usage: test-distrib.sh [ install <version> | upgrade <version1> <version2> ]"
    exit 1
}

base() {
    if [ -n "$MIRROR" ]; then
        sed -i -e "s,http://http.debian.net/debian,http://$MIRROR/debian,g" /etc/apt/sources.list
        sed -i -e "s,http://security.debian.org,http://$MIRROR/debian-security,g" /etc/apt/sources.list
        sed -i -e "s,http://archive.ubuntu.com/ubuntu,http://$MIRROR/ubuntu,g" /etc/apt/sources.list
    fi
    sed -i -e "s,^deb-src,#deb-src,g" /etc/apt/sources.list
    export DEBIAN_FRONTEND=noninteractive
    apt-get update || true
    apt-get -q -y install wget net-tools
    wget -O- http://apt.nuxeo.org/nuxeo.key | apt-key add -
    echo "deb http://apt.nuxeo.org/ wheezy releases" > /etc/apt/sources.list.d/nuxeo.list
    echo "deb http://apt.nuxeo.org/ wheezy fasttracks" >> /etc/apt/sources.list.d/nuxeo.list
    echo "deb http://apt.nuxeo.org/ wheezy snapshots" >> /etc/apt/sources.list.d/nuxeo.list
    if [ -n "$MIRROR" ]; then
        sed -i -e "s,http://apt.nuxeo.org,http://$MIRROR/nuxeo,g" /etc/apt/sources.list.d/nuxeo.list
    fi
    if [ ! -f /testfiles/cache/jdk-8-linux-x64.tgz ]; then
        mkdir -p /testfiles/cache
        wget -O/testfiles/cache/jdk-8-linux-x64.tgz --no-check-certificate --header 'Cookie: oraclelicense=accept-securebackup-cookie' 'http://download.oracle.com/otn-pub/java/jdk/8u40-b26/jdk-8u40-linux-x64.tar.gz'
    fi
    mkdir /usr/lib/jvm
    cd /usr/lib/jvm/
    tar xzf /testfiles/cache/jdk-8-linux-x64.tgz
    ln -s jdk1.8.0_40 java-8
    update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-8/jre/bin/java 1081
    update-alternatives --set java /usr/lib/jvm/java-8/jre/bin/java
    apt-get update || true
    echo nuxeo nuxeo/bind-address select 0.0.0.0 | debconf-set-selections
    echo nuxeo nuxeo/http-port select 8080 | debconf-set-selections
    echo nuxeo nuxeo/database select Autoconfigure PostgreSQL | debconf-set-selections

}

mpinstall() {
    if [ -f /testfiles/instance.clid ]; then
        cp /testfiles/instance.clid /var/lib/nuxeo/data/
        chown nuxeo:nuxeo /var/lib/nuxeo/data/instance.clid
    fi
    export NUXEO_CONF=/etc/nuxeo/nuxeo.conf
    su nuxeo -c '/var/lib/nuxeo/server/bin/nuxeoctl --accept=true mp-set nuxeo-dm'
}

install() {
    if [ "$1" == "latest" ]; then
        apt-get -o Dpkg::Options::="--force-confold" -q -y install nuxeo
    else
        apt-get -o Dpkg::Options::="--force-confold" -q -y install nuxeo=$1-01
    fi
}

if [ "$ACTION" == "install" ]; then
    if [ "$V1" == "" ]; then
        usage
    fi
elif [ "$ACTION" == "upgrade" ]; then
    if [ "$V1" == "" ] || [ "$V2" == "" ]; then
        usage
    fi
else
    usage
fi

base

if [ "$ACTION" == "install" ]; then
    install $V1
    mpinstall
elif [ "$ACTION" == "upgrade" ]; then
    install $V1
    mpinstall
    install $V2
fi

