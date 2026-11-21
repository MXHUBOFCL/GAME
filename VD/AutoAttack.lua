return function(ctx)
local AutoAttackCard, CollectionService, HttpService, KillerAbilityCard, ObjectivesCard, Players, ReplicatedStorage, RunService, localPlayer = ctx.AutoAttackCard, ctx.CollectionService, ctx.HttpService, ctx.KillerAbilityCard, ctx.ObjectivesCard, ctx.Players, ctx.ReplicatedStorage, ctx.RunService, ctx.localPlayer
do

    local LUNGE_DELAY = 0.21
    local AURA_COOLDOWN = 1.1
    local ATTACK_RANGE = 9
    local REACH_RANGE = 13
    local LEGIT_ANGLE = 0.5
    local KICK_REGRESS = 25

    local K = {
        attack = false,
        carry = false,
        hook = false,
        kickGen = false,
        breakPallet = false,
        antiStun = false,
        freeTurn = false,
        reachAssist = false,

        atkUntil = 0,
        rejected = {},
        badPoint = setmetatable({}, {__mode = "k"}),
        kicked = setmetatable({}, {__mode = "k"}),
    }

    local function remote(...)
        local cur = ReplicatedStorage:FindFirstChild("Remotes")
        for _, name in ipairs({...}) do
            cur = cur and cur:FindFirstChild(name)
        end
        return cur
    end

    local R = {
        carry = remote("Carry", "CarrySurvivorEvent"),
        carryAnimDone = remote("Carry", "CarryAnimDone"),
        hook = remote("Carry", "HookEvent"),
        hookCommit = remote("Carry", "HookCommit"),
        hookReject = remote("Carry", "HookReject"),
        gen = remote("Generator", "BreakGenEvent"),
        genCommit = remote("Generator", "BreakGenCommit"),
        genReject = remote("Generator", "BreakGenReject"),
        attack = remote("Attacks", "BasicAttack"),
        lunge = remote("Attacks", "Lunge"),
        stun = remote("Pallet", "Jason", "Stun"),
        stunOver = remote("Pallet", "Jason", "Stunover") or remote("Pallet", "Jason", "StunOver"),
    }

    for _, name in ipairs({"hookReject", "genReject"}) do
        local rejectRemote = R[name]
        if rejectRemote then
            rejectRemote.OnClientEvent:Connect(function(id)
                if typeof(id) == "string" then
                    K.rejected[id] = true
                end
            end)
        end
    end

    local function isKiller()
        return localPlayer.Team ~= nil and localPlayer.Team.Name == "Killer"
    end

    local function me()
        local char = localPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if char and hrp and hum and hum.Health > 0 then
            return char, hrp, hum
        end
        return nil
    end

    local function ready(char)
        return not (char:GetAttribute("Immobile") or char:GetAttribute("IsStunned"))
    end

    local function survivors()
        local list = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= localPlayer and plr.Team and plr.Team.Name == "Survivors" and plr.Character then
                table.insert(list, plr.Character)
            end
        end
        for _, bot in ipairs(CollectionService:GetTagged("SurvivorBot")) do
            table.insert(list, bot)
        end
        return list
    end

    local function aliveRoot(char)
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 then
            return root, hum
        end
        return nil
    end

    local function canHit(char)
        return aliveRoot(char) ~= nil
            and char:GetAttribute("Knocked") ~= true
            and not char:GetAttribute("IsCarried")
            and not char:GetAttribute("IsHooked")
    end

    local function validPoint(point)
        return point:IsA("BasePart") and point.Parent and not CollectionService:HasTag(point, "doing action")
            and not point.Parent:GetAttribute("Regressing")
    end

    local function nearest(tag, filter)
        local char, hrp = me()
        if not char then
            return nil
        end
        local best, bestDist = nil, math.huge
        local now = tick()
        for _, point in ipairs(CollectionService:GetTagged(tag)) do
            if validPoint(point) and (K.badPoint[point] or 0) < now and (not filter or filter(point)) then
                local dist = (point.Position - hrp.Position).Magnitude
                if dist < bestDist then
                    best, bestDist = point, dist
                end
            end
        end
        return best
    end

    local function walkTo(pos, stop, active)
        local _, hrp = me()
        if not hrp then
            return false
        end
        if (hrp.Position - pos).Magnitude <= stop then
            return true
        end
        return _G.Ox.Walker.walkTo(pos, {stop = stop, timeout = 60, active = function()
            return _G.Ox.ScriptAlive and isKiller() and me() ~= nil and active()
        end})
    end

    local function interact(point, startRemote, commitRemote, hold, stop, active)
        if not (startRemote and commitRemote) then
            return false
        end
        if not walkTo(point.Position, stop, active) then
            K.badPoint[point] = tick() + 8
            return false
        end
        local char = me()
        if not char or not active() then
            return false
        end
        _G.Ox.Walker.face(point.Position)
        task.wait(0.1)
        local id = HttpService:GenerateGUID(false)
        K.rejected[id] = nil
        pcall(function()
            startRemote:FireServer(point, id, char)
        end)
        task.wait(0.1)
        pcall(function()
            commitRemote:FireServer(point, id, char)
        end)
        local t0 = tick()
        while tick() - t0 < hold and not K.rejected[id] and _G.Ox.ScriptAlive and me() do
            task.wait(0.05)
        end
        return not K.rejected[id]
    end

    local function hookOccupied(hookPoint)
        for _, char in ipairs(survivors()) do
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and char:GetAttribute("IsHooked") and (root.Position - hookPoint.Position).Magnitude < 10 then
                return true
            end
        end
        return false
    end

    local function doHook()
        local char = me()
        local hookPoint = nearest("HookPoint", function(point)
            return not hookOccupied(point)
        end)
        if not (char and hookPoint) then
            return false
        end
        local function active()
            return K.hook and char:GetAttribute("IsCarrying") == true
        end
        interact(hookPoint, R.hook, R.hookCommit, 0.6, 3.5, active)
        local t0 = tick()
        while char and char:GetAttribute("IsCarrying") and tick() - t0 < 2.5 do
            task.wait(0.1)
        end
        return true
    end

    local function doCarry()
        local char, hrp = me()
        if not char or not R.carry then
            return false
        end
        local target, bestDist = nil, math.huge
        local now = tick()
        for _, other in ipairs(survivors()) do
            local root, hum = aliveRoot(other)
            if root and (K.badPoint[other] or 0) < now then
                local downed = other:GetAttribute("Knocked") == true or hum.Health <= 20
                local progress = other:GetAttribute("HookedProgress")
                local onEarlyHook = progress ~= nil and progress < 2
                if downed and not onEarlyHook and not other:GetAttribute("IsCarried") and not other:GetAttribute("IsHooked") then
                    local dist = (root.Position - hrp.Position).Magnitude
                    if dist < bestDist then
                        target, bestDist = other, dist
                    end
                end
            end
        end
        if not target then
            return false
        end
        local function active()
            return K.carry and target.Parent ~= nil
                and not target:GetAttribute("IsCarried") and not target:GetAttribute("IsHooked")
        end
        local root = target:FindFirstChild("HumanoidRootPart")
        if not walkTo(root.Position, 3.2, active) then
            K.badPoint[target] = tick() + 8
            return true
        end
        if not active() or not me() then
            return true
        end
        _G.Ox.Walker.face(target.HumanoidRootPart.Position)
        task.wait(0.1)
        pcall(function()
            R.carry:FireServer(target)
        end)
        task.wait(0.5)
        if R.carryAnimDone then
            pcall(function()
                R.carryAnimDone:FireServer(1)
            end)
        end
        return true
    end

    local function doGen()
        local point = nearest("GeneratorPoint", function(pt)
            local gen = pt.Parent
            local progress = gen:GetAttribute("RepairProgress") or 0
            local kicks = gen:GetAttribute("kickcount") or 0
            local fresh = tick() - (K.kicked[gen] or 0) > KICK_REGRESS
            return progress > 0 and progress < 100 and kicks <= 7 and fresh
        end)
        if not point then
            return false
        end
        if interact(point, R.gen, R.genCommit, 1.95, 3.5, function()
            return K.kickGen
        end) then
            K.kicked[point.Parent] = tick()
        end
        return true
    end

    local palletRemote = {start = remote("Pallet", "Jason", "Destroy-Global"), commit = remote("Pallet", "Jason", "PalletBreakCommit")}
    local palletCache, palletScanAt = {}, 0
    local function droppedPalletPoint()
        local char, hrp = me()
        if not hrp then
            return nil
        end
        if tick() - palletScanAt > 3 then
            palletScanAt = tick()
            palletCache = {}
            local root = workspace:FindFirstChild("Map") or workspace
            for _, d in ipairs(root:GetDescendants()) do
                if d.Name == "PalletPoint" and d:IsA("BasePart") then
                    palletCache[#palletCache + 1] = d
                end
            end
        end
        local best, bestDist, now = nil, math.huge, tick()
        for _, point in ipairs(palletCache) do
            local model = point.Parent
            if point.Parent and model and model:GetAttribute("PalletState") == "Dropped" and (K.badPoint[point] or 0) < now then
                local dist = (point.Position - hrp.Position).Magnitude
                if dist < bestDist then
                    best, bestDist = point, dist
                end
            end
        end
        return best
    end

    local function doPalletBreak()
        local point = droppedPalletPoint()
        if not point then
            return false
        end
        if not palletRemote.start or not palletRemote.commit then
            palletRemote.start = remote("Pallet", "Jason", "Destroy-Global")
            palletRemote.commit = remote("Pallet", "Jason", "PalletBreakCommit")
        end
        interact(point, palletRemote.start, palletRemote.commit, 1.8, 3.5, function()
            return K.breakPallet and point.Parent ~= nil and point.Parent:GetAttribute("PalletState") == "Dropped"
        end)
        return true
    end

    local function fireLunge()
        if R.lunge then
            pcall(function()
                R.lunge:FireServer()
            end)
        end
    end

    local function faceTarget(hrp, root)
        hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(root.Position.X, hrp.Position.Y, root.Position.Z))
    end

    local function legitTarget(hrp)
        local look = hrp.CFrame.LookVector
        local range = K.reachAssist and REACH_RANGE or ATTACK_RANGE
        local angle = K.reachAssist and -0.1 or LEGIT_ANGLE
        local best, bestDist = nil, math.huge
        for _, char in ipairs(survivors()) do
            if canHit(char) then
                local offset = char.HumanoidRootPart.Position - hrp.Position
                local dist = offset.Magnitude
                if dist > 0 and dist <= range and dist < bestDist and look:Dot(offset.Unit) >= angle then
                    best, bestDist = char, dist
                end
            end
        end
        return best
    end

    local function swing(target)
        local root = target:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end
        local _, hrp = me()
        if not hrp then
            return
        end
        if K.reachAssist then
            faceTarget(hrp, root)
        end
        fireLunge()
        task.wait(LUNGE_DELAY)
        local _, hrp2 = me()
        if hrp2 and root.Parent and K.reachAssist then
            faceTarget(hrp2, root)
        end
        pcall(function()
            R.attack:FireServer()
        end)
    end

    local function doAttack(hrp)
        if not R.attack or tick() < K.atkUntil then
            return false
        end
        local target = legitTarget(hrp)
        if not target then
            return false
        end
        K.atkUntil = tick() + AURA_COOLDOWN
        swing(target)
        return true
    end

    local function step()
        if not (K.attack or K.carry or K.hook or K.kickGen or K.breakPallet) or not isKiller() then
            return
        end
        local char, hrp = me()
        if not char or not ready(char) then
            return
        end
        if not _G.Ox.Act.try("killer", 70) then
            return
        end

        if char:GetAttribute("IsCarrying") then
            if K.hook then
                doHook()
            end
        elseif not (K.carry and doCarry()) and not (K.attack and doAttack(hrp)) and not (K.breakPallet and doPalletBreak()) and K.kickGen then
            doGen()
        end
        _G.Ox.Act.done("killer")
    end

    task.spawn(function()
        while _G.Ox.ScriptAlive do
            task.wait(0.15)
            local ok, err = pcall(step)
            if not ok then
                _G.Ox.Act.done("killer")
                warn("[MXHUB] killer automation: " .. tostring(err))
                task.wait(1)
            end
        end
    end)

    local mutedStun = {}
    local function releaseStun()
        if K.antiStun and isKiller() and R.stunOver then
            pcall(function()
                R.stunOver:FireServer()
            end)
        end
    end

    local function setStunMuted(muted)
        if muted then
            if type(getconnections) ~= "function" or not R.stun then
                return
            end
            pcall(function()
                for _, conn in ipairs(getconnections(R.stun.OnClientEvent)) do
                    if conn.Enabled and conn.Function ~= releaseStun then
                        conn:Disable()
                        table.insert(mutedStun, conn)
                    end
                end
            end)
        else
            for _, conn in ipairs(mutedStun) do
                pcall(function()
                    conn:Enable()
                end)
            end
            table.clear(mutedStun)
        end
    end

    if R.stun and R.stunOver then
        R.stun.OnClientEvent:Connect(releaseStun)
    end

    local turnConn
    turnConn = RunService.Heartbeat:Connect(function()
        if not _G.Ox.ScriptAlive then
            turnConn:Disconnect()
            return
        end
        if not K.freeTurn or not isKiller() then
            return
        end
        local char, hrp, hum = me()
        if not char or hum.AutoRotate or char:GetAttribute("overridelookscript") or char:GetAttribute("Immobile") then
            return
        end
        local look = workspace.CurrentCamera.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        if flat.Magnitude > 0 then
            hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flat)
        end
    end)

    AutoAttackCard:AddToggle("Auto Attack (Aura)", false, function(on)
        K.attack = on
    end, {Flag = "MXHUB_AutoAttack"})

    AutoAttackCard:AddToggle("Reach Assist", false, function(on)
        K.reachAssist = on
    end, {Flag = "MXHUB_ReachAssist"})

    ObjectivesCard:AddToggle("Auto Carry", false, function(on)
        K.carry = on
    end, {Flag = "MXHUB_AutoCarry"})

    ObjectivesCard:AddToggle("Auto Hook", false, function(on)
        K.hook = on
    end, {Flag = "MXHUB_AutoHook"})

    ObjectivesCard:AddToggle("Auto Break Pallet", false, function(on)
        K.breakPallet = on
    end, {Flag = "MXHUB_AutoBreakPallet"})

    KillerAbilityCard:AddToggle("Anti Stun (Pallet)", false, function(on)
        K.antiStun = on
        setStunMuted(on)
    end, {Flag = "MXHUB_AntiStun"})

    KillerAbilityCard:AddToggle("No Turn Limit", false, function(on)
        K.freeTurn = on
    end, {Flag = "MXHUB_FreeTurn"})

end
end
