return function(ctx)
local EspMasterCard, Players, RunService, lib, localPlayer = ctx.EspMasterCard, ctx.Players, ctx.RunService, ctx.lib, ctx.localPlayer
do
    local TixoESP = {faceOn = false, coneOn = false, conn = nil, acc = 0}
    local FACE_FOLDER, CONE_FOLDER = "MXHUBKillerFaceLine", "MXHUBKillerCone"

    local function newBeam(folder, a0, a1, transparency)
        local beam = Instance.new("Beam")
        beam.Attachment0 = a0
        beam.Attachment1 = a1
        beam.Width0 = 0.12
        beam.Width1 = 0.12
        beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
        beam.FaceCamera = true
        beam.LightEmission = 1
        if transparency then
            beam.Transparency = NumberSequence.new(transparency)
        end
        beam.Parent = folder
    end

    local function drawCone(hrp)
        if hrp:FindFirstChild(CONE_FOLDER) then
            return
        end
        local folder = Instance.new("Folder")
        folder.Name = CONE_FOLDER
        folder.Parent = hrp
        local center = Instance.new("Attachment")
        center.Position = Vector3.new(0, -2.8, 0)
        center.Parent = folder
        local half = math.rad(50 / 2)
        local range, segments = 9, 8
        local prev
        for i = 0, segments do
            local ang = -half + (i / segments) * (half * 2)
            local att = Instance.new("Attachment")
            att.Position = Vector3.new(math.sin(ang) * range, -2.8, -math.cos(ang) * range)
            att.Parent = folder
            if prev then
                newBeam(folder, prev, att)
            end
            if i == 0 or i == segments then
                newBeam(folder, center, att)
            end
            prev = att
        end
    end

    local function drawFace(hrp)
        if hrp:FindFirstChild(FACE_FOLDER) then
            return
        end
        local folder = Instance.new("Folder")
        folder.Name = FACE_FOLDER
        folder.Parent = hrp
        local a0 = Instance.new("Attachment")
        a0.Parent = folder
        local a1 = Instance.new("Attachment")
        a1.Position = Vector3.new(0, 0, -60)
        a1.Parent = folder
        newBeam(folder, a0, a1, 0.2)
    end

    local function clear(name)
        for _, p in ipairs(Players:GetPlayers()) do
            local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            local f = hrp and hrp:FindFirstChild(name)
            if f then
                f:Destroy()
            end
        end
    end

    local function refresh()
        local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        local maxDist = _G.Ox.ESPConfig.MaxDistance or 1000
        for _, p in ipairs(Players:GetPlayers()) do
            local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local isKiller = p ~= localPlayer and p.Team and p.Team.Name == "Killer"
                local inRange = isKiller and (not myRoot or (hrp.Position - myRoot.Position).Magnitude <= maxDist)
                local fc = hrp:FindFirstChild(CONE_FOLDER)
                local ff = hrp:FindFirstChild(FACE_FOLDER)
                if inRange and TixoESP.coneOn then
                    drawCone(hrp)
                elseif fc then
                    fc:Destroy()
                end
                if inRange and TixoESP.faceOn then
                    drawFace(hrp)
                elseif ff then
                    ff:Destroy()
                end
            end
        end
    end

    local function sync()
        if TixoESP.faceOn or TixoESP.coneOn then
            if not TixoESP.conn then
                TixoESP.acc = 1
                TixoESP.conn = RunService.Heartbeat:Connect(function(dt)
                    TixoESP.acc += dt
                    if TixoESP.acc >= 0.5 then
                        TixoESP.acc = 0
                        pcall(refresh)
                    end
                end)
            end
        elseif TixoESP.conn then
            TixoESP.conn:Disconnect()
            TixoESP.conn = nil
        end
        pcall(refresh)
        if not TixoESP.faceOn then
            clear(FACE_FOLDER)
        end
        if not TixoESP.coneOn then
            clear(CONE_FOLDER)
        end
    end

    EspMasterCard:AddCheckbox("ESP Face Line Killer", false, function(on)
        TixoESP.faceOn = on
        sync()
    end, {Flag = "EspFaceLine"})
    EspMasterCard:AddCheckbox("Hitbox Range Killer (kerucut serang)", false, function(on)
        TixoESP.coneOn = on
        sync()
    end, {Flag = "EspHitboxCone"})

    lib.API.Track(function()
        TixoESP.faceOn, TixoESP.coneOn = false, false
        sync()
    end)
end
end
