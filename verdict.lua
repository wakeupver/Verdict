-- Cleanup previous instance
if _G.VerdictObsidianUI then
    local prev = _G.VerdictObsidianUI
    if type(prev.Unload) == "function" then
        pcall(function() prev:Unload() end)
    end
    _G.VerdictObsidianUI = nil
end

local BASE = "https://raw.githubusercontent.com/wakeupver/Verdict/main/"

local function load(path)
    return loadstring(game:HttpGet(BASE .. path))()
end

-- Core
local Services = load("core/services.lua")
local ConnMgr  = load("core/connections.lua")
local Utils    = load("core/utils.lua")

-- Config
local Flags, State = load("config.lua")

-- Modules — each is a factory(ctx) returning its API
local function buildCtx(extra)
    local ctx = {
        BASE        = BASE,
        Services    = Services,
        Connections = ConnMgr,
        Utils       = Utils,
        Flags       = Flags,
        State       = State,
    }
    if extra then
        for k, v in pairs(extra) do ctx[k] = v end
    end
    return ctx
end

local baseCtx = buildCtx()

local CharUtils     = load("modules/char.lua")(baseCtx)
baseCtx.CharUtils   = CharUtils

local AimbotModule  = load("modules/aimbot.lua")(baseCtx)
baseCtx.AimbotModule = AimbotModule

local LightingModule = load("modules/lighting.lua")(baseCtx)
baseCtx.LightingModule = LightingModule

local FPSModule     = load("modules/fps.lua")(baseCtx)
baseCtx.FPSModule   = FPSModule

local BoostModule   = load("modules/boost.lua")(baseCtx)
baseCtx.BoostModule = BoostModule

local DrawingModule = load("modules/drawing.lua")(baseCtx)
baseCtx.DrawingModule = DrawingModule

-- Build UI
load("ui/window.lua")(baseCtx)
