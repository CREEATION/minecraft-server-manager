#!/bin/bash

# CORE
source ./Internal/ServerManager/core/imports.sh

# GET PASSED ARGUMENTS
# -m silent
# -f start/restart/stop
while getopts m:f:h: opt ; do
	case "${opt}" in
		m) ARG_MODE=${OPTARG} ;;
		f) ARG_FORCE=${OPTARG} ;;
		h) ARG_HELP=${OPTARG} ;;
	esac
done

if [ "$ARG_MODE" == "silent" ] ; then
	MODE_SILENT=true
fi

if [ "$ARG_MODE" == "build" ] ; then
	$INTERNAL_DIR/ModManager/build.sh
	exit
fi

# GET WHAT TO FORCE
FORCE_START=false
FORCE_RESTART=false
FORCE_STOP=false

case "$ARG_FORCE" in
	"start") FORCE_START=true ;;
	"restart") FORCE_RESTART=true ;;
	"stop") FORCE_STOP=true ;;
	*) ;;
esac

# START SCRIPT
clear

# BACK TO MAIN MENU OPTION
menu_back_to_main()
{
	script_echo "[x] Zurück zum Hauptmenü"
	
	read OPTION
	
	if [[ $OPTION =~ ^[x]$ ]] ; then
		SERVER_SCRIPT=$(readlink -f "$0")
		exec "$SERVER_SCRIPT"
	fi
}

script_echo "# Hauptmenü:"
script_echo_separator

if $( server_is_online ) > /dev/null ; then
	script_echo "   [ SERVER ONLINE ]"
	script_echo_separator
	script_echo "    Server-Konsole aufrufen:"
	script_echo "    $ screen -r KoksNuttenServer"
	script_echo_separator
	script_echo "[1] Server-Informationen anzeigen"
	script_echo "[2] Server neu starten"
	script_echo "[3] Server stoppen"
	script_echo_separator
	script_echo "[4] Mod-Manager (TODO)"
	script_echo "[5] Telegram-Manager (TODO)"
	
else
	script_echo "[ SERVER OFFLINE ] -"
	script_echo_separator
	script_echo "[1] Server starten"
	script_echo "[2] Server konfigurieren (TODO)"
	script_echo_separator
	script_echo_separator
	script_echo "[3] Mod-Manager (TODO)"
	script_echo "[4] Telegram-Manager (TODO)"
	
fi

script_echo_separator
script_echo "[0] Beenden"
script_echo_separator

read -p ">> Bitte wähle eine Option: " OPTION

clear

# stop script
if [[ $OPTION =~ ^[0]$ ]] ; then
	exit
fi

if [ $(server_is_online) == true ] ; then
	# SHOW SERVER INFO
	if [[ $OPTION =~ ^[1]$ ]] ; then
		server_info_terminal
	
	# RESTART SERVER
	elif [[ $OPTION =~ ^[2]$ ]] ; then
		script_echo "> Starte den Server neu..."
		
		server_cmd "say §cIch §cglaube §cich §cmuss §cin §210 §2Sekunden §csterben. Sorry."
		script_echo "> Der vorzeitige Tod des Servers wurde den Spielern angekündigt!"
		
		# wait 10 seconds before restarting
		sleep 10
		
		server_cmd "say Huch, wie schnell die Zeit vergeht... §eAdieu!"
		server_cmd "say §7(Bin §7nur §7kurz §7Zigaretten §7holen. §7Maximal §75 §7Minuten. §7Versprochen!)"
		
		# save world
		server_cmd "save-all"
		
		# stop server
		sleep 10 #buffer to read text
		
		script_echo "> Server wird gestoppt..."
		server_cmd "stop"
		
		# wait for it...
		sleep 5
		
		# terminate screen session
		screen_terminate "$SCREEN_NAME_SERVER"
		
		script_echo "> Alles klar, der Server sollte jetzt aus sein."
		
		# notify via telegram
		telegram_set_server_offline
		
		sleep 3
		
		# start minecraft server
		server_start
		
		LOADING_BAR=""
		LOADING_BAR_CHAR="."
		
		while [ $(server_is_online) == false ] ; do			
			clear
			script_echo "> Server wird gestartet$LOADING_BAR"
			# progress bar
			LOADING_BAR="$LOADING_BAR$LOADING_BAR_CHAR"
			
			sleep 3
		done
		
		clear
		script_echo "> Server ist online!"
		script_echo "$ screen -r $SCREEN_NAME_SERVER"
		
		# notify via telegram
		telegram_set_server_online
		
		menu_back_to_main
		
	# STOP SERVER
	elif [[ $OPTION =~ ^[3]$ ]] ; then
		script_echo "> Server wird gestoppt..."
		
		# save world
		server_cmd "save-all"
		script_echo "> Welt wird gespeichert..."
		sleep 2
		
		# stop server
		server_cmd "stop"
		
		# stop caddy
		screen_terminate "$SCREEN_NAME_HTTP"
		
		# wait for it...
		sleep 5
		
		# terminate screen session
		screen_terminate "$SCREEN_NAME_SERVER"
		
		clear
		
		script_echo "> Alles klar, der Server sollte jetzt aus sein."
		
		# notify via telegram
		telegram_set_server_offline
		
		menu_back_to_main
		
	# nonsense...
	else
		script_exit "    \"Wenn man auf Salat verzichtet, kann man plötzlich
     das volle Potenzial seines Hirns nutzen.\"
- Robert, 2019 (hat er so gesagt)"
		
	fi
else
	# START SERVER
	if [[ $OPTION =~ ^[1]$ ]] ; then
		script_echo "> Server wird gestartet"
		
		# start minecraft server
		server_start
		
		LOADING_BAR=""
		LOADING_BAR_CHAR="."
		
		while [ $(server_is_online) == false ] ; do			
			clear
			script_echo "> Server wird gestartet$LOADING_BAR"
			# progress bar
			LOADING_BAR="$LOADING_BAR$LOADING_BAR_CHAR"
			
			sleep 3
		done
		
		clear
		script_echo "> Server ist online!"
		script_echo "$ screen -r $SCREEN_NAME_SERVER"
		
		# start http server
		http_server_start
		
		# notify via telegram
		telegram_set_server_online
		
		menu_back_to_main
	
	# CONFIGURE BASIC SERVER STUFF
	elif [[ $OPTION =~ ^[2]$ ]] ; then
		script_echo "TODO"
		menu_back_to_main
	
	# nonsense...
	else
		script_exit "    \"Wenn man auf Salat verzichtet, kann man plötzlich
     das volle Potenzial seines Hirns nutzen.\"
- Robert, 2019 (hat er so gesagt)"

	fi

fi

exit
