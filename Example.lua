-- Source URL. To test a branch before it is merged, replace "main" with the branch name,
-- e.g. ".../GAME/fix/settings-themes-effects/Source.lua".
local SOURCE = "https://raw.githubusercontent.com/MXHUBOFCL/GAME/main/Source.lua"
local MX = loadstring(game:HttpGet(SOURCE))()

local C = Color3.fromRGB
MX:AddThemes({
	Doir = { Window = C(10, 8, 9), Side = C(5, 4, 5), Panel = C(8, 6, 7), Card = C(14, 10, 12), Element = C(23, 17, 20), Hover = C(36, 26, 31), Border = C(104, 97, 101), Accent = C(4, 0, 255), Text = C(250, 240, 245), Sub = C(150, 125, 136), Off = C(44, 32, 38) },
	Gecko = { Window = C(25, 27, 28), Side = C(19, 21, 21), Panel = C(30, 32, 33), Card = C(36, 39, 40), Element = C(48, 52, 53), Hover = C(62, 67, 68), Border = C(115, 118, 119), Accent = C(203, 244, 85), Text = C(245, 246, 247), Sub = C(139, 170, 179), Off = C(70, 72, 73), OnAccent = C(24, 29, 12) },
})

MX.Discord = "https://discord.gg/G7FCTC2mEk"

local function demo(title, text)
	MX:Info(title, text or "Example only, nothing happens.", 2)
end

local Window = MX:CreateWindow({
	Title = "MX HUB",
	SubTitle = "MX UI v" .. MX.Version,
	Size = Vector2.new(720, 460),
	TabWidth = 170,
	Theme = "Obsidian",
	MobileButton = "Auto",
	-- Background effects (also in Settings > Effects): Stars, Snow, Rain, Fire.
	Effects = { Snow = true },
	EffectIntensity = 60,
})

-- Watermark and keybind list can also be switched on/off from Quick Settings (gear icon).
local Watermark = MX:CreateWatermark({ Title = "MX HUB" })
Watermark:AddTime()

MX:CreateKeybindList({ Key = Enum.KeyCode.K, Visible = false })

-- Runs when the user presses "Unload Script" in Quick Settings or the X button.
-- Toggles are switched off automatically first (set MX.UnloadResetsToggles = false to disable).
MX:OnUnload(function()
	print("[MX] unloaded, clean up your own loops/instances here")
end)

Window:AddCategory("Overview")
local Home = Window:AddTab("Home", "home")
local Visuals = Window:AddTab({ Title = "Visuals", Icon = "wand" })
local Elements = Window:AddTab({ Title = "Elements", Icon = "sliders-horizontal", Badge = "NEW" })
Window:AddCategory("Misc")

Home:AddImage({ Title = "MX HUB", Description = "Tap to copy the Discord invite", Height = 110, Badge = "MX", Image = MX.WelcomeImage, Callback = function()
	MX.Utils.Copy(MX.Discord)
	MX:Success("Copied", MX.Discord)
end })
Home:AddParagraph({ Title = "Welcome", Content = "MX UI works with mouse and touch. The gear icon in the header opens Quick Settings (Glass, Watermark, Keybind List, Mobile Button, UI Scale, Configs, Unload). The Settings tab only holds appearance: themes and effects. On phones a round MX button opens and closes the menu. On PC use INSERT or RIGHT SHIFT." })

local Info = Home:AddSection({ Title = "Labels and Progress", Icon = "activity" })
local Status = Info:AddLabel("Status: Idle")
local Bar = Info:AddProgress({ Title = "Progress", Default = 20 })
Info:AddButton({ Title = "Run Progress", Description = "Shows a spinner while it runs", Callback = function()
	for i = 0, 100, 5 do
		Bar:Set(i)
		Status:Set("Status: " .. i .. "%")
		task.wait(0.05)
	end
	MX:Success("Done", "Progress finished.")
end })

local Notes = Home:AddSection({ Title = "Notifications", Icon = "bell", Collapsible = true })
Notes:AddButton({ Title = "Info", Callback = function() MX:Info("Info", "An info notification.") end })
Notes:AddButton({ Title = "Success", Callback = function() MX:Success("Saved", "Your settings were saved.") end })
Notes:AddButton({ Title = "Warning", Callback = function() MX:Warning("Careful", "Connection looks unstable.") end })
Notes:AddButton({ Title = "Error", Callback = function() MX:Error("Failed", "Could not reach the server.") end })
Notes:AddButton({ Title = "With Buttons", Callback = function()
	MX:Notify({ Type = "Info", Title = "Friend Request", Content = "Someone wants to add you.", Duration = 8, Buttons = {
		{ Text = "Accept", Primary = true, Callback = function() MX:Success("Accepted", "You are now friends.") end },
		{ Text = "Decline" },
	} })
end })

local Extras = Elements:AddSection({ Title = "Toggle Extras", Icon = "settings" })
Extras:AddToggle({ Title = "Boxes", Description = "Color swatch and a gear with options", Flag = "boxes", Options = {
	{ Type = "ColorPicker", Title = "Color", Flag = "boxes_color", Default = C(255, 120, 170) },
	{ Type = "Toggle", Title = "Filled", Flag = "boxes_fill", Style = "Switch" },
	{ Type = "Slider", Title = "Thickness", Flag = "boxes_thick", Min = 1, Max = 5, Default = 1 },
	{ Type = "Dropdown", Title = "Style", Flag = "boxes_style", Values = { "2D", "3D", "Corner" }, Default = "2D" },
} })
Extras:AddToggle({ Title = "Chams", Description = "Keybind, color and options together", Flag = "chams", Keybind = Enum.KeyCode.C, KeyMode = "Toggle", Color = { Flag = "chams_color", Default = C(96, 205, 255) }, Options = function(menu)
	menu:AddSlider({ Title = "Transparency", Flag = "chams_trans", Min = 0, Max = 100, Default = 40, Suffix = "%" })
	menu:AddMultiSelect({ Title = "Targets", Flag = "chams_targets", Values = { "Players", "NPCs", "Items" }, Default = { "Players" } })
end })
Extras:AddToggle({ Title = "Fly", Description = "Toggle mode, press X. Tap it in the keybind list on mobile", Flag = "fly", Keybind = Enum.KeyCode.X, KeyMode = "Toggle", Style = "Switch" })
Extras:AddToggle({ Title = "Sprint", Description = "Hold mode", Flag = "sprint", Keybind = Enum.KeyCode.LeftShift, KeyMode = "Hold", Style = "Switch" })

local Sl = Elements:AddSection({ Title = "Sliders and Inputs", Icon = "sliders-horizontal" })
Sl:AddSlider({ Title = "Basic Slider", Flag = "sl1", Min = 0, Max = 100, Default = 50 })
Sl:AddSlider({ Title = "WalkSpeed", Flag = "ws", Min = 16, Max = 120, Default = 16, Toggle = true, ToggleFlag = "ws_on", ToggleCallback = function(v) demo("WalkSpeed", tostring(v)) end })
Sl:AddNumberInput({ Title = "Amount", Flag = "amount", Min = 0, Max = 500, Default = 25, Increment = 5, Suffix = " pcs" })
Sl:AddTextbox({ Title = "Textbox", Flag = "text", Placeholder = "Type something", Callback = function(t, enter) if enter then demo("Textbox", t) end end })

local Dr = Elements:AddSection({ Title = "Dropdowns", Icon = "list" })
Dr:AddDropdown({ Title = "Dropdown", Flag = "drop", Values = { "One", "Two", "Three" }, Default = "One" })
Dr:AddMultiSelect({ Title = "Targets", Flag = "targets", Values = { "Players", "NPCs", "Items", "Chests", "Bosses", "Pets", "Vehicles", "Portals" }, Default = { "Players" } })
Dr:AddDropdown({ Title = "With Search", Flag = "drop2", Values = { "Frankfurt", "Amsterdam", "London", "Paris", "Madrid", "Warsaw", "Stockholm", "Tokyo", "Jakarta" }, Default = "Jakarta" })
Dr:AddMultiSelect({ Title = "Multi Select", Flag = "multi", Values = { "Red", "Green", "Blue", "Yellow" }, Default = { "Red" } })
Dr:AddColorPicker({ Title = "Color Picker", Flag = "color", Default = C(255, 120, 170), DefaultAlpha = 1 })
Dr:AddKeybind({ Title = "Teleport", Flag = "tp", Default = Enum.KeyCode.V, Mode = "Press", Callback = function() demo("Teleport", "Key pressed") end })

local States = Elements:AddSection({ Title = "Hold, Locked, Loading", Icon = "lock" })
States:AddButton({ Title = "Hold To Reset", Hold = 1.5, Callback = function() MX:Success("Confirmed", "Reset.") end })
States:AddToggle({ Title = "Locked Toggle", Locked = true, LockedReason = "Premium only" })
States:AddButton({ Title = "Failing Callback", Description = "Flashes red", Callback = function() error("Something went wrong") end })
States:AddButton({ Title = "Dialog", Callback = function()
	Window:Dialog({ Title = "Are You Sure?", Content = "Only an example dialog.", Buttons = { { Title = "Confirm", Primary = true, Callback = function() MX:Success("Confirmed", "OK") end }, { Title = "Cancel" } } })
end })
States:AddButton({ Title = "Open Info Window", Callback = function()
	MX:AddWindow({ Title = "Server", Icon = "info", Width = 300, Height = 200, DestroyOnClose = true,
		Content = { "[green]Connected[/] as [b]{user}[/]", "FPS {fps}  Ping {ping}  Players {players}/{maxplayers}" },
		Rows = { { "Place", "{placeid}" }, { "Time", "{time}" } } })
end })

local FxSec = Visuals:AddSection({ Title = "Effects From Script", Icon = "flame" })
for _, name in ipairs({ "Stars", "Snow", "Rain", "Fire" }) do
	FxSec:AddButton({ Title = "Toggle " .. name, Callback = function()
		Window:ToggleEffect(name)
		demo(name, Window:GetEffect(name) and "On" or "Off")
	end })
end
FxSec:AddButton({ Title = "Cozy Preset", Description = "Snow + Fire, Frost theme", Callback = function()
	Window:SetEffect("Rain", false)
	Window:SetEffect("Snow", true)
	Window:SetEffect("Fire", true)
	MX:SetTheme("Frost")
end })

local QuickSec = Visuals:AddSection({ Title = "Quick Settings From Script", Icon = "settings" })
QuickSec:AddButton({ Title = "Toggle Glass", Callback = function() MX:SetGlass(not MX:GetGlass()) end })
QuickSec:AddButton({ Title = "Toggle Watermark", Callback = function() MX:SetWatermark(not MX:GetWatermark()) end })
QuickSec:AddButton({ Title = "Toggle Keybind List", Callback = function() MX:SetKeybindList(not MX:GetKeybindList()) end })
QuickSec:AddButton({ Title = "Random Theme", Callback = function()
	local list = MX.ThemeOrder
	MX:SetTheme(list[math.random(1, #list)])
end })

local Tabs = Elements:AddSection({ Title = "Inner Tabs", Icon = "layers", Side = "Full" })
local Inner = Tabs:AddTabs({ "First", "Second" })
Inner.Pages.First:AddToggle({ Title = "Toggle On First", Flag = "inner_t" })
Inner.Pages.Second:AddButton({ Title = "Back To First", Callback = function() Inner:Select("First") end })

-- Settings tab = Theme + Effects. Everything functional lives in Quick Settings.
Window:AddSettingsTab()
MX:LoadAutoConfig()
MX:Info("MX HUB", "Loaded. Tap the MX button or press INSERT. Gear icon = Quick Settings.")
