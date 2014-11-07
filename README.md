# [BLEMeshChat](https://github.com/chrisballinger/BLEMeshChat) [![Build Status](https://travis-ci.org/chrisballinger/BLEMeshChat.svg?branch=master)](https://travis-ci.org/chrisballinger/BLEMeshChat)

[![Screenshot](https://i.imgur.com/z8lEdPMm.png)]([Imgur](https://i.imgur.com/z8lEdPM.png))

Bluetooth LE mesh chat prototype for iOS. [Android version over here](https://github.com/onlyinamerica/blemeshchat).

## Goals

* Use the Bluetooth 4.0 Low Energy APIs on iOS and Android to allow for pairing-free promiscuous background synchronization for anyone with a protocol-compatible app installed.
* Be a 100% sneakernet protocol, with absolutely no internet functionality.
* Use modern crypto (via libsodium) that's tailored to the limitations of BLE and an ultra-high latency, unreliable sneakernet.
* Implement a familiar and friendly Twitter-style UI/UX with a public feed, replies, reposts and (maybe) direct messaging.
* Only show Gravatar-style avatars and hashes for other's identities until you verify keys in person, and somehow make this process seem enjoyable.

## Protocol

There's still a lot of unsolved problems, but we're close to a working prototype. For more information about the current draft protocol, check out the [Bluetooth LE Mesh Chat Spec](https://github.com/chrisballinger/BLEMeshChat/wiki) wiki.

## Attribution

* Icons 8 [GPS Receiving](http://icons8.com/icons/#!/1098/gps_receiving)
* Icons 8 [Wifi](http://icons8.com/icons/#!/172/wifi)

## License

MPL 2.0
