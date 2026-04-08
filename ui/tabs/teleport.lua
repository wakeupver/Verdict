return function(tab, ctx)
    local Services  = ctx.Services
    local CharUtils = ctx.CharUtils
    local Library   = ctx.Library

    local TeleBox = tab:AddLeftGroupbox("Player Teleport", "map")

    TeleBox:AddDropdown("TeleportPlayer", {
        SpecialType         = "Player",
        ExcludeLocalPlayer  = true,
        Text                = "Pilih Pemain",
        Callback            = function() end
    })

    TeleBox:AddButton({
        Text = "Teleport ke Pemain",
        Func = function()
            local playerName = Library.Options and Library.Options.TeleportPlayer and Library.Options.TeleportPlayer.Value
            local target = playerName and Services.Players:FindFirstChild(playerName)
            local hrp = target and CharUtils.getHRP(target, false)
            if hrp then CharUtils.teleportTo(hrp.CFrame + Vector3.new(0, 3, 0)) end
        end
    })

    TeleBox:AddButton({
        Text = "Refresh List",
        Func = function()
            local list = {}
            for _, p in ipairs(Services.Players:GetPlayers()) do
                if p ~= Services.Players.LocalPlayer then table.insert(list, p.Name) end
            end
            table.sort(list)
            if Library.Options and Library.Options.TeleportPlayer then
                pcall(function() Library.Options.TeleportPlayer:SetValues(list) end)
            end
        end
    })
end
