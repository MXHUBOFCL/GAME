local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local env = (getgenv and getgenv()) or _G

if env.MXNotify and type(env.MXNotify.Destroy) == "function" then
	pcall(function() env.MXNotify:Destroy() end)
end

local Touch = UserInputService.TouchEnabled
local Mobile = Touch and not UserInputService.KeyboardEnabled
local C3 = Color3.fromRGB

local Notify = {
	Version = "2.0.0",
	Config = {
		Width = Mobile and 196 or 226,
		OffsetX = 6,
		OffsetY = 6,
		Spacing = 5,
		MaxVisible = 5,
		Duration = 4,
		Radius = 8,
		HoverPause = true,
	},
	Theme = {
		Card = C3(23, 23, 30),
		Element = C3(32, 32, 41),
		Border = C3(58, 58, 72),
		Text = C3(240, 240, 246),
		Sub = C3(150, 152, 170),
		Info = C3(236, 236, 240),
		Success = C3(86, 214, 140),
		Warning = C3(245, 180, 66),
		Error = C3(236, 80, 90),
		OnAccent = C3(20, 20, 24),
	},
	Types = { Info = true, Success = true, Warning = true, Error = true },
	Glyphs = { Info = "i", Success = "+", Warning = "!", Error = "x" },
}

local Bindings = {}
local Active = {}
local Count = 0
local Dead = false

local function protect(gui)
	if gethui then
		local ok, h = pcall(gethui)
		if ok and h then gui.Parent = h return end
	end
	if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
	local ok = pcall(function() gui.Parent = CoreGui end)
	if not ok then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
end

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

local function bind(obj, prop, key)
	obj[prop] = Notify.Theme[key]
	Bindings[#Bindings + 1] = { o = obj, p = prop, k = key }
end

local function tween(o, props, t, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local Gui = new("ScreenGui", {
	Name = "MXNotify",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 2147483000,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
protect(Gui)

local Holder = new("Frame", {
	Name = "Holder",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.fromOffset(Notify.Config.Width, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	Position = UDim2.fromOffset(Notify.Config.OffsetX, Notify.Config.OffsetY),
}, Gui)
new("UIListLayout", {
	Padding = UDim.new(0, Notify.Config.Spacing),
	SortOrder = Enum.SortOrder.LayoutOrder,
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	VerticalAlignment = Enum.VerticalAlignment.Top,
}, Holder)

local function typeColor(kind)
	return Notify.Theme[kind] or Notify.Theme.Info
end

function Notify:Send(o)
	o = o or {}
	if Dead then return { Dismiss = function() end, Update = function() end } end
	Count += 1
	local kind = self.Types[o.Type] and o.Type or "Info"
	local closed = false
	local paused = false
	local elapsed = 0
	local duration = tonumber(o.Duration)
	if duration == nil then duration = self.Config.Duration end
	local conn

	local wrap = new("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = Count,
	}, Holder)

	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, -(self.Config.Width + 40), 0, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, wrap)
	bind(card, "BackgroundColor3", "Card")
	new("UICorner", { CornerRadius = UDim.new(0, self.Config.Radius) }, card)
	local stroke = new("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = 0.15 }, card)
	bind(stroke, "Color", "Border")

	local accent = new("Frame", { BorderSizePixel = 0, Size = UDim2.new(0, 3, 1, 0) }, card)
	accent.BackgroundColor3 = typeColor(kind)

	local inner = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(3, 0),
		Size = UDim2.new(1, -3, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, card)
	new("UIPadding", { PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 9), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 6) }, inner)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, inner)

	local top = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
	}, inner)

	local badge = new("Frame", {
		Size = UDim2.fromOffset(22, 22),
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
	}, top)
	badge.BackgroundColor3 = typeColor(kind)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, badge)
	local glyph
	if o.Icon then
		glyph = new("ImageLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(12, 12),
			Image = tostring(o.Icon),
			ImageColor3 = typeColor(kind),
		}, badge)
	else
		glyph = new("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Font = Enum.Font.BuilderSansBold,
			TextSize = 13,
			Text = self.Glyphs[kind],
			TextColor3 = typeColor(kind),
		}, badge)
	end

	local textCol = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(29, 0),
		Size = UDim2.new(1, -47, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, top)
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, textCol)
	local title = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 13),
		Font = Enum.Font.BuilderSansBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = tostring(o.Title or kind),
		LayoutOrder = 1,
	}, textCol)
	bind(title, "TextColor3", "Text")
	local content = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.BuilderSans,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = tostring(o.Content or ""),
		Visible = o.Content ~= nil and tostring(o.Content) ~= "",
		LayoutOrder = 2,
	}, textCol)
	bind(content, "TextColor3", "Sub")
	local sub = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.BuilderSans,
		TextSize = 10,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = tostring(o.SubContent or ""),
		Visible = o.SubContent ~= nil and tostring(o.SubContent) ~= "",
		LayoutOrder = 3,
	}, textCol)
	bind(sub, "TextColor3", "Sub")

	local close = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Font = Enum.Font.BuilderSansBold,
		TextSize = 13,
		Text = "x",
		ZIndex = 4,
	}, top)
	bind(close, "TextColor3", "Sub")

	local bar = new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundTransparency = 0.35,
		ZIndex = 3,
		Visible = duration > 0,
	}, card)
	bar.BackgroundColor3 = typeColor(kind)

	local function dismiss()
		if closed then return end
		closed = true
		if conn then conn:Disconnect() end
		for i, h in ipairs(Active) do
			if h == wrap then table.remove(Active, i) break end
		end
		tween(card, { Position = UDim2.new(0, -(self.Config.Width + 40), 0, 0) }, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.22, function()
			if not wrap.Parent then return end
			local h = wrap.AbsoluteSize.Y
			wrap.AutomaticSize = Enum.AutomaticSize.None
			wrap.ClipsDescendants = true
			wrap.Size = UDim2.new(1, 0, 0, h)
			tween(wrap, { Size = UDim2.new(1, 0, 0, 0) }, 0.16, Enum.EasingStyle.Quad)
			task.delay(0.18, function() wrap:Destroy() end)
		end)
	end

	if o.Buttons and #o.Buttons > 0 then
		local row = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, Touch and 26 or 22),
			LayoutOrder = 2,
		}, inner)
		new("UIListLayout", { Padding = UDim.new(0, 6), FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right }, row)
		for i, b in ipairs(o.Buttons) do
			local btn = new("TextButton", {
				Size = UDim2.new(0, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Font = Enum.Font.BuilderSansMedium,
				TextSize = 11,
				Text = "  " .. tostring(b.Text or b.Title or "OK") .. "  ",
				LayoutOrder = i,
			}, row)
			new("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
			if b.Primary then
				btn.BackgroundColor3 = typeColor(kind)
				bind(btn, "TextColor3", "OnAccent")
			else
				bind(btn, "BackgroundColor3", "Element")
				bind(btn, "TextColor3", "Text")
			end
			btn.Activated:Connect(function()
				dismiss()
				if b.Callback then task.spawn(b.Callback) end
			end)
		end
	end

	close.Activated:Connect(dismiss)

	if self.Config.HoverPause and not Touch then
		card.MouseEnter:Connect(function() paused = true end)
		card.MouseLeave:Connect(function() paused = false end)
	end

	if o.Swipe ~= false then
		local startX, dragging
		card.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch then
				startX = i.Position.X
				dragging = true
				paused = true
			end
		end)
		card.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch and dragging then
				dragging = false
				paused = false
				if startX and startX - i.Position.X > 40 then dismiss() end
			end
		end)
	end

	while #Active >= self.Config.MaxVisible do
		local oldest = table.remove(Active, 1)
		if oldest and oldest:FindFirstChildWhichIsA("Frame") then
			local c = oldest:FindFirstChildWhichIsA("Frame")
			tween(c, { Position = UDim2.new(0, -(self.Config.Width + 40), 0, 0) }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.2, function() if oldest.Parent then oldest:Destroy() end end)
		end
	end
	Active[#Active + 1] = wrap

	tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.32, Enum.EasingStyle.Back)

	if duration > 0 then
		conn = RunService.Heartbeat:Connect(function(dt)
			if closed then return end
			if paused then return end
			elapsed += dt
			local p = math.clamp(1 - elapsed / duration, 0, 1)
			bar.Size = UDim2.new(p, 0, 0, 2)
			if elapsed >= duration then dismiss() end
		end)
	end

	local handle = { Dismiss = dismiss }
	function handle.Update(n)
		if closed or type(n) ~= "table" then return end
		if n.Type and Notify.Types[n.Type] then
			kind = n.Type
			local c = typeColor(kind)
			accent.BackgroundColor3 = c
			badge.BackgroundColor3 = c
			bar.BackgroundColor3 = c
			if glyph:IsA("TextLabel") then
				glyph.Text = Notify.Glyphs[kind]
				glyph.TextColor3 = c
			else
				glyph.ImageColor3 = c
			end
		end
		if n.Title then title.Text = tostring(n.Title) end
		if n.Content then
			content.Text = tostring(n.Content)
			content.Visible = true
		end
		if n.SubContent then
			sub.Text = tostring(n.SubContent)
			sub.Visible = true
		end
	end
	return handle
end

for kind in pairs(Notify.Types) do
	Notify[kind] = function(self, title, content, duration)
		return self:Send({ Type = kind, Title = title, Content = content, Duration = duration })
	end
end

function Notify:SetTheme(t)
	if type(t) ~= "table" then return end
	for k, v in pairs(t) do
		if typeof(v) == "Color3" then self.Theme[k] = v end
	end
	local alive = {}
	for _, b in ipairs(Bindings) do
		if b.o and b.o.Parent then
			b.o[b.p] = self.Theme[b.k]
			alive[#alive + 1] = b
		end
	end
	Bindings = alive
end

function Notify:SetPosition(x, y)
	self.Config.OffsetX = x or self.Config.OffsetX
	self.Config.OffsetY = y or self.Config.OffsetY
	Holder.Position = UDim2.fromOffset(self.Config.OffsetX, self.Config.OffsetY)
end

function Notify:SetScale(s)
	local sc = Gui:FindFirstChild("Scale") or new("UIScale", { Name = "Scale" }, Gui)
	sc.Scale = math.clamp(tonumber(s) or 1, 0.6, 1.6)
end

function Notify:ClearAll()
	for _, w in ipairs(Active) do
		if w and w.Parent then w:Destroy() end
	end
	table.clear(Active)
end

function Notify:Destroy()
	Dead = true
	self:ClearAll()
	if Gui then Gui:Destroy() end
	if env.MXNotify == self then env.MXNotify = nil end
end

env.MXNotify = Notify

return Notify
