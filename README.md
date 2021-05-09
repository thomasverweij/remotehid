# RemoteHID

Hammerspoon script enabling users to use their touch devices as remote controls for their mac. Useful when presenting or when using a mac as media player. Features a web interface providing touch and keyboard controls (accessible on local network).  

## WARNING

Running this script will expose functionality on your local network that may help attackers compromise your system. Use with care and only on networks you trust.  

## Requirements

- [Hammerspoon](https://www.hammerspoon.org) installed on system

## Install

1. [Download spoon](https://github.com/thomasverweij/remotehid/blob/master/RemoteHID.spoon.zip).
2. Unzip and double click RemoteHID.spoon to install.
3. Load and configure spoon in `~/.hammerspoon/init.lua`:

Example configuration with default settings:

```lua
hs.loadSpoon("RemoteHID")
spoon.RemoteHID.port = "7638"           --server port
spoon.RemoteHID.interface = nil         --interface
spoon.RemoteHID.password = "changeme"   --password for webinterface

spoon.RemoteHID:bindHotKeys({           --bind hotkeys (available commands: start, stop):
    start={{"cmd", "alt"}, "s", message="Started RemoteHID"},
    stop={{"cmd", "alt"}, "a", message="Stopped RemoteHID"}
})
```

## Usage

1. Make sure hammerspoon is running
2. Start server using specified key combination (or `spoon.RemoteHID:start()`).
3. On your touch device, browse to http://YourMacHostname.local:7638 and login (keep username blank).
4. Start controlling your mac using the web interface.
5. Stop server using specified key combination (or `spoon.RemoteHID:stop()`).

