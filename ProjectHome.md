SSH-VPN utilizza l'opzione -w di OpenSSH per creare una VPN routed.

Tramite i dispositivi tun creati da openssh viene stabilita una connessione punto punto con il peer remoto.
SSH-VPN si occupa di effettuare il dicover dei dispositivi tun liberi da utilizzare.
Tramite il file di configurazione si impostano gli indirizzamenti e i comandi di routing locali e remoti.

Es:
```
SSH_OPTS="-i /home/pietro/.ssh/id_dsa" # Opzioni passate a ssh
RUSER=root                             # Utente utilizzato per la connessione
PEER=foo.bar.com                       # Peer remoto
RTUNADDR=10.10.101.2                   # Indirizzo remoto della VPN
LTUNADDR=10.10.101.1                   # Indirizzo locale della VPN
REMOTE_NET=192.168.2.0/24              # Subnet remota
ENABLE_PEER_IP_FORWARD=false           # Abilita l' ip_forwarding sul peer remoto
TRY_LOAD_PEER_TUN_MOD=true             # esegue modprobe tun sul peer
# $LOCAL_TUN is local tun device
# $REMOTE_TUN is remote tun device
# in POST_TUN_PEER_COMMAND use ' instead " !!!
POST_TUN_PEER_COMMAND='iptables -I FORWARD -i $REMOTE_TUN -j ACCEPT' # comando eseguito sul peer dopo la connessione
# in POST_TUN_LOCAL_COMMAND use ' instead " !!!
POST_TUN_LOCAL_COMMAND='ip route add 192.168.6.0/24 via $RTUNADDR dev $LOCAL_TUN' #comando eseguito localmente dopo la connessione

```