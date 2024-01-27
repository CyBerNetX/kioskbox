# kioskbox
script  pour creer un raspberry pi en web kiosk


Hardware prérequis :

 - Raspberry pi 3 b+			=> https://www.amazon.fr/s?k=raspberry+pi+3b%2B
 - écran 7" raspberry pi officiel	=> https://www.amazon.fr/DSI-LCD-Raspberry-Affichage-Luminosit%C3%A9/dp/B096KL11X8/
 - boiter 				=> https://www.amazon.fr/Raspberry-%C3%A9cran-tactile-Coque-bo%C3%AEtier/dp/B01GQFUWIC/

 - usb key

Prérequis logiciel :

 - passer le raspberry pi en boot sur usb
 
 - installer raspi os bookworm  desktop 64 bit sur la clef 
 - deposer un fichier vide ssh dans /boot/firmeware/
 - creer le fichier userconf.txt dans /boot/firmeware/ 
    - par la commande: 
      echo -e "pi:"$(echo "jxTcrbSs"  | openssl passwd -6 -stdin) >/boot/firmeware/userconf.txt
      defini le user pi avec le mot de passe : "jxTcrbSs"
 	- a vous de le changer
 - creer le fichier /boot/firmeware/wpa_supplicant.conf
'''
country=fr
update_config=1
ctrl_interface=/var/run/wpa_supplicant

network={
 scan_ssid=1
 ssid="MyNetworkSSID"
 psk="Pa55w0rd1234"
}

'''

