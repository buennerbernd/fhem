# FHEM modules KLF200 and KLF200Node

![](https://img.shields.io/github/last-commit/buennerbernd/fhem.svg?style=flat)

My own implementation to support the Velux KLF200 box with firmware version 2.0.0.71 in [FHEM](https://www.fhem.de/).

This FHEM integration supports unique io-homecontrol features:
* Control device positions per percent individually and simultaneously
* Simple controls like up, down and stop
* Activate scenes
* Get feedback from devices like position and success/error messages even if controlled by other remotes
* Set the velocity (fast, silent) if supported by device
* Set and read limitations
* Evaluate the rain sensor of Velux window openers

Because of FHEM supports MQTT, this module might be also useful for other house automation systems.

KLF200 API documentation and firmware download: https://www.velux.com/api/klf200

These modules integrate any io-homecontrol actuator into the open source smart-home solution FHEM by KLF-200.

- Module 83_KLF200.pm represents the KLF200 box.
- Module 83_KLF200Node.pm represents the devices, managed by the KLF200 box.

IO-homecontrol devices with positive feedback by users of the KLF200 modules:

* Roller Shutter:
  * VELUX SML
  * VELUX SSL
  * Somfy Oximo io
  * Somfy RS100 io
  * Somfy Izymo io
* Dual Roller Shutter
  * VELUX SMG
* Vertical Interior Blinds:
  * VELUX FSK
  * VELUX DML
* Window opener with integrated rain sensor:
  * VELUX KMG
  * VELUX CVP
  * VELUX KSX
  * VELUX GPU
* Horizontal awning:
  * Somfy Sunea io
  * Somfy Maestria+ 50 io
* Vertical Exterior Awning
  * VELUX MSL
  * VELUX MML
* Exterior Venetian blind
  * Somfy
* Light only supporting on/off
  * Somfy

Load the modules into FHEM:

    update all https://raw.githubusercontent.com/buennerbernd/fhem/master/KLF200/2.0/controls_KLF200.txt
FHEM must be also up to date:

    update
Restart FHEM:
    
    shutdown restart

Define

    define <name> KLF200 <host>

    Example:
        define Velux KLF200 192.168.0.66
        
Once your device is defined, you have to enter the password:

    set <name> login <password>

As password use the WIFI password, printed at the bottom of the box. If this doesn't work, please try the password of the WebUI of the KLF200. The password will be stored obfuscated in the FHEM backend and is optional for further login calls.
After login the devices will be created by auto create as instances of KLF200Node.

The device name of the nodes will be name_NodeID, but the names from the KLF200 Web UI will be set as alias.
  
Further documentation you will find in the commandref of both modules.

When your devices are successfully created, please call

    fheminfo send
    
to be part of the [anonymous device statistics](https://fhem.de/stats/statistics.html). (Search for KLF200Node to see models, that are already in use.)

So I have the chance to see if new devices must be supported.

[FHEM Forum: Velux KLF200 mit Firmware 2.0.0.71 für io-homecontrol](https://forum.fhem.de/index.php/topic,92907.0.html)

[FHEM Wiki German: Velux KLF200](https://wiki.fhem.de/wiki/Velux_KLF200)

[FHEM Wiki English translation: Velux KLF200](https://translate.google.com/translate?hl=&sl=de&tl=en&u=https%3A%2F%2Fwiki.fhem.de%2Fwiki%2FVelux_KLF200)
