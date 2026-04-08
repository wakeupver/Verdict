return function(ctx)
    local State = ctx.State

    local FPSModule = {}

    function FPSModule.isSupported()
        return typeof(setfpscap) == "function"
            or typeof(set_fps_cap) == "function"
            or (syn and typeof(syn.set_fps_cap) == "function")
    end

    function FPSModule.setCap(n)
        if typeof(setfpscap) == "function" then
            setfpscap(n)
        elseif typeof(set_fps_cap) == "function" then
            set_fps_cap(n)
        elseif syn and typeof(syn.set_fps_cap) == "function" then
            syn.set_fps_cap(n)
        end
    end

    function FPSModule.getCap()
        if typeof(getfpscap) == "function" then
            return getfpscap()
        elseif typeof(get_fps_cap) == "function" then
            return get_fps_cap()
        elseif syn and typeof(syn.get_fps_cap) == "function" then
            return syn.get_fps_cap()
        end
        return 60
    end

    if FPSModule.isSupported() then
        State.originalCap = FPSModule.getCap()
    end

    return FPSModule
end
