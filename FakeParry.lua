return function(ctx)
local ExtraCard, lib, localPlayer = ctx.ExtraCard, ctx.lib, ctx.localPlayer
    do
        local ExtraCard = ctx.ExtraCard
        local cleanups = {}
        lib.API.Track(function()
            for _, f in ipairs(cleanups) do
                pcall(f)
            end
        end)
        local function animator()
            local char = localPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then
                return nil
            end
            local an = hum:FindFirstChildOfClass("Animator")
            if not an then
                an = Instance.new("Animator")
                an.Parent = hum
            end
            return an
        end

        local PARRY = {
            StopWatch = "rbxassetid://81793464499285",
            Enten = "rbxassetid://127096285501517",
            Default = "rbxassetid://109133187196613",
            BloodShield = "rbxassetid://75939529748815",
            Fih = "rbxassetid://123307242865945",
            Feedbacker = "rbxassetid://126894569253341",
        }
        local parryTrack
        local function playFakeParry()
            if parryTrack then
                pcall(function()
                    parryTrack:Stop()
                    parryTrack:Destroy()
                end)
                parryTrack = nil
            end
            local an = animator()
            if not an then
                return
            end
            local skin = localPlayer:GetAttribute("EquippedSkin_Parrying_Dagger")
            local anim = Instance.new("Animation")
            anim.AnimationId = PARRY[skin] or PARRY.Default
            parryTrack = an:LoadAnimation(anim)
            parryTrack.Looped = false
            parryTrack:Play()
        end
        ExtraCard:AddButton("Fake Parry", playFakeParry)
        table.insert(cleanups, function()
            if parryTrack then
                parryTrack:Stop()
            end
        end)

    end
end
