# TODO — OnAir

Task checklist. Requirements live in SPEC.md; current milestone lives in CONTEXT.md.
Key decisions are in SPEC.md "## decided".

## Repo setup
- [ ] `git init` + `.gitignore` (Swift / Xcode / macOS)
- [ ] `.gitignore` also excludes SPEC.md, CLAUDE.md, CONTEXT.md
- [ ] Create private GitHub repo "OnAir" via `gh` (go public after finishing)
- [ ] README.md

## App scaffold
- [ ] Xcode project — SwiftUI menu bar (agent) app, `LSUIElement`, no Dock icon, macOS 26.x target
- [ ] Version bump by 0.1 on every build (build phase script)
- [ ] App icon symbolizing "OnAir"
- [ ] `NSStatusItem` icon with states: idle / camera / mic / both / disabled (MQTT unreachable)
- [ ] Single click on the status icon toggles the whole function on/off

## Device state detection
- [ ] Camera active/inactive via private-property polling (CoreMediaIO `kCMIODevicePropertyDeviceIsRunningSomewhere`)
- [ ] Microphone active/inactive via private-property polling (CoreAudio `kAudioDevicePropertyDeviceIsRunningSomewhere`)
- [ ] Poll on the configured interval (default 3 s); emit one event per state change (debounce)
- [ ] Master toggle off → stop polling

## MQTT
- [ ] Integrate `swift-mqtt` (SPM)
- [ ] Connect using configured URL / user / password
- [ ] Publish separate camera / mic events to the same topic on each enabled state change — QoS 0, retained = true
  - Camera: `{"camera": "on"|"off", "timestamp": <epoch>}`
  - Mic:    `{"mic": "on"|"off", "timestamp": <epoch>}`
- [ ] Detect unreachable broker (out of house) → set status icon to disabled state
- [ ] Reconnect handling

## Configuration window (menu bar → config)
- [ ] Config window opened from the menu bar
- [ ] MQTT settings: URL, User, Password, topic
- [ ] Trigger toggles: camera, mic
- [ ] Polling interval in seconds (default 3)
- [ ] Copyright text: "Provided for free by Herbert Teibler. Distributed 'as is' without warrenty of any kind"
- [ ] Version info: "Version 1.0" + date
- [ ] "Close" button
- [ ] Visual polish
- [ ] Persist settings (password in Keychain)

## Release
- [ ] Notarize the app
- [ ] Make GitHub repo public
