#!/bin/bash

#=================================================
# PACKAGE UPDATING HELPER
#=================================================

# This script is meant to be run by GitHub Actions
# The YunoHost-Apps organisation offers a template Action to run this script periodically
# Since each app is different, maintainers can adapt its contents so as to perform
# automatic actions when a new upstream release is detected.

# Remove this exit command when you are ready to run this Action
#exit 1

#=================================================
# FETCHING LATEST RELEASE AND ITS ASSETS
#=================================================

# Fetching information
app=$(cat manifest.toml | tomlq -j '.id')
current_version=$(cat manifest.toml | tomlq -j '.version|split("~")[0]')
upstream_version=$(curl -Ls https://pypi.org/pypi/$app/json | jq -r .info.version)

# Setting up the environment variables
echo "Current version: $current_version"
echo "Latest release from upstream: $upstream_version"
echo "VERSION=$upstream_version" >> $GITHUB_ENV
# For the time being, let's assume the script will fail
echo "PROCEED=false" >> $GITHUB_ENV

# Proceed only if the retrieved version is greater than the current one
if ! dpkg --compare-versions "$current_version" "lt" "$upstream_version"
then
	echo "::warning :: No new version available"
	exit 0
# Proceed only if a PR for this new version does not already exist
elif git ls-remote -q --exit-code --heads https://github.com/$GITHUB_REPOSITORY.git ci-auto-update-v$upstream_version
then
	echo "::warning ::A branch already exists for this update"
	exit 0
fi

#=================================================
# GENERIC FINALIZATION
#=================================================

# Replace new version in manifest
sed -i "s/^version = .*/version = \"$upstream_version~ynh1\"/" manifest.toml
#DOES NOT WORK BECAUSE IT REORDER ALL THE MANIFEST IN A STRANGE WAY
#echo "$(tomlq --toml-output --slurp --indent 4 ".[] | .version = \"$version~ynh1\"" manifest.toml)" > manifest.toml 

# No need to update the README, yunohost-bot takes care of it

# The Action will proceed only if the PROCEED environment variable is set to true
echo "PROCEED=true" >> $GITHUB_ENV
exit 0
