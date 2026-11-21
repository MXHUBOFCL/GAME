return function(ctx)
    local VeilCard, PistolSection, Players, ReplicatedStorage, RunService, localPlayer, lib = ctx.VeilCard, ctx.PistolSection, ctx.Players, ctx.ReplicatedStorage, ctx.RunService, ctx.localPlayer, ctx.lib

    local COLORS = {
        Merah = Color3.fromRGB(255, 70, 70),
        Biru = Color3.fromRGB(70, 170, 255),
        Hijau = Color3.fromRGB(80, 255, 130),
        Kuning = Color3.fromRGB(255, 220, 70),
        Ungu = Color3.fromRGB(190, 110, 255),
        Putih = Color3.fromRGB(255, 255, 255),
    }
    local COLOR_NAMES = {"Merah", "Biru", "Hijau", "Kuning", "Ungu", "Putih"}

    local Tracker = {
        spearOn = false,
        bulletOn = false,
        spearColor = COLORS.Ungu,
        bulletColor = COLORS.Merah,
        spearLife = 2,
        bulletLife = 1.2,
    }
    _G.Ox.Tracker = Tracker

    local folder = Instance.new("Folder")
    folder.Name = "MXHUB_Tracker"
    folder.Parent = workspace

    local segments = {}
    local runs = {}
    local MAX_SEGMENTS = 700

    local function addSegment(a, b, color, life, width)
        local length = (b - a).Magnitude
        if length < 0.01 then
            return
        end
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part.Material = Enum.Material.Neon
        part.Color = color
        part.Transparency = 0.1
        part.Size = Vector3.new(width, width, length)
        part.CFrame = CFrame.lookAt((a + b) / 2, b)
        part.Parent = folder
        table.insert(segments, {part = part, born = os.clock(), life = life})
        while #segments > MAX_SEGMENTS do
            local old = table.remove(segments, 1)
            old.part:Destroy()
        end
    end

    local function worldHit(from, to, ignore)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true
        local list = {folder}
        for _, instance in ipairs(ignore or {}) do
            table.insert(list, instance)
        end
        for _ = 1, 16 do
            params.FilterDescendantsInstances = list
            local hit = workspace:Raycast(from, to - from, params)
            if not hit then
                return nil
            end
            local inst = hit.Instance
            if inst.Transparency < 0.05 and inst.Name ~= "Plant" then
                return hit.Position
            end
            table.insert(list, inst)
        end
        return nil
    end

    local function launch(position, maxTime, color, life, width, stopOnHit)
        local started = os.clock()
        local last = position(0)
        local run = {}
        run.connection = RunService.Heartbeat:Connect(function()
            local t = os.clock() - started
            if t > maxTime then
                t = maxTime
            end
            local nextPoint = position(t)
            if nextPoint then
                local stopAt = stopOnHit and worldHit(last, nextPoint, {localPlayer.Character})
                if stopAt then
                    addSegment(last, stopAt, color, life, width)
                    run.connection:Disconnect()
                    runs[run] = nil
                    return
                end
                addSegment(last, nextPoint, color, life, width)
                last = nextPoint
            end
            if t >= maxTime then
                run.connection:Disconnect()
                runs[run] = nil
            end
        end)
        runs[run] = true
    end

    local fadeConnection = RunService.Heartbeat:Connect(function()
        local now = os.clock()
        local i = 1
        while i <= #segments do
            local seg = segments[i]
            local age = (now - seg.born) / seg.life
            if age >= 1 or not seg.part.Parent then
                seg.part:Destroy()
                table.remove(segments, i)
            else
                seg.part.Transparency = 0.1 + 0.9 * age * age
                i = i + 1
            end
        end
    end)

    local SPEAR_GRAVITY = Vector3.new(0, -98.1, 0)
    local SPEAR_OFFSET = 3
    local SPEAR_LIFE = 4
    pcall(function()
        local math3 = require(ReplicatedStorage.Modules.Killers.Veil.SpearMath)
        SPEAR_GRAVITY = math3.Gravity or SPEAR_GRAVITY
        SPEAR_OFFSET = math3.SpawnOffset or SPEAR_OFFSET
        SPEAR_LIFE = math3.MaxLife or SPEAR_LIFE
    end)

    function Tracker.spear(origin, direction, speed)
        if not Tracker.spearOn or typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
            return
        end
        local start = origin + direction.Unit * SPEAR_OFFSET
        local velocity = direction.Unit * speed
        launch(function(t)
            return start + velocity * t + SPEAR_GRAVITY * (0.5 * t * t)
        end, SPEAR_LIFE, Tracker.spearColor, Tracker.spearLife, 0.22, true)
    end

    function Tracker.bullet(from, to, speed)
        if not Tracker.bulletOn or typeof(from) ~= "Vector3" or typeof(to) ~= "Vector3" then
            return
        end
        local length = (to - from).Magnitude
        if length < 0.5 then
            return
        end
        local duration = length / math.max(tonumber(speed) or 800, 1)
        launch(function(t)
            return from:Lerp(to, math.min(t / math.max(duration, 0.001), 1))
        end, duration, Tracker.bulletColor, Tracker.bulletLife, 0.12, false)
    end

    task.spawn(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 20)
        local items = remotes and remotes:WaitForChild("Items", 10)
        local tof = items and items:WaitForChild("Twist of Fate", 10)
        local visualize = tof and tof:WaitForChild("VisualizeBullet", 10)
        if visualize then
            visualize.OnClientEvent:Connect(function(from, to, speed)
                pcall(Tracker.bullet, from, to, speed)
            end)
        end
    end)

    if VeilCard then
        VeilCard:AddToggle("Spear Tracker", false, function(on)
            Tracker.spearOn = on
        end, {Flag = "SpearTracker"})
        VeilCard:AddDropdown("Spear Tracker Color", COLOR_NAMES, false, function(name)
            Tracker.spearColor = COLORS[name] or Tracker.spearColor
        end, {Flag = "SpearTrackerColor", Default = "Ungu"})
        VeilCard:AddSlider("Spear Trail Duration", 1, 6, 2, function(value)
            Tracker.spearLife = value
        end, {Increment = 1, Flag = "SpearTrailLife"})
    end

    if PistolSection then
        PistolSection:AddToggle("Bullet Tracker", false, function(on)
            Tracker.bulletOn = on
        end, {Flag = "BulletTracker"})
        PistolSection:AddDropdown("Bullet Tracker Color", COLOR_NAMES, false, function(name)
            Tracker.bulletColor = COLORS[name] or Tracker.bulletColor
        end, {Flag = "BulletTrackerColor", Default = "Merah"})
        PistolSection:AddSlider("Bullet Trail Duration", 0.3, 4, 1.2, function(value)
            Tracker.bulletLife = value
        end, {Increment = 0.1, Flag = "BulletTrailLife"})
    end

    lib.API.Track(function()
        fadeConnection:Disconnect()
        for run in pairs(runs) do
            pcall(function()
                run.connection:Disconnect()
            end)
        end
        folder:Destroy()
        _G.Ox.Tracker = nil
    end)
end
