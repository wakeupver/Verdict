return function(tab, ctx)
    local Services       = ctx.Services
    local Flags          = ctx.Flags
    local ConnMgr        = ctx.Connections
    local CharUtils      = ctx.CharUtils
    local LightingModule = ctx.LightingModule

    local PlayerBox = tab:AddLeftGroupbox("Player", "boxes")

    PlayerBox:AddToggle("NoClip", {
        Text    = "No Clip",
        Default = false,
        Callback = function(v)
            Flags.noclip = v
            ConnMgr.drop("noclip")
            if not v then return end
            ConnMgr.set("noclip", Services.RunService.Stepped:Connect(function()
                local char = CharUtils.getChar(nil, false)
                if not char then return end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then pcall(function() part.CanCollide = false end) end
                end
            end))
        end
    })

    PlayerBox:AddToggle("DisableCollision", {
        Text    = "Disable Player Collision",
        Default = false,
        Callback = function(v)
            Flags.noCollision = v
            ConnMgr.drop("noCollision")
            if v then
                ConnMgr.set("noCollision", Services.RunService.Heartbeat:Connect(function()
                    for _, plr in ipairs(Services.Players:GetPlayers()) do
                        if plr ~= Services.Players.LocalPlayer then
                            local char = plr.Character
                            if char then
                                for _, part in ipairs(char:GetDescendants()) do
                                    if part:IsA("BasePart") then pcall(function() part.CanCollide = false end) end
                                end
                            end
                        end
                    end
                end))
            else
                for _, plr in ipairs(Services.Players:GetPlayers()) do
                    if plr ~= Services.Players.LocalPlayer then
                        local char = plr.Character
                        if char then
                            for _, part in ipairs(char:GetDescendants()) do
                                if part:IsA("BasePart") then pcall(function() part.CanCollide = true end) end
                            end
                        end
                    end
                end
            end
        end
    })

    PlayerBox:AddToggle("InfiniteJump", {
        Text    = "Infinite Jump",
        Default = false,
        Callback = function(v)
            Flags.infiniteJump = v
            ConnMgr.drop("infiniteJump")
            if not v then return end
            ConnMgr.set("infiniteJump", Services.UIS.JumpRequest:Connect(function()
                local hum = CharUtils.getHum(nil, false)
                if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
            end))
        end
    })

    local VisualBox = tab:AddRightGroupbox("Visual", "eye")

    VisualBox:AddToggle("Fullbright", {
        Text    = "Fullbright",
        Default = false,
        Callback = function(v)
            ConnMgr.drop("fullbright")
            if v then
                LightingModule.fullbright()
                ConnMgr.set("fullbright", Services.RunService.RenderStepped:Connect(function()
                    local L = Services.Lighting
                    L.Brightness    = 2
                    L.ClockTime     = 14
                    L.FogEnd        = 1e9
                    L.GlobalShadows = false
                    L.Ambient       = Color3.new(1, 1, 1)
                end))
            else
                LightingModule.restore()
            end
        end
    })

    local UtilityBox = tab:AddRightGroupbox("Utility", "zap")

    UtilityBox:AddToggle("ClickTeleport", {
        Text    = "Click Teleport",
        Default = false,
        Callback = function(v)
            Flags.clickTp = v
            ConnMgr.drop("clickTp")
            if not v then return end
            local lp = Services.Players.LocalPlayer
            if not lp then return end
            local mouse = lp:GetMouse()
            ConnMgr.set("clickTp", mouse.Button1Down:Connect(function()
                if mouse.Hit then
                    CharUtils.teleportTo(CFrame.new(mouse.Hit.Position + Vector3.new(0, 5, 0)))
                end
            end))
        end
    })
end
