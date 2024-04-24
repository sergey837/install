#!/bin/sh
DEFAULT_DOWNLOAD="http://mirror-dl.9hits.com/3.0.4/9hitsv3-linux64.tar.bz2"
_9HITSUSER="_9hits"

set -- --default-dl=$DEFAULT_DOWNLOAD $@
ARGS=$@
dist="unknown"

main() {
	[ "$(id -u)" != "0" ] && \
		abort "This script must be executed as root."
		
	check_dist
	
	echo "Installing dependencies..."
	case "${dist}" in
		debian|ubuntu|zorin)
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
		echo "9HITS LOG: user created: $_9HITSUSER"
	else
		echo "9HITS LOG: creating user: $_9HITSUSER"
		adduser -D $_9HITSUSER
	fi

	wget -O "/tmp/get-app.sh" https://9hitste.github.io/install/3.0.4/get-app.sh && chmod +x "/tmp/get-app.sh"
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
	DEBIAN_FRONTEND=noninteractive apk update
	DEBIAN_FRONTEND=noninteractive apk upgrade
	DEBIAN_FRONTEND=noninteractive apk add --no-cache unzip acl cron xvfb bzip2 libcanberra-gtk3 libxss htop sed tar libxtst libnss3 wget psmisc bc gtk+3.0 gcompat at-spi2-atk at-spi2-core
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
	echo -n "Verifying compatibility with 9hits..."
	if [ -f /etc/os-release ]; then
		dist=$(awk -F= '$1 == "ID" {gsub("\"", ""); print$2}' /etc/os-release)
	elif [ -f /etc/redhat-release ]; then
		dist=$(awk '{print tolower($1)}' /etc/redhat-release)
	else
		not_supported
	fi

	dist=$(echo "${dist}" | tr '[:upper:]' '[:lower:]')

	case "${dist}" in
		debian|ubuntu|alpine|centos|fedora|rocky|zorin)
			echo "OK"
			;;
		*)
			not_supported
			;;
	esac
}

not_supported() {
	cat <<-EOF
	The 9Hits App does not support the OS/Distribution on this machine.
	EOF
	exit 1
}

# abort with an error message
abort() {
	echo "ERROR: $1" >&2
	exit 1
}

main
