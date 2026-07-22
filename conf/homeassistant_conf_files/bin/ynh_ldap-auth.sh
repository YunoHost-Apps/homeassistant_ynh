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
BASEDN="$USERDN"
SCOPE="base"
FILTER_AUTH="(&(uid=$username)(objectClass=userPermissionYnh))"
FILTER_PERM="${FILTER_AUTH::-1}(permission=cn=homeassistant.main,ou=permission,$ORG))"
FILTER_ADMIN="${FILTER_AUTH::-1}(permission=cn=homeassistant.admin,ou=permission,$ORG))"
ATTRS="cn"
AUTH_FILE="__DATA_DIR__/.storage/auth"
HA_GROUP_USER="system-users"
HA_GROUP_ADMIN="system-admin"

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
		[ ! -z "$DEBUG" ] && log "User '$username' has '$name' as HA username and have the permission to access HA."
		echo "name=$name"
		return 0
	fi
}

# Check if this ynh user is member of the ynh admins group.
check_admin_group() {
	local ynh_user=""

	# Parse named arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--ynh_user=*)  ynh_user="${1#--ynh_user=}";   shift ;;
		esac
	done
	
	output=$(ldapsearch $LDAPSEARCH_OPTS \
		-D "$USERDN" -w "$password" \
		-s "$SCOPE" -b "$BASEDN" "$FILTER_ADMIN" $ATTRS)
	
	if [ $? -ne 0 ] || [ -z "$output" ]; then
		[ ! -z "$DEBUG" ] && log "User '$username' is NOT in the ynh admin group and so, if not already existing as HA user, created as HA simple user."
		update_group --ha_user_name="$name" --from_ha_group="$HA_GROUP_ADMIN" --to_ha_group="$HA_GROUP_USER"
		echo "group=$HA_GROUP_USER"
	else
		[ ! -z "$DEBUG" ] && log "User '$username' has in the admin perm in ynh and so, if not already existing as HA user, created as HA admin."
		update_group --ha_user_name="$name" --from_ha_group="$HA_GROUP_USER" --to_ha_group="$HA_GROUP_ADMIN"
		echo "group=$HA_GROUP_ADMIN"
	fi
}

# Update if needed the ha group in the auth file
update_group() {
	local ha_user_name=""
	local from_ha_group=""
	local to_ha_group=""

	# Parse named arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--ha_user_name=*)  ha_user_name="${1#--ha_user_name=}";   shift ;;
			--from_ha_group=*) from_ha_group="${1#--from_ha_group=}"; shift ;;
			--to_ha_group=*)   to_ha_group="${1#--to_ha_group=}";     shift ;;
		esac
	done
	
	# Embeded function to check current group in auth file
	check_group() {
		jq \
			--arg ha_user_name "$ha_user_name" \
			--arg to_ha_group "$to_ha_group" \
			'.data.users[] | select(.name == $ha_user_name) | .group_ids | any(. == $to_ha_group)' \
			"$AUTH_FILE"
	}
	
	if [ "$(check_group)" = "false" ]; then
		# Update auth file
		[ ! -z "$DEBUG" ] && log "The HA group of '$username' is going to be updated to '$to_ha_group'."
		tmp=$(mktemp)
		trap 'rm -f "$tmp"' EXIT
		jq \
			--arg ha_user_name "$ha_user_name" \
			--arg from_ha_group "$from_ha_group" \
			--arg to_ha_group "$to_ha_group" \
			'(.data.users[] | select(.name == $ha_user_name) | .group_ids[] | select(. == $from_ha_group)) |= $to_ha_group' \
			"$AUTH_FILE" > "$tmp" && cat "$tmp" > "$AUTH_FILE"

		# Verify the update
		if [ ! -z "$DEBUG" ]; then
			if [ "$(check_group)" != "true" ]; then
				log "ERROR: Failed to update the HA group of '$username' to '$to_ha_group'."
				return 1
			else
				log "The HA group of '$username' was successfully updated to '$to_ha_group'."
				return 0
			fi
		fi
	else
		[ ! -z "$DEBUG" ] && log "The HA group of '$username' is already '$to_ha_group'."
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
check_admin_group --ynh_user="$name"

# Exit successfully
exit 0
