return function(tab, ctx)
    local ThemeManager = ctx.ThemeManager
    local SaveManager  = ctx.SaveManager

    if ThemeManager and SaveManager then
        ThemeManager:ApplyToTab(tab)
        SaveManager:BuildConfigSection(tab)
        SaveManager:LoadAutoloadConfig()
    end
end
