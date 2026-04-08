return function(ctx)
    -- Pastikan semua dependencies ada, jika tidak beri nilai default agar tidak error
    local Services    = ctx.Services or {
        Players = game:GetService("Players"),
        Workspace = game:GetService("Workspace"),
        RunService = game:GetService("RunService")
    }
    local Flags       = ctx.Flags or { aimbotEnabled = true, aimbotFOV = 150, aimbotSmoothing = 0.1, prediction = 0.12 }
    local CharUtils   = ctx.CharUtils
    local LocalPlayer = Services.Players.LocalPlayer
    local Camera      = Services.Workspace.CurrentCamera

    local AimbotModule = {}

    -- Update kamera secara berkala jika terjadi perubahan di workspace
    Services.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        Camera = Services.Workspace.CurrentCamera
    end)

    function AimbotModule.getClosestTarget()
        if not Flags.aimbotEnabled then return nil end
        
        local vpSize = Camera.ViewportSize
        local screenCenter = Vector2.new(vpSize.X * 0.5, vpSize.Y * 0.5)
        
        local fovLimit = Flags.aimbotFOV or 120
        local shortest = fovLimit
        local best = nil

        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                -- Validasi Team
                local teamCheckPassed = true
                if Flags.aimbotTeamCheck and plr.Team == LocalPlayer.Team then
                    teamCheckPassed = false
                end

                if teamCheckPassed then
                    local char = plr.Character
                    if char and CharUtils.isAlive(char) then
                        -- Ambil posisi part (Head/HumanoidRootPart)
                        local pos, part = CharUtils.resolveTargetPosition(char, Flags.aimbotLockPart or "Head")
                        
                        if pos and part then
                            -- Konversi posisi dunia ke posisi layar (Viewport)
                            local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
                            
                            if onScreen then
                                local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                                if dist < shortest then
                                    shortest = dist
                                    best = { 
                                        player = plr, 
                                        position = pos, 
                                        part = part 
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    -- Fungsi Prediksi Posisi (Penting agar tembakan tidak ketinggalan)
    function AimbotModule.getPredictedPosition(target)
        if not target or not target.part then return nil end
        local velocity = CharUtils.getVelocity(target.part)
        return target.part.Position + (velocity * (Flags.prediction or 0.12))
    end

    -- Fungsi eksekusi pergerakan kamera
    function AimbotModule.aimAt(targetPos, smoothness)
        if not targetPos then return end
        
        local currentCF = Camera.CFrame
        local targetCF = CFrame.new(currentCF.Position, targetPos)
        
        -- Smoothness: 1 = Instan, 0.01 = Sangat Lambat
        local s = ctx.Utils.clamp(1 - (smoothness or Flags.aimbotSmoothing or 0.05), 0.01, 1)
        Camera.CFrame = currentCF:Lerp(targetCF, s)
    end

    return AimbotModule
end
