return function(ctx)
    local Services   = ctx.Services
    local Flags      = ctx.Flags
    local CharUtils  = ctx.CharUtils
    local clamp      = ctx.Utils.clamp
    local LocalPlayer = Services.Players.LocalPlayer
    local Camera      = Services.Workspace.CurrentCamera

    local AimbotModule = {}
    local function isVisible(targetPos, character)
        if not Flags.aimbotWallCheck then return true end
        local origin = Camera.CFrame.Position
        local direction = targetPos - origin
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.IgnoreWater = true
        local result = Services.Workspace:Raycast(origin, direction, raycastParams)
        return result == nil -- Jika nil, berarti tidak ada penghalang
    end

    function AimbotModule.getClosestTarget()
        local vpSize = Camera.ViewportSize
        local screenCenter = Vector2.new(vpSize.X * 0.5, vpSize.Y * 0.5)
        local fovRadius = Flags.aimbotFOV or 120
        local shortest = fovRadius
        local best = nil

        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local isTeammate = Flags.aimbotTeamCheck and (plr.Team == LocalPlayer.Team)
                if not isTeammate then
                    local char = plr.Character
                    if char and (not Flags.aimbotAliveCheck or CharUtils.isAlive(char)) then
                        local pos, part = CharUtils.resolveTargetPosition(char, Flags.aimbotLockPart or "Head")
                        
                        if pos then
                            local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
                            
                            if onScreen then
                                local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                                if dist < shortest then
                                    if isVisible(pos, char) then
                                        shortest = dist
                                        best = { 
                                            player = plr, 
                                            position = pos, 
                                            part = part, 
                                            instance = char 
                                        }
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    -- Fungsi prediksi yang lebih stabil dengan pengecekan akselerasi sederhana
    function AimbotModule.predictPosition(target)
        if not target or not target.part then return nil end
        
        local velocity = CharUtils.getVelocity(target.part)
        local ping = 0.1 -- Bisa diganti dengan real ping jika tersedia
        local predictionAmount = Flags.prediction or 0.12
        
        -- Rumus: Posisi + (Kecepatan * (Waktu Prediksi + Offset Ping))
        return target.part.Position + (velocity * (predictionAmount + (ping * 0.5)))
    end

    -- Fungsi untuk menghaluskan gerakan (Lerping)
    -- Gunakan ini di loop utama Anda saat menggerakkan kamera
    function AimbotModule.getSmoothedCFrame(targetPos)
        local currentCF = Camera.CFrame
        local targetCF = CFrame.new(currentCF.Position, targetPos)
        local smoothness = Flags.aimbotSmoothing or 0.1 -- Semakin kecil semakin halus/lambat
        
        return currentCF:Lerp(targetCF, clamp(smoothness, 0.01, 1))
    end

    return AimbotModule
end
