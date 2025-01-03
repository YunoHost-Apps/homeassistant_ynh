<!--
Nota bene : ce README est automatiquement généré par <https://github.com/YunoHost/apps/tree/master/tools/readme_generator>
Il NE doit PAS être modifié à la main.
-->

# Home Assistant pour YunoHost

[![Niveau d’intégration](https://apps.yunohost.org/badge/integration/homeassistant)](https://ci-apps.yunohost.org/ci/apps/homeassistant/)
![Statut du fonctionnement](https://apps.yunohost.org/badge/state/homeassistant)
![Statut de maintenance](https://apps.yunohost.org/badge/maintained/homeassistant)

[![Installer Home Assistant avec YunoHost](https://install-app.yunohost.org/install-with-yunohost.svg)](https://install-app.yunohost.org/?app=homeassistant)

*[Lire le README dans d'autres langues.](./ALL_README.md)*

> *Ce package vous permet d’installer Home Assistant rapidement et simplement sur un serveur YunoHost.*  
> *Si vous n’avez pas YunoHost, consultez [ce guide](https://yunohost.org/install) pour savoir comment l’installer et en profiter.*

## Vue d’ensemble

Home Assistant zst une application domotique open source qui donne la priorité au contrôle local et à la confidentialité. Propulsé par une communauté mondiale de bricoleurs et de passionnés de bricolage. Parfait pour fonctionner sur un Raspberry Pi ou un serveur local.

### Caractéristiques

- Fonctionne avec plus de 1000 marques ;
- Des automatismes puissants ;
- Étendez votre système avec des modules complémentaires ;
- Toutes les données de votre maison intelligente restent locales ;
- Applications mobiles compagnons ;
- Gestion de l'énergie domestique.

**Version incluse :** 2025.1.0~ynh1

**Démo :** <https://demo.home-assistant.io>

## Captures d’écran

![Capture d’écran de Home Assistant](./doc/screenshots/screenshot1.png)

## Documentations et ressources

- Site officiel de l’app : <https://www.home-assistant.io>
- Documentation officielle de l’admin : <https://www.home-assistant.io/docs/>
- Dépôt de code officiel de l’app : <https://github.com/home-assistant/core>
- YunoHost Store : <https://apps.yunohost.org/app/homeassistant>
- Signaler un bug : <https://github.com/YunoHost-Apps/homeassistant_ynh/issues>

## Informations pour les développeurs

Merci de faire vos pull request sur la [branche `testing`](https://github.com/YunoHost-Apps/homeassistant_ynh/tree/testing).

Pour essayer la branche `testing`, procédez comme suit :

```bash
sudo yunohost app install https://github.com/YunoHost-Apps/homeassistant_ynh/tree/testing --debug
ou
sudo yunohost app upgrade homeassistant -u https://github.com/YunoHost-Apps/homeassistant_ynh/tree/testing --debug
```

**Plus d’infos sur le packaging d’applications :** <https://yunohost.org/packaging_apps>
