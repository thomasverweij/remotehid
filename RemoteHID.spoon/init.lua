--- === RemoteHID ===
---  
--- Hammerspoon script enabling users to use their smartphone as a remote control for their mac.
--- 

local obj={}
obj.__index = obj

-- Metadata
obj.name = "RemoteHID"
obj.version = "0.1"
obj.author = "Thomas Verweij <tverweij@pm.me>"
obj.homepage = "https://github.com/thomasverweij"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- RemoteHID.port
--- Variable
--- The port that the server will listen on (default: 7638). 
obj.port = "7638"

--- RemoteHID.interface
--- Variable
--- The interface that the server will listen on.
---
--- As well as real interface names (e.g. en0) the following values are valid:
--- * An IP address of one of your interfaces
---     * localhost
---     * loopback
---     * nil (which means all interfaces, and is the default)
obj.interface = nil

--- RemoteHID.password
--- Variable
--- The password to access the webinterface.
---
--- default: changeme
obj.password = "changeme"

obj._mainScreen = nil 
obj._screenWidth = nil 
obj._screenHeight = nil
obj._server = nil
obj._menuBar = nil

local function _readFile(path)
    local file = io.open(path, "rb") 
    if not file then return nil end
    local content = file:read "*a" 
    file:close()
    return content
end

local function _typeString(data)
    hs.eventtap.keyStrokes(data["chars"])
    return true
end

local function _pressKey(data)
    if data["key"] == "spotlight" then hs.eventtap.keyStroke({"cmd"}, "space") 
    elseif data["key"] == "voldown" then _adjustVolume(-5)
    elseif data["key"] == "volup" then _adjustVolume(5)    
    elseif hs.keycodes.map[data["key"]] ~= nil then hs.eventtap.keyStroke(data["mods"], data["key"])
    end
    return true
end

local function _moveMouse(data)
    hs.mouse.setRelativePosition(
        hs.geometry.point(
            data["x"] * obj._screenWidth, 
            data["y"] * obj._screenHeight)
    )
end

local function _leftClick()
    hs.eventtap.leftClick(
        hs.mouse.absolutePosition()
    )
    return true
end

local function _scroll(data)
    hs.eventtap.scrollWheel({
        data["x"] / 2, 
        data["y"] / 2 
        },
        {}
    )
    return true
end

local function _missionControl()
    hs.eventtap.keyStroke({"fn","ctrl"}, "up", 100)
    return true
end

local function _adjustVolume(x)
    local dev = hs.audiodevice.defaultOutputDevice()
    local new = math.min(100, math.max(0, math.floor(dev:volume() + x)))
    dev:setVolume(new)
    return true
end

local _actions = {
    ["string"] = _typeString, 
    ["key"] = _pressKey,
    ["mousemove"] = _moveMouse,
    ["scroll"] = _scroll,
    ["leftclick"] = _leftClick,
    ["missioncontrol"] = _missionControl
}

--- RemoteHID:init()
--- Method
--- Init function. Called when loading spoon
function obj:init()

    function _serverCallback(method, path, headers, body)
        if path == "/"
        then
            local content = _readFile(hs.spoons.resourcePath("client.html"))
            return content, 200, {}
        else
            return "Page not found", 404, {}
        end
    end
    
    function _wsCallback(msg)
        local data = hs.json.decode(msg)
        r = _actions[data["type"]] and _actions[data["type"]](data)
        return string.format("exit: %i %s", r and 0 or 1, msg)
    end

    function _menuCallback()
        local t = "RemoteHID running on: " .. (self.interface or "*") .. ":" .. self.port
        return {
            { title = t, disabled = true },
            { title = "-"},
            { title = "Deactivate", fn = function() self:stop() end }
        }
    end
    
    self._mainScreen = hs.screen.mainScreen()
    self._screenWidth = self._mainScreen:currentMode()["w"]
    self._screenHeight = self._mainScreen:currentMode()["h"]
    self._menuBar = hs.menubar.new(true)
    self._menuBar:setMenu(_menuCallback)
    self._menuBar:setTooltip("RemoteHID")
    self._server = hs.httpserver.new(false, true)
    self._server:setCallback(_serverCallback)
    self._server:websocket("/ws", _wsCallback)
end

--- RemoteHID:start()
--- Method
--- Start RemoteHID server
function obj:start()
    self._server:setPort(self.port)
    self._server:setPassword(self.password)
    self._server:setInterface(self.interface)
    self._menuBar:returnToMenuBar()
    self._menuBar:setTitle("⚪")
    self._server:start()
    print("-- Started RemoteHID server")
end


--- RemoteHID:stop()
--- Method
--- Stop RemoteHID server
function obj:stop()
    self._menuBar:removeFromMenuBar()
    self._server:stop()
    print("-- Stopped RemoteHID server")
end

--- RemoteHID:bindHotkeys()
--- Method
--- Binds hotkeys for RemoteHID
--- Parameters:
---  * mapping - A table containing hotkey details for the following items:
---   * start: to start server
---   * stop: to stop server
---
--- Example:
--- ```
--- local hyper = {"alt", "cmd"}
--- spoon.RemoteHID:bindHotKeys({
---     start={hyper, "s", message="Started RemoteHID"},
---     stop={hyper, "a", message="Stopped RemoteHID"}
--- })
--- ```
function obj:bindHotKeys(mapping)
    local spec = {
      start = hs.fnutils.partial(self.start, self),
      stop = hs.fnutils.partial(self.stop, self)
    }
    hs.spoons.bindHotkeysToSpec(spec, mapping)
    return self
end

return obj

