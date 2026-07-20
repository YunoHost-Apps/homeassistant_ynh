#!/bin/bash
#
# ldap-auth.sh - Simple shell script to authenticate users against LDAP
#

#=================================================
# DEBUGGING
#=================================================
#DEBUG=1 # Uncomment to enable debugging
LOG_FILE=$(cd -P -- "$(dirname -- "$0")" && pwd -P)"/ldap-auth.log"

#=================================================
# CONFIGURATION
#=================================================
LDAPSEARCH_OPTS="-o nettimeout=3 -H ldap://127.0.0.1:389 -x -LLL"
ORG="dc=yunohost,dc=org"
USERDN="uid=$username,ou=users,$ORG"
GROUPDN="ou=groups,$ORG"
BASEDN="$USERDN"
SCOPE="base"
FILTER_AUTH="(&(uid=$username)(objectClass=userPermissionYnh))"
FILTER_PERM="${FILTER_AUTH::-1}(permission=cn=homeassistant.main,ou=permission,$ORG))"
FILTER_ADMIN="${FILTER_AUTH::-1}(memberOf=cn=admins,ou=groups,$ORG))"
ATTRS="cn"

#=================================================
# FUNCTIONS
#=================================================
# Log messages to log file.
log() {
	echo -e "$(date)\t$1" >> "$LOG_FILE"
}

# Full ldap debug
ldap_debug() {
	output=$(ldapsearch $LDAPSEARCH_OPTS -v \
		-D "$USERDN" -w "$password" \
		-s "$SCOPE" -b "$BASEDN" "$FILTER_AUTH" cn permission memberOf)
	result=$?
	log "ldap debug result: $result"
	log "ldap debug output:"
	echo -e "$output" >> "$LOG_FILE"
}

# Check credentials of this ynh user with ldap.
check_credentials() {
	ldapsearch $LDAPSEARCH_OPTS \
		-D "$USERDN" -w "$password" \
		-s "$SCOPE" -b "$BASEDN" "$FILTER_AUTH" $ATTRS
	if [ $? -ne 0 ]; then
		[ ! -z "$DEBUG" ] && log "Wrong credentials, user '$username' failed to authenticate."
		return 1
	else
		[ ! -z "$DEBUG" ] && log "User '$username' authenticated successfully."
		return 0
	fi
}

# Check if this ynh user has the permission to access Home-Assistant.
check_app_permission() {
	output=$(ldapsearch $LDAPSEARCH_OPTS \
		-D "$USERDN" -w "$password" \
		-s "$SCOPE" -b "$BASEDN" "$FILTER_PERM" $ATTRS)
	if [ $? -ne 0 ] || [ -z "$output" ]; then
		[ ! -z "$DEBUG" ] && log "User '$username' does NOT have the permission to access HA."
		return 1
	else
		name=$(echo "$output" | sed -nr "s/^\s*cn:\s*(.+)\s*\$/\1/Ip")
		[ ! -z "$DEBUG" ] && log "User '$username' has '$name' as fullname and have the permission to access HA."
		echo "name=$name"
		return 0
	fi
}

# Check if this ynh user is member of the ynh admins group.
check_admin_group() {
	output=$(ldapsearch $LDAPSEARCH_OPTS \
		-D "$USERDN" -w "$password" \
		-s "$SCOPE" -b "$BASEDN" "$FILTER_ADMIN" $ATTRS)
	if [ $? -ne 0 ] || [ -z "$output" ]; then
		[ ! -z "$DEBUG" ] && log "User '$username' is NOT in the ynh admin group and so, if not already existing as HA user, created as HA simple user."
		echo "group=system-users"
	else
		[ ! -z "$DEBUG" ] && log "User '$username' is in the ynh admins group and so, if not already existing as HA user, created as HA admin."
		echo "group=system-admin"
	fi
}

#=================================================
# MAIN SCRIPT
#=================================================
# Prepare log file and pint ldap full output
if [ ! -z "$DEBUG" ]; then
	[ -f "$LOG_FILE" ] && :> "$LOG_FILE"
	ldap_debug
fi

# Execute checks
check_credentials || exit 1
check_app_permission || exit 1
check_admin_group

# Exit successfully
exit 0
