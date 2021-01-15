#!/bin/sh
#
# ldap-auth.sh - Simple shell script to authenticate users against LDAP
#

# Uncomment to enable debugging to stderr (prints full client output
# and more).
#DEBUG=1

# Must be one of "curl" and "ldapsearch".
# NOTE:
# - When choosing "curl", make sure "curl --version | grep ldap" outputs
#   something. Otherwise, curl was compiled without LDAP support.
# - When choosing "ldapsearch", make sure the ldapwhoami command is
#   available as well, as that might be needed in some cases.
CLIENT="ldapsearch"

# Usernames should be validated using a regular expression to be of
# a known format. Special characters will be escaped anyway, but it is
# generally not recommended to allow more than necessary.
# This pattern is set by default. In your config file, you can either
# overwrite it with a different one or use "unset USERNAME_PATTERN" to
# disable validation completely.
USERNAME_PATTERN='^[a-z|A-Z|0-9|_|-|.]+$'

# Adapt to your needs.
SERVER="ldap://127.0.0.1:389"
USERDN="uid=$username,ou=users,dc=yunohost,dc=org"
BASEDN="$USERDN"
SCOPE="base"
FILTER="(&(uid=$username)(objectClass=posixAccount))"
NAME_ATTR="cn"
ATTRS="$ATTRS $NAME_ATTR"

# When the timeout (in seconds) is exceeded (e.g. due to slow networking),
# authentication fails.
TIMEOUT=3

########## END OF CONFIGURATION ##########


########## SCRIPT CODE FOLLOWS, DON'T TOUCH!  ##########

# Log messages to log file.
log() {
	echo "$(date)\t$1" >> $LOG_FILE
}

# Check permission of ynh user.
ynh_user_app_permission() {
	access=$(cat "/etc/ssowat/conf.json" | jq 'def IN(s): . as $in | first(if (s == $in) then true else empty end) ; .permissions["homeassistant.main"].users as $f | '\"$username\"' | IN($f[])'
	[ ! -z "$access" ] && return 1
	return 0
}

ldap_auth_ldapsearch() {
	common_opts="-o nettimeout=$TIMEOUT -H $SERVER -x"
	[ ! -z "$DEBUG" ] && common_opts="-v $common_opts"
	output=$(ldapsearch $common_opts -LLL \
		-D "$USERDN" -w "$password" \
		-s "$SCOPE" -b "$BASEDN" "$FILTER" dn $ATTRS)
	[ $? -ne 0 ] && return 1
	return 0
}

on_auth_success() {
	# print the meta entries for use in HA
	if [ ! -z "$NAME_ATTR" ]; then
		name=$(echo "$output" | sed -nr "s/^\s*$NAME_ATTR:\s*(.+)\s*\$/\1/Ip")
		[ -z "$name" ] || echo "name=$name"
	fi
}

# Reset log file.
if [ ! -z "$DEBUG" ]; then
	LOG_FILE=$(cd -P -- "$(dirname -- "$0")" && pwd -P)"/ldap-auth.log"
	[ -f "$LOG_FILE" ] && :> "$LOG_FILE"
fi

# Check app access permisssion for the ynh user.
ynh_user_app_permission
if [ $? -eq 0 ]; then
	[ ! -z "$DEBUG" ] && log "User '$username' does not have the permission to access these app."
	exit 1
else
	[ ! -z "$DEBUG" ] && log "User '$username' have the permission to access these app."
fi

# Validate config.
err=0
if [ -z "$SERVER" ] || [ -z "$USERDN" ]; then
	[ ! -z "$DEBUG" ] && log "SERVER and USERDN need to be configured."
	err=1
fi
if [ -z "$TIMEOUT" ]; then
	[ ! -z "$DEBUG" ] && log "TIMEOUT needs to be configured."
	err=1
fi
if [ ! -z "$BASEDN" ]; then
	if [ -z "$SCOPE" ] || [ -z "$FILTER" ]; then
		[ ! -z "$DEBUG" ] && log "BASEDN, SCOPE and FILTER may only be configured together."
		err=1
	fi
elif [ ! -z "$ATTRS" ]; then
	[ ! -z "$DEBUG" ] && log "Configuring ATTRS only makes sense when enabling searching."
	err=1
fi

# Check username and password are present and not malformed.
if [ -z "$username" ] || [ -z "$password" ]; then
	[ ! -z "$DEBUG" ] && log "Need username and password environment variables."
	err=1
elif [ ! -z "$USERNAME_PATTERN" ]; then
	username_match=$(echo "$username" | sed -r "s/$USERNAME_PATTERN/x/")
	if [ "$username_match" != "x" ]; then
		[ ! -z "$DEBUG" ] && log "Username '$username' has an invalid format."
		err=1
	fi
fi

[ $err -ne 0 ] && exit 2

# Do the authentication.
ldap_auth_ldapsearch
result=$?

entries=0
if [ $result -eq 0 ]; then
	entries=$(echo "$output" | grep -cie '^dn\s*:')
	[ "$entries" != "1" ] && result=1
fi

if [ ! -z "$DEBUG" ]; then
	log "Result: $result"
	log "Number of entries: $entries"
	log "Client output:"
	log "$output"
fi

if [ $result -ne 0 ]; then
	[ ! -z "$DEBUG" ] && log "User '$username' failed to authenticate."
	type on_auth_failure > /dev/null && on_auth_failure
	exit 1
fi

[ ! -z "$DEBUG" ] && log "User '$username' authenticated successfully."
type on_auth_success > /dev/null && on_auth_success
exit 0
