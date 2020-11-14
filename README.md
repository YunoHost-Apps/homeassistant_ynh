# Home Assistant for YunoHost

[![Integration level](https://dash.yunohost.org/integration/homeassistant.svg)](https://dash.yunohost.org/appci/app/homeassistant) ![](https://ci-apps.yunohost.org/ci/badges/homeassistant.status.svg) ![](https://ci-apps.yunohost.org/ci/badges/homeassistant.maintain.svg)  
[![Install homeassistant with YunoHost](https://install-app.yunohost.org/install-with-yunohost.png)](https://install-app.yunohost.org/?app=homeassistant)

*[Lire ce readme en français.](./README_fr.md)*

> *This package allows you to install homeassistant quickly and simply on a YunoHost server.  
If you don't have YunoHost, please consult [the guide](https://yunohost.org/#/install) to learn how to install it.*

## Overview
Home Assistant is a home automation platform running on Python 3. It is able to track and control all devices at home and offer a platform for automating control.

**Shipped version:** 0.117.6

## Screenshots

![](https://camo.githubusercontent.com/24b8190f22f6e4277778a4f30a61fce1dd5e95169e6ce149408bbc4a0b9eb0dc/68747470733a2f2f7261772e6769746875622e636f6d2f686f6d652d617373697374616e742f686f6d652d617373697374616e742f6d61737465722f646f63732f73637265656e73686f74732e706e67)

## Demo

* [Official demo](https://camo.githubusercontent.com/24b8190f22f6e4277778a4f30a61fce1dd5e95169e6ce149408bbc4a0b9eb0dc/68747470733a2f2f7261772e6769746875622e636f6d2f686f6d652d617373697374616e742f686f6d652d617373697374616e742f6d61737465722f646f63732f73637265656e73686f74732e706e67)

## Configuration

How to configure this app: From an admin panel, a plain file with SSH, or any other way.

## Documentation

 * Official documentation: https://www.home-assistant.io/docs/
 * YunoHost documentation: If specific documentation is needed, feel free to contribute.

## YunoHost specific features

#### Multi-user support

Are LDAP and HTTP auth supported?
Can the app be used by multiple users?

#### Supported architectures

* x86-64 - [![Build Status](https://ci-apps.yunohost.org/ci/logs/homeassistant%20%28Apps%29.svg)](https://ci-apps.yunohost.org/ci/apps/homeassistant/)
* ARMv8-A - [![Build Status](https://ci-apps-arm.yunohost.org/ci/logs/homeassistant%20%28Apps%29.svg)](https://ci-apps-arm.yunohost.org/ci/apps/homeassistant/)

## Limitations

* Any known limitations.

## Additional information

* Other info you would like to add about this app.

**More info on the documentation page:**  
https://yunohost.org/packaging_apps

## Links

 * Report a bug: https://github.com/YunoHost-Apps/homeassistant_ynh/issues
 * App website: https://www.home-assistant.io/
 * Upstream app repository: https://github.com/home-assistant/home-assistant
 * YunoHost website: https://yunohost.org/

---

## Developer info

Please send your pull request to the [testing branch](https://github.com/YunoHost-Apps/homeassistant_ynh/tree/testing).

To try the testing branch, please proceed like that.
```
sudo yunohost app install https://github.com/YunoHost-Apps/REPLACEBYYOURAPP_ynh/tree/testing --debug
or
sudo yunohost app upgrade homeassistant -u https://github.com/YunoHost-Apps/homeassistant_ynh/tree/testing --debug
```
