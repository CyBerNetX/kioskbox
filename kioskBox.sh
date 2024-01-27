#!/bin/bash

# script de creation d un web kiosk sur raspberry pi 3/4,
# avec ecran 7 pouces.
#
# auteur : jb masurel
# licence : gpl v3
#
############### Varriables ##################
REALPATH=$(dirname $(realpath -s $0))
url=
essid=
wifi_passwd=
conffile=~/webconsole.conf
inverse=
app="sleep 10 && $REALPATH/$(basename $0)"

SUDO=$(whereis -b sudo|cut -d" " -f 2)

############## fonction debut ##############

function usage(){
   echo "sudo $0 -u [url] -e [essid] -w [wifi_passwd] [-i]"
    echo ""
    echo " -u :  url du web kiosk"
    echo " -e : essid du réseau wifi"writeconffile
    echo " -w : mot de passe du wifi"
    echo " -i : inversion de 180° de l affichage console"
    echo ""
    echo " -a  execute fonction A"
    echo ""
    echo " -b  execute fonction B"
    echo ""
    echo "Auteur : CyBerNetX"
    echo "licence GPL v3"
    exit 0
}



function writeconffile(){
    if  [[ ! -f $conffile ]];
    then
        echo "url=$url"|tee -a $conffile
        echo "essid=$essid"|tee -a $conffile
        echo "wifi_passwd=$wifi_passwd"|tee -a $conffile
        echo "inverse=$inverse"|tee -a $conffile
    fi
}

function wpa(){
    if [[ -n $essid ]] && [[ -n $wifi_passwd ]]
    then
        wpa_passphrase $essid $wifi_passwd >> /etc/wpa_supplicant/wpa_supplicant.conf
    else
        echo "valeur essid et wifi password non défini!"
    fi
}

function cronparam(){
    case $@  
    in

        adda)
            echo "pas de paramettre add -a"
            if [[ -z $( crontab -l|grep "@reboot $app" ) ]]
            then
                echo "crontab vide: add 1er_run"
                #ADD
                #(crontab  -l ; echo "@reboot $0 -a") | crontab -
                ( crontab -l; echo "@reboot $app -a 2>&1 | tee -a /dev/tty1 $REALPATH/installer_webkiosk.log" ) | crontab -
            else
                echo "crontab plein"
            fi
        ;;
        addbdela)
        echo "first run"
        echo "first_run del 1 add 2"
        if [[ -n $( crontab -l|grep "@reboot $app -a" ) ]]
        then
            echo "crontab first_run: del 1er run"
            #DEL
            #crontab -l | grep -v "@reboot $0 -a"  | crontab -
            ( crontab -l|grep -v "@reboot $app -a" ) | crontab -
            #ADD
            #(crontab  -l ; echo "@reboot $0 -b") | crontab -
            ( crontab -l; echo "@reboot $app -b 2>&1 | tee -a /dev/tty1 $REALPATH/installer_webkiosk.log" ) | crontab -
        fi
        ;;

        delb)
        echo "second run"
        echo "second_run DEL 2 ADD 3"
        if [[ -n $( crontab -l|grep "@reboot $app -b 2>&1 | tee -a /dev/tty1 $REALPATH/installer_webkiosk.log" ) ]]
        then
            echo "crontab second_run: del 2eme run"
            #DEL
            #crontab -l | grep -v "@reboot $0 -b"  | crontab -
            ( crontab -l|grep -v "@reboot $app -b" ) | crontab -
            #ADD
            #(crontab  -l ; echo "@reboot $0 -c") | crontab -
            #( crontab -l; echo "@reboot $app -c 2>&1 | tee -a /dev/tty1 $REALPATH/installer_webkiosk.log" ) | crontab -
        fi
        ;;

    esac
}

function fonction_A(){

    # MAJ

    $SUDO raspi-config nonint do_wifi_country FR
    $SUDO raspi-config nonint do_hostname "KioskBox"
    $SUDO raspi-config nonint do_expand_rootfs
    $SUDO raspi-config nonint do_ssh 0
    $SUDO apt-get update -y
    $SUDO apt-get dist-upgrade -y
    $SUDO apt install -y matchbox wmctrl
    [[  -z $(grep dtoverlay=vc4-kms-v3d /boot/config.txt) ]] && echo "dtoverlay=vc4-kms-v3d"|tee -a /boot/config.txt|| echo "dtoverlay=vc4-kms-v3d PRESENT"
    [[  -z $(grep dtoverlay=vc4-kms-dsi-7inch /boot/config.txt) ]] &&  echo "dtoverlay=vc4-kms-dsi-7inch"|tee -a /boot/config.txt ||  echo "dtoverlay=vc4-kms-dsi-7inch PRESENT"    

    [[ $inverse -eq "1" ]] && (echo $(cat /boot/cmdline.txt ) "video=DSI-1:800x480@60,rotate=180" >/boot/cmdline.txt ;echo -e "lcd_rotate=2\ndisplay_rotate=2" |$SUDO tee -a /boot/config.txt) 
    [[ ! -e /lib/systemd/system/kiosk.service ]] && cat <<'EOFKIOSKSRVCS' > /lib/systemd/system/kiosk.service
[Unit]
Description=Chromium Kiosk
Wants=graphical.target
After=graphical.target

[Service]
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
Type=simple
ExecStart=/bin/bash /lib/systemd/system/kiosk.sh
Restart=on-abort
User=pi
Group=pi

[Install]
WantedBy=graphical.target
EOFKIOSKSRVCS


[[ ! -e /lib/systemd/system/kiosk.sh ]] && cat <<EOFKIOSKSH |tee /lib/systemd/system/kiosk.sh
#!/bin/bash
xset s noblank
xset s off
xset -dpms

unclutter -idle 0.5 -root &
matchbox-keyboard --daemon &
wmctrl -r 'matchbox-keyboard' -b add,above

sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /home/pi/.config/chromium/Default/Preferences
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' /home/pi/.config/chromium/Default/Preferences

while true; do
   xdotool keydown ctrl+Tab; xdotool keyup ctrl+Tab;
   /usr/bin/chromium-browser --noerrdialogs --disable-infobars --kiosk $url 
   sleep 10
done
EOFKIOSKSH

wpa
}





function fonction_B(){

echo ""
echo -e "Script 3 : Installation interface graphique"
echo ""
echo ""


sleep 2
curl -sL https://www.framboise314.fr/wp-content/uploads/2016/12/keyboard.zip -o keyboard.zip
unzip keyboard.zip
mv /usr/share/matchbox-keyboard/keyboard.xml /usr/share/matchbox-keyboard/keyboard.xml.old
cp keyboard.xml /usr/share/matchbox-keyboard/keyboard.xml



# INSTALL
echo ""
echo -e "INSTALLATION DU MODE FULLSCREEN"
echo ""
echo ""
sleep 2
$SUDO apt-get install -y xdotool unclutter sed

# INSTALL SERVICES
echo ""
echo -e "INSTALLATION DES SERVICES AU DEMARRAGE!"
echo ""
echo ""
sleep 2
$SUDO systemctl enable kiosk.service



}

############## fonction fin ##############


if [ `whoami` = "root" ]; then

    if [[ -n $conffile ]]
    then
        source $conffile
    fi

 #   checkvar
    
    cronparam adda
    while getopts abchiu:e:w: option
    do 
        case "${option}"
            in
            a)
            cronparam addbdela
            fonction_A
            
            ;;
            b)
            cronparam delb
            fonction_B
            ;;
            u) url=${OPTARG};;
            e) essid=${OPTARG};;
            i) inverse=1;;
            w) wifi_passwd=${OPTARG};;
            h) usage ;;
            *) usage ;exit ;;
        esac
        
    done
    writeconffile
    
    echo "reboot !"
    /usr/sbin/shutdown -r 0
    
    
else
	echo "se script à besoin d'être lancer en tant que root!"
    usage
fi
