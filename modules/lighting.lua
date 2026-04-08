return function(ctx)
    local Services = ctx.Services
    local State    = ctx.State

    local LightingModule = {}

    function LightingModule.save()
        local L = Services.Lighting
        State.originalLighting = {
            Brightness    = L.Brightness,
            ClockTime     = L.ClockTime,
            FogEnd        = L.FogEnd,
            GlobalShadows = L.GlobalShadows,
            Ambient       = L.Ambient,
        }
    end

    function LightingModule.restore()
        for k, v in pairs(State.originalLighting) do
            pcall(function() Services.Lighting[k] = v end)
        end
        for _, eff in ipairs(Services.Lighting:GetChildren()) do
            if eff:IsA("PostEffect") then
                pcall(function() eff.Enabled = true end)
            end
        end
    end

    function LightingModule.fullbright()
        LightingModule.save()
        local L = Services.Lighting
        L.Brightness    = 2
        L.ClockTime     = 14
        L.FogEnd        = 1e9
        L.GlobalShadows = false
        L.Ambient       = Color3.new(1, 1, 1)
    end

    return LightingModule
end
