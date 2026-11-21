return function(ctx)
local CoreGui, ExtraCard, Players, ReplicatedStorage, lib, localPlayer = ctx.CoreGui, ctx.ExtraCard, ctx.Players, ctx.ReplicatedStorage, ctx.lib, ctx.localPlayer
    do
        local ExtraCard = ctx.ExtraCard
        local TweenSvc = game:GetService("TweenService")
        local guiParent = (pcall(function() return CoreGui.Name end) and CoreGui) or localPlayer:WaitForChild("PlayerGui")
        local cleanups = {}
        lib.API.Track(function()
            for _, f in ipairs(cleanups) do
                pcall(f)
            end
        end)

        local perkGui, perkToken = nil, 0
        local function stopPerkInfo()
            perkToken += 1
            if perkGui then
                perkGui:Destroy()
                perkGui = nil
            end
        end
        local function startPerkInfo()
            stopPerkInfo()
            local killers = ReplicatedStorage:FindFirstChild("Killers")
            local general = killers and killers:FindFirstChild("!General")
            general = general and general:FindFirstChild("Perks")
            if not killers or not general then
                return
            end
            local token = perkToken
            perkGui = Instance.new("ScreenGui")
            perkGui.Name = "MXHUBPerkInfo"
            perkGui.ResetOnSpawn = false
            perkGui.IgnoreGuiInset = true
            perkGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            perkGui.Parent = guiParent

            local frame = Instance.new("Frame")
            frame.Size = UDim2.fromOffset(220, 160)
            frame.Position = UDim2.fromScale(0.65, 0.3)
            frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
            frame.BorderSizePixel = 0
            frame.Active = true
            frame.Draggable = true
            frame.ClipsDescendants = true
            frame.Parent = perkGui
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
            local stroke = Instance.new("UIStroke", frame)
            stroke.Color = Color3.fromRGB(60, 60, 70)

            local top = Instance.new("TextLabel")
            top.Size = UDim2.new(1, 0, 0, 26)
            top.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            top.BorderSizePixel = 0
            top.Text = "  Info Perk"
            top.TextColor3 = Color3.new(1, 1, 1)
            top.Font = Enum.Font.GothamBold
            top.TextSize = 12
            top.TextXAlignment = Enum.TextXAlignment.Left
            top.Parent = frame

            local scroll = Instance.new("ScrollingFrame")
            scroll.Size = UDim2.new(1, -8, 1, -32)
            scroll.Position = UDim2.fromOffset(4, 30)
            scroll.BackgroundTransparency = 1
            scroll.BorderSizePixel = 0
            scroll.ScrollBarThickness = 2
            scroll.Parent = frame
            local layout = Instance.new("UIListLayout", scroll)
            layout.Padding = UDim.new(0, 3)

            local function addText(text, color, header)
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(1, 0, 0, header and 16 or 14)
                l.BackgroundTransparency = 1
                l.Text = " " .. text
                l.TextColor3 = color or Color3.new(1, 1, 1)
                l.TextXAlignment = Enum.TextXAlignment.Left
                l.Font = header and Enum.Font.GothamBold or Enum.Font.Gotham
                l.TextSize = header and 11 or 10
                l.Parent = scroll
            end

            local function isPerk(name)
                if general:FindFirstChild(name) then
                    return true
                end
                for _, k in ipairs(killers:GetChildren()) do
                    local pf = k:FindFirstChild("Perks")
                    if pf and pf:FindFirstChild(name) then
                        return true
                    end
                end
                return false
            end

            local function scan()
                for _, c in ipairs(scroll:GetChildren()) do
                    if c:IsA("TextLabel") then
                        c:Destroy()
                    end
                end
                local found = false
                for _, p in ipairs(Players:GetPlayers()) do
                    local char = p.Character
                    if char and char:FindFirstChild("Humanoid") then
                        local list = {}
                        for _, obj in ipairs(char:GetChildren()) do
                            local base, lvl = string.match(obj.Name, "^(.-)%s+(%d+)$")
                            if base and isPerk(base) then
                                list[#list + 1] = string.format("• %s (Lvl %s)", base, lvl)
                            end
                        end
                        if #list > 0 then
                            found = true
                            local team = p.Team and p.Team.Name
                            if p == localPlayer then
                                addText("Kamu (" .. p.Name .. ")", Color3.fromRGB(100, 255, 100), true)
                            elseif team == "Killer" then
                                addText("KILLER: " .. p.Name, Color3.fromRGB(255, 80, 80), true)
                            else
                                addText("Survivor: " .. p.Name, Color3.fromRGB(80, 170, 255), true)
                            end
                            for _, line in ipairs(list) do
                                addText(line, Color3.fromRGB(220, 220, 220), false)
                            end
                        end
                    end
                end
                if not found then
                    addText("Memindai...", Color3.fromRGB(150, 150, 150), false)
                end
                scroll.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 5)
            end

            task.spawn(function()
                while perkToken == token and perkGui do
                    pcall(scan)
                    task.wait(3)
                end
            end)
        end
        ExtraCard:AddToggle("Perk Info Panel", false, function(on)
            if on then
                startPerkInfo()
            else
                stopPerkInfo()
            end
        end, {Flag = "PerkInfoPanel"})
        table.insert(cleanups, stopPerkInfo)

    end
end
