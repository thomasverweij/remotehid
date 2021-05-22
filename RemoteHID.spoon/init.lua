--- === RemoteHID ===
---  
--- Hammerspoon script enabling users to use their smartphone as a remote mouse and keyboard for their mac.
--- 

local server={}
local actions={}

server.__index = server

-- Metadata
server.name = "RemoteHID"
server.version = "0.1"
server.author = "Thomas Verweij <tverweij@pm.me>"
server.homepage = "https://github.com/thomasverweij/remotehid"
server.license = "MIT - https://opensource.org/licenses/MIT"

--- RemoteHID.port
--- Variable
--- The port that the server will listen on (default: 7638). 
server.port = "7638"

--- RemoteHID.interface
--- Variable
--- The interface that the server will listen on.
---
--- As well as real interface names (e.g. en0) the following values are valid:
--- * An IP address of one of your interfaces
---     * localhost
---     * loopback
---     * nil (which means all interfaces, and is the default)
server.interface = nil


server._mainScreen = nil 
server._screenWidth = nil 
server._screenHeight = nil
server._server = nil
server._menuBar = nil
server._host = nil
server._token = nil
server._pin = nil

function _readFile(path)
    local file = io.open(path, "rb") 
    if not file then return nil end
    local content = file:read "*a" 
    file:close()
    return content
end

function resourcePath(name)
    local scriptPath = hs.spoons.scriptPath()
    local scriptDir = scriptPath .. hs.fs.displayName(scriptPath)
    local maybeScriptDir = (hs.fs.pathToAbsolute(scriptDir) .. "/" or scriptPath)
    return maybeScriptDir .. name
end

function _validate(msg)
    local data = hs.json.decode(msg)
    if not data then return false end
    if not data["d"] then return false end
    if not data["s"] then return false end
    local d = hs.base64.decode(data["d"])
    local s = hs.base64.decode(data["s"])
    local cs = hs.hash.hmacSHA256(server._token, d)
    if cs ~= s then return false     
    else return hs.json.decode(d)
    end
end

function _getNetworkHost()
    h = hs.fnutils.filter(
        hs.host.names(), 
        function(x) return string.find(x,".local") end
    )
    return (h[1] or "") .. ":" .. server.port
end

function _typeString(data)
    hs.eventtap.keyStrokes(data["chars"])
    return true
end

function _pressKey(data)
    if data["key"] == "spotlight" then hs.eventtap.keyStroke({"cmd"}, "space") 
    elseif data["key"] == "voldown" then _adjustVolume(-5)
    elseif data["key"] == "volup" then _adjustVolume(5)    
    elseif hs.keycodes.map[data["key"]] ~= nil then hs.eventtap.keyStroke(data["mods"], data["key"])
    end
    return true
end

function _moveMouse(data)
    hs.mouse.setRelativePosition(
        hs.geometry.point(
            data["x"] * server._screenWidth, 
            data["y"] * server._screenHeight)
    )
end

function _leftClick()
    hs.eventtap.leftClick(
        hs.mouse.absolutePosition()
    )
    return true
end

function _scroll(data)
    hs.eventtap.scrollWheel({
        data["x"] / 2, 
        data["y"] / 2 
        },
        {}
    )
    return true
end

function _missionControl()
    hs.eventtap.keyStroke({"fn","ctrl"}, "up", 100)
    return true
end

function _adjustVolume(x)
    local dev = hs.audiodevice.defaultOutputDevice()
    local new = math.min(100, math.max(0, math.floor(dev:volume() + x)))
    dev:setVolume(new)
    return true
end


actions.string = _typeString
actions.key = _pressKey
actions.mousemove = _moveMouse
actions.scroll = _scroll
actions.leftclick = _leftClick
actions.missioncontrol = _missionControl



--- RemoteHID:init()
--- Method
--- Init function. Called when loading spoon
function server:init()
    
    function _serverCallback(method, path, headers, body)
        if path ~= "/" then return "Page not found", 404, {} end
        self._token = hs.hash.MD5(os.time() .. self._pin)
        local content = string.gsub(
                _readFile(resourcePath("client.html")),
                "{{ token }}",
                self._token
            )
        hs.notify.withdrawAll()
        return content, 200, {}
    end

    function _wsCallback(msg)
        local data = _validate(msg)
        if not data then return "Unauthenticated" end
        r = actions[data["type"]] and actions[data["type"]](data)
        return "ack"
    end

    function _menuCallback()
        return {
            { title = "Interface: " .. (self.interface or "*"), disabled = true },
            { title = "Host: " .. (self._host or "Unavailable"), disabled = true },
            { title = "-"},
            { title = "Deactivate", fn = function() self:stop() end }
        }
    end
    
    self._mainScreen = hs.screen.mainScreen()
    self._screenWidth = self._mainScreen:currentMode()["w"]
    self._screenHeight = self._mainScreen:currentMode()["h"]
    self._host = _getNetworkHost()
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
function server:start()
    self._server:stop()
    self._pin = tostring(math.random(1000,9999))
    self._server:setPort(self.port or "7638")
    self._server:setPassword(self._pin)
    self._server:setInterface(self.interface)
    self._menuBar:returnToMenuBar()
    self._menuBar:setTitle("⚪")
    self._server:start()
    print("-- Started RemoteHID server")
    hs.notify.new(nil, {
        title = "RemoteHID started", 
        subTitle = "Pin: " .. self._pin .. "", 
        withdrawAfter = 0
    }):send()
end


--- RemoteHID:stop()
--- Method
--- Stop RemoteHID server
function server:stop()
    hs.notify.withdrawAll()
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
function server:bindHotKeys(mapping)
    local spec = {
      start = hs.fnutils.partial(self.start, self),
      stop = hs.fnutils.partial(self.stop, self)
    }
    hs.spoons.bindHotkeysToSpec(spec, mapping)
    return self
end

return server

