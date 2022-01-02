# Home Assistant pour YunoHost

[![Niveau d'intégration](https://dash.yunohost.org/integration/homeassistant.svg)](https://dash.yunohost.org/appci/app/homeassistant) ![](https://ci-apps.yunohost.org/ci/badges/homeassistant.status.svg) ![](https://ci-apps.yunohost.org/ci/badges/homeassistant.maintain.svg)  
[![Installer Home Assistant avec YunoHost](https://install-app.yunohost.org/install-with-yunohost.svg)](https://install-app.yunohost.org/?app=homeassistant)

*[Read this readme in english.](./README.md)*
*[Lire ce readme en français.](./README_fr.md)*

> *Ce package vous permet d'installer Home Assistant rapidement et simplement sur un serveur YunoHost.
Si vous n'avez pas YunoHost, regardez [ici](https://yunohost.org/#/install) pour savoir comment l'installer et en profiter.*

## Vue d'ensemble

Plateforme domotique

**Version incluse :** 2021.12.7~ynh1

**Démo :** https://demo.home-assistant.io

## Captures d'écran

![](./doc/screenshots/screenshot1)

## Avertissements / informations importantes

* Known limitations:
    * Are LDAP and HTTP auth supported? LDAP=Yes | HTTP auth=No
    * Can the app be used by multiple users? Yes


* Additional informations:
    * As the pyhton version shipped in Debian stable is not always supported, a recent version could be built during the installation process. It may take a while to achive that (15 to 60 minutes)

## Documentations et ressources

* Site officiel de l'app : https://www.home-assistant.io
* Documentation officielle de l'admin : https://www.home-assistant.io/docs/
* Documentation YunoHost pour cette app : https://yunohost.org/app_homeassistant
* Signaler un bug : https://github.com/YunoHost-Apps/homeassistant_ynh/issues

## Informations pour les développeurs

Merci de faire vos pull request sur la [branche testing](https://github.com/YunoHost-Apps/homeassistant_ynh/tree/testing).

Pour essayer la branche testing, procédez comme suit.
```
sudo yunohost app install https://github.com/YunoHost-Apps/homeassistant_ynh/tree/testing --debug
ou
sudo yunohost app upgrade homeassistant -u https://github.com/YunoHost-Apps/homeassistant_ynh/tree/testing --debug
```

**Plus d'infos sur le packaging d'applications :** https://yunohost.org/packaging_apps