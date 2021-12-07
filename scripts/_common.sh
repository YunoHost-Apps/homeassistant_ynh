#
# Common variables & functions
#

# Release to install
VERSION=2021.11.5

# Package dependencies
PKG_DEPENDENCIES="python3 python3-dev python3-venv python3-pip libffi-dev libssl-dev libjpeg-dev zlib1g-dev autoconf build-essential libopenjp2-7 libtiff5"

# Requirements (Major.Minor.Patch)
# PY_VERSION=$(curl -s "https://www.python.org/ftp/python/" | grep ">3.9" | tail -n1 | cut -d '/' -f 2 | cut -d '>' -f 2)
# Pyhton 3.9.2 will be shiped with bullseye
PY_REQUIRED_VERSION=3.9.2

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

# Compare version in arguments
myynh_version_compare () {
	# myynh_version_compare A B
	# 0 -> A = B
	# 1 -> A > B
	# 2 -> A < B
	if [[ $1 == $2 ]] ; then
		echo 0; return
	fi
	local IFS=.
	local i ver1=($1) ver2=($2)
	# fill empty fields in ver1 with zeros
	for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)) ; do
		ver1[i]=0
	done
	for ((i=0; i<${#ver1[@]}; i++)) ; do
		if [[ -z ${ver2[i]} ]] ; then
			# fill empty fields in ver2 with zeros
			ver2[i]=0
		fi
		if ((10#${ver1[i]} > 10#${ver2[i]})) ; then
			echo 1; return
		fi
		if ((10#${ver1[i]} < 10#${ver2[i]})) ; then
			echo 2; return
		fi
	done
	echo 1; return
}

# Package dependencies
# usage: myynh_install_dependencies --python="3.8.6"
# | arg: -p, --python=    - the python version to install
myynh_install_dependencies () {
	# Declare an array to define the options of this helper.
	local legacy_args=u
	local -A args_array=( [p]=python= )
	local python
	# Manage arguments with getopts
	ynh_handle_getopts_args "$@"
	
	# Install main dependencies from apt
	ynh_install_app_dependencies "${PKG_DEPENDENCIES}"
	
	# Check python version from APT
	local PY_APT_VERSION=$(python3 --version | cut -d ' ' -f 2)
	
	# Check existing built version of python in /usr/local/bin
	if [ -e "/usr/local/bin/python${python:0:3}" ]; then
		local PY_BUILT_VERSION=$(/usr/local/bin/python${python:0:3} --version \
			| cut -d ' ' -f 2)
	else
		local PY_BUILT_VERSION=0
	fi
	
	# Compare version
	if [ $(myynh_version_compare $PY_APT_VERSION $python) -le 1 ]; then
		# APT >= Required
		ynh_print_info --message="Using provided python3..."
		MY_PYTHON="python3"
	else
		# Either python already built or to build 
		if [ $(myynh_version_compare $PY_BUILT_VERSION $python) -le 1 ]; then
			# Built >= Required
			ynh_print_info --message="Using already used python3 built version..."
			MY_PYTHON="/usr/local/bin/python${PY_BUILT_VERSION:0:3}"
		else
			ynh_print_info --message="Installing additional dependencies to build python..."
			PKG_DEPENDENCIES="${PKG_DEPENDENCIES} tk-dev libncurses5-dev libncursesw5-dev libreadline6-dev libdb5.3-dev libgdbm-dev libsqlite3-dev libbz2-dev libexpat1-dev liblzma-dev wget tar"
			ynh_install_app_dependencies "${PKG_DEPENDENCIES}"
			# APT < Minimal & Actual < Minimal => Build & install Python into /usr/local/bin
			ynh_print_info --message="Building python (may take a while)..."
			# Store current direcotry 
			local MY_DIR=$(pwd)
			# Download
			wget -O "/tmp/Python-$python.tar.xz" "https://www.python.org/ftp/python/$python/Python-$python.tar.xz" 2>&1
			# Extract
			cd /tmp
			tar xf "Python-$python.tar.xz"
			# Install
			cd "Python-$python"
			./configure --enable-optimizations
			ynh_exec_warn_less make -j4
			ynh_exec_warn_less make altinstall
			# Clean
			cd ..
			ynh_secure_remove "Python-$python"
			ynh_secure_remove "Python-$python.tar.xz"
			# Set version
			MY_PYTHON="/usr/local/bin/python${python:0:3}"
			# Go back to working directory
			cd $MY_DIR
		fi
	fi
	# Save python version in settings 
	ynh_app_setting_set --app="$app" --key=python --value="$python"
}

# Install/Upgrade Homeassistant in virtual environement
myynh_install_homeassistant () {
	ynh_exec_as $app -H -s /bin/bash -c " \
		echo 'create the virtual environment' \
			&& $MY_PYTHON -m venv "$final_path" \
		&& echo 'activate the virtual environment' \
			&& source "$final_path/bin/activate" \
		&& echo 'install last version of wheel' \
			&& pip --no-cache-dir install --upgrade wheel \
		&& echo 'install Home Assistant' \
			&& pip --no-cache-dir install --upgrade $app==$VERSION \
		"
}
