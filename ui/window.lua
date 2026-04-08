return function(ctx)
    local BASE = ctx.BASE

    local function load(path)
        return loadstring(game:HttpGet(BASE .. path))()
    end

    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

    local ok, lib = pcall(function()
        return loadstring(game:HttpGet(repo .. "Library.lua"))()
    end)
    if not (ok and type(lib) == "table") then
        error("Unable to load Obsidian UI library.")
    end

    local Library = lib
    local ThemeManager, SaveManager

    pcall(function() ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))() end)
    pcall(function() SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()  end)

    if ThemeManager then ThemeManager:SetLibrary(Library) end
    if SaveManager  then SaveManager:SetLibrary(Library)  end

    local Window = Library:CreateWindow({
        Title            = "Verdict",
        Footer           = "Optimized & Lightweight ♡",
        Icon             = 95816097006870,
        NotifySide       = "Right",
        ShowCustomCursor = true,
    })

    local Tabs = {
        Main       = Window:AddTab("Main",        "user"),
        Combat     = Window:AddTab("Combat",      "crosshair"),
        Teleport   = Window:AddTab("Teleport",    "map"),
        Misc       = Window:AddTab("Misc",        "eye"),
        UISettings = Window:AddTab("UI Settings", "settings"),
    }

    local tabCtx = {
        Library      = Library,
        ThemeManager = ThemeManager,
        SaveManager  = SaveManager,
    }
    for k, v in pairs(ctx) do tabCtx[k] = v end

    load("ui/tabs/main.lua")(Tabs.Main,       tabCtx)
    load("ui/tabs/combat.lua")(Tabs.Combat,    tabCtx)
    load("ui/tabs/teleport.lua")(Tabs.Teleport, tabCtx)
    load("ui/tabs/misc.lua")(Tabs.Misc,        tabCtx)
    load("ui/tabs/ui_settings.lua")(Tabs.UISettings, tabCtx)

    Library:OnUnload(function()
        ctx.Connections.clearAll()
        local cam = ctx.Services.Workspace.CurrentCamera
        if cam then
            cam.CameraSubject = ctx.CharUtils.getHum(nil, false) or ctx.CharUtils.getChar(nil, false)
        end
        if ctx.FPSModule.isSupported() then
            ctx.FPSModule.setCap(ctx.State.originalCap)
        end
        ctx.BoostModule.restore()
        ctx.DrawingModule.destroyFOV()
        _G.VerdictObsidianUI = nil
    end)

    _G.VerdictObsidianUI = Library
end
