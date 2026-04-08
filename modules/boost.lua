return function(ctx)
    local Services        = ctx.Services
    local ConnMgr         = ctx.Connections
    local LightingModule  = ctx.LightingModule

    local ClassLookup = {
        disableEnabled = {
            ParticleEmitter = true, Trail = true, Smoke = true,
            Fire = true, Beam = true, Highlight = true,
        },
        lights = {
            PointLight = true, SpotLight = true, SurfaceLight = true,
        },
        textures = {
            Decal = true, Texture = true,
        },
        parts = {
            BasePart = true, UnionOperation = true, MeshPart = true,
        },
    }

    local function optimizeLite(obj)
        local c = obj.ClassName
        if ClassLookup.disableEnabled[c] or ClassLookup.lights[c] then
            pcall(function() obj.Enabled = false end)
        end
    end

    local function optimizeBalanced(obj)
        optimizeLite(obj)
        local c = obj.ClassName
        if ClassLookup.textures[c] then
            pcall(function() obj.Transparency = 1 end)
        elseif ClassLookup.parts[c] then
            pcall(function()
                obj.Material    = Enum.Material.Plastic
                obj.Reflectance = 0
            end)
        end
    end

    local BoostModule = {}

    function BoostModule.apply(mode)
        mode = mode or "Lite"
        LightingModule.save()

        for _, eff in ipairs(Services.Lighting:GetChildren()) do
            if eff:IsA("PostEffect") then pcall(function() eff.Enabled = false end) end
        end

        local walker = (mode == "Lite" and optimizeLite) or optimizeBalanced

        for _, o in ipairs(Services.Workspace:GetDescendants()) do
            pcall(function() walker(o) end)
        end

        ConnMgr.set("boostWatcher", Services.Workspace.DescendantAdded:Connect(function(o)
            pcall(function() walker(o) end)
        end))

        if mode == "Ultra" then
            pcall(function()
                Services.Lighting.GlobalShadows = false
                Services.Lighting.Brightness    = 1
                Services.Lighting.FogEnd        = 1e9
                Services.Lighting.Ambient       = Color3.new(1, 1, 1)
                Services.Workspace.StreamingEnabled    = true
                Services.Workspace.StreamingMinRadius  = 64
            end)
        end
    end

    function BoostModule.restore()
        ConnMgr.drop("boostWatcher")
        LightingModule.restore()
    end

    return BoostModule
end
