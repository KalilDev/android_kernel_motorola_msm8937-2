#!/bin/bash
message="Eva kernel CI build completed with the latest commit -"

curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="$message $(git log --pretty=format:'%h : %s' -1)" -d chat_id=@evakernel

curl -F chat_id="-1001379000271" -F document=@"$PWD/$ZIP_NAME" https://api.telegram.org/bot$BOT_API_KEY/sendDocument

rm -rf ${PWD}/${ZIP_NAME}
