return function(ctx)
    local Services = ctx.Services
    local LocalPlayer = Services.Players.LocalPlayer
    local CharUtils = {}

    function CharUtils.getChar(plr, waitFor)
        plr = plr or LocalPlayer
        if not plr then return nil end
        if plr.Character then return plr.Character end
        if waitFor and plr.CharacterAdded then return plr.CharacterAdded:Wait() end
        return nil
    end

    function CharUtils.getHum(plr, waitFor)
        local char = CharUtils.getChar(plr, waitFor)
        return char and char:FindFirstChildOfClass("Humanoid")
    end

    function CharUtils.getHRP(plr, waitFor)
        local char = CharUtils.getChar(plr, waitFor)
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    function CharUtils.isAlive(char)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        return hum and hum.Health > 0
    end

    function CharUtils.teleportTo(cf)
        local hrp = CharUtils.getHRP(nil, false)
        if hrp and cf then hrp.CFrame = cf end
    end

    function CharUtils.getVelocity(part)
        if not part then return Vector3.new(0, 0, 0) end
        local ok, vel = pcall(function()
            return part.AssemblyLinearVelocity or part.Velocity or Vector3.new(0, 0, 0)
        end)
        return (ok and vel) or Vector3.new(0, 0, 0)
    end

    function CharUtils.resolveTargetPosition(char, preferredPart)
        if not char then return nil end
        if preferredPart and type(preferredPart) == "string" then
            local p = char:FindFirstChild(preferredPart)
            if p and p:IsA("BasePart") then return p.Position, p end
        end
        local priorities = { "Head", "UpperTorso", "Torso", "HumanoidRootPart", "LowerTorso" }
        for _, name in ipairs(priorities) do
            local p = char:FindFirstChild(name)
            if p and p:IsA("BasePart") then return p.Position, p end
        end
        if char.PrimaryPart and char.PrimaryPart:IsA("BasePart") then
            return char.PrimaryPart.Position, char.PrimaryPart
        end
        local ok, cf = pcall(function() return char:GetBoundingBox() end)
        if ok and cf then return cf.Position, nil end
        return nil
    end

    return CharUtils
end
