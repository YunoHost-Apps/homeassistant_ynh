#!/bin/bash

# define usefull variables
app="homeassistant"
final_path="/opt/yunohost/$app"

# stop homeassistant systemd service
#sudo systemctl stop $app@$app.service

# create the virtual environment
python3 -m venv "$final_path"

# activate the virtual environment
. "$final_path/bin/activate"

# upgrade required python package
pip install --upgrade wheel

# upgrade homeassistant python package
pip install --upgrade $app

# restart homeassistant systemd service
sudo systemctl restart $app@$app.service
