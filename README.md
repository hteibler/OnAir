# OnAir

A native macOS menu bar app that watches whether the camera or microphone is
active and publishes a message via MQTT whenever that state changes.

## Features

- Lives in the menu bar (`NSStatusItem`), no Dock icon
- Detects camera / microphone activity by polling (interval configurable, default 3 s)
- Publishes separate camera / mic events to one MQTT topic, QoS 0, retained
- Icon shows a disabled state when the MQTT broker is unreachable
- Single click on the icon toggles the whole function on / off
- Configuration window: MQTT URL / user / password / topic, trigger toggles,
  polling interval, launch-at-login toggle

## MQTT payload

Published to the configured base topic, e.g. `/macbook/onair`:

```json
{"camera": "on", "timestamp": 1724762400}
{"mic": "off", "timestamp": 1724762400}
```

## Requirements

- macOS 26.x
- Xcode 26.x
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Build

```bash
xcodegen generate
xcodebuild -project OnAir.xcodeproj -scheme OnAir build
```

`OnAir.xcodeproj` is generated from `project.yml` and is not checked in.
Swift Package dependencies (`emqx/swift-mqtt`) resolve automatically on first build.

## Configuration storage

MQTT URL / username / topic are stored in `UserDefaults` (`at.teibler.OnAir`);
the password is stored in the Keychain. The configuration window is not built
yet — set values manually for now, e.g.:

```bash
defaults write at.teibler.OnAir mqtt.url "mqtt://broker.example:1883"
defaults write at.teibler.OnAir mqtt.topic "/macbook/onair"
```

Release builds bump `CFBundleShortVersionString` by 0.1 automatically.

## License

Provided for free by Herbert Teibler. Distributed 'as is' without warranty of any kind.
