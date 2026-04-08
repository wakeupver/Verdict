local Flags = {
    aimbot          = false,
    aimbotFOV       = 120,
    aimbotSmoothness = 0.15,
    aimbotLockPart  = "Head",
    aimbotTeamCheck = false,
    aimbotAliveCheck = true,
    prediction      = 0.12,

    showFOV         = false,
    fovColor        = Color3.fromRGB(255, 255, 255),
    fovThickness    = 2,

    noclip          = false,
    noCollision     = false,
    infiniteJump    = false,

    smoothCam       = false,
    sensitivity     = 1.0,
    clickTp         = false,

    boostMode       = "Lite",
    positionSlot    = 1,
}

local State = {
    savedSlots      = {},
    originalLighting = {},
    originalCap     = 60,
    fovCircle       = nil,
    freeCam         = nil,
}

return Flags, State
