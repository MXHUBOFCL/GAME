return function(ctx)
local ExtraCard, Players, lib, localPlayer = ctx.ExtraCard, ctx.Players, ctx.lib, ctx.localPlayer
    do
        local ExtraCard = ctx.ExtraCard
        local cleanups = {}
        lib.API.Track(function()
            for _, f in ipairs(cleanups) do
                pcall(f)
            end
        end)

        local originalDesc
        local copyTarget
        local function playerNames()
            local list = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= localPlayer then
                    list[#list + 1] = p.Name
                end
            end
            table.sort(list)
            if #list == 0 then
                list[1] = "-"
            end
            return list
        end
        local copyDrop = ExtraCard:AddDropdown("Copy Avatar dari", playerNames(), false, function(value)
            copyTarget = value
        end)
        local function refreshPlayers()
            copyDrop:SetOptions(playerNames())
        end
        local addedConn = Players.PlayerAdded:Connect(refreshPlayers)
        local removedConn = Players.PlayerRemoving:Connect(function()
            task.defer(refreshPlayers)
        end)
        table.insert(cleanups, function()
            addedConn:Disconnect()
            removedConn:Disconnect()
        end)
        ExtraCard:AddButton("Copy Avatar", function()
            local target = copyTarget and Players:FindFirstChild(copyTarget)
            local char = localPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not (target and hum) then
                return
            end
            task.spawn(function()
                local ok, desc = pcall(function()
                    return Players:GetHumanoidDescriptionFromUserId(target.UserId)
                end)
                if not ok or not desc then
                    return
                end
                if not originalDesc then
                    pcall(function()
                        originalDesc = hum:GetAppliedDescription()
                    end)
                end
                pcall(function()
                    hum:ApplyDescription(desc)
                end)
            end)
        end)
        ExtraCard:AddButton("Kembalikan Avatar", function()
            local char = localPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and originalDesc then
                pcall(function()
                    hum:ApplyDescription(originalDesc)
                end)
            end
        end)
    end
end
