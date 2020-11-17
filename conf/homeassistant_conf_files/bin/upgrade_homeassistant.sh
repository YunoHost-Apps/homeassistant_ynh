#!/bin/bash

# define usefull variables
app="homeassistant"
final_path="/opt/yunohost/$app"

local MY_PYTHON=$(readlink -e "$final_path/bin/python")

# create the virtual environment
$MY_PYTHON -m venv "$final_path"

# activate the virtual environment
source "$final_path/bin/activate"

# install last version of pip
pip install --upgrade pip

# install last version of wheel
pip install --upgrade wheel

# upgrade homeassistant python package
pip install --upgrade $app

# restart homeassistant systemd service
sudo systemctl restart $app@$app.service
