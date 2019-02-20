#!/bin/bash

# name of the terminal screen ("> man screen")
SCREEN_NAME_SERVER="KoksNuttenServer"
SCREEN_NAME_TELEGRAM="KoksNuttenTelegramBot"
SCREEN_NAME_HTTP="KoksNuttenModManager"

# -------
# INTERNAL
SERVER_DIR="${PWD%/Internal/*}"
INTERNAL_DIR="$SERVER_DIR/Internal"
SERVER_PORT="$( cat server.properties | awk '/server-port=([0-9])+/' )" ; SERVER_PORT=${SERVER_PORT##*=}

SERVER_MODS_DIR="$INTERNAL_DIR/ModManager/release/client"
for MODPACK in "$SERVER_MODS_DIR"/*.zip; do
  SERVER_MODS="${MODPACK##*client/}"
done

# MODES
MODE_SILENT=false

#JAVA_PARAMS="java -Xms2048M -Xmx12288M"
JAVA_PARAMS="java -Xms4G -Xmx4G -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=100 -XX:+DisableExplicitGC -XX:TargetSurvivorRatio=90 -XX:G1NewSizePercent=50 -XX:G1MaxNewSizePercent=80 -XX:G1MixedGCLiveThresholdPercent=35 -XX:+AlwaysPreTouch -XX:+ParallelRefProcEnabled"
JAVA_OPTIONAL="nogui"

# SERVER INFO
IP_INTERNAL="$( ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' )"
IP_EXTERNAL="$( lynx --source https://ipecho.net/plain )"
IP_EXTERNAL_FULL="$IP_EXTERNAL:$SERVER_PORT"

# we use two separate loops here to ensure we got the
# current minecraft version already for later use

# get minecraft version from server jar files
for jar in $SERVER_DIR/*.jar
do
	jar="${jar#${SERVER_DIR}/}"
	
	if [ "${jar/minecraft_server}" != "$jar" ] ; then
		# get minecraft jar name
		MINECRAFT_JAR="$jar"
		
		MINECRAFT_VERSION=${jar%\.jar*}
		MINECRAFT_VERSION=${MINECRAFT_VERSION##*server\.}
	fi
done

# set path
MINECRAFT_PATH="$SERVER_DIR/$MINECRAFT_JAR"


# get forge version, too
for jar in $SERVER_DIR/*.jar
do
	jar="${jar#${SERVER_DIR}/}"
	
	if [ "${jar/forge}" != "$jar" ] ; then
		# get forge jar name
		FORGE_JAR="$jar"
		
		FORGE_VERSION=${jar%\-universal\.jar*}
		FORGE_VERSION=${FORGE_VERSION##*forge\-$MINECRAFT_VERSION\-}
	fi
done

# set path
FORGE_PATH="$SERVER_DIR/$FORGE_JAR"

# set java run command
JAVA_RUN="$JAVA_PARAMS -jar $SERVER_DIR/$FORGE_JAR $JAVA_OPTIONAL"


####################################################################################################
# TELEGRAM VARIABLES

# GROUP CHAT ID
TELEGRAM_CHATID="$( cat $INTERNAL_DIR/TelegramBot/group_id )"

# API Token
TELEGRAM_API_TOKEN="$( cat $INTERNAL_DIR/TelegramBot/token )"

# MAX REQUEST TIME
TELEGRAM_MAX_REQ_TIME=10

TELEGRAM_API_URL=https://api.telegram.org/bot$TELEGRAM_API_TOKEN

# API SEND MESSAGE REQUEST
TELEGRAM_API_SEND_URL=$TELEGRAM_API_URL/sendMessage

# API DELETE MESSAGE REQUEST
TELEGRAM_API_DELETE_URL=$TELEGRAM_API_URL/deleteMessage

# API PIN MESSAGE REQUEST
TELEGRAM_API_PIN_URL=$TELEGRAM_API_URL/pinChatMessage

# API UNPIN MESSAGE REQUEST
TELEGRAM_API_UNPIN_URL=$TELEGRAM_API_URL/unpinChatMessage

# LAST SENT MESSAGE
#TELEGRAM_LAST_MSG_ID_FILE=$SERVER_DIR/telegram_last_msg_id.txt
TELEGRAM_LAST_MSG_ID="undefined" #; echo "$TELEGRAM_LAST_MSG_ID" > $TELEGRAM_LAST_MSG_ID_FILE ; chmod +x $TELEGRAM_LAST_MSG_ID_FILE

# STATUS MESSAGES
# %0A = new line
TELEGRAM_MSG_ONLINE="Server online: %0A\`$IP_EXTERNAL_FULL\` %0A[Modpack downloaden](http://$IP_EXTERNAL:2015/$SERVER_MODS)%0A%0ASchreibe /status um aktuelle Server-Informationen abzufragen."
TELEGRAM_MSG_OFFLINE="Server offline."
