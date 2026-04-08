return function(ctx)
    local Services    = ctx.Services
    local Flags       = ctx.Flags
    local CharUtils   = ctx.CharUtils
    local clamp       = ctx.Utils.clamp
    local LocalPlayer = Services.Players.LocalPlayer
    local Camera      = Services.Workspace.CurrentCamera

    local AimbotModule = {}

    -- Variable untuk menyimpan target terakhir agar transisi tidak 'lompat-lompat'
    local lastTarget = nil

    function AimbotModule.getClosestTarget()
        local vpSize = Camera.ViewportSize
        local screenCenter = Vector2.new(vpSize.X * 0.5, vpSize.Y * 0.5)
        
        local fovLimit = Flags.aimbotFOV or 120
        local shortest = fovLimit
        local best = nil

        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                -- Validasi Team & Nyawa
                local isEnemy = not Flags.aimbotTeamCheck or (plr.Team ~= LocalPlayer.Team)
                local isAlive = not Flags.aimbotAliveCheck or CharUtils.isAlive(plr.Character)

                if isEnemy and isAlive and plr.Character then
                    local pos, part = CharUtils.resolveTargetPosition(plr.Character, Flags.aimbotLockPart)
                    
                    if pos then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
                        
                        if onScreen then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                            if dist < shortest then
                                shortest = dist
                                best = { 
                                    player = plr, 
                                    position = pos, 
                                    part = part, 
                                    distanceFromCenter = dist 
                                }
                            end
                        end
                    end
                end
            end
        end
        
        lastTarget = best
        return best
    end

    -- Prediksi posisi yang lebih mulus (Velocity Scaling)
    function AimbotModule.predictPosition(target)
        if not target or not target.part then return nil end
        
        local velocity = CharUtils.getVelocity(target.part)
        -- Mengalikan prediksi dengan angka kecil agar tidak 'over-shooting' saat musuh lag
        local predictionStrength = Flags.prediction or 0.12
        
        return target.part.Position + (velocity * predictionStrength)
    end

    -- KUNCI STABILITAS: Smoothing Function
    -- Gunakan fungsi ini untuk menghitung CFrame kamera yang baru
    function AimbotModule.calculateSmoothCFrame(targetPos, deltaTime)
        local currentCF = Camera.CFrame
        local targetCF = CFrame.new(currentCF.Position, targetPos)
        
        -- Smoothing berdasarkan DeltaTime agar stabil di FPS berapapun
        -- Jika Flags.smoothing tidak ada, default ke 5 (semakin tinggi semakin lambat/halus)
        local lerpFactor = clamp(deltaTime * (Flags.aimbotSmoothingSpeed or 5), 0, 1)
        
        return currentCF:Lerp(targetCF, lerpFactor)
    end

    return AimbotModule
end
