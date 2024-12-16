#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

# App version
## yq is not a dependencie of yunohost package so tomlq command is not available
## (see https://github.com/YunoHost/yunohost/blob/dev/debian/control)
app_version=$(cat ../manifest.toml 2>/dev/null \
				| grep '^version = ' | cut -d '=' -f 2 \
				| cut -d '~' -f 1 | tr -d ' "') #2024.2.5

# Python required version
## jq is a dependencie of yunohost package
## (see https://github.com/YunoHost/yunohost/blob/dev/debian/control)
py_required_major=$(curl -Ls https://pypi.org/pypi/$app/$app_version/json \
						| jq -r '.info.requires_python' | cut -d '=' -f 2 \
						| rev | cut -d '.' -f2-  | rev) #3.11

# Fail2ban
failregex="^%(__prefix_line)s.*\[homeassistant.components.http.ban\] Login attempt or request with invalid authentication from.* \(<HOST>\).* Requested URL: ./auth/.*"

# Path
path_with_homeassistant="$install_dir/bin:$data_dir/bin:$PATH"

# Install/Upgrade Homeassistant in virtual environement
myynh_install_homeassistant () {
	# Requirements
	pip_required=$(curl -Ls https://pypi.org/pypi/$app/$app_version/json \
		| jq -r '.info.requires_dist[]' \
		| grep 'pip' \
		|| echo "pip" ) #pip (<23.1,>=21.0) if exist otherwise pip

	# Install uv
	PIPX_HOME="/opt/pipx" PIPX_BIN_DIR="/usr/local/bin" pipx install uv --force 2>&1
	uv="/usr/local/bin/uv"

	# Create the virtual environment
	(
		cd "$install_dir"
		chown -R "$app:" "$install_dir"
		ynh_hide_warnings ynh_exec_as_app "$uv" venv "$install_dir/venv" --python "$py_required_major"

		# activate the virtual environment
		set +o nounset
		source "$install_dir/venv/bin/activate"
		set -o nounset

		# install required version of pip
		ynh_hide_warnings ynh_exec_as_app "$uv" pip --no-cache-dir install --upgrade "$pip_required"

		# install dependencies
		ynh_hide_warnings ynh_exec_as_app "$uv" pip --no-cache-dir install --upgrade webrtcvad wheel mysqlclient psycopg2-binary isal

		# install Home Assistant
		ynh_hide_warnings ynh_exec_as_app "$uv" pip --no-cache-dir install --upgrade "$app==$app_version"
	)
}

# Set permissions
myynh_set_permissions () {
	chown -R $app: "$install_dir"
	chmod u=rwX,g=rX,o= "$install_dir"
	chmod -R o-rwx "$install_dir"

	chown -R $app: "$data_dir"
	chmod u=rwX,g=rX,o= "$data_dir"
	chmod -R o-rwx "$data_dir"
	[ -e "$data_dir/bin/" ] && chmod -R +x "$data_dir/bin/"

	[ -e "$(dirname "$log_file")" ] && chown -R $app: "$(dirname "$log_file")"

	[ -e "/etc/sudoers.d/$app" ] && chown -R root: "/etc/sudoers.d/$app"

	# Upgade user groups
	user_groups=""
	[ $(getent group dialout) ] && user_groups="${user_groups} dialout"
	[ $(getent group gpio) ] && user_groups="${user_groups} gpio"
	[ $(getent group i2c) ] && user_groups="${user_groups} i2c"
	ynh_system_user_create --username="$app" --groups="$user_groups"
}
