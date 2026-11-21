return function(ctx)
local LagCard, lib = ctx.LagCard, ctx.lib
    do
        local Invis = {lag = false, lagMs = 300}
        _G.Ox.Invis = Invis
        local lagLast, lagState = 0, false

        function Invis.active()
            return Invis.lag
        end

        function Invis.rewrite(...)
            local a = table.pack(...)
            if not (Invis.lag and typeof(a[2]) == "CFrame") then
                return nil
            end
            local now = os.clock()
            if now - lagLast >= math.max(0.02, Invis.lagMs / 1000) then
                lagLast = now
                lagState = not lagState
            end
            if not lagState then
                return nil
            end
            local cf = a[2]
            local look = cf.LookVector
            local flat = Vector3.new(look.X, 0, look.Z)
            local dir = flat.Magnitude > 0.001 and flat.Unit or Vector3.new(0, 0, -1)
            a[2] = CFrame.new(cf.Position - dir * math.random(3, 9)) * cf.Rotation
            return a
        end

        local LagCard = ctx.LagCard
        LagCard:AddToggle("Fake Lag", false, function(on)
            Invis.lag = on
            lagLast, lagState = 0, false
        end, {Flag = "FakeLag"})
        LagCard:AddSlider("Fake Lag Interval (ms)", 50, 1000, 300, function(value)
            Invis.lagMs = value
        end, {Increment = 10, Flag = "FakeLagMs"})

        lib.API.Track(function()
            Invis.lag = false
            _G.Ox.Invis = nil
        end)
    end
end
