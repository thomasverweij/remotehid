# RemoteHID

Hammerspoon script enabling users to use their touch devices as a remote mouse and keyboard for their mac. Useful when presenting or when using a mac as media player. Features a web interface providing touch and keyboard controls (accessible on local network).  

<img src="https://raw.githubusercontent.com/thomasverweij/remotehid/img/screenshot1.png" width="200" />   <img src="https://raw.githubusercontent.com/thomasverweij/remotehid/img/screenshot2.png" width="200" />


## WARNING

Running this script will expose functionality on your local network that may help attackers compromise your system. Use with care and only on networks you trust.  

## Requirements

- [Hammerspoon](https://www.hammerspoon.org) installed on system

## Install

1. [Download spoon](https://github.com/thomasverweij/remotehid/blob/main/RemoteHID.spoon.zip).
2. Unzip and double click RemoteHID.spoon to install.
3. Load and configure spoon in `~/.hammerspoon/init.lua`:

Example configuration with default settings:

```lua
hs.loadSpoon("RemoteHID")
spoon.RemoteHID.port = "7638"           --server port
spoon.RemoteHID.interface = nil         --interface

spoon.RemoteHID:bindHotKeys({           --bind hotkeys (available commands: start, stop):
    start={{"cmd", "alt"}, "s", message="Started RemoteHID"},
    stop={{"cmd", "alt"}, "a", message="Stopped RemoteHID"}
})
```

## Usage

1. Make sure hammerspoon is running
2. Start server using specified key combination (or `spoon.RemoteHID:start()`).
3. You will receive a message with a 4-digit pin.
4. On your touch device, browse to http://YourMacHostname.local:7638 or scan the QR code from the menu. 
5. Log in using pin (keep username blank).
6. Start controlling your mac using the web interface.
7. Stop server using specified key combination (or `spoon.RemoteHID:stop()`).
