#!/bin/bash
#
# upgrade_homeassistant.sh - Simple shell script to upgrade homeassistant installed in a python environnement
#

# Uncomment to enable debugging to stderr (prints full client output and more)
#DEBUG=1

# define usefull variables
app="homeassistant"
final_path="/var/www/$app"
data_path="/home/yunohost.app/$app"

########## END OF CONFIGURATION ##########


########## SCRIPT CODE FOLLOWS, DON'T TOUCH!  ##########

# Log messages to log file.
log() {
        echo "$(date)    $1" >> $LOG_FILE
}

# Reset log file.
if [ ! -z "$DEBUG" ]; then
        LOG_FILE=$(cd -P -- "$(dirname -- "$0")" && pwd -P)"/upgrade_homeassistant.log"
        [ -f "$LOG_FILE" ] && :> "$LOG_FILE"
fi

# upgrade the virtual environment
MY_PYTHON=$(readlink -e "$final_path/bin/python")
[ ! -z "$DEBUG" ] && log "Using pyhton '$MY_PYTHON'."
$MY_PYTHON -m venv --upgrade "$final_path"

# Run source in a 'sub shell'
(
    # activate the virtual environment
    set +o nounset
    [ ! -z "$DEBUG" ] && log "Activate the virtual environment"
    source "$final_path/bin/activate"
    set -o nounset

    # add pip
    [ ! -z "$DEBUG" ] && log "Upgrade pip"
    "$final_path/bin/python3" -m ensurepip --upgrade

    local VERBOSE
    [ ! -z "$DEBUG" ] && VERBOSE="--log $LOG_FILE"

    # install last version of wheel
    [ ! -z "$DEBUG" ] && log "Install latest pip version of wheel"
    "$final_path/bin/pip3" --cache-dir "$data_path/.cache" install --upgrade wheel $VERBOSE

    # install last version of mysqlclient
    [ ! -z "$DEBUG" ] && log "Install latest pip version of mysqlclient"
    "$final_path/bin/pip3" --cache-dir "$data_path/.cache" install --upgrade mysqlclient $VERBOSE

    # upgrade homeassistant python package
    [ ! -z "$DEBUG" ] && log "Install latest pip version of $app"
    "$final_path/bin/pip3" --cache-dir "$data_path/.cache" install --upgrade $app $VERBOSE
)

# restart homeassistant systemd service
[ ! -z "$DEBUG" ] && log "Restart $app systemd service"
sudo systemctl restart $app.service

exit 0
