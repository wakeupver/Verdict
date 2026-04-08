return function(ctx)
    local Services = ctx.Services
    local Flags    = ctx.Flags
    local State    = ctx.State
    local ConnMgr  = ctx.Connections

    local DrawingLib = nil
    pcall(function() DrawingLib = Drawing or drawing end)

    local DrawingModule = {}

    function DrawingModule.createFOV()
        if not DrawingLib then return end
        DrawingModule.destroyFOV()
        pcall(function()
            State.fovCircle = DrawingLib.new("Circle")
            State.fovCircle.Visible   = false
            State.fovCircle.Color     = Flags.fovColor
            State.fovCircle.Thickness = Flags.fovThickness
            State.fovCircle.NumSides  = 64
            State.fovCircle.Filled    = false
            State.fovCircle.Radius    = Flags.aimbotFOV
            State.fovCircle.Position  = Vector2.new(0, 0)
        end)
    end

    function DrawingModule.destroyFOV()
        if State.fovCircle then
            pcall(function() State.fovCircle:Remove() end)
            State.fovCircle = nil
        end
    end

    function DrawingModule.updateFOV()
        if not State.fovCircle then return end
        local cam = Services.Workspace.CurrentCamera
        if not cam then return end
        local vp = cam.ViewportSize
        pcall(function()
            State.fovCircle.Visible   = true
            State.fovCircle.Position  = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
            State.fovCircle.Radius    = Flags.aimbotFOV
            State.fovCircle.Color     = Flags.fovColor
            State.fovCircle.Thickness = Flags.fovThickness
        end)
    end

    return DrawingModule
end
