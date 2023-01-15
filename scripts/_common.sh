#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

# Release to install
app_version=2023.1.4

# Package dependencies
pkg_dependencies="python3 python3-dev python3-venv python3-pip libffi-dev libssl-dev libjpeg-dev zlib1g-dev autoconf build-essential libopenjp2-7 libtiff5 libturbojpeg0 libmariadb-dev libmariadb-dev-compat rustc"

# Requirements (Major.Minor.Patch)
# PY_VERSION=$(curl -s "https://www.python.org/ftp/python/" | grep ">3.9" | tail -n1 | cut -d '/' -f 2 | cut -d '>' -f 2)
# Pyhton 3.9.2 will be shiped with bullseye
py_required_version=3.10.9

#=================================================
# PERSONAL HELPERS
#=================================================

# Create homeassistant user
mynh_system_user_create () {
    user_groups=""
    [ $(getent group dialout) ] && user_groups="${user_groups} dialout"
    [ $(getent group gpio) ] && user_groups="${user_groups} gpio"
    [ $(getent group i2c) ] && user_groups="${user_groups} i2c"
    ynh_system_user_create --username=$app --groups="$user_groups" --home_dir="$data_path"
}


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

myynh_compile_libffi () {
	ynh_print_info --message="Building libffi..."
	
	# Download
	wget "https://github.com/libffi/libffi/releases/download/v3.3/libffi-3.3.tar.gz" 2>&1
	
	# Extract
	tar zxf libffi-3.3.tar.gz
	
	# Install
	cd libffi-3.3
	ynh_exec_warn_less ./configure
	ynh_exec_warn_less make install
	ldconfig
	
	#Exit
	cd ..
}

# Install specific python version
# usage: myynh_install_python --python="3.8.6"
# | arg: -p, --python=    - the python version to install
myynh_install_python () {
	# Declare an array to define the options of this helper.
	local legacy_args=u
	local -A args_array=( [p]=python= )
	local python
	# Manage arguments with getopts
	ynh_handle_getopts_args "$@"
	
	# Check python version from APT
	local py_apt_version=$(python3 --version | cut -d ' ' -f 2)
	
	# Usefull variables
	local python_major=${python%.*}
	
	# Check existing built version of python in /usr/local/bin
	if [ -e "/usr/local/bin/python$python_major" ]
	then
		local py_built_version=$(/usr/local/bin/python$python_major --version \
			| cut -d ' ' -f 2)
	else
		local py_built_version=0
	fi
	
	# Compare version
	if $(dpkg --compare-versions $py_apt_version ge $python)
	then
		# APT >= Required
		ynh_print_info --message="Using provided python3..."
		
		py_app_version="python3"
		
	else
		# Either python already built or to build 
		if $(dpkg --compare-versions $py_built_version ge $python)
		then
			# Built >= Required
			ynh_print_info --message="Using already used python3 built version..."
			
			py_app_version="/usr/local/bin/python${py_built_version%.*}"
			
		else
			ynh_print_info --message="Installing additional dependencies to build python..."
			
			pkg_dependencies="${pkg_dependencies} tk-dev libncurses5-dev libncursesw5-dev libreadline6-dev libdb5.3-dev libgdbm-dev libsqlite3-dev libbz2-dev libexpat1-dev liblzma-dev wget tar  libnss3-dev libreadline-dev"
			ynh_install_app_dependencies "${pkg_dependencies}"
			
			# APT < Minimal & Actual < Minimal => Build & install Python into /usr/local/bin
			ynh_print_info --message="Building python (may take a while)..."
			
			# Store current direcotry 
			local MY_DIR=$(pwd)
			
			# Create a temp direcotry
			tmpdir="$(mktemp --directory)"
			cd "$tmpdir"
			
			# Download
			wget --output-document="Python-$python.tar.xz" \
				"https://www.python.org/ftp/python/$python/Python-$python.tar.xz" 2>&1
			
			# Extract
			tar xf "Python-$python.tar.xz"
			
			# Install
			cd "Python-$python"
			./configure --enable-optimizations
			ynh_exec_warn_less make -j4
			ynh_exec_warn_less make altinstall
			
			# Go back to working directory
			cd "$MY_DIR"
			
			# Clean
			ynh_secure_remove "$tmpdir"
			
			# Set version
			py_app_version="/usr/local/bin/python$python_major"
		fi
	fi
	# Save python version in settings 
	ynh_app_setting_set --app=$app --key=python --value="$python"
}
	
# Install/Upgrade Homeassistant in virtual environement
myynh_install_homeassistant () {
	# Create the virtual environment
	ynh_exec_as $app $py_app_version -m venv --without-pip "$final_path"
	
	# Run source in a 'sub shell'
	(
		# activate the virtual environment
		set +o nounset
		source "$final_path/bin/activate"
		set -o nounset
		
		# add pip
		ynh_exec_as $app "$final_path/bin/python3" -m ensurepip
		
		# install last version of wheel
		ynh_exec_as $app "$final_path/bin/pip3" --cache-dir "$data_path/.cache" install --upgrade wheel
		
		# install last version of mysqlclient
		ynh_exec_as $app "$final_path/bin/pip3" --cache-dir "$data_path/.cache" install --upgrade mysqlclient
		
		# install Home Assistant
		ynh_exec_as $app "$final_path/bin/pip3" --cache-dir "$data_path/.cache" install --upgrade $app==$app_version
	)
}

# Upgrade the virtual environment directory
myynh_upgrade_venv_directory () {
	ynh_exec_as $app $py_app_version -m venv --upgrade "$final_path"
}

# Set permissions
myynh_set_permissions () {
	chown -R $app: "$final_path"
	chmod 750 "$final_path"
	chmod -R o-rwx "$final_path"

	chown -R $app: "$data_path"
	chmod 750 "$data_path"
	chmod -R o-rwx "$data_path"
	chmod -R +x "$data_path/bin/"

	chown -R $app: "$(dirname "$log_file")"

	chown -R root: "/etc/sudoers.d/$app"
}
