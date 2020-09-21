#!/bin/bash
#
# Copyright (C) 2020 by DarkWebAze@Github, < https://github.com/DarkWebAze >.
#
# This file is part of < https://github.com/DarkWebAze/DarkUserBot > project,
# and is released under the "GNU v3.0 License Agreement".
# Please see < https://github.com/DarkWebAze/DarkUserBot/blob/master/LICENSE >
#
# All rights reserved.

. init/logbot/logbot.sh
. init/utils.sh
. init/checks.sh

trap handleSigTerm TERM
trap handleSigInt INT

initDark() {
    printLogo
    assertPrerequisites
    sendMessage "DarkUserBot Yüklenir ..."
    assertEnvironment
    editLastMessage "DarkUserBot Başlayır ..."
    printLine
}

startDark() {
    runPythonModule dark "$@"
}

stopDark() {
    sendMessage "DarkUserBotdan Çıxılır ..."
    exit 0
}

handleSigTerm() {
    log "Exiting With SIGTERM (143) ..."
    stopDark
    endLogBotPolling
    exit 143
}

handleSigInt() {
    log "Exiting With SIGINT (130) ..."
    stopDark
    endLogBotPolling
    exit 130
}

runDark() {
    initDark
    startLogBotPolling
    startDark "$@"
    stopDark
}
