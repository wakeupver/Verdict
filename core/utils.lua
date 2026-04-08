local Utils = {}

function Utils.clamp(x, a, b)
    return math.max(a, math.min(b, x))
end

function Utils.safeCall(fn, ...)
    return pcall(fn, ...)
end

return Utils
