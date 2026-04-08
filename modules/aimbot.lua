return function(ctx)
    local Services   = ctx.Services
    local Flags      = ctx.Flags
    local CharUtils  = ctx.CharUtils
    local clamp      = ctx.Utils.clamp
    local LocalPlayer = Services.Players.LocalPlayer
    local RunService  = Services.RunService

    local AimbotModule = {}

    -- Fungsi untuk mencari target (Logika Anda yang sudah berfungsi)
    function AimbotModule.getClosestTarget()
        local cam = Services.Workspace.CurrentCamera
        if not cam then return nil end

        local vpSize = cam.ViewportSize
        local screenCenter = Vector2.new(vpSize.X * 0.5, vpSize.Y * 0.5)
        local fov = Flags.aimbotFOV or 120
        local shortest = fov
        local best = nil

        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                if not (Flags.aimbotTeamCheck and LocalPlayer and plr.Team == LocalPlayer.Team) then
                    local char = plr.Character
                    if char and (not Flags.aimbotAliveCheck or CharUtils.isAlive(char)) then
                        local pos, part = CharUtils.resolveTargetPosition(char, Flags.aimbotLockPart)
                        if pos then
                            local screenPos, onScreen = cam:WorldToViewportPoint(pos)
                            if onScreen then
                                local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                                if dist < shortest then
                                    shortest = dist
                                    best = { player = plr, position = pos, part = part }
                                end
                            end
                        end
                    end
                end
            end
        end

        return best
    end

    -- Prediksi yang lebih stabil
    function AimbotModule.predictPosition(part)
        if not part then return nil end
        local velocity = CharUtils.getVelocity(part)
        local predictionValue = Flags.prediction or 0.12
        return part.Position + (velocity * predictionValue)
    end

    -- FUNGSI BARU: Menggerakkan kamera dengan stabil (Lerp)
    function AimbotModule.applySmoothing(targetPos, deltaTime)
        local cam = Services.Workspace.CurrentCamera
        if not cam or not targetPos then return end

        local currentCFrame = cam.CFrame
        local lookAtTarget = CFrame.new(currentCFrame.Position, targetPos)
        
        -- Semakin besar smoothing, semakin lambat pergerakannya (lebih stabil)
        -- Jika Flags.smoothing tidak ada, default ke 0.1
        local smoothAmount = Flags.aimbotSmoothing or 0.1
        
        -- Kita gunakan deltaTime agar kecepatan gerak sama di semua FPS
        local alpha = clamp(deltaTime * (1 / smoothAmount), 0, 1)
        
        cam.CFrame = currentCFrame:Lerp(lookAtTarget, alpha)
    end

    return AimbotModule
end
