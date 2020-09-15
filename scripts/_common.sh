#
# Common variables & functions
#

# Release to install
VERSION=0.114.4

# Package dependencies
PKG_DEPENDENCIES="python3 python3-venv python3-pip build-essential libssl-dev libffi-dev python3-dev"

# Check if directory/file already exists (path in argument)
myynh_check_path () {
	[ -z "$1" ] && ynh_die "No argument supplied"
	[ ! -e "$1" ] || ynh_die "$1 already exists"
}

# Create directory only if not already exists (path in argument)
myynh_create_dir () {
	[ -z "$1" ] && ynh_die "No argument supplied"
	[ -d "$1" ] || mkdir -p "$1"
}

# Execute a command as another user
# usage: exec_as USER COMMAND [ARG ...]
exec_as() {
	local USER=$1
	shift 1
	
	if [[ $USER = $(whoami) ]]; then
		eval "$@"
	else
		sudo -u "$USER" "$@"
	fi
}
