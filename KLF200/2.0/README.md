My own implementation to support the Velux KLF200 box with firmware version 2.0.0.71 in FHEM.

https://www.velux.com/api/klf200

Module 83_KLF200.pm represents the KLF200 box.

Module 83_KLF200Node.pm represents the devices, managed by the KLF200 box.

Copy both ih the folder /opt/fhem/FHEM/ and restart FHEM.

Define

    define <name> KLF200 <host> <pwfile>

    Example:
        define Velux KLF200 192.168.0.66 /opt/fhem/etc/veluxpw.txt
        
The devices will be created by auto create as instances of KLF200Node.

The device name of the nodes will be name_NodeID, but the names from the KLF200 Web UI will be set as alias.
  
Attributes

    directionOn: up/down (default is up) Defines the meaning of on, off, 100%, 0%. 
                                         This might depend on the device type and personal preferences.
