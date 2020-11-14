#
# Common variables & functions
#

# Release to install
VERSION=0.117.6

# Package dependencies
PKG_DEPENDENCIES="python3 python3-dev python3-venv python3-pip libffi-dev libssl-dev libjpeg-dev zlib1g-dev autoconf build-essential libopenjp2-7 libtiff5"

# Requirements (Major.Minor.Patch)
# PY_VERSION=$(curl -s "https://www.python.org/ftp/python/" | grep ">3.8" | tail -n1 | cut -d '/' -f 2 | cut -d '>' -f 2)
PY_VERSION=3.8.6

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
myynh_install_dependencies () {
	# Install main dependencies from apt
	ynh_script_progression --message="Installing dependencies..."
	ynh_install_app_dependencies "${PKG_DEPENDENCIES}"
	
	# Check python version from APT
	local PY_APT_VERSION=$(python3 --version | cut -d ' ' -f 2)
	
	# Check existing built version of python in /usr/local/bin
	if [ -e "/usr/local/bin/python${PY_VERSION:0:3}" ]; then
		local PY_BUILT_VERSION=$(/usr/local/bin/python${PY_VERSION:0:3} --version \
			| cut -d ' ' -f 2)
	else
		local PY_BUILT_VERSION=0
	fi
	
	# Compare version
	if [ $(myynh_version_compare $PY_APT_VERSION $PY_VERSION) -le 1 ]; then
		# APT >= Required
		ynh_script_progression --message="Using provided python3..."
		MY_PYTHON="python3"
	else
		# Either python already built or to build 
		ynh_script_progression --message="Installing additional dependencies..."
		PKG_DEPENDENCIES="${PKG_DEPENDENCIES} tk-dev libncurses5-dev libncursesw5-dev libreadline6-dev libdb5.3-dev libgdbm-dev libsqlite3-dev libbz2-dev libexpat1-dev liblzma-dev wget tar"
		ynh_install_app_dependencies "${PKG_DEPENDENCIES}"      
		if [ $(myynh_version_compare $PY_BUILT_VERSION $PY_VERSION) -le 1 ]; then
			# Built >= Required
			ynh_script_progression --message="Using already used python3 built version..."
			MY_PYTHON="/usr/local/bin/python${PY_BUILT_VERSION:0:3}"
		else
            # APT < Minimal & Actual < Minimal => Build & install Python into /usr/local/bin
            ynh_script_progression --message="Building python (may take a while)..."
            # Download
            wget -O "/tmp/Python-$PY_VERSION.tar.xz" "https://www.python.org/ftp/python/$PY_VERSION/Python-$PY_VERSION.tar.xz"
            # Extract
            cd /tmp
            tar xf "Python-$PY_VERSION.tar.xz"
            # Install
            cd "Python-$PY_VERSION"
            ./configure --enable-optimizations
            make -j4
            make altinstall
            # Clean
            cd ..
            ynh_secure_remove "Python-$PY_VERSION"
            ynh_secure_remove "Python-$PY_VERSION.tar.xz"
            # Set version
            MY_PYTHON="/usr/local/bin/python${PY_VERSION:0:3}"
		fi
	fi
}

# Install/Upgrade Homeassistant in virtual environement
myynh_install_homeassistant () {
    exec_as $app -H -s /bin/bash -c " \
        echo 'create the virtual environment' \
            && $MY_PYTHON -m venv "$final_path" \
        && echo 'activate the virtual environment' \
            && source "$final_path/bin/activate" \
        && echo 'install last version of pip' \
            && pip install --upgrade pip \
        && echo 'install last version of wheel' \
            && pip install --upgrade wheel \
        && echo 'install Home Assistant' \
            && pip install --upgrade $app==$VERSION \
        "
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
