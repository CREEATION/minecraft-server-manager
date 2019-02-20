#!/bin/bash

http_server_start()
{
	screen -dmS "$SCREEN_NAME_HTTP"
	screen -S "$SCREEN_NAME_HTTP" -p 0 -X stuff "caddy -root $INTERNAL_DIR/ModManager/release/client/; exec sh^M"
}

script_exit()
{
	echo "$*" ; sleep 3 ; exit
}

script_echo()
{
	echo "- $*"
}

script_echo_separator()
{
	echo "-------"
}

script_echo_newline()
{
	script_echo "
"
}

screen_is_running()
{
	if [ $( screen -ls | grep -c "$*" ) -gt 0 ] ; then
		echo true
	else
		echo false
	fi
}

screen_terminate()
{
	screen -S "$*" -p 0 -X stuff "^C"
	server_cmd "exit"
}

server_start()
{
	screen -dmS "$SCREEN_NAME_SERVER" sh -c "$JAVA_RUN; exec /bin/bash"
}

# send command to server screen
server_cmd()
{
	local SCREEN_RUNNING=$( screen_is_running "$SCREEN_NAME_SERVER" )
	
	if $SCREEN_RUNNING ; then
	    screen -S "$SCREEN_NAME_SERVER" -p 0 -X stuff "$*\015"
	else
		script_echo "Screen \"$SCREEN_NAME_SERVER\" läuft gar nicht. Konnte \"$*\" nicht ausführen."
		exit
	fi
}

server_cmd_hardcopy()
{
    server_cmd "$*"
    sleep 1 #buffer
    screen -S "$SCREEN_NAME_SERVER" -p 0 -X hardcopy "-h"
    sleep 0.25 #buffer
}

# check if server is online
server_is_online()
{
	sleep 1 #buffer
	
	local SCREEN_RUNNING=$( screen_is_running "$SCREEN_NAME_SERVER" )
	
	if $SCREEN_RUNNING ; then
		server_cmd_hardcopy "ping"
		
		# save last line of output to variable	
		local SERVER_ONLINE="$( cat "./hardcopy.0" | awk '/Pong\!/ {print $5}' )"
		SERVER_ONLINE=${SERVER_ONLINE##*$'\n'}
		
		# remove temp file
		rm "./hardcopy.0"
		
		if [[ "$SERVER_ONLINE" == "Pong!" ]] ; then
			echo true
		else
			echo false
		fi
	else
		echo false
	fi
}

# get list of current players
server_get_players()
{
	# list players in console
	server_cmd_hardcopy "list"
	
	# save last line of output to variable	
	local PLAYERS_ONLINE_TIMESTAMP="$( cat "./hardcopy.0" | awk '/are [0-9]+\/[0-9]+ players/ {print $1}' )"
	PLAYERS_ONLINE_TIMESTAMP=${PLAYERS_ONLINE_TIMESTAMP##*$'\n'}
	
	PLAYERS_ONLINE_LIST="$( cat "./hardcopy.0" | grep -F "$PLAYERS_ONLINE_TIMESTAMP" )"
	PLAYERS_ONLINE_LIST=${PLAYERS_ONLINE_LIST##*$'\n'}
	
	# remove temp file
	rm "./hardcopy.0"
	
	echo ${PLAYERS_ONLINE_LIST##*$']: '}
}

# get current online players
server_get_players_online()
{
	# list players in console
	server_cmd_hardcopy "list"
	
	# save last line of output to variable
	local PLAYERS_ONLINE="$( cat "./hardcopy.0" | awk '/are [0-9]+\/[0-9]+ players/ {print $7}' )"
	
	# remove temp file
	rm "./hardcopy.0"
	
	echo ${PLAYERS_ONLINE##*$'\n'}
}

# print server online info to terminal
server_info_terminal()
{
	local PLAYERS_ONLINE="$(server_get_players_online)"
	local PLAYERS_NAMES="$(server_get_players)"
	local STR_PLAYERS_ONLINE="$PLAYERS_ONLINE ($PLAYERS_NAMES)"
	
	if [ "${PLAYERS_ONLINE%/*}" = "0" ] ; then
		STR_PLAYERS_ONLINE="$PLAYERS_ONLINE"
	fi
	
	echo "|-
|| Tipp: Nutze \"screen -r\" um zur Server-Konsole zu wechseln.
|
|| Server-IP: 		$IP_EXTERNAL ($IP_INTERNAL)
|| Port: 		$SERVER_PORT
|
|| Spieler online: 	$STR_PLAYERS_ONLINE
|
|| Verzeichnis: 	$SERVER_DIR
|| Minecraft Version: 	$MINECRAFT_VERSION
|| Forge Version: 	$FORGE_VERSION
|-
"

	script_echo "[x] Zurück zum Hauptmenü"
	
	read OPTION
	
	if [[ $OPTION =~ ^[x]$ ]] ; then
		$SERVER_DIR/Internal/ServerManager/server.sh
	fi
}


####################################################################################################
# TELEGRAM FUNCTIONS

telegram_bot_start()
{
	screen -dmS "$SCREEN_NAME_TELEGRAM" sh -c "exec $SERVER_DIR/Internal/"
}

#telegram_save_last_msg_id()
#{
#	echo "$*" > $TELEGRAM_LAST_MSG_ID_FILE
#}

#telegram_get_last_msg_id()
#{
#	echo "$( head -c -1 $TELEGRAM_LAST_MSG_ID_FILE )"
#}

telegram_delete_message()
{
	curl -s --max-time $TELEGRAM_MAX_REQ_TIME -d "chat_id=$TELEGRAM_CHATID&message_id=$*" $TELEGRAM_API_DELETE_URL > /dev/null
}

# send message and save message id
telegram_send_message()
{
	local LAST_MSG_ID=$( curl -s --max-time $TELEGRAM_MAX_REQ_TIME -d "chat_id=$TELEGRAM_CHATID&parse_mode=Markdown&disable_web_page_preview=1&disable_notification=true&text=$*" $TELEGRAM_API_SEND_URL | jq -r '.result.message_id' )
	
	# save last message id to file for later use in case anything bad happens
	#telegram_save_last_msg_id "$LAST_MSG_ID"
	
	echo "$LAST_MSG_ID"
}

telegram_pin_message()
{
	curl -s --max-time $TELEGRAM_MAX_REQ_TIME -d "chat_id=$TELEGRAM_CHATID&disable_notification=true&message_id=$*" $TELEGRAM_API_PIN_URL > /dev/null
}

telegram_unpin_message()
{
	curl -s --max-time $TELEGRAM_MAX_REQ_TIME -d "chat_id=$TELEGRAM_CHATID&disable_notification=true" $TELEGRAM_API_UNPIN_URL > /dev/null
}

telegram_set_server_online()
{
	# run telegram bot
	$SERVER_DIR/Internal/TelegramBot/bashbot.sh start
	
	# delete last server status message
	#telegram_delete_message "$( telegram_get_last_msg_id )"
	#sleep 1 #buffer
	
	# send message and save message id to pin in chat
	TELEGRAM_LAST_MSG_ID=$( telegram_send_message "$TELEGRAM_MSG_ONLINE" )
	
	# pin message
	telegram_pin_message "$TELEGRAM_LAST_MSG_ID"
}

telegram_set_server_offline()
{
	# kill telegram bot
	$SERVER_DIR/Internal/TelegramBot/bashbot.sh kill
	
	# delete last server status message
	#telegram_delete_message "$( telegram_get_last_msg_id )"
	#sleep 1 #buffer
	
	# send message and save message id to pin in chat
	TELEGRAM_LAST_MSG_ID=$( telegram_send_message "$TELEGRAM_MSG_OFFLINE" )
	
	# pin message
	telegram_pin_message "$TELEGRAM_LAST_MSG_ID"
}

# print server online info to terminal
server_info_telegram()
{
	local PLAYERS_ONLINE="$(server_get_players_online)"
	local PLAYERS_NAMES="$(server_get_players)"
	local STR_PLAYERS_ONLINE="$PLAYERS_ONLINE ($PLAYERS_NAMES)"
	
	if [ "${PLAYERS_ONLINE%/*}" = "0" ] ; then
		STR_PLAYERS_ONLINE="$PLAYERS_ONLINE"
	fi
	
	TELEGRAM_MSG_STATUS="Server-IP: \`$IP_EXTERNAL:$SERVER_PORT\`%0ASpieler online: \`$STR_PLAYERS_ONLINE\`%0A%0AMinecraft Version: \`$MINECRAFT_VERSION\`%0AForge Version: \`$FORGE_VERSION\`%0A%0A[Modpack downloaden](http://$IP_EXTERNAL:2015/$SERVER_MODS)"
	
	telegram_send_message "$TELEGRAM_MSG_STATUS"
}
