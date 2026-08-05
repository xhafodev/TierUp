--[[
	TierUp library

	Usage:
		local TierUp = require(path.to.library)

		TierUp.new({
			Title = "My UI",
			Tabs = { "tab 1", "tab 2" },
			Theme = "TierUp",
			OnLoad = function(L) ... end,
		})

	Place icons.lua as a sibling ModuleScript named "icons" (optional).
]]

local TierUp = {}

function TierUp.new(config)
	config = config or {}

	local cloneref = cloneref or function(obj)
		return obj
	end

	local Players = cloneref(game:GetService("Players"))
	local UserInputService = cloneref(game:GetService("UserInputService"))
	local TweenService = cloneref(game:GetService("TweenService"))
	local RunService = cloneref(game:GetService("RunService"))
	local HttpService = cloneref(game:GetService("HttpService"))
	local player = cloneref(Players.LocalPlayer)
	local mouse = cloneref(player:GetMouse())
	local playerGui = cloneref(player:WaitForChild("PlayerGui"))

	local function loadIcons()
		if config and config.Icons then
			return config.Icons
		end
		local okScript, scriptObj = pcall(function()
			return script
		end)
		if okScript and scriptObj then
			local candidates = {}
			local child = scriptObj:FindFirstChild("icons")
			if child then table.insert(candidates, child) end
			if scriptObj.Parent then
				local sib = scriptObj.Parent:FindFirstChild("icons")
				if sib then table.insert(candidates, sib) end
			end
			for _, mod in ipairs(candidates) do
				if mod:IsA("ModuleScript") then
					local ok, result = pcall(require, mod)
					if ok and type(result) == "table" then
						return result
					end
				end
			end
		end
		return {
			plus = "rbxassetid://111774323017047",
			minus = "rbxassetid://118026365011536",
			check = "rbxassetid://93898873302694",
			keyboard = "rbxassetid://121474456068237",
		}
	end

	local Icons = loadIcons()

	local ACCENT = Color3.fromRGB(163, 188, 199)

	local COLORS = {
		MainBg      = Color3.fromRGB(49, 49, 49),
		HeaderBg    = Color3.fromRGB(0, 0, 0),
		GroupBg     = Color3.fromRGB(82, 82, 82),
		GroupHeader = Color3.fromRGB(42, 42, 42),
		ControlBg   = Color3.fromRGB(40, 40, 40),
		TabBg       = Color3.fromRGB(84, 84, 84),
		Text        = Color3.fromRGB(255, 255, 255),
		Accent      = ACCENT,
		ToggleOff   = Color3.fromRGB(40, 40, 40),
		TrackBg     = Color3.fromRGB(55, 55, 55),
	}

	local FONT = Enum.Font.FredokaOne
	local SHADOW_IMAGE = "rbxassetid://6014261993"

	local function corner(parent, radius)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, radius)
		c.Parent = parent
		return c
	end

	local function label(parent, props)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Font = FONT
		l.TextColor3 = props.TextColor3 or COLORS.Text
		l.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
		l.TextYAlignment = Enum.TextYAlignment.Center
		l.TextSize = props.TextSize or 14
		l.Text = props.Text or ""
		l.Size = props.Size or UDim2.new(1, 0, 0, 20)
		l.Position = props.Position or UDim2.new(0, 0, 0, 0)
		l.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
		l.ZIndex = props.ZIndex or (parent.ZIndex + 1)
		l.Name = props.Name or "Label"
		l.Parent = parent
		return l
	end

	local function UIShadow(parent, opts)
		opts = opts or {}
		local spread = opts.Spread or 24
		local shadow = Instance.new("ImageLabel")
		shadow.Name = "UIShadow"
		shadow.Image = SHADOW_IMAGE
		shadow.ImageColor3 = Color3.new(0, 0, 0)
		shadow.ImageTransparency = opts.Transparency or 0.45
		shadow.BackgroundTransparency = 1
		shadow.ScaleType = Enum.ScaleType.Slice
		shadow.SliceCenter = Rect.new(49, 49, 450, 450)
		shadow.Size = UDim2.new(1, spread, 1, spread)
		shadow.Position = UDim2.new(0.5, 0, 0.5, opts.OffsetY or 4)
		shadow.AnchorPoint = Vector2.new(0.5, 0.5)
		shadow.ZIndex = math.max(parent.ZIndex - 1, 0)
		shadow.Parent = parent
		return shadow
	end

	local function iconImage(parent, iconName, props)
		props = props or {}
		local img = Instance.new("ImageLabel")
		img.Name = props.Name or "Icon"
		img.BackgroundTransparency = 1
		img.Image = Icons[iconName] or ""
		img.ImageColor3 = props.ImageColor3 or COLORS.Text
		img.ScaleType = Enum.ScaleType.Fit
		img.Size = props.Size or UDim2.fromOffset(14, 14)
		img.Position = props.Position or UDim2.new(0.5, 0, 0.5, 0)
		img.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
		img.ZIndex = props.ZIndex or (parent.ZIndex + 1)
		img.Parent = parent
		return img
	end

	local function makeButton(parent, props)
		local btn = Instance.new("TextButton")
		btn.Name = props.Name or "Button"
		btn.AutoButtonColor = false
		btn.Font = FONT
		btn.Text = props.Text or ""
		btn.TextColor3 = props.TextColor3 or COLORS.Text
		btn.TextSize = props.TextSize or 14
		btn.BackgroundColor3 = props.BackgroundColor3 or COLORS.ControlBg
		btn.Size = props.Size
		btn.Position = props.Position or UDim2.new(0, 0, 0, 0)
		btn.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
		btn.ZIndex = props.ZIndex or (parent.ZIndex + 1)
		btn.BorderSizePixel = 0
		btn.Parent = parent
		corner(btn, props.Corner or 8)
		if props.Shadow ~= false then
			UIShadow(btn, { Spread = props.ShadowSpread or 18, Transparency = 0.5, OffsetY = 3 })
		end

		local scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = btn

		local function currentBase()
			return COLORS.ControlBg
		end

		local function setScale(s)
			TweenService:Create(scale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = s,
			}):Play()
		end

		btn.MouseEnter:Connect(function()
			local base = currentBase()
			TweenService:Create(btn, TweenInfo.new(0.12), {
				BackgroundColor3 = Color3.fromRGB(
					math.min(255, base.R * 255 + 18),
					math.min(255, base.G * 255 + 18),
					math.min(255, base.B * 255 + 18)
				),
			}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = currentBase() }):Play()
			setScale(1)
		end)
		btn.MouseButton1Down:Connect(function()
			setScale(0.97)
		end)
		btn.MouseButton1Up:Connect(function()
			setScale(1)
		end)

		return btn
	end

	local CONTROL_SIZE = UDim2.new(0.48, 0, 0, 30)
	local CONTROL_CORNER = 7
	local CONTROL_SHADOW = { Spread = 18, Transparency = 0.45, OffsetY = 3 }

	local themeRefreshers = {}
	local function bindThemeRefresh(fn)
		table.insert(themeRefreshers, fn)
	end

	local pushNotification

	local function matteControl(parent, name)
		local shell = Instance.new("Frame")
		shell.Name = name
		shell.Size = CONTROL_SIZE
		shell.Position = UDim2.new(1, 0, 0.5, 0)
		shell.AnchorPoint = Vector2.new(1, 0.5)
		shell.BackgroundColor3 = COLORS.ControlBg
		shell.BorderSizePixel = 0
		shell.ZIndex = 15
		shell.ClipsDescendants = false
		shell.Parent = parent
		corner(shell, CONTROL_CORNER)
		UIShadow(shell, CONTROL_SHADOW)
		return shell
	end

	local function isInteractiveUnder(pos, root)
		for _, obj in ipairs(playerGui:GetGuiObjectsAtPosition(pos.X, pos.Y)) do
			if obj:IsDescendantOf(root) then
				if obj:IsA("GuiButton") or obj:IsA("TextBox") then
					return true
				end
			end
		end
		return false
	end

	local existing = playerGui:FindFirstChild("TierUp")
	if existing then existing:Destroy() end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TierUp"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 100
	screenGui.Parent = playerGui

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.fromOffset(700, 500)
	main.Position = UDim2.new(0.5, 0, 0.5, 0)
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.BackgroundColor3 = COLORS.MainBg
	main.BorderSizePixel = 0
	main.ZIndex = 10
	main.ClipsDescendants = false
	main.Parent = screenGui
	corner(main, 14)
	UIShadow(main, { Spread = 40, Transparency = 0.35, OffsetY = 8 })

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 37)
	header.BackgroundColor3 = COLORS.HeaderBg
	header.BorderSizePixel = 0
	header.ZIndex = 11
	header.Parent = main
	corner(header, 14)

	local headerFill = Instance.new("Frame")
	headerFill.Size = UDim2.new(1, 0, 0, 12)
	headerFill.Position = UDim2.new(0, 0, 1, -12)
	headerFill.BackgroundColor3 = COLORS.HeaderBg
	headerFill.BorderSizePixel = 0
	headerFill.ZIndex = 11
	headerFill.Parent = header

	label(header, {
		Name = "Title",
		Text = "TierUp",
		TextSize = 18,
		Size = UDim2.new(0, 160, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		ZIndex = 12,
	})

	local tabRow = Instance.new("Frame")
	tabRow.Name = "Tabs"
	tabRow.BackgroundTransparency = 1
	tabRow.Size = UDim2.fromOffset(252, 24)
	tabRow.Position = UDim2.new(1, -14, 0.5, 0)
	tabRow.AnchorPoint = Vector2.new(1, 0.5)
	tabRow.ZIndex = 12
	tabRow.Parent = header

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabLayout.Padding = UDim.new(0, 6)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabRow

	local pagesFolder = Instance.new("Folder")
	pagesFolder.Name = "Pages"
	pagesFolder.Parent = main

	local BODY_TOP = 37 + 6
	local SIDE_PAD = 13
	local GAP = 8
	local BOTTOM_PAD = 7
	local GB_W, GB_H = 333, 450
	local MIN_MAIN_W, MIN_MAIN_H = 440, 250

	local function updateMainLayout()
		local mainW = main.AbsoluteSize.X
		local mainH = main.AbsoluteSize.Y

		GB_W = math.max(160, math.floor((mainW - (SIDE_PAD * 2) - GAP) / 2))
		GB_H = math.max(120, mainH - BODY_TOP - BOTTOM_PAD)

		for _, page in ipairs(pages) do
			local gb1 = page:FindFirstChild("Groupbox1")
			local gb2 = page:FindFirstChild("Groupbox2")
			if gb1 then
				gb1.Size = UDim2.fromOffset(GB_W, GB_H)
				gb1.Position = UDim2.fromOffset(SIDE_PAD, BODY_TOP)
			end
			if gb2 then
				gb2.Size = UDim2.fromOffset(GB_W, GB_H)
				gb2.Position = UDim2.fromOffset(SIDE_PAD + GB_W + GAP, BODY_TOP)
			end
		end
	end

	local function makeGroupbox(parent, name, title, x)
		local gb = Instance.new("Frame")
		gb.Name = name
		gb.Size = UDim2.fromOffset(GB_W, GB_H)
		gb.Position = UDim2.fromOffset(x, BODY_TOP)
		gb.BackgroundColor3 = COLORS.GroupBg
		gb.BorderSizePixel = 0
		gb.ZIndex = 12
		gb.ClipsDescendants = false
		gb.Parent = parent
		corner(gb, 12)

		local gh = Instance.new("Frame")
		gh.Name = "GroupHeader"
		gh.Size = UDim2.new(1, 0, 0, 36)
		gh.BackgroundColor3 = COLORS.GroupHeader
		gh.BorderSizePixel = 0
		gh.ZIndex = 13
		gh.Parent = gb
		corner(gh, 12)

		local ghFill = Instance.new("Frame")
		ghFill.Size = UDim2.new(1, 0, 0, 14)
		ghFill.Position = UDim2.new(0, 0, 1, -14)
		ghFill.BackgroundColor3 = COLORS.GroupHeader
		ghFill.BorderSizePixel = 0
		ghFill.ZIndex = 13
		ghFill.Parent = gh

		label(gh, {
			Name = "GroupTitle",
			Text = title,
			TextSize = 15,
			Size = UDim2.new(1, 0, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 14,
		})

		local content = Instance.new("Frame")
		content.Name = "Content"
		content.BackgroundTransparency = 1
		content.Size = UDim2.new(1, -28, 1, -52)
		content.Position = UDim2.fromOffset(14, 44)
		content.ZIndex = 13
		content.Parent = gb

		return gb, content
	end

	local tabButtons = {}
	local pages = {}
	local activeTab = 1

	local function setActiveTab(index)
		activeTab = index
		for i, btn in ipairs(tabButtons) do
			local active = (i == index)
			btn.TextColor3 = active and COLORS.Accent or COLORS.Text
		end
		for i, page in ipairs(pages) do
			page.Visible = (i == index)
		end
	end

	local tabNames = config.Tabs or { "tab 1" }

	for i, tabName in ipairs(tabNames) do
		local tab = Instance.new("TextButton")
		tab.Name = "Tab" .. i
		tab.AutoButtonColor = false
		tab.Font = FONT
		tab.Text = tabName
		tab.TextColor3 = COLORS.Text
		tab.TextSize = 12
		tab.Size = UDim2.fromOffset(80, 24)
		tab.BackgroundColor3 = COLORS.TabBg
		tab.BorderSizePixel = 0
		tab.ZIndex = 13
		tab.LayoutOrder = i
		tab.Parent = tabRow
		corner(tab, 3)
		tab.MouseButton1Click:Connect(function()
			setActiveTab(i)
		end)
		tabButtons[i] = tab

		local page = Instance.new("Frame")
		page.Name = "Page" .. i
		page.BackgroundTransparency = 1
		page.Size = UDim2.fromScale(1, 1)
		page.Visible = (i == 1)
		page.ZIndex = 12
		page.Parent = pagesFolder
		pages[i] = page
	end

	local NOTIF_W = 280
	local NOTIF_H = 40
	local NOTIF_GAP = 6
	local NOTIF_PAD = 14
	local NOTIF_DURATION = 3.2
	local NOTIF_BAR_H = 4
	local notifStack = {}

	local function restackNotifications()
		for i, item in ipairs(notifStack) do
			local targetY = NOTIF_PAD + (i - 1) * (NOTIF_H + NOTIF_GAP)
			TweenService:Create(item, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(1, -NOTIF_PAD, 0, targetY),
			}):Play()
		end
	end

	pushNotification = function(text)
		local n = Instance.new("Frame")
		n.Name = "Notification"
		n.Size = UDim2.fromOffset(NOTIF_W, NOTIF_H)
		n.AnchorPoint = Vector2.new(1, 0)
		n.Position = UDim2.new(1, NOTIF_W + 40, 0, NOTIF_PAD + #notifStack * (NOTIF_H + NOTIF_GAP))
		n.BackgroundColor3 = COLORS.MainBg
		n.BorderSizePixel = 0
		n.ZIndex = 600
		n.ClipsDescendants = true
		n.Parent = screenGui

		label(n, {
			Name = "Message",
			Text = text,
			TextSize = 14,
			Size = UDim2.new(1, -20, 1, -(NOTIF_BAR_H + 4)),
			Position = UDim2.fromOffset(12, -1),
			ZIndex = 601,
		})

		local timerTrack = Instance.new("Frame")
		timerTrack.Name = "TimerTrack"
		timerTrack.Size = UDim2.new(1, 0, 0, NOTIF_BAR_H)
		timerTrack.Position = UDim2.new(0, 0, 1, -NOTIF_BAR_H)
		timerTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		timerTrack.BorderSizePixel = 0
		timerTrack.ZIndex = 601
		timerTrack.ClipsDescendants = true
		timerTrack.Parent = n

		local timerFill = Instance.new("Frame")
		timerFill.Name = "TimerFill"
		timerFill.AnchorPoint = Vector2.new(1, 0)
		timerFill.Position = UDim2.new(1, 0, 0, 0)
		timerFill.Size = UDim2.new(1, 0, 1, 0)
		timerFill.BackgroundColor3 = COLORS.Accent
		timerFill.BorderSizePixel = 0
		timerFill.ZIndex = 602
		timerFill.Parent = timerTrack

		table.insert(notifStack, n)
		restackNotifications()

		TweenService:Create(n, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -NOTIF_PAD, 0, NOTIF_PAD + (#notifStack - 1) * (NOTIF_H + NOTIF_GAP)),
		}):Play()

		local timerTween = TweenService:Create(timerFill, TweenInfo.new(NOTIF_DURATION, Enum.EasingStyle.Linear), {
			Size = UDim2.new(0, 0, 1, 0),
		})
		timerTween:Play()
		timerTween.Completed:Connect(function()
			local idx = table.find(notifStack, n)
			if idx then
				table.remove(notifStack, idx)
			end
			local out = TweenService:Create(n, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(1, NOTIF_W + 40, 0, n.Position.Y.Offset),
			})
			out:Play()
			out.Completed:Connect(function()
				n:Destroy()
				restackNotifications()
			end)
		end)
	end
	setActiveTab(1)

	local colorModalClose = nil
	local colorModal = Instance.new("TextButton")
	colorModal.Name = "ColorPickerModal"
	colorModal.Size = UDim2.fromScale(1, 1)
	colorModal.BackgroundTransparency = 1
	colorModal.Text = ""
	colorModal.AutoButtonColor = false
	colorModal.Visible = false
	colorModal.Active = true
	colorModal.ZIndex = 510
	colorModal.Parent = screenGui
	colorModal.MouseButton1Click:Connect(function()
		if colorModalClose then
			colorModalClose()
		end
	end)

	local function bindColorPickerModal(picker, isOpen, setOpenFn)
		picker.Active = true
		local function closeFromModal()
			setOpenFn(false)
		end
		return function(state)
			if state then
				if colorModalClose and colorModalClose ~= closeFromModal then
					colorModalClose()
				end
				colorModalClose = closeFromModal
				colorModal.Visible = true
				picker.Visible = true
			else
				picker.Visible = false
				if colorModalClose == closeFromModal then
					colorModalClose = nil
					colorModal.Visible = false
				end
			end
		end
	end

	local colorClipboard = nil
	local activeColorMenuClose = nil

	local function colorToHex(col)
		return string.format(
			"#%02X%02X%02X",
			math.floor(col.R * 255 + 0.5),
			math.floor(col.G * 255 + 0.5),
			math.floor(col.B * 255 + 0.5)
		)
	end

	local function colorToRgbText(col)
		return string.format(
			"%d, %d, %d",
			math.floor(col.R * 255 + 0.5),
			math.floor(col.G * 255 + 0.5),
			math.floor(col.B * 255 + 0.5)
		)
	end

	local function parseHexColor(str)
		if type(str) ~= "string" then return nil end
		str = str:gsub("%s+", ""):gsub("^#", "")
		if #str == 3 then
			str = str:sub(1, 1):rep(2) .. str:sub(2, 2):rep(2) .. str:sub(3, 3):rep(2)
		end
		if #str ~= 6 or not str:match("^%x%x%x%x%x%x$") then
			return nil
		end
		return Color3.fromRGB(
			tonumber(str:sub(1, 2), 16),
			tonumber(str:sub(3, 4), 16),
			tonumber(str:sub(5, 6), 16)
		)
	end

	local function parseRgbColor(str)
		if type(str) ~= "string" then return nil end
		local r, g, b = str:match("^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$")
		if not r then
			r, g, b = str:match("^%s*(%d+)%s+(%d+)%s+(%d+)%s*$")
		end
		if not r then return nil end
		return Color3.fromRGB(
			math.clamp(tonumber(r), 0, 255),
			math.clamp(tonumber(g), 0, 255),
			math.clamp(tonumber(b), 0, 255)
		)
	end

	local function hideColorContextMenu()
		if not activeColorMenuClose then return end
		local close = activeColorMenuClose
		activeColorMenuClose = nil
		close()
	end

	local function bindColorContextMenu(swatch, getColor, setColor)
		local actions = { "copy", "paste" }
		local ITEM_H = 26
		local MENU_W = 80
		local open = false
		local menuTween = nil

		local menu = Instance.new("Frame")
		menu.Name = "ColorActionWindow"
		menu.BackgroundColor3 = COLORS.ControlBg
		menu.BorderSizePixel = 0
		menu.Visible = false
		menu.ClipsDescendants = true
		menu.AnchorPoint = Vector2.new(1, 0)
		menu.Position = UDim2.new(1, 0, 1, 4)
		menu.Size = UDim2.fromOffset(MENU_W, 0)
		menu.ZIndex = 500
		menu.Parent = swatch
		corner(menu, CONTROL_CORNER)

		local inner = Instance.new("Frame")
		inner.Name = "Inner"
		inner.BackgroundColor3 = COLORS.ControlBg
		inner.BorderSizePixel = 0
		inner.Size = UDim2.new(1, 0, 0, #actions * ITEM_H)
		inner.ZIndex = 501
		inner.Parent = menu
		corner(inner, CONTROL_CORNER)

		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = inner

		local function setOpen(state)
			if state == open then return end
			open = state
			if menuTween then
				menuTween:Cancel()
				menuTween = nil
			end
			menu.BackgroundColor3 = COLORS.ControlBg
			inner.BackgroundColor3 = COLORS.ControlBg
			if open then
				if activeColorMenuClose then
					local prev = activeColorMenuClose
					activeColorMenuClose = nil
					prev()
				end
				activeColorMenuClose = function()
					if open then
						setOpen(false)
					end
				end
				menu.Size = UDim2.fromOffset(MENU_W, 0)
				menu.Visible = true
				menu.ZIndex = 500
				menuTween = TweenService:Create(menu, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.fromOffset(MENU_W, #actions * ITEM_H),
				})
				menuTween:Play()
			else
				if activeColorMenuClose then
					activeColorMenuClose = nil
				end
				menuTween = TweenService:Create(menu, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Size = UDim2.fromOffset(MENU_W, 0),
				})
				menuTween:Play()
				menuTween.Completed:Connect(function()
					if not open then
						menu.Visible = false
					end
				end)
			end
		end

		for i, actionName in ipairs(actions) do
			local opt = Instance.new("TextButton")
			opt.Name = actionName
			opt.AutoButtonColor = false
			opt.Font = FONT
			opt.Text = actionName
			opt.TextColor3 = COLORS.Text
			opt.TextSize = 12
			opt.BackgroundColor3 = COLORS.ControlBg
			opt.BorderSizePixel = 0
			opt.Size = UDim2.new(1, 0, 0, ITEM_H)
			opt.ZIndex = 502
			opt.LayoutOrder = i
			opt.Parent = inner
			corner(opt, 5)

			opt.MouseEnter:Connect(function()
				opt.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
				opt.TextColor3 = COLORS.Accent
			end)
			opt.MouseLeave:Connect(function()
				opt.BackgroundColor3 = COLORS.ControlBg
				opt.TextColor3 = COLORS.Text
			end)
			opt.MouseButton1Click:Connect(function()
				if actionName == "copy" then
					colorClipboard = getColor()
					local hex = colorToHex(colorClipboard)
					pcall(function()
						local g = getgenv and getgenv()
						local fn = (g and g.setclipboard) or setclipboard
						if type(fn) == "function" then
							fn(hex)
						end
					end)
					if pushNotification then
						pushNotification("copied " .. hex)
					end
				elseif actionName == "paste" then
					if colorClipboard then
						setColor(colorClipboard)
						if pushNotification then
							pushNotification("pasted " .. colorToHex(colorClipboard))
						end
					elseif pushNotification then
						pushNotification("clipboard empty")
					end
				end
				setOpen(false)
			end)
		end

		swatch.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				setOpen(not open)
			end
		end)

		UserInputService.InputBegan:Connect(function(input)
			if not open then return end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local objs = playerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
			for _, obj in ipairs(objs) do
				if obj:IsDescendantOf(menu) or obj == swatch then
					return
				end
			end
			setOpen(false)
		end)

		bindThemeRefresh(function()
			menu.BackgroundColor3 = COLORS.ControlBg
			inner.BackgroundColor3 = COLORS.ControlBg
			for _, child in ipairs(inner:GetChildren()) do
				if child:IsA("TextButton") then
					child.BackgroundColor3 = COLORS.ControlBg
					child.TextColor3 = COLORS.Text
				end
			end
		end)
	end

	local function addColorValueFields(picker, pad, width, topY, zBase, onColorParsed, getColor)
		local FIELD_H = 20
		local GAP = 4
		local editing = false

		local function makeField(name, placeholder, order)
			local box = Instance.new("TextBox")
			box.Name = name
			box.Font = FONT
			box.PlaceholderText = placeholder
			box.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
			box.Text = ""
			box.TextColor3 = COLORS.Text
			box.TextSize = 12
			box.ClearTextOnFocus = false
			box.BackgroundColor3 = COLORS.ControlBg
			box.BorderSizePixel = 0
			box.Size = UDim2.new(1, -(pad * 2), 0, FIELD_H)
			box.Position = UDim2.fromOffset(pad, topY + (order - 1) * (FIELD_H + GAP))
			box.TextXAlignment = Enum.TextXAlignment.Left
			box.TextYAlignment = Enum.TextYAlignment.Center
			box.ZIndex = zBase
			box.Parent = picker
			corner(box, 4)
			local p = Instance.new("UIPadding")
			p.PaddingLeft = UDim.new(0, 8)
			p.PaddingRight = UDim.new(0, 8)
			p.Parent = box
			return box
		end

		local hexBox = makeField("HexField", "hex", 1)
		local rgbBox = makeField("RgbField", "rgb", 2)

		local function updateFields(col)
			if editing then return end
			hexBox.Text = colorToHex(col)
			rgbBox.Text = colorToRgbText(col)
		end

		local function revertFields()
			if getColor then
				updateFields(getColor())
			end
		end

		local function tryApply(col)
			if not col then return end
			editing = true
			onColorParsed(col)
			hexBox.Text = colorToHex(col)
			rgbBox.Text = colorToRgbText(col)
			editing = false
		end

		hexBox.FocusLost:Connect(function()
			local col = parseHexColor(hexBox.Text)
			if col then
				tryApply(col)
			else
				revertFields()
			end
		end)

		rgbBox.FocusLost:Connect(function()
			local col = parseRgbColor(rgbBox.Text)
			if col then
				tryApply(col)
			else
				revertFields()
			end
		end)

		return {
			Height = FIELD_H * 2 + GAP,
			Update = updateFields,
			HexBox = hexBox,
			RgbBox = rgbBox,
		}
	end

	local function themePack(accent, main, group, header, control, tab)
		return {
			MainBg = main,
			HeaderBg = header,
			GroupBg = group,
			GroupHeader = Color3.fromRGB(
				math.max(0, math.floor(group.R * 255 * 0.55)),
				math.max(0, math.floor(group.G * 255 * 0.55)),
				math.max(0, math.floor(group.B * 255 * 0.55))
			),
			ControlBg = control,
			TabBg = tab,
			Accent = accent,
			TrackBg = Color3.fromRGB(
				math.min(255, math.floor(control.R * 255 + 12)),
				math.min(255, math.floor(control.G * 255 + 12)),
				math.min(255, math.floor(control.B * 255 + 12))
			),
			ToggleOff = control,
			Text = Color3.fromRGB(255, 255, 255),
		}
	end

	local THEMES = {
		TierUp = themePack(
			Color3.fromRGB(163, 188, 199),
			Color3.fromRGB(49, 49, 49),
			Color3.fromRGB(82, 82, 82),
			Color3.fromRGB(0, 0, 0),
			Color3.fromRGB(40, 40, 40),
			Color3.fromRGB(84, 84, 84)
		),
		Gamesense = themePack(
			Color3.fromRGB(163, 255, 100),
			Color3.fromRGB(22, 22, 22),
			Color3.fromRGB(32, 32, 32),
			Color3.fromRGB(12, 12, 12),
			Color3.fromRGB(26, 26, 26),
			Color3.fromRGB(38, 38, 38)
		),
		Neverlose = themePack(
			Color3.fromRGB(0, 150, 255),
			Color3.fromRGB(18, 18, 26),
			Color3.fromRGB(28, 28, 40),
			Color3.fromRGB(10, 10, 16),
			Color3.fromRGB(22, 22, 32),
			Color3.fromRGB(36, 36, 52)
		),
		Fatality = themePack(
			Color3.fromRGB(220, 50, 70),
			Color3.fromRGB(24, 18, 18),
			Color3.fromRGB(40, 28, 28),
			Color3.fromRGB(12, 8, 8),
			Color3.fromRGB(32, 22, 22),
			Color3.fromRGB(48, 32, 32)
		),
		Onetap = themePack(
			Color3.fromRGB(255, 140, 0),
			Color3.fromRGB(20, 20, 20),
			Color3.fromRGB(34, 34, 34),
			Color3.fromRGB(10, 10, 10),
			Color3.fromRGB(28, 28, 28),
			Color3.fromRGB(44, 44, 44)
		),
		Ryfk7 = themePack(
			Color3.fromRGB(180, 70, 255),
			Color3.fromRGB(16, 14, 22),
			Color3.fromRGB(30, 26, 40),
			Color3.fromRGB(8, 6, 12),
			Color3.fromRGB(24, 20, 32),
			Color3.fromRGB(42, 36, 55)
		),
		ChudVision = themePack(
			Color3.fromRGB(255, 214, 90),
			Color3.fromRGB(18, 18, 14),
			Color3.fromRGB(36, 34, 24),
			Color3.fromRGB(8, 8, 6),
			Color3.fromRGB(28, 26, 18),
			Color3.fromRGB(48, 44, 28)
		),
		Calamari = themePack(
			Color3.fromRGB(255, 90, 130),
			Color3.fromRGB(20, 14, 18),
			Color3.fromRGB(38, 26, 32),
			Color3.fromRGB(10, 6, 8),
			Color3.fromRGB(30, 20, 26),
			Color3.fromRGB(52, 34, 42)
		),
		CompKiller = themePack(
			Color3.fromRGB(80, 220, 180),
			Color3.fromRGB(14, 18, 18),
			Color3.fromRGB(26, 34, 32),
			Color3.fromRGB(6, 10, 10),
			Color3.fromRGB(20, 28, 26),
			Color3.fromRGB(34, 48, 44)
		),
		NixWare = themePack(
			Color3.fromRGB(100, 180, 255),
			Color3.fromRGB(15, 17, 22),
			Color3.fromRGB(28, 32, 42),
			Color3.fromRGB(8, 9, 12),
			Color3.fromRGB(22, 25, 34),
			Color3.fromRGB(40, 46, 60)
		),
	}

	local THEME_ORDER = {
		"TierUp", "Gamesense", "Neverlose", "Fatality", "Onetap",
		"Ryfk7", "ChudVision", "Calamari", "CompKiller", "NixWare",
	}

	local Theme = {
		current = "TierUp",
		swatches = {},
		dropdownValue = nil,
	}

	local function colorEquals(a, b)
		return math.abs(a.R - b.R) < 0.004
			and math.abs(a.G - b.G) < 0.004
			and math.abs(a.B - b.B) < 0.004
	end

	local function themeMatches(name)
		local t = THEMES[name]
		if not t then return false end
		for k, v in pairs(t) do
			if COLORS[k] and not colorEquals(COLORS[k], v) then
				return false
			end
		end
		return true
	end

	local function updateThemesDropdownLabel()
		if not Theme.dropdownValue then return end
		if Theme.current ~= "custom" and themeMatches(Theme.current) then
			Theme.dropdownValue.Text = Theme.current
			return
		end
		for _, name in ipairs(THEME_ORDER) do
			if themeMatches(name) then
				Theme.current = name
				Theme.dropdownValue.Text = name
				return
			end
		end
		Theme.current = "custom"
		Theme.dropdownValue.Text = "custom"
	end

	local function applyTheme(themeName, skipSwatchSync)
		if themeName and themeName ~= "custom" and THEMES[themeName] then
			Theme.current = themeName
			for k, v in pairs(THEMES[themeName]) do
				COLORS[k] = v
			end
		elseif themeName == "custom" then
			Theme.current = "custom"
		end

		main.BackgroundColor3 = COLORS.MainBg
		header.BackgroundColor3 = COLORS.HeaderBg
		headerFill.BackgroundColor3 = COLORS.HeaderBg

		for _, d in ipairs(screenGui:GetDescendants()) do
			if d.Name == "Groupbox1" or d.Name == "Groupbox2" then
				if d:IsA("Frame") then d.BackgroundColor3 = COLORS.GroupBg end
			elseif d.Name == "GroupHeader" then
				d.BackgroundColor3 = COLORS.GroupHeader
			elseif d.Name:match("^Tab%d+$") and d:IsA("TextButton") then
				d.BackgroundColor3 = COLORS.TabBg
			elseif d.Name == "Watermark" or d.Name == "Keybinds" or d.Name == "Notification" then
				d.BackgroundColor3 = COLORS.MainBg
			elseif d.Name == "Topbar" or d.Name == "TopbarFill" or d.Name == "HeaderFill" then
				d.BackgroundColor3 = COLORS.HeaderBg
			elseif d.Name == "Dropdown" or d.Name == "TextField" or d.Name == "KeybindField"
				or d.Name == "ActionButton" or d.Name == "NotificationButton" or d.Name == "TimerButton"
				or d.Name == "ModeWindow" or d.Name == "Inner" or d.Name == "DropdownOptions"
				or d.Name == "ThemesDropdown" or d.Name == "ThemesOptions" or d.Name == "MultiDropdown"
				or d.Name == "ConfigDropdown" or d.Name == "ConfigOptions" or d.Name == "ConfigName"
				or d.Name == "ConfigCreate" or d.Name == "ConfigLoad" or d.Name == "ConfigOverwrite"
				or d.Name == "HexField" or d.Name == "RgbField" or d.Name == "ColorActionWindow"
				or d.Name == "copy" or d.Name == "paste"
				or d.Name:match("^Opt") or d.Name:match("^ThemeOpt") or d.Name:match("^ConfigOpt")
				or d.Name == "hold" or d.Name == "toggle" or d.Name == "always" then
				if d:IsA("GuiObject") and d.BackgroundTransparency < 0.5 then
					d.BackgroundColor3 = COLORS.ControlBg
				end
				if (d:IsA("TextButton") or d:IsA("TextLabel")) and d:GetAttribute("AccentText") then
					d.TextColor3 = COLORS.Accent
				elseif d:IsA("TextButton") and (d.Name:match("^Opt") or d.Name:match("^ThemeOpt") or d.Name:match("^ConfigOpt")) then
					d.TextColor3 = COLORS.Text
				end
			elseif d.Name == "Track" or d.Name == "TimerTrack" then
				d.BackgroundColor3 = COLORS.TrackBg
			elseif d.Name == "Fill" and d.Parent and d.Parent.Name == "Track" then
				d.BackgroundColor3 = COLORS.Accent
			elseif d.Name == "TimerFill" then
				d.BackgroundColor3 = COLORS.Accent
			elseif d.Name == "Toggle" and d:IsA("GuiButton") then
				d.BackgroundColor3 = d:GetAttribute("On") and COLORS.Accent or COLORS.ToggleOff
			elseif d.Name == "Check" and d:IsA("TextLabel") then
				d.TextColor3 = COLORS.Accent
			elseif d.Name == "Value" and d:IsA("TextLabel") and d.Parent and d.Parent.Name == "SliderBlock" then
				d.TextColor3 = COLORS.Accent
			elseif d:GetAttribute("AccentText") and (d:IsA("TextLabel") or d:IsA("TextButton")) then
				d.TextColor3 = COLORS.Accent
			elseif d:IsA("Frame") and d.Parent and d.Parent.Name == "GroupHeader" and d.Name ~= "GroupTitle" then
				d.BackgroundColor3 = COLORS.GroupHeader
			elseif d.Name == "Divider" and d:IsA("Frame") then
				d.BackgroundColor3 = COLORS.Text
			elseif (d:IsA("ImageLabel") or d:IsA("ImageButton")) and d.Name ~= "UIShadow" then
				d.ImageColor3 = COLORS.Text
			end
		end

		setActiveTab(activeTab)
		if applyKeybindVisual then
			applyKeybindVisual()
		end

		for _, fn in ipairs(themeRefreshers) do
			fn()
		end

		if not skipSwatchSync then
			for key, sw in pairs(Theme.swatches) do
				if COLORS[key] then
					sw.BackgroundColor3 = COLORS[key]
				end
			end
		end

		updateThemesDropdownLabel()
	end

	local THEME_ROW_H = 22
	local THEME_PAD_Y = 2

	local function makeThemeColorPicker(parent, yPos, colorKey, title)
		local h, s, v = COLORS[colorKey]:ToHSV()
		local open = false
		local animInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		local row = Instance.new("Frame")
		row.Name = "ThemeColor_" .. colorKey
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, THEME_ROW_H)
		row.Position = UDim2.fromOffset(0, yPos)
		row.ZIndex = 14
		row.Parent = parent

		label(row, {
			Text = title,
			TextSize = 13,
			Size = UDim2.new(1, -56, 1, 0),
			ZIndex = 15,
		})

		local swatch = Instance.new("TextButton")
		swatch.Name = "Swatch"
		swatch.AutoButtonColor = false
		swatch.Text = ""
		swatch.Size = UDim2.fromOffset(46, 15)
		swatch.Position = UDim2.new(1, 0, 0.5, 0)
		swatch.AnchorPoint = Vector2.new(1, 0.5)
		swatch.BackgroundColor3 = COLORS[colorKey]
		swatch.BorderSizePixel = 0
		swatch.ZIndex = 15
		swatch.Parent = row
		corner(swatch, 3)
		UIShadow(swatch, { Spread = 14, Transparency = 0.45, OffsetY = 2 })
		Theme.swatches[colorKey] = swatch

		local PICK_W = 200
		local PAD, BAR_W, GAP = 5, 14, 4
		local SV_H = 108
		local FIELDS_GAP = 5
		local FIELD_BLOCK = 20 * 2 + 4
		local PICK_H = PAD + SV_H + FIELDS_GAP + FIELD_BLOCK + PAD
		local SV_W = PICK_W - PAD * 2 - BAR_W * 2 - GAP * 2

		local picker = Instance.new("Frame")
		picker.Name = "ColorPickerWindow"
		picker.Size = UDim2.fromOffset(PICK_W, PICK_H)
		picker.Position = UDim2.new(1, 0, 1, 4)
		picker.AnchorPoint = Vector2.new(1, 0)
		picker.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		picker.BorderSizePixel = 0
		picker.Visible = false
		picker.Active = true
		picker.ZIndex = 530
		picker.Parent = row
		corner(picker, 3)

		local pickerSink = Instance.new("TextButton")
		pickerSink.Name = "Sink"
		pickerSink.Size = UDim2.fromScale(1, 1)
		pickerSink.BackgroundTransparency = 1
		pickerSink.Text = ""
		pickerSink.AutoButtonColor = false
		pickerSink.ZIndex = 530
		pickerSink.Parent = picker

		local svBox = Instance.new("Frame")
		svBox.Size = UDim2.fromOffset(SV_W, SV_H)
		svBox.Position = UDim2.fromOffset(PAD, PAD)
		svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svBox.BorderSizePixel = 0
		svBox.ClipsDescendants = true
		svBox.ZIndex = 531
		svBox.Parent = picker

		local whiteFade = Instance.new("Frame")
		whiteFade.Size = UDim2.fromScale(1, 1)
		whiteFade.BackgroundColor3 = Color3.new(1, 1, 1)
		whiteFade.BorderSizePixel = 0
		whiteFade.ZIndex = 532
		whiteFade.Parent = svBox
		local wg = Instance.new("UIGradient")
		wg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		wg.Parent = whiteFade

		local blackFade = Instance.new("Frame")
		blackFade.Size = UDim2.fromScale(1, 1)
		blackFade.BackgroundColor3 = Color3.new(0, 0, 0)
		blackFade.BorderSizePixel = 0
		blackFade.ZIndex = 533
		blackFade.Parent = svBox
		local bg = Instance.new("UIGradient")
		bg.Rotation = 90
		bg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		bg.Parent = blackFade

		local cursor = Instance.new("Frame")
		cursor.Size = UDim2.fromOffset(10, 10)
		cursor.AnchorPoint = Vector2.new(0.5, 0.5)
		cursor.BackgroundColor3 = Color3.new(1, 1, 1)
		cursor.BorderSizePixel = 0
		cursor.ZIndex = 535
		cursor.Parent = svBox
		corner(cursor, 5)

		local hueBar = Instance.new("Frame")
		hueBar.Size = UDim2.fromOffset(BAR_W, SV_H)
		hueBar.Position = UDim2.fromOffset(PAD + SV_W + GAP, PAD)
		hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
		hueBar.BorderSizePixel = 0
		hueBar.ClipsDescendants = true
		hueBar.ZIndex = 531
		hueBar.Parent = picker
		local hueGrad = Instance.new("UIGradient")
		hueGrad.Rotation = 90
		hueGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
			ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
			ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
			ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
			ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
			ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
		})
		hueGrad.Parent = hueBar

		local hueMarker = Instance.new("Frame")
		hueMarker.Size = UDim2.new(1, 2, 0, 3)
		hueMarker.AnchorPoint = Vector2.new(0.5, 0.5)
		hueMarker.Position = UDim2.new(0.5, 0, h, 0)
		hueMarker.BackgroundColor3 = Color3.new(1, 1, 1)
		hueMarker.BorderSizePixel = 0
		hueMarker.ZIndex = 535
		hueMarker.Parent = hueBar

		local satBar = Instance.new("Frame")
		satBar.Size = UDim2.fromOffset(BAR_W, SV_H)
		satBar.Position = UDim2.fromOffset(PAD + SV_W + GAP + BAR_W + GAP, PAD)
		satBar.BackgroundColor3 = Color3.new(1, 1, 1)
		satBar.BorderSizePixel = 0
		satBar.ClipsDescendants = true
		satBar.ZIndex = 531
		satBar.Parent = picker
		local satGrad = Instance.new("UIGradient")
		satGrad.Rotation = 90
		satGrad.Parent = satBar

		local satMarker = Instance.new("Frame")
		satMarker.Size = UDim2.new(1, 2, 0, 3)
		satMarker.AnchorPoint = Vector2.new(0.5, 0.5)
		satMarker.Position = UDim2.new(0.5, 0, 1 - s, 0)
		satMarker.BackgroundColor3 = Color3.new(1, 1, 1)
		satMarker.BorderSizePixel = 0
		satMarker.ZIndex = 535
		satMarker.Parent = satBar

		local colorFields
		local function commit()
			local col = Color3.fromHSV(h, s, v)
			COLORS[colorKey] = col
			swatch.BackgroundColor3 = col
			applyTheme("custom", true)
			swatch.BackgroundColor3 = col
			if colorFields then
				colorFields.Update(col)
			end
		end

		local function refresh(anim)
			svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			satGrad.Color = ColorSequence.new(Color3.fromHSV(h, 0, v), Color3.fromHSV(h, 1, v))
			local cpos = UDim2.new(s, 0, 1 - v, 0)
			local hpos = UDim2.new(0.5, 0, h, 0)
			local spos = UDim2.new(0.5, 0, 1 - s, 0)
			if anim then
				TweenService:Create(cursor, animInfo, { Position = cpos }):Play()
				TweenService:Create(hueMarker, animInfo, { Position = hpos }):Play()
				TweenService:Create(satMarker, animInfo, { Position = spos }):Play()
			else
				cursor.Position = cpos
				hueMarker.Position = hpos
				satMarker.Position = spos
			end
			local col = Color3.fromHSV(h, s, v)
			swatch.BackgroundColor3 = col
			if colorFields then
				colorFields.Update(col)
			end
		end

		colorFields = addColorValueFields(
			picker,
			PAD,
			PICK_W,
			PAD + SV_H + FIELDS_GAP,
			536,
			function(col)
				h, s, v = col:ToHSV()
				refresh(true)
				commit()
			end,
			function()
				return Color3.fromHSV(h, s, v)
			end
		)

		refresh(false)

		local applyModal
		local function setOpen(state)
			if state == open then return end
			open = state
			if applyModal then applyModal(state) end
			if state then
				h, s, v = COLORS[colorKey]:ToHSV()
				refresh(false)
				picker.Size = UDim2.fromOffset(PICK_W, 0)
				TweenService:Create(picker, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.fromOffset(PICK_W, PICK_H),
				}):Play()
			end
		end
		applyModal = bindColorPickerModal(picker, function() return open end, setOpen)

		swatch.MouseButton1Click:Connect(function()
			hideColorContextMenu()
			setOpen(not open)
		end)

		bindColorContextMenu(swatch, function()
			return COLORS[colorKey]
		end, function(col)
			h, s, v = col:ToHSV()
			refresh(true)
			commit()
			setOpen(true)
		end)

		local dragSV, dragHue, dragSat = false, false, false
		svBox.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragSV = true
				local rx = (input.Position.X - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1)
				local ry = (input.Position.Y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1)
				s, v = math.clamp(rx, 0, 1), 1 - math.clamp(ry, 0, 1)
				refresh(true)
				commit()
			end
		end)
		hueBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragHue = true
				h = math.clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / math.max(hueBar.AbsoluteSize.Y, 1), 0, 1)
				refresh(true)
				commit()
			end
		end)
		satBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragSat = true
				s = 1 - math.clamp((input.Position.Y - satBar.AbsolutePosition.Y) / math.max(satBar.AbsoluteSize.Y, 1), 0, 1)
				refresh(true)
				commit()
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
			if dragSV then
				local rx = (input.Position.X - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1)
				local ry = (input.Position.Y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1)
				s, v = math.clamp(rx, 0, 1), 1 - math.clamp(ry, 0, 1)
				refresh(true)
				commit()
			elseif dragHue then
				h = math.clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / math.max(hueBar.AbsoluteSize.Y, 1), 0, 1)
				refresh(true)
				commit()
			elseif dragSat then
				s = 1 - math.clamp((input.Position.Y - satBar.AbsolutePosition.Y) / math.max(satBar.AbsoluteSize.Y, 1), 0, 1)
				refresh(true)
				commit()
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragSV, dragHue, dragSat = false, false, false
			end
		end)
	end
	local CONFIG_DIR = "TierUp/Configs"
	local memoryConfigs = {}
	local Config = {
		selected = nil,
		nameBox = nil,
		dropdownValue = nil,
		refresh = nil,
		sectionBottom = 4,
	}

	local function envGet(name)
		local ok, g = pcall(function()
			return getgenv()
		end)
		if ok and type(g) == "table" and g[name] ~= nil then
			return g[name]
		end
		return rawget(_G, name)
	end

	local function fsCall(name, ...)
		local fn = envGet(name)
		if type(fn) ~= "function" then
			return false
		end
		local ok, a, b, c = pcall(fn, ...)
		if not ok then
			return false
		end
		return true, a, b, c
	end

	local function ensureConfigDir()
		local okRoot, hasRoot = fsCall("isfolder", "TierUp")
		if not okRoot or not hasRoot then
			fsCall("makefolder", "TierUp")
		end
		local okDir, hasDir = fsCall("isfolder", CONFIG_DIR)
		if not okDir or not hasDir then
			fsCall("makefolder", CONFIG_DIR)
		end
	end

	local function sanitizeConfigName(name)
		name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
		name = name:gsub("[^%w%-%_ ]", "")
		name = name:gsub("%s+", "_")
		if name == "" then return nil end
		return name
	end

	local function colorToTable(c)
		return {
			R = math.floor(c.R * 255 + 0.5),
			G = math.floor(c.G * 255 + 0.5),
			B = math.floor(c.B * 255 + 0.5),
		}
	end

	local function tableToColor(t)
		if type(t) ~= "table" then return nil end
		local r, g, b = tonumber(t.R), tonumber(t.G), tonumber(t.B)
		if not r or not g or not b then return nil end
		return Color3.fromRGB(r, g, b)
	end

	local function getConfigData()
		local colors = {}
		for k, v in pairs(COLORS) do
			if typeof(v) == "Color3" then
				colors[k] = colorToTable(v)
			end
		end
		return {
			Theme = Theme.current,
			Colors = colors,
			Keybind = {
				Key = keybindKey.Name,
				Mode = keybindMode,
			},
		}
	end

	local function getConfigJson()
		return HttpService:JSONEncode(getConfigData())
	end

	local function applyConfigData(data)
		if type(data) ~= "table" then return false end
		if type(data.Colors) == "table" then
			for k, v in pairs(data.Colors) do
				local col = tableToColor(v)
				if col and COLORS[k] ~= nil then
					COLORS[k] = col
				end
			end
		end
		local themeName = data.Theme
		if type(themeName) == "string" and THEMES[themeName] and themeMatches(themeName) then
			Theme.current = themeName
			applyTheme(themeName, false)
		else
			Theme.current = "custom"
			applyTheme("custom", false)
		end

		if type(data.Keybind) == "table" then
			local keyName = data.Keybind.Key
			if type(keyName) == "string" then
				local ok, code = pcall(function()
					return Enum.KeyCode[keyName]
				end)
				if ok and typeof(code) == "EnumItem" then
					keybindKey = code
					local shown = keycodeLabel(keybindKey)
					if keybindPickerLabel then
						keybindPickerLabel.Text = shown
					end
					if keybindListKeyLabel then
						keybindListKeyLabel.Text = "[" .. shown .. "]"
					end
				end
			end
			local mode = data.Keybind.Mode
			if mode == "hold" or mode == "toggle" or mode == "always" then
				keybindMode = mode
				if keybindMode == "always" then
					keybindActive = true
				elseif keybindMode == "hold" then
					keybindActive = UserInputService:IsKeyDown(keybindKey)
				end
				applyKeybindVisual()
			end
		end
		return true
	end

	local function listConfigNames()
		local names = {}
		local seen = {}
		ensureConfigDir()
		local ok, files = fsCall("listfiles", CONFIG_DIR)
		if ok and type(files) == "table" then
			for _, path in ipairs(files) do
				local name = tostring(path):gsub("\\", "/"):match("([^/]+)$") or tostring(path)
				name = name:gsub("%.json$", "")
				if name ~= "" and not seen[name] then
					seen[name] = true
					table.insert(names, name)
				end
			end
		end
		for name in pairs(memoryConfigs) do
			if not seen[name] then
				seen[name] = true
				table.insert(names, name)
			end
		end
		table.sort(names, function(a, b)
			return a:lower() < b:lower()
		end)
		return names
	end

	local function writeConfigFile(name, json)
		ensureConfigDir()
		local path = CONFIG_DIR .. "/" .. name .. ".json"
		local ok = fsCall("writefile", path, json)
		memoryConfigs[name] = json
		return ok or true
	end

	local function readConfigFile(name)
		local path = CONFIG_DIR .. "/" .. name .. ".json"
		local ok, data = fsCall("readfile", path)
		if ok and type(data) == "string" and data ~= "" then
			return data
		end
		return memoryConfigs[name]
	end

	local function createConfig(name)
		name = sanitizeConfigName(name)
		if not name then
			pushNotification("enter a config name")
			return false
		end
		local json = getConfigJson()
		writeConfigFile(name, json)
		Config.selected = name
		if Config.refresh then Config.refresh() end
		pushNotification("created: " .. name)
		return true
	end

	local function loadConfig(name)
		name = sanitizeConfigName(name or Config.selected)
		if not name then
			pushNotification("select a config")
			return false
		end
		local raw = readConfigFile(name)
		if not raw then
			pushNotification("config not found")
			return false
		end
		local ok, data = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		if not ok or type(data) ~= "table" then
			pushNotification("invalid config")
			return false
		end
		if applyConfigData(data) then
			Config.selected = name
			if Config.dropdownValue then
				Config.dropdownValue.Text = name
			end
			pushNotification("loaded: " .. name)
			return true
		end
		return false
	end

	local function overwriteConfig(name)
		name = sanitizeConfigName(name or Config.selected)
		if not name then
			pushNotification("select a config")
			return false
		end
		if not readConfigFile(name) then
			pushNotification("config not found")
			return false
		end
		writeConfigFile(name, getConfigJson())
		Config.selected = name
		if Config.refresh then Config.refresh() end
		pushNotification("overwrote: " .. name)
		return true
	end

	local Keybind = {
		featureLabel = nil,
		listKeyLabel = nil,
		key = Enum.KeyCode.K,
		active = false,
		listening = false,
		pickerLabel = nil,
		mode = "toggle",
	}

	local function keycodeLabel(code)
		local name = code.Name
		if #name == 1 then return name end
		if name:match("^%a$") then return name end
		return name
	end

	local function applyKeybindVisual()
		if not Keybind.featureLabel then return end
		if Keybind.mode == "always" then
			Keybind.active = true
			Keybind.featureLabel.TextColor3 = COLORS.Accent
		else
			Keybind.featureLabel.TextColor3 = Keybind.active and COLORS.Accent or COLORS.Text
		end
	end

	local L = {
		pages = pages,
		screenGui = screenGui,
		main = main,
		header = header,
		headerFill = headerFill,
		COLORS = COLORS,
		Icons = Icons,
		FONT = FONT,
		TweenService = TweenService,
		UserInputService = UserInputService,
		RunService = RunService,
		HttpService = HttpService,
		playerGui = playerGui,
		SIDE_PAD = SIDE_PAD,
		GAP = GAP,
		GB_W = GB_W,
		GB_H = GB_H,
		ROW_H = 28,
		PAD_Y = 6,
		CONTROL_CORNER = CONTROL_CORNER,
		CONTROL_SIZE = CONTROL_SIZE,
		CONTROL_SHADOW = CONTROL_SHADOW,
		Groupbox = makeGroupbox,
		Label = label,
		Button = makeButton,
		MatteControl = matteControl,
		IconImage = iconImage,
		Corner = corner,
		UIShadow = UIShadow,
		Notify = pushNotification,
		ApplyTheme = applyTheme,
		BindThemeRefresh = bindThemeRefresh,
		BindColorContextMenu = bindColorContextMenu,
		AddColorValueFields = addColorValueFields,
		BindColorPickerModal = bindColorPickerModal,
		MakeThemeColorPicker = makeThemeColorPicker,
		ColorToHex = colorToHex,
		ColorToRgbText = colorToRgbText,
		ParseHexColor = parseHexColor,
		ParseRgbColor = parseRgbColor,
		HideColorContextMenu = hideColorContextMenu,
		SetActiveTab = setActiveTab,
		THEME_ROW_H = THEME_ROW_H,
		THEME_PAD_Y = THEME_PAD_Y,
		THEME_ORDER = THEME_ORDER,
		THEMES = THEMES,
		Keybind = Keybind,
		KeycodeLabel = keycodeLabel,
		ApplyKeybindVisual = applyKeybindVisual,
		Config = Config,
		Theme = Theme,
		CreateConfig = createConfig,
		LoadConfig = loadConfig,
		OverwriteConfig = overwriteConfig,
		ListConfigNames = listConfigNames,
		UpdateLayout = updateMainLayout,
	}

	if config.Title then
		for _, c in ipairs(header:GetChildren()) do
			if c:IsA("TextLabel") and c.Name == "Title" then
				c.Text = config.Title
				break
			end
		end
	end

	if type(config.OnLoad) == "function" then
		config.OnLoad(L)
	end

	do
		local wm = Instance.new("Frame")
		wm.Name = "Watermark"
		wm.Size = UDim2.fromOffset(320, 55)
		wm.Position = UDim2.new(0.5, 0, 0, 14)
		wm.AnchorPoint = Vector2.new(0.5, 0)
		wm.BackgroundColor3 = COLORS.MainBg
		wm.BorderSizePixel = 0
		wm.ZIndex = 200
		wm.Parent = screenGui
		corner(wm, 10)

		label(wm, {
			Name = "Brand",
			Text = config.Title or "TierUp",
			TextSize = 20,
			Size = UDim2.new(0, 120, 1, 0),
			Position = UDim2.fromOffset(18, 0),
			ZIndex = 201,
		})

		local divider = Instance.new("Frame")
		divider.Name = "Divider"
		divider.Size = UDim2.fromOffset(2, 28)
		divider.Position = UDim2.new(1, -78, 0.5, 0)
		divider.AnchorPoint = Vector2.new(0.5, 0.5)
		divider.BackgroundColor3 = COLORS.Text
		divider.BorderSizePixel = 0
		divider.ZIndex = 201
		divider.Parent = wm

		local timeLabel = label(wm, {
			Name = "Time",
			Text = "TIME",
			TextSize = 16,
			Size = UDim2.fromOffset(70, 55),
			Position = UDim2.new(1, -150, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 201,
		})

		local fpsLabel = label(wm, {
			Name = "FPS",
			Text = "FPS",
			TextSize = 16,
			Size = UDim2.fromOffset(60, 55),
			Position = UDim2.new(1, -68, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 201,
		})

		local fpsAccum, fpsFrames, fpsShown = 0, 0, 0
		RunService.RenderStepped:Connect(function(dt)
			fpsAccum += dt
			fpsFrames += 1
			if fpsAccum >= 0.5 then
				fpsShown = math.floor(fpsFrames / fpsAccum + 0.5)
				fpsAccum = 0
				fpsFrames = 0
				fpsLabel.Text = tostring(fpsShown)
			end

			local t = os.date("*t")
			local h = t.hour % 12
			if h == 0 then h = 12 end
			timeLabel.Text = string.format("%d:%02d", h, t.min)
		end)
	end

	do
		local KB_W = 210
		local KB_TOP = 34
		local KB_ROW = 22
		local KB_GAP = 8
		local KB_PAD_Y = 10

		local kb = Instance.new("Frame")
		kb.Name = "Keybinds"
		kb.Size = UDim2.fromOffset(KB_W, KB_TOP + KB_PAD_Y * 2 + KB_ROW)
		kb.Position = UDim2.new(0, 16, 0.5, 0)
		kb.AnchorPoint = Vector2.new(0, 0.5)
		kb.BackgroundColor3 = COLORS.MainBg
		kb.BorderSizePixel = 0
		kb.ZIndex = 180
		kb.ClipsDescendants = true
		kb.Parent = screenGui
		corner(kb, 10)

		local topbar = Instance.new("Frame")
		topbar.Name = "Topbar"
		topbar.Size = UDim2.fromOffset(KB_W, KB_TOP)
		topbar.Position = UDim2.fromOffset(0, 0)
		topbar.BackgroundColor3 = COLORS.HeaderBg
		topbar.BorderSizePixel = 0
		topbar.ZIndex = 181
		topbar.Parent = kb
		corner(topbar, 10)

		local topFill = Instance.new("Frame")
		topFill.Name = "TopbarFill"
		topFill.Size = UDim2.new(1, 0, 0, 12)
		topFill.Position = UDim2.new(0, 0, 1, -12)
		topFill.BackgroundColor3 = COLORS.HeaderBg
		topFill.BorderSizePixel = 0
		topFill.ZIndex = 181
		topFill.Parent = topbar

		label(topbar, {
			Name = "Title",
			Text = "Keybinds",
			TextSize = 15,
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 182,
		})

		local list = Instance.new("Frame")
		list.Name = "List"
		list.BackgroundTransparency = 1
		list.Size = UDim2.new(1, -24, 1, -(KB_TOP + KB_PAD_Y))
		list.Position = UDim2.fromOffset(12, KB_TOP + 6)
		list.ZIndex = 181
		list.Parent = kb

		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, KB_GAP)
		layout.Parent = list

		local function resizeKeybinds()
			local count = 0
			for _, child in ipairs(list:GetChildren()) do
				if child:IsA("Frame") then
					count += 1
				end
			end
			local body = count * KB_ROW + math.max(0, count - 1) * KB_GAP
			local h = KB_TOP + KB_PAD_Y + body + KB_PAD_Y
			kb.Size = UDim2.fromOffset(KB_W, h)
		end

		local function addKeybind(name, key, order)
			local row = Instance.new("Frame")
			row.Name = name
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1, 0, 0, KB_ROW)
			row.ZIndex = 182
			row.LayoutOrder = order
			row.Parent = list

			local nameLbl = label(row, {
				Name = "Feature",
				Text = name,
				TextSize = 14,
				Size = UDim2.new(1, -48, 1, 0),
				ZIndex = 183,
			})
			local keyLbl = label(row, {
				Name = "Key",
				Text = "[" .. key .. "]",
				TextSize = 14,
				Size = UDim2.fromOffset(56, KB_ROW),
				Position = UDim2.new(1, 0, 0, 0),
				AnchorPoint = Vector2.new(1, 0),
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 183,
			})
			resizeKeybinds()
			return nameLbl, keyLbl
		end

		keybindFeatureLabel, keybindListKeyLabel = addKeybind("example keybind", "K", 1)
		Keybind.featureLabel = keybindFeatureLabel
		Keybind.listKeyLabel = keybindListKeyLabel
		applyKeybindVisual()
		resizeKeybinds()

		UserInputService.InputBegan:Connect(function(input, gp)
			if Keybind.listening then
				if input.UserInputType ~= Enum.UserInputType.Keyboard then
					return
				end
				if input.KeyCode == Enum.KeyCode.Escape then
					Keybind.listening = false
					if Keybind.pickerLabel then
						Keybind.pickerLabel.Text = keycodeLabel(Keybind.key)
					end
					return
				end
				if input.KeyCode == Enum.KeyCode.Unknown then
					return
				end
				Keybind.key = input.KeyCode
				Keybind.listening = false
				local shown = keycodeLabel(Keybind.key)
				if Keybind.pickerLabel then
					Keybind.pickerLabel.Text = shown
				end
				if Keybind.listKeyLabel then
					Keybind.listKeyLabel.Text = "[" .. shown .. "]"
				end
				if Keybind.mode == "hold" then
					Keybind.active = true
				end
				applyKeybindVisual()
				return
			end

			if gp then return end
			if input.KeyCode ~= Keybind.key then return end
			if Keybind.mode == "always" then
				Keybind.active = true
				applyKeybindVisual()
			elseif Keybind.mode == "hold" then
				Keybind.active = true
				applyKeybindVisual()
			else
				Keybind.active = not Keybind.active
				applyKeybindVisual()
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if Keybind.listening then return end
			if input.KeyCode ~= Keybind.key then return end
			if Keybind.mode == "hold" then
				Keybind.active = false
				applyKeybindVisual()
			end
		end)

		local kbDragging, kbStart, kbPos = false, nil, nil
		topbar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				kbDragging = true
				kbStart = input.Position
				if kb.AnchorPoint ~= Vector2.new(0, 0) then
					local abs = kb.AbsolutePosition
					kb.AnchorPoint = Vector2.new(0, 0)
					kb.Position = UDim2.fromOffset(abs.X, abs.Y)
				end
				kbPos = kb.Position
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if not kbDragging then return end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement
				and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local d = input.Position - kbStart
			TweenService:Create(kb, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.fromOffset(kbPos.X.Offset + d.X, kbPos.Y.Offset + d.Y),
			}):Play()
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				kbDragging = false
			end
		end)
	end

	local dragging = false
	local dragStart = nil
	local startPos = nil

	header.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if isInteractiveUnder(input.Position, tabRow) then
			return
		end

		dragging = true
		dragStart = input.Position
		startPos = main.Position

		if main.AnchorPoint ~= Vector2.new(0, 0) then
			local abs = main.AbsolutePosition
			main.AnchorPoint = Vector2.new(0, 0)
			main.Position = UDim2.fromOffset(abs.X, abs.Y)
			startPos = main.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local delta = input.Position - dragStart
		TweenService:Create(main, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			),
		}):Play()
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	local RESIZE_GREY = Color3.fromRGB(130, 130, 130)
	local RESIZE_WHITE = Color3.fromRGB(255, 255, 255)
	local resizing = false
	local resizeHovered = false
	local resizeStart = nil
	local resizeStartSize = nil

	local resizeGrip = Instance.new("TextButton")
	resizeGrip.Name = "ResizeGrip"
	resizeGrip.AutoButtonColor = false
	resizeGrip.Text = ""
	resizeGrip.Size = UDim2.fromOffset(14, 14)
	resizeGrip.Position = UDim2.new(1, -3, 1, -3)
	resizeGrip.AnchorPoint = Vector2.new(1, 1)
	resizeGrip.BackgroundColor3 = RESIZE_GREY
	resizeGrip.BorderSizePixel = 0
	resizeGrip.ZIndex = 50
	resizeGrip.Parent = main
	corner(resizeGrip, 3)

	for i = 0, 2 do
		local line = Instance.new("Frame")
		line.Name = "Line" .. i
		line.BorderSizePixel = 0
		line.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
		line.Size = UDim2.fromOffset(2, 7)
		line.Position = UDim2.fromOffset(3 + (i * 3), 4 + (i * 3))
		line.Rotation = 45
		line.ZIndex = 51
		line.Parent = resizeGrip
	end

	local function setResizeGripHover(active)
		resizeGrip.BackgroundColor3 = active and RESIZE_WHITE or RESIZE_GREY
		for _, child in ipairs(resizeGrip:GetChildren()) do
			if child:IsA("Frame") and child.Name:match("^Line") then
				child.BackgroundColor3 = active and Color3.fromRGB(170, 170, 170) or Color3.fromRGB(90, 90, 90)
			end
		end
	end

	resizeGrip.MouseEnter:Connect(function()
		resizeHovered = true
		if not resizing then
			setResizeGripHover(true)
		end
	end)
	resizeGrip.MouseLeave:Connect(function()
		resizeHovered = false
		if not resizing then
			setResizeGripHover(false)
		end
	end)

	resizeGrip.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		resizing = true
		resizeStart = input.Position
		resizeStartSize = main.Size
		setResizeGripHover(true)

		if main.AnchorPoint ~= Vector2.new(0, 0) then
			local abs = main.AbsolutePosition
			main.AnchorPoint = Vector2.new(0, 0)
			main.Position = UDim2.fromOffset(abs.X, abs.Y)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not resizing then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = input.Position - resizeStart
		local newW = math.max(MIN_MAIN_W, resizeStartSize.X.Offset + delta.X)
		local newH = math.max(MIN_MAIN_H, resizeStartSize.Y.Offset + delta.Y)
		main.Size = UDim2.fromOffset(newW, newH)
		updateMainLayout()
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if resizing then
				resizing = false
				setResizeGripHover(resizeHovered)
			end
		end
	end)

	applyTheme(config.Theme or "TierUp")
	return L
end

return TierUp
