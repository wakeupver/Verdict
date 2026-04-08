local Connections = {}

local function safeDisconnect(conn)
    if conn then pcall(function() conn:Disconnect() end) end
end

local ConnMgr = {}

function ConnMgr.set(key, conn)
    if not key then return end
    if Connections[key] then safeDisconnect(Connections[key]) end
    Connections[key] = conn
end

function ConnMgr.drop(key)
    if Connections[key] then
        safeDisconnect(Connections[key])
        Connections[key] = nil
    end
end

function ConnMgr.clearAll()
    for k, v in pairs(Connections) do
        safeDisconnect(v)
        Connections[k] = nil
    end
end

return ConnMgr
