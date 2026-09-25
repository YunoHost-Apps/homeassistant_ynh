#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

# App version
## yq is not a dependencie of yunohost package so tomlq command is not available
## (see https://github.com/YunoHost/yunohost/blob/dev/debian/control)
app_version=$(cat ../manifest.toml 2>/dev/null \
				| /usr/bin/grep '^version = ' | cut -d '=' -f 2 \
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
			| /usr/bin/grep 'pip' \
			|| echo "pip" ) #pip (<23.1,>=21.0) if exist otherwise pip
	# Install uv
		PIPX_HOME="/opt/pipx" PIPX_BIN_DIR="/usr/local/bin" pipx install uv --force 2>&1
		PIPX_HOME="/opt/pipx" PIPX_BIN_DIR="/usr/local/bin" pipx upgrade uv --force 2>&1
		local uv="/usr/local/bin/uv"
	# Create the virtual environment
	(
		cd "$install_dir"
		chown -R "$app:" "$install_dir"
		# Define some options for uv
			export UV_PYTHON_INSTALL_DIR="$install_dir"
			export UV_NO_CACHE=true
			export UV_NO_MODIFY_PATH=true
		# Create the virtual environment
			ynh_exec_as_app "$uv" --quiet venv "$install_dir/venv" --python "$py_required_major"
		# Activate the virtual environment
			set +o nounset
			source "$install_dir/venv/bin/activate"
			set -o nounset
		# Install required version of pip
			ynh_exec_as_app "$uv" --quiet pip --no-cache-dir install --upgrade "$pip_required"
		# Install Home Assistant with uv
			ynh_exec_as_app "$uv" --quiet pip --no-cache-dir install "$app==$app_version" wheel mysqlclient zlib_ng isal
		# Fix missing python modules
			ynh_exec_as_app "$uv" --quiet pip --no-cache-dir install aioesphomeapi # Fix #591
		# Clear uv options
			unset UV_PYTHON_INSTALL_DIR
			unset UV_NO_CACHE
			unset UV_NO_MODIFY_PATH
	)
}

# Set permissions
myynh_set_permissions () {
	chown -R $app: "$install_dir"
	chmod u=rwx,g=rx,o= "$install_dir"
	chmod -R o-rwx "$install_dir"

	chown -R $app: "$data_dir"
	chmod u=rwx,g=rx,o= "$data_dir"
	chmod -R o-rwx "$data_dir"
	[ -e "$data_dir/bin/" ] && chmod -R +x "$data_dir/bin/"

	if [ -e "$(dirname "$log_file")" ]
	then
		chown -R $app: "$(dirname "$log_file")"
		chmod u=rwx,g=rx,o= "$(dirname "$log_file")"
	fi

	[ -e "/etc/sudoers.d/$app" ] && chown -R root: "/etc/sudoers.d/$app"

	# Upgade user groups
	local user_groups=""
	[[ -n $(getent group dialout) ]] && user_groups="${user_groups} dialout"
	[[ -n $(getent group gpio) ]] && user_groups="${user_groups} gpio"
	[[ -n $(getent group i2c) ]] && user_groups="${user_groups} i2c"
	ynh_system_user_create --username="$app" --groups="$user_groups"
}

# Workaround used to fix https://github.com/home-assistant/core/issues/181437
fix_cmd_missing_arg() {
    FILE="/home/yunohost.app/$app/configuration.yaml"

    # Retrive line number of all line matching "- type: command_line"
    line_start_with_type_cmd=$(/usr/bin/grep -n '\- type: command_line' "$FILE" | cut -d: -f1)
        # Exit if not finding
        if [[ -z "$line_start_with_type_cmd" ]]; then
            return
        fi

    # Extract the block of 4 lines
    extract=$(/usr/bin/grep -ws '\- type: command_line' $FILE -A 3)

    # exit if is args: is existing between line_start_with_type_cmd and line_end
    if echo "$extract" | /usr/bin/grep -q 'args:'
    then
        return
    fi

    # Definie the arg line to insert with right padding
    padding=$(/usr/bin/grep -bo "type: command_line" "$FILE" | cut -d: -f1)
    new_line="args: []"
    new_line=$(printf "%*s%s" $padding '' "$new_line")

    # Backup the file
    /bin/cp -f "$FILE" "$FILE.bak"

    # Add arg line
    sed -i "$((line_start_with_type_cmd+1))i\\$new_line" "$FILE"
}
