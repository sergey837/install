#!/bin/sh
ARGS=$@
INSTALL_DIR=~
DOWNLOAD_URL=""

main() {
    echo "Обновление..."
    parse_args
    update
}

parse_args() {
    for i in $ARGS; do
      case $i in
        --install-dir=*)
          INSTALL_DIR="${i#*=}"
          shift # past argument=value
          ;;
        --default-dl=*)
          DOWNLOAD_URL="${i#*=}"
          shift # past argument=value
          ;;
        --download-url=*)
          DOWNLOAD_URL="${i#*=}"
          shift # past argument=value
          ;;
        -*|--*)
          echo "Неизвестная опция $i"
          ;;
        *)
          ;;
      esac
    done
}

update () {
    if [ -d "$INSTALL_DIR/9hitsv3-linux64/" ]; then
        echo "Резервное копирование crontab..."
        crontab -l > "$INSTALL_DIR/9hitsv3-linux64/_9hits_cron.bak" && crontab -r
        echo "Остановка запущенного приложения..."
        pkill 9hits ; pkill 9hbrowser ; pkill 9htl ; pkill exe
        echo "Загрузка..."
        cd "$INSTALL_DIR/9hitsv3-linux64/" && wget -O "$INSTALL_DIR/_9hits_patch.tar.bz2" $DOWNLOAD_URL
        echo "Распаковка обновления..."
        pkill 9hits ; pkill 9hbrowser ; pkill 9htl ; pkill exe
        cd "$INSTALL_DIR/9hitsv3-linux64/" && tar -xvf "$INSTALL_DIR/_9hits_patch.tar.bz2"
        rm -f "$INSTALL_DIR/_9hits_patch.tar.bz2"
        chmod -R 777 "$INSTALL_DIR/9hitsv3-linux64/"
        chmod +x "$INSTALL_DIR/9hitsv3-linux64/9hits"
        chmod +x "$INSTALL_DIR/9hitsv3-linux64/3rd/9htl"
        chmod +x "$INSTALL_DIR/9hitsv3-linux64/browser/9hbrowser"
        chmod +x "$INSTALL_DIR/9hitsv3-linux64/9HitsApp"
    
        echo "Удаление кэша..."
        rm -rf ~/.cache/9hits-app/
        echo "Восстановление crontab..."
        if [ -f "$INSTALL_DIR/9hitsv3-linux64/_9hits_cron.bak" ]; then
            crontab "$INSTALL_DIR/9hitsv3-linux64/_9hits_cron.bak"
            rm -f "$INSTALL_DIR/9hitsv3-linux64/_9hits_cron.bak"
            echo "Восстановлено"
        fi
        if !(crontab -l | grep -q "* * * * * $INSTALL_DIR/9hitsv3-linux64/cron-start"); then
            (echo "* * * * * $INSTALL_DIR/9hitsv3-linux64/cron-start") | crontab -
            echo "Воссоздано"
        fi
        
        echo "ПРИЛОЖЕНИЕ 9HITS ОБНОВЛЕНО!"
    else
        echo "ОШИБКА: НЕ НАЙДЕНО ПРИЛОЖЕНИЕ 9HITS ($INSTALL_DIR)!"
    fi
}

main
