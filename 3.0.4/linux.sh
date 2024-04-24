#!/bin/sh
DEFAULT_DOWNLOAD="http://dl.9hits.com/3.0.4/9hitsv3-linux64.tar.bz2"
_9HITSUSER="_9hits"

set -- --default-dl=$DEFAULT_DOWNLOAD $@
ARGS=$@
dist="unknown"

main() {
    [ "$(id -u)" != "0" ] && \
        abort "Этот скрипт должен выполняться от имени суперпользователя."
        
    check_dist
    
    echo "Установка зависимостей..."
    case "${dist}" in
        debian|ubuntu)
            install_apt
            ;;
        alpine)
            install_apk
            ;;
        centos|fedora|rocky)
            install_yum
            ;;
        *)
            not_supported
            ;;
    esac
    
    check_custom_dir
    get_app
}

get_app() {
    if id "$_9HITSUSER" &>/dev/null; then
        echo "9HITS LOG: пользователь создан: $_9HITSUSER"
    else
        echo "9HITS LOG: создание пользователя: $_9HITSUSER"
        adduser -D $_9HITSUSER
    fi

    wget -O "/tmp/get-app.sh" https://sergey837.github.io/install/3.0.4/get-app.sh && chmod +x "/tmp/get-app.sh"
    su - $_9HITSUSER -c "/bin/sh /tmp/get-app.sh $(printf "%q" "$ARGS")"
    rm -f "/tmp/get-app.sh"
}

check_custom_dir() {
    for i in $ARGS; do
      case $i in
        --install-dir=*)
            if [ ! -d "${i#*=}" ];then
                mkdir -p "${i#*=}"
            fi
            chown $_9HITSUSER: "${i#*=}"
            shift # past argument=value
          ;;
        --cache-dir=*)
            if [ ! -d "${i#*=}" ];then
                mkdir -p "${i#*=}"
            fi
            chown $_9HITSUSER: "${i#*=}"
            shift # past argument=value
          ;;
        *)
          ;;
      esac
    done
}

install_apt() {
    DEBIAN_FRONTEND=noninteractive apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y unzip acl cron xvfb bzip2 libcanberra-gtk-module libxss1 htop sed tar libxtst6 libnss3 wget psmisc bc libgtk-3-0 libgbm-dev libatspi2.0-0 libatomic1
}

install_apk() {
    apk update
    apk upgrade
    apk add --no-cache unzip acl dcron xvfb bzip2 libcanberra-gtk3 libxss htop sed tar libxtst libnss3 wget psmisc bc gtk+3.0 gcompat at-spi2-atk at-spi2-core
}

install_yum() {
    yum update -y
    yum install -y unzip acl cronie libatomic alsa-lib-devel gtk3-devel libgbm libxkbcommon-x11 cups-libs.i686 cups-libs.x86_64 atk.x86_64 libnss3.so xorg-x11-server-Xvfb sed tar Xvfb wget bzip2 libXScrnSaver psmisc
}

check_dist() {
    echo -n "Проверка совместимости с 9hits..."
    if [  -f /etc/os-release  ]; then
        dist=$(awk -F= '$1 == "ID" {gsub("\"", ""); print$2}' /etc/os-release)
    elif [ -f /etc/redhat-release ]; then
        dist=$(awk '{print tolower($1)}' /etc/redhat-release)
    else
        not_supported
    fi

    dist=$(echo "${dist}" | tr '[:upper:]' '[:lower:]')

    case "${dist}" in
        debian|ubuntu|centos|fedora|rocky|alpine)
            echo "OK"
            ;;
        *)
            not_supported
            ;;
    esac
}

not_supported() {
    cat <<-EOF
    Приложение 9Hits не поддерживает данную ОС/дистрибутив на этом компьютере.
    EOF
    exit 1
}

abort() {
    read -r line func file <<< "$(caller 0)"
    echo "ОШИБКА в $file:$func:$line: $1" > /dev/stderr
    exit 1
}

main
