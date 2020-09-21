#!/bin/bash
#
# Copyright (C) 2020 by DarkWebAze@Github, < https://github.com/DarkWebAze >.
#
# This file is part of < https://github.com/DarkWebAze/DarkUserBot > project,
# and is released under the "GNU v3.0 License Agreement".
# Please see < https://github.com/DarkWebAze/DarkUserBot/blob/master/LICENSE >
#
# All rights reserved.

_checkBashReq() {
    log "Komandalara Yoxlanılır ..."
    command -v jq &> /dev/null || quit "Lazımlı Komanda: jq : tapılmadı!"
}

_checkPythonVersion() {
    log "Python Versiya Yoxlanılır ..."
    ( test -z $pVer || test $(sed 's/\.//g' <<< $pVer) -lt 380 ) \
        && quit "You MUST have a python version of at least 3.8.0 !"
    log "\tFound PYTHON - v$pVer ..."
}

_checkConfigFile() {
    log "Yapılandırma Faylı Yoxlanılır ..."
    configPath="config.env"
    if test -f $configPath; then
        log "\tYapılandırma faylı tapıldı : $configPath, Yüklənir ..."
        set -a
        . $configPath
        set +a
        test ${_____REMOVE_____THIS_____LINE_____:-fasle} = true \
            && quit "Please remove the line mentioned in the first hashtag from the config.sh file"
    fi
}

_checkRequiredVars() {
    log "Lazımlı ENV Faylı Yoxlanılır ..."
    for var in API_ID API_HASH LOG_CHANNEL_ID DATABASE_URL; do
        test -z ${!var} && quit "Required $var var !"
    done
    [[ -z $HU_STRING_SESSION && -z $BOT_TOKEN ]] && quit "Required HU_STRING_SESSION or BOT_TOKEN var !"
    [[ -n $BOT_TOKEN && -z $OWNER_ID ]] && quit "Required OWNER_ID var !"
    test -z $BOT_TOKEN && log "\t[HINT] >>> BOT_TOKEN not found ! (Disabling Advanced Loggings)"
}

_checkDefaultVars() {
    replyLastMessage "Var Olan ENV Faylı Yoxlanılır ..."
    declare -rA def_vals=(
        [WORKERS]=0
        [PREFERRED_LANGUAGE]="en"
        [DOWN_PATH]="downloads"
        [UPSTREAM_REMOTE]="upstream"
        [UPSTREAM_REPO]="https://github.com/DarkWebAze/DarkUserBot"
        [LOAD_UNOFFICIAL_PLUGINS]=true
        [G_DRIVE_IS_TD]=true
        [CMD_TRIGGER]="."
        [SUDO_TRIGGER]="!"
        [FINISHED_PROGRESS_STR]="█"
        [UNFINISHED_PROGRESS_STR]="░"
    )
    for key in ${!def_vals[@]}; do
        set -a
        test -z ${!key} && eval $key=${def_vals[$key]}
        set +a
    done
    DOWN_PATH=${DOWN_PATH%/}/
    if [[ -n $HEROKU_API_KEY && -n $HEROKU_APP_NAME ]]; then
        local herokuErr=$(runPythonCode '
import heroku3
try:
    if "'$HEROKU_APP_NAME'" not in heroku3.from_key("'$HEROKU_API_KEY'").apps():
        raise Exception("Invalid HEROKU_APP_NAME \"'$HEROKU_APP_NAME'\"")
except Exception as e:
    print(e)')
        [[ $herokuErr ]] && quit "heroku response > $herokuErr"
        declare -g HEROKU_GIT_URL="https://api:$HEROKU_API_KEY@git.heroku.com/$HEROKU_APP_NAME.git"
    fi
    for var in G_DRIVE_IS_TD LOAD_UNOFFICIAL_PLUGINS; do
        eval $var=$(tr "[:upper:]" "[:lower:]" <<< ${!var})
    done
    local uNameAndPass=$(grep -oP "(?<=\/\/)(.+)(?=\@)" <<< $DATABASE_URL)
    local parsedUNameAndPass=$(runPythonCode '
from urllib.parse import quote_plus
print(quote_plus("'$uNameAndPass'"))')
    DATABASE_URL=$(sed 's/$uNameAndPass/$parsedUNameAndPass/' <<< $DATABASE_URL)
}

_checkDatabase() {
    editLastMessage ""
    editLastMessage "DATABASE_URL yoxlanılır ...."
    editLastMessage "Checking DATABASE_URL ..."
    local mongoErr=$(runPythonCode '
import pymongo
try:
    pymongo.MongoClient("'$DATABASE_URL'").list_database_names()
except Exception as e:
    print(e)')
    [[ $mongoErr ]] && quit "pymongo response > $mongoErr" || log "\tpymongo response > {status : 200}"
}

_checkTriggers() {
    editLastMessage "KOMANDLAR yoxlanılır ..."
    test $CMD_TRIGGER = $SUDO_TRIGGER \
        && quit "Invalid SUDO_TRIGGER!, You can't use $CMD_TRIGGER as SUDO_TRIGGER"
}

_checkPaths() {
    editLastMessage ""Qovluqlar yoxlanılır ...""
    for path in $DOWN_PATH logs bin; do
        test ! -d $path && {
            log "\tCreating Path : ${path%/} ..."
            mkdir -p $path
        }
    done
}

_checkBins() {
    editLastMessage "BINS yoxlanılır ..."
    declare -rA bins=(
        [bin/megadown]="https://raw.githubusercontent.com/yshalsager/megadown/master/megadown"
        [bin/cmrudl]="https://raw.githubusercontent.com/yshalsager/cmrudl.py/master/cmrudl.py"
    )
    for bin in ${!bins[@]}; do
        test ! -f $bin && {
            log "\tYüklenir $bin ..."
            curl -so $bin ${bins[$bin]}
        }
    done
}

_checkGit() {
    editLastMessage "GIT yoxlanılır ..."
    if test ! -d .git; then
        if test ! -z $HEROKU_GIT_URL; then
            replyLastMessage "\tHeroku Git klonlanır "
            gitClone $HEROKU_GIT_URL tmp_git || quit "Invalid HEROKU_API_KEY or HEROKU_APP_NAME var !"
            mv tmp_git/.git .
            rm -rf tmp_git
            editLastMessage "\tChecking Heroku Remote ..."
            remoteIsExist heroku || addHeroku
        else
            replyLastMessage "\tBoş Git Başlatılır  ..."
            gitInit
        fi
        deleteLastMessage
    fi
}

_checkUpstreamRepo() {
    editLastMessage "Checking UPSTREAM_REPO ..."
    remoteIsExist $UPSTREAM_REMOTE || addUpstream
    replyLastMessage "\tFetching Data From UPSTREAM_REPO ..."
    fetchUpstream || updateUpstream && fetchUpstream || quit "Invalid UPSTREAM_REPO var !"
    fetchBranches
    deleteLastMessage
}

_checkUnoffPlugins() {
    editLastMessage "Checking DarkUserBot [Extra] Plugins ..."
    if test $LOAD_UNOFFICIAL_PLUGINS = true; then
        editLastMessage "\tLoading DarkUserBot [Extra] Plugins ..."
        replyLastMessage "\t\tClonning ..."
        gitClone --depth=1 https://github.com/DarkWebAze/DarkUserBot-Plugins.git
        editLastMessage "\t\tPIP versiya yükseltilir..."
        upgradePip
        editLastMessage "\t\tLazımlı bağımlılıqlar yüklenir ..."
        installReq DarkUserBot-Plugins
        editLastMessage "\t\tArda qalanlar temizlenir ..."
        rm -rf darkuserbot/plugins/unofficial/
        mv DarkUserBot-Plugins/plugins/ darkuserbot/plugins/unofficial/
        cp -r DarkUserBot-Plugins/resources/* resources/
        rm -rf DarkUserBot-Plugins/
        deleteLastMessage
        editLastMessage "\tDarkUserBot [Extra] Plugins Loaded Successfully !"
    else
        editLastMessage "\tDarkUserBot [Extra] Plugins Disabled !"
    fi
    deleteLastMessage
}

assertPrerequisites() {
    _checkBashReq
    _checkPythonVersion
    _checkConfigFile
    _checkRequiredVars
}

assertEnvironment() {
    _checkDefaultVars
    _checkDatabase
    _checkTriggers
    _checkPaths
    _checkBins
    _checkGit
    _checkUpstreamRepo
    _checkUnoffPlugins
}
