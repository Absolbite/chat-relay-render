local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer

local Lib = {}

Lib.Settings = {
	TextLimit = 50,
	MessageCooldown = 5,
	MaxMessageLength = 200,
	UISize = {530, 360},
	Theme = "Darker",
	Transparency = 0.03,
	Scale = 465,
	Server = "wss://your-server.example.com",
	Token = "",
}

local Font = Enum.Font
local AlignLeft = Enum.TextXAlignment.Left
local WHITE = Color3.new(1, 1, 1)

local function RGB(t)
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function MakeTheme(a, m, h2, stroke, accent, text, dark)
	return {
		Hub1 = ColorSequence.new({
			ColorSequenceKeypoint.new(0, RGB(a)),
			ColorSequenceKeypoint.new(0.5, RGB(m)),
			ColorSequenceKeypoint.new(1, RGB(a)),
		}),
		Hub2 = RGB(h2),
		Stroke = RGB(stroke),
		Accent = RGB(accent),
		Text = RGB(text),
		Dark = RGB(dark),
	}
end

local Themes = {
	Darker = MakeTheme({25, 25, 25}, {32.5, 32.5, 32.5}, {30, 30, 30}, {40, 40, 40}, {88, 101, 242}, {243, 243, 243}, {180, 180, 180}),
	Dark = MakeTheme({40, 40, 40}, {47.5, 47.5, 47.5}, {45, 45, 45}, {65, 65, 65}, {65, 150, 255}, {245, 245, 245}, {190, 190, 190}),
	Purple = MakeTheme({27.5, 25, 30}, {32.5, 32.5, 32.5}, {30, 30, 30}, {40, 40, 40}, {150, 0, 255}, {240, 240, 240}, {180, 180, 180}),
	Ocean = MakeTheme({10, 30, 50}, {15, 40, 65}, {12, 35, 55}, {20, 55, 80}, {0, 180, 220}, {220, 240, 255}, {140, 180, 210}),
	Crimson = MakeTheme({30, 10, 10}, {40, 15, 15}, {35, 12, 12}, {55, 20, 20}, {220, 40, 40}, {255, 230, 230}, {200, 160, 160}),
	Emerald = MakeTheme({10, 28, 18}, {14, 38, 24}, {12, 33, 21}, {20, 55, 35}, {0, 200, 100}, {220, 255, 235}, {140, 200, 165}),
	Sunset = MakeTheme({35, 18, 10}, {45, 25, 12}, {40, 22, 12}, {65, 38, 18}, {255, 120, 30}, {255, 240, 220}, {210, 175, 140}),
	Midnight = MakeTheme({8, 8, 18}, {12, 12, 25}, {10, 10, 22}, {22, 22, 45}, {100, 80, 255}, {220, 218, 255}, {155, 150, 210}),
	Rose = MakeTheme({32, 14, 24}, {42, 20, 32}, {38, 17, 28}, {60, 28, 46}, {255, 80, 140}, {255, 228, 240}, {210, 160, 185}),
	Monochrome = MakeTheme({18, 18, 18}, {26, 26, 26}, {22, 22, 22}, {50, 50, 50}, {200, 200, 200}, {240, 240, 240}, {170, 170, 170}),
	Neon = MakeTheme({5, 5, 10}, {8, 8, 16}, {6, 6, 13}, {15, 15, 30}, {0, 255, 128}, {210, 255, 235}, {130, 210, 170}),
	Gold = MakeTheme({28, 22, 6}, {38, 30, 9}, {33, 26, 7}, {58, 46, 14}, {255, 210, 50}, {255, 250, 220}, {210, 188, 130}),
	Lilac = MakeTheme({25, 18, 35}, {34, 25, 46}, {30, 22, 40}, {52, 38, 70}, {195, 140, 255}, {240, 230, 255}, {185, 160, 220}),
	Slate = MakeTheme({18, 22, 28}, {24, 30, 38}, {21, 26, 33}, {38, 48, 60}, {100, 160, 220}, {220, 230, 245}, {150, 170, 200}),
	Arctic = MakeTheme({15, 25, 35}, {20, 34, 48}, {18, 30, 42}, {30, 55, 75}, {130, 220, 255}, {225, 245, 255}, {155, 200, 230}),
}

local ThemeOrder = {"Darker", "Dark", "Purple", "Ocean", "Crimson", "Emerald", "Sunset", "Midnight", "Rose", "Monochrome", "Neon", "Gold", "Lilac", "Slate", "Arctic"}

Lib.Themes = Themes

local function New(class, props, kids)
	local obj = Instance.new(class)
	local parent
	for key, value in pairs(props or {}) do
		if key == "Parent" then
			parent = value
		else
			obj[key] = value
		end
	end
	for _, child in ipairs(kids or {}) do
		child.Parent = obj
	end
	if parent then
		obj.Parent = parent
	end
	return obj
end

local function Tween(obj, props, time)
	TweenService:Create(obj, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quint), props):Play()
end

local function Corner(parent, radius)
	return New("UICorner", {CornerRadius = UDim.new(0, radius or 6), Parent = parent})
end

local function ParseColor(text)
	text = (tostring(text or ""):gsub("%s", ""))
	local hex = text:match("^#?(%x%x%x%x%x%x)$")
	if hex then
		return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
	end
	local r, g, b = text:match("^(%d+),(%d+),(%d+)$")
	if r then
		return Color3.fromRGB(math.clamp(tonumber(r), 0, 255), math.clamp(tonumber(g), 0, 255), math.clamp(tonumber(b), 0, 255))
	end
end

local function Brighten(color, amount)
	return Color3.fromRGB(
		math.clamp(color.R * 255 + amount, 0, 255),
		math.clamp(color.G * 255 + amount, 0, 255),
		math.clamp(color.B * 255 + amount, 0, 255)
	)
end

local function ToHex(color)
	return string.format("#%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end

local function ToRGBText(color)
	return string.format("%d, %d, %d", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end

local function FormatTime(ms)
	local ok, text = pcall(function()
		return DateTime.fromUnixTimestampMillis(ms):FormatLocalTime("HH:mm", "en-us")
	end)
	if ok and text then
		return text
	end
	return os.date("%H:%M", math.floor(ms / 1000))
end

local function GuiParent()
	local ok, hui = pcall(function()
		return gethui and gethui()
	end)
	if ok and hui then
		return hui
	end
	if pcall(function() return CoreGui.Name end) then
		return CoreGui
	end
	return LP:WaitForChild("PlayerGui")
end

local function LoadConfig(folder)
	if not (isfile and readfile) then
		return {}
	end
	local ok, data = pcall(function()
		local path = "Community-Lib/" .. folder .. "/config.json"
		if isfile(path) then
			return HttpService:JSONDecode(readfile(path))
		end
	end)
	return (ok and type(data) == "table") and data or {}
end

local function SaveConfig(folder, data)
	if not writefile then
		return
	end
	pcall(function()
		if makefolder then
			if not isfolder("Community-Lib") then
				makefolder("Community-Lib")
			end
			if not isfolder("Community-Lib/" .. folder) then
				makefolder("Community-Lib/" .. folder)
			end
		end
		writefile("Community-Lib/" .. folder .. "/config.json", HttpService:JSONEncode(data))
	end)
end

local function CopyText(text)
	local fn = setclipboard or toclipboard or (syn and syn.write_clipboard) or (Clipboard and Clipboard.set)
	if not fn then
		return false
	end
	return pcall(fn, text)
end

local function MakeNet(settings, handlers)
	local Net = {Alive = true, Mode = nil}
	local request = (syn and syn.request) or (http and http.request) or http_request or request
	local connectWS = WebSocket and (WebSocket.connect or WebSocket.Connect)
	local socket
	local lastId = 0
	local failures = 0

	local function hello()
		return {
			t = "hello",
			uid = LP.UserId,
			name = LP.Name,
			display = LP.DisplayName,
			token = settings.Token,
		}
	end

	local function baseUrl()
		return (settings.Server:gsub("^ws", "http"))
	end

	local function handle(raw)
		local ok, data = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		if not ok or type(data) ~= "table" then
			return
		end
		if data.t == "history" then
			for _, m in ipairs(data.msgs or {}) do
				lastId = math.max(lastId, m.id or 0)
				handlers.msg(m)
			end
		elseif data.t == "msg" and data.m then
			lastId = math.max(lastId, data.m.id or 0)
			handlers.msg(data.m)
		elseif data.t == "err" then
			handlers.err(data)
		end
	end

	local function runSocket()
		local ok, sock = pcall(connectWS, settings.Server)
		if not ok or not sock then
			failures = failures + 1
			return false
		end
		failures = 0
		socket = sock
		local closed = false
		sock.OnMessage:Connect(handle)
		sock.OnClose:Connect(function()
			closed = true
		end)
		sock:Send(HttpService:JSONEncode(hello()))
		handlers.status(true)
		while Net.Alive and not closed do
			task.wait(1)
		end
		socket = nil
		handlers.status(false)
		return true
	end

	local function runPoll()
		local url = ("%s/poll?uid=%d&after=%d&token=%s"):format(baseUrl(), LP.UserId, lastId, HttpService:UrlEncode(settings.Token))
		local ok, res = pcall(request, {Url = url, Method = "GET"})
		if ok and res and res.StatusCode == 200 then
			local good, data = pcall(function()
				return HttpService:JSONDecode(res.Body)
			end)
			if good and type(data) == "table" then
				for _, m in ipairs(data.msgs or {}) do
					lastId = math.max(lastId, m.id or 0)
					handlers.msg(m)
				end
				handlers.status(true)
				return
			end
		end
		handlers.status(false)
	end

	task.spawn(function()
		while Net.Alive do
			if connectWS and failures < 3 then
				Net.Mode = "ws"
				runSocket()
				task.wait(2)
			elseif request then
				Net.Mode = "http"
				runPoll()
				task.wait(2)
			else
				Net.Mode = nil
				handlers.status(false)
				task.wait(5)
			end
		end
	end)

	function Net:Send(payload)
		if socket then
			return pcall(function()
				socket:Send(HttpService:JSONEncode(payload))
			end)
		end
		if Net.Mode == "http" and request then
			task.spawn(function()
				local body = hello()
				body.t = "send"
				for key, value in pairs(payload) do
					body[key] = value
				end
				local ok, res = pcall(request, {
					Url = baseUrl() .. "/send",
					Method = "POST",
					Headers = {["Content-Type"] = "application/json"},
					Body = HttpService:JSONEncode(body),
				})
				if ok and res and res.Body then
					local good, data = pcall(function()
						return HttpService:JSONDecode(res.Body)
					end)
					if good and data and data.err then
						handlers.err({reason = data.err, wait = data.wait})
					end
				end
			end)
			return true
		end
		return false
	end

	function Net:Close()
		Net.Alive = false
		if socket then
			pcall(function()
				socket:Close()
			end)
		end
	end

	return Net
end

function Lib:MakeWindow(Configs)
	Configs = Configs or {}
	local Name = Configs.Name or "Community Hub"
	local SubTitle = Configs.SubTitle or ""
	local SaveFolder = Configs.SaveFolder or "Default"

	local S = {}
	for key, value in pairs(Lib.Settings) do
		S[key] = value
	end
	for key, value in pairs(Configs.Settings or {}) do
		S[key] = value
	end

	local Cfg = LoadConfig(SaveFolder)
	if Cfg.theme and Themes[Cfg.theme] then
		S.Theme = Cfg.theme
	end
	if tonumber(Cfg.transparency) then
		S.Transparency = Cfg.transparency
	end
	if not Themes[S.Theme] then
		S.Theme = "Darker"
	end

	local Th = Themes[S.Theme]
	S.NameColor = ParseColor(Cfg.nameColor) and Cfg.nameColor or ToHex(Th.Accent)
	S.FontColor = ParseColor(Cfg.fontColor) and Cfg.fontColor or ToHex(Th.Text)
	Cfg.buttons = type(Cfg.buttons) == "table" and Cfg.buttons or {}

	local MIN_W, MIN_H, MAX_W, MAX_H = 430, 220, 1000, 500
	local W, H = S.UISize[1], S.UISize[2]
	if type(Cfg.size) == "table" and tonumber(Cfg.size[1]) and tonumber(Cfg.size[2]) then
		W, H = Cfg.size[1], Cfg.size[2]
	end
	W = math.clamp(W, MIN_W, MAX_W)
	H = math.clamp(H, MIN_H, MAX_H)

	local TOP, SIDE = 28, 135
	local PAGE_TITLE = 28
	local MARGIN = 12

	local Window = {}
	local Conns = {}
	local Binds = {}
	local SavePending = false

	local function Connect(signal, fn)
		local c = signal:Connect(fn)
		table.insert(Conns, c)
		return c
	end

	local function SaveSoon()
		if SavePending then
			return
		end
		SavePending = true
		task.delay(0.5, function()
			SavePending = false
			SaveConfig(SaveFolder, Cfg)
		end)
	end

	local GuiName = "Community-Lib_" .. SaveFolder
	local parent = GuiParent()
	local old = parent:FindFirstChild(GuiName)
	if old then
		old:Destroy()
	end

	local Gui = New("ScreenGui", {
		Name = GuiName,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = parent,
	})

	local function Bind(inst, fn)
		fn()
		table.insert(Binds, {inst, fn})
	end

	local function Refresh()
		for i = #Binds, 1, -1 do
			local b = Binds[i]
			if b[1]:IsDescendantOf(Gui) then
				pcall(b[2])
			else
				table.remove(Binds, i)
			end
		end
	end

	local function BindText(label, key)
		Bind(label, function()
			label.TextColor3 = Th[key or "Text"]
		end)
	end

	local function BindSub(frame, transparency)
		Bind(frame, function()
			frame.BackgroundColor3 = Th.Accent
			frame.BackgroundTransparency = transparency or 0.85
		end)
	end

	local function Stroke(parentObj, key, thickness)
		local stroke = New("UIStroke", {
			Thickness = thickness or 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = parentObj,
		})
		Bind(stroke, function()
			stroke.Color = Th[key or "Stroke"]
		end)
		return stroke
	end

	local Main = New("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(W, H),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Parent = Gui,
	})
	local MainScale = New("UIScale", {Parent = Main})
	local MainGradient = New("UIGradient", {Rotation = 45, Parent = Main})
	Corner(Main, 7)
	local MainStroke = New("UIStroke", {
		Thickness = 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = Main,
	})
	Bind(Main, function()
		Main.BackgroundTransparency = S.Transparency
		MainGradient.Color = Th.Hub1
		MainStroke.Color = Brighten(Th.Stroke, 55)
	end)

	local function ApplyScale()
		local view = workspace.CurrentCamera.ViewportSize
		MainScale.Scale = math.clamp(math.min(view.X / S.Scale, view.Y / (S.UISize[2] + 24)), 0.5, 1)
	end
	ApplyScale()
	Connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), ApplyScale)

	local Top = New("Frame", {
		Size = UDim2.new(1, 0, 0, TOP),
		BackgroundTransparency = 1,
		Parent = Main,
	})

	local TitleRow = New("Frame", {
		Position = UDim2.fromOffset(15, 0),
		Size = UDim2.new(1, -80, 1, 0),
		BackgroundTransparency = 1,
		Parent = Top,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local NameLabel = New("TextLabel", {
		LayoutOrder = 1,
		Size = UDim2.fromOffset(0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = Font.GothamBold,
		TextSize = 12,
		Text = Name,
		Parent = TitleRow,
	})
	Bind(NameLabel, function()
		NameLabel.TextColor3 = Brighten(Th.Accent, 60)
	end)

	local SubLabel = New("TextLabel", {
		LayoutOrder = 2,
		Size = UDim2.fromOffset(0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = Font.Gotham,
		TextSize = 8,
		Text = SubTitle,
		Visible = SubTitle ~= "",
		Parent = TitleRow,
	})
	BindText(SubLabel, "Dark")

	local CloseButton = New("ImageButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Image = "rbxassetid://10747384394",
		AutoButtonColor = false,
		Parent = Top,
	})
	local MinButton = New("ImageButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -35, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Image = "rbxassetid://10734896206",
		AutoButtonColor = false,
		Parent = Top,
	})
	Bind(CloseButton, function()
		CloseButton.ImageColor3 = Th.Text
		MinButton.ImageColor3 = Th.Text
	end)

	local dragging, dragStart, dragOrigin
	Connect(Top.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			dragOrigin = Main.Position
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					c:Disconnect()
				end
			end)
		end
	end)
	Connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = (input.Position - dragStart) / MainScale.Scale
			Main.Position = UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + d.X, dragOrigin.Y.Scale, dragOrigin.Y.Offset + d.Y)
		end
	end)

	local Body = New("Frame", {
		Position = UDim2.fromOffset(0, TOP),
		Size = UDim2.new(1, 0, 1, -TOP),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = Main,
	})

	local TabList = New("ScrollingFrame", {
		Size = UDim2.new(0, SIDE, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = Body,
	}, {
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 6),
			PaddingTop = UDim.new(0, 5),
			PaddingBottom = UDim.new(0, 10),
		}),
		New("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}),
	})

	local Content = New("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(1, -SIDE, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = Body,
	})

	local PageTitle = New("TextLabel", {
		Position = UDim2.fromOffset(MARGIN, 5),
		Size = UDim2.new(0.5, 0, 0, 23),
		BackgroundTransparency = 1,
		Font = Font.GothamBold,
		TextSize = 17,
		TextXAlignment = AlignLeft,
		Text = "",
		Parent = Content,
	})
	BindText(PageTitle)

	local StatusLabel = New("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -MARGIN, 0, 5),
		Size = UDim2.new(0.4, 0, 0, 23),
		BackgroundTransparency = 1,
		Font = Font.Gotham,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "Connecting...",
		Parent = Content,
	})
	BindText(StatusLabel, "Dark")

	local Tabs, CurrentTab = {}, nil
	local SelectTab

	local function MakeTab(name, order)
		local btn = New("TextButton", {
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 23),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Parent = TabList,
		})
		Corner(btn, 3)
		Bind(btn, function()
			btn.BackgroundColor3 = Th.Accent
		end)

		local bar = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.new(0, 3, 0, 0),
			BorderSizePixel = 0,
			Parent = btn,
		})
		Corner(bar, 4)
		Bind(bar, function()
			bar.BackgroundColor3 = Th.Accent
		end)

		local label = New("TextLabel", {
			Position = UDim2.fromOffset(14, 0),
			Size = UDim2.new(1, -22, 1, 0),
			BackgroundTransparency = 1,
			Font = Font.GothamBold,
			TextSize = 10,
			TextXAlignment = AlignLeft,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = name,
			Parent = btn,
		})
		BindText(label)

		local page = New("Frame", {
			Position = UDim2.fromOffset(0, PAGE_TITLE),
			Size = UDim2.new(1, 0, 1, -PAGE_TITLE),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = Content,
		})

		Tabs[name] = {btn = btn, bar = bar, page = page}
		Connect(btn.Activated, function()
			SelectTab(name)
		end)
		return page
	end

	local Overlay = New("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 40,
		Parent = Main,
	})

	local function CloseOverlay()
		for _, child in ipairs(Overlay:GetChildren()) do
			child:Destroy()
		end
		Overlay.Visible = false
	end
	Connect(Overlay.MouseButton1Down, CloseOverlay)

	function SelectTab(name)
		CloseOverlay()
		CurrentTab = name
		for tabName, tab in pairs(Tabs) do
			local on = tabName == name
			tab.page.Visible = on
			Tween(tab.btn, {BackgroundTransparency = on and 0.85 or 1}, 0.25)
			Tween(tab.bar, {Size = UDim2.new(0, 3, on and 0.6 or 0, 0)}, 0.25)
		end
		PageTitle.Text = name
		StatusLabel.Visible = name == "Chat"
	end

	local function ShowMenu(anchor, items, width, align, maxRows)
		CloseOverlay()
		Overlay.Visible = true

		local rows = math.min(#items, maxRows or 8)
		local height = rows * 24 + 8
		local sc = MainScale.Scale
		local ap = (anchor.AbsolutePosition - Main.AbsolutePosition) / sc
		local asz = anchor.AbsoluteSize / sc

		local x = align == "right" and (ap.X + asz.X - width) or ap.X
		local y = ap.Y + asz.Y + 3
		if y + height > H - 4 then
			y = ap.Y - height - 3
		end
		x = math.clamp(x, 4, W - width - 4)
		y = math.clamp(y, 4, H - height - 4)

		local pop = New("Frame", {
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(width, height),
			BackgroundTransparency = 0.05,
			ZIndex = 41,
			Parent = Overlay,
		})
		Corner(pop, 6)
		Stroke(pop)
		Bind(pop, function()
			pop.BackgroundColor3 = Th.Hub2
		end)

		local list = New("ScrollingFrame", {
			Position = UDim2.fromOffset(0, 4),
			Size = UDim2.new(1, 0, 1, -8),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ZIndex = 42,
			Parent = pop,
		}, {
			New("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4)}),
			New("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}),
		})
		Bind(list, function()
			list.ScrollBarImageColor3 = Th.Accent
		end)

		for index, item in ipairs(items) do
			local row = New("TextButton", {
				LayoutOrder = index,
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = item.selected and 0.85 or 1,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 43,
				Parent = list,
			})
			Corner(row, 3)
			Bind(row, function()
				row.BackgroundColor3 = Th.Accent
			end)
			local label = New("TextLabel", {
				Position = UDim2.fromOffset(8, 0),
				Size = UDim2.new(1, -12, 1, 0),
				BackgroundTransparency = 1,
				Font = Font.GothamBold,
				TextSize = 10,
				TextXAlignment = AlignLeft,
				Text = item.text,
				ZIndex = 44,
				Parent = row,
			})
			BindText(label)
			Connect(row.MouseEnter, function()
				if not item.selected then
					Tween(row, {BackgroundTransparency = 0.92}, 0.12)
				end
			end)
			Connect(row.MouseLeave, function()
				if not item.selected then
					Tween(row, {BackgroundTransparency = 1}, 0.12)
				end
			end)
			Connect(row.Activated, function()
				CloseOverlay()
				item.fn()
			end)
		end
	end

	local Toast = New("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -54),
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0.05,
		Font = Font.GothamBold,
		TextSize = 10,
		Text = "",
		Visible = false,
		ZIndex = 60,
		Parent = Main,
	}, {
		New("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}),
	})
	Corner(Toast, 5)
	Stroke(Toast)
	Bind(Toast, function()
		Toast.BackgroundColor3 = Th.Hub2
		Toast.TextColor3 = Th.Text
	end)

	local toastToken = 0
	local function Notify(text)
		toastToken = toastToken + 1
		local token = toastToken
		Toast.Text = text
		Toast.Visible = true
		task.delay(1.6, function()
			if token == toastToken then
				Toast.Visible = false
			end
		end)
	end

	local ChatPage = MakeTab("Chat", 1)
	local SettingsPage = MakeTab("Settings", 2)

	local Net
	local WriteTarget
	local Messages, Seen = {}, {}
	local NextSend = 0

	local INPUT_H, SEND_W, BOTTOM = 28, 60, 8

	local Chip = New("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, MARGIN, 1, -(BOTTOM + INPUT_H + 6)),
		Size = UDim2.new(1, -MARGIN * 2, 0, 18),
		Visible = false,
		Parent = ChatPage,
	})
	Corner(Chip, 3)
	BindSub(Chip, 0.75)

	local ChipLabel = New("TextLabel", {
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -30, 1, 0),
		BackgroundTransparency = 1,
		Font = Font.GothamMedium,
		TextSize = 10,
		TextXAlignment = AlignLeft,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = "",
		Parent = Chip,
	})
	BindText(ChipLabel)

	local ChipClose = New("ImageButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -4, 0.5, 0),
		Size = UDim2.fromOffset(11, 11),
		BackgroundTransparency = 1,
		Image = "rbxassetid://10747384394",
		AutoButtonColor = false,
		Parent = Chip,
	})
	Bind(ChipClose, function()
		ChipClose.ImageColor3 = Th.Dark
	end)

	local Scroll = New("ScrollingFrame", {
		Position = UDim2.fromOffset(MARGIN, 2),
		Size = UDim2.new(1, -MARGIN * 2, 1, -(BOTTOM + INPUT_H + 6)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = ChatPage,
	}, {
		New("UIPadding", {PaddingRight = UDim.new(0, 4)}),
		New("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}),
	})
	Bind(Scroll, function()
		Scroll.ScrollBarImageColor3 = Th.Accent
	end)

	local function ChatLayout()
		local reserved = BOTTOM + INPUT_H + 6 + (WriteTarget and 22 or 0)
		Scroll.Size = UDim2.new(1, -MARGIN * 2, 1, -reserved)
		Chip.Visible = WriteTarget ~= nil
	end

	local function SetTarget(target)
		WriteTarget = target
		if target then
			ChipLabel.Text = "To Write: " .. target.display
		end
		ChatLayout()
	end
	Connect(ChipClose.Activated, function()
		SetTarget(nil)
	end)

	local InputRow = New("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, MARGIN, 1, -BOTTOM),
		Size = UDim2.new(1, -MARGIN * 2, 0, INPUT_H),
		BackgroundTransparency = 1,
		Parent = ChatPage,
	})

	local InputPanel = New("Frame", {
		Size = UDim2.new(1, -(SEND_W + 6), 1, 0),
		Parent = InputRow,
	})
	Corner(InputPanel, 3)
	BindSub(InputPanel)

	local Input = New("TextBox", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		BackgroundTransparency = 1,
		Font = Font.GothamMedium,
		TextSize = 10,
		TextXAlignment = AlignLeft,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		PlaceholderText = "To chat click here or press / key",
		Text = "",
		Parent = InputPanel,
	})
	Bind(Input, function()
		Input.TextColor3 = Th.Text
		Input.PlaceholderColor3 = Th.Dark
	end)

	local SendButton = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, SEND_W, 1, 0),
		Font = Font.GothamBold,
		TextSize = 10,
		Text = "Send",
		AutoButtonColor = false,
		Parent = InputRow,
	})
	Corner(SendButton, 3)
	BindSub(SendButton)
	BindText(SendButton)
	Connect(SendButton.MouseEnter, function()
		Tween(SendButton, {BackgroundTransparency = 0.7}, 0.15)
	end)
	Connect(SendButton.MouseLeave, function()
		Tween(SendButton, {BackgroundTransparency = 0.85}, 0.15)
	end)

	local function ScrollToBottom()
		task.defer(function()
			task.wait()
			Scroll.CanvasPosition = Vector2.new(0, Scroll.AbsoluteCanvasSize.Y)
		end)
	end

	local function MessageMenu(anchor, m)
		ShowMenu(anchor, {
			{
				text = "Copy",
				fn = function()
					Notify(CopyText(m.text) and "Copied" or "Clipboard unavailable")
				end,
			},
			{
				text = "To Write",
				fn = function()
					if m.uid == LP.UserId then
						Notify("You can't write to yourself")
						return
					end
					SetTarget({uid = m.uid, display = m.display})
					SelectTab("Chat")
					Input:CaptureFocus()
				end,
			},
		}, 84, "right", 2)
	end

	local function AddMessage(m)
		if type(m) ~= "table" or not m.id or Seen[m.id] then
			return
		end
		Seen[m.id] = true

		local nearBottom = Scroll.CanvasPosition.Y + Scroll.AbsoluteWindowSize.Y >= Scroll.AbsoluteCanvasSize.Y - 30
		local mine = m.uid == LP.UserId

		local item = New("Frame", {
			LayoutOrder = m.id,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = Scroll,
		}, {
			New("UIPadding", {
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 7),
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
			New("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}),
		})
		Corner(item, 3)
		BindSub(item, m.to and 0.7 or 0.85)

		local header = New("Frame", {
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Parent = item,
		}, {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})

		New("TextLabel", {
			LayoutOrder = 1,
			Size = UDim2.fromOffset(0, 14),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Font = Font.GothamBold,
			TextSize = 11,
			RichText = false,
			Text = tostring(m.display or "Player"),
			TextColor3 = ParseColor(m.nc) or WHITE,
			Parent = header,
		})

		if m.to then
			local tag = New("TextLabel", {
				LayoutOrder = 2,
				Size = UDim2.fromOffset(0, 14),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Font = Font.GothamMedium,
				TextSize = 9,
				RichText = false,
				Text = mine and ("to " .. tostring(m.toDisplay or "Player")) or "whisper to you",
				Parent = header,
			})
			BindText(tag, "Dark")
		end

		local time = New("TextLabel", {
			LayoutOrder = 3,
			Size = UDim2.fromOffset(0, 14),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Font = Font.Gotham,
			TextSize = 9,
			Text = FormatTime(tonumber(m.ts) or os.time() * 1000),
			Parent = header,
		})
		BindText(time, "Dark")

		local dots = New("TextButton", {
			LayoutOrder = 4,
			Size = UDim2.fromOffset(22, 14),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Parent = header,
		})
		for i = -1, 1 do
			local dot = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, i * 5, 0.5, 0),
				Size = UDim2.fromOffset(3, 3),
				BorderSizePixel = 0,
				Parent = dots,
			})
			Corner(dot, 2)
			Bind(dot, function()
				dot.BackgroundColor3 = Th.Dark
			end)
		end
		Connect(dots.Activated, function()
			MessageMenu(dots, m)
		end)

		New("TextLabel", {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = Font.GothamMedium,
			TextSize = 11,
			TextWrapped = true,
			RichText = false,
			TextXAlignment = AlignLeft,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = tostring(m.text or ""),
			TextColor3 = ParseColor(m.fc) or Th.Text,
			Parent = item,
		})

		table.insert(Messages, item)
		while #Messages > S.TextLimit do
			table.remove(Messages, 1):Destroy()
		end

		if nearBottom or mine then
			ScrollToBottom()
		end
	end

	local function SendMessage()
		local text = (Input.Text:gsub("^%s+", ""))
		text = (text:gsub("%s+$", ""))
		if text == "" then
			return
		end

		local now = os.clock()
		if now < NextSend then
			Notify("Wait " .. math.ceil(NextSend - now) .. "s")
			return
		end

		local length = utf8.len(text) or #text
		if length > S.MaxMessageLength then
			text = text:sub(1, (utf8.offset(text, S.MaxMessageLength + 1) or (#text + 1)) - 1)
		end

		local ok = Net:Send({
			t = "msg",
			text = text,
			to = WriteTarget and WriteTarget.uid or nil,
			toName = WriteTarget and WriteTarget.display or nil,
			nc = S.NameColor,
			fc = S.FontColor,
		})
		if not ok then
			Notify("Offline")
			return
		end

		NextSend = now + S.MessageCooldown
		Input.Text = ""
		SetTarget(nil)

		task.spawn(function()
			while true do
				local left = NextSend - os.clock()
				if left <= 0 then
					SendButton.Text = "Send"
					break
				end
				SendButton.Text = tostring(math.ceil(left))
				task.wait(0.2)
			end
		end)
	end

	Connect(SendButton.Activated, SendMessage)
	Connect(Input.FocusLost, function(enterPressed)
		if enterPressed then
			SendMessage()
		end
	end)
	Connect(UserInputService.InputBegan, function(input, processed)
		if processed or input.KeyCode ~= Enum.KeyCode.Slash then
			return
		end
		if Main.Visible and CurrentTab == "Chat" then
			task.delay(0.03, function()
				Input:CaptureFocus()
				Input.Text = ""
			end)
		end
	end)

	Net = MakeNet(S, {
		msg = function(m)
			AddMessage(m)
		end,
		status = function(online)
			StatusLabel.Text = online and "Online" or "Offline"
		end,
		err = function(data)
			if data.reason == "cooldown" then
				NextSend = os.clock() + (tonumber(data.wait) or S.MessageCooldown)
				Notify("Wait " .. tostring(data.wait or S.MessageCooldown) .. "s")
			elseif data.reason == "auth" then
				Notify("Server rejected the token")
			else
				Notify("Message not sent")
			end
		end,
	})

	local SettingsScroll = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = SettingsPage,
	}, {
		New("UIPadding", {
			PaddingLeft = UDim.new(0, MARGIN),
			PaddingRight = UDim.new(0, MARGIN),
			PaddingTop = UDim.new(0, 2),
			PaddingBottom = UDim.new(0, 8),
		}),
		New("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}),
	})
	Bind(SettingsScroll, function()
		SettingsScroll.ScrollBarImageColor3 = Th.Accent
	end)

	local rowOrder = 0
	local function Row(title)
		rowOrder = rowOrder + 1
		local row = New("Frame", {
			LayoutOrder = rowOrder,
			Size = UDim2.new(1, 0, 0, 25),
			Parent = SettingsScroll,
		})
		Corner(row, 3)
		BindSub(row)
		local label = New("TextLabel", {
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(0.4, 0, 1, 0),
			BackgroundTransparency = 1,
			Font = Font.GothamMedium,
			TextSize = 10,
			TextXAlignment = AlignLeft,
			Text = title,
			Parent = row,
		})
		BindText(label)
		return row
	end

	local ThemeRow = Row("Theme")
	local ThemeButton = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(150, 18),
		Text = "",
		AutoButtonColor = false,
		Parent = ThemeRow,
	})
	Corner(ThemeButton, 4)
	BindSub(ThemeButton)
	local ThemeLabel = New("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.new(1, -28, 0.85, 0),
		BackgroundTransparency = 1,
		Font = Font.GothamBold,
		TextSize = 10,
		TextXAlignment = AlignLeft,
		Text = S.Theme,
		Parent = ThemeButton,
	})
	BindText(ThemeLabel)
	New("ImageLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Image = "rbxassetid://10709790948",
		Parent = ThemeButton,
	})

	function Window:SetTheme(name)
		if not Themes[name] then
			return
		end
		S.Theme = name
		Th = Themes[name]
		Cfg.theme = name
		ThemeLabel.Text = name
		Refresh()
		SaveSoon()
	end

	Connect(ThemeButton.Activated, function()
		local items = {}
		for _, name in ipairs(ThemeOrder) do
			table.insert(items, {
				text = name,
				selected = name == S.Theme,
				fn = function()
					Window:SetTheme(name)
				end,
			})
		end
		ShowMenu(ThemeButton, items, 150, "right", 7)
	end)

	local SliderRow = Row("Transparency")
	local ValueLabel = New("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(34, 14),
		BackgroundTransparency = 1,
		Font = Font.GothamBold,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "",
		Parent = SliderRow,
	})
	BindText(ValueLabel, "Dark")

	local Track = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -50, 0.5, 0),
		Size = UDim2.fromOffset(106, 4),
		BorderSizePixel = 0,
		Parent = SliderRow,
	})
	Corner(Track, 2)
	Bind(Track, function()
		Track.BackgroundColor3 = Th.Stroke
	end)
	local Fill = New("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		Parent = Track,
	})
	Corner(Fill, 2)
	Bind(Fill, function()
		Fill.BackgroundColor3 = Th.Accent
	end)
	local Knob = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(10, 10),
		BorderSizePixel = 0,
		Parent = Track,
	})
	Corner(Knob, 5)
	Bind(Knob, function()
		Knob.BackgroundColor3 = Th.Text
	end)
	local Hit = New("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 12, 0, 20),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = Track,
	})

	local MAX_T = 0.9
	local function ShowSlider()
		local alpha = math.clamp(S.Transparency / MAX_T, 0, 1)
		Fill.Size = UDim2.fromScale(alpha, 1)
		Knob.Position = UDim2.fromScale(alpha, 0.5)
		ValueLabel.Text = string.format("%.2f", S.Transparency)
	end

	function Window:SetTransparency(value)
		S.Transparency = math.clamp(tonumber(value) or S.Transparency, 0, MAX_T)
		Cfg.transparency = S.Transparency
		ShowSlider()
		Refresh()
		SaveSoon()
	end
	ShowSlider()

	local sliding = false
	local function SlideTo(x)
		local alpha = math.clamp((x - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
		Window:SetTransparency(math.floor(alpha * MAX_T * 100 + 0.5) / 100)
	end
	Connect(Hit.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			SlideTo(input.Position.X)
		end
	end)
	Connect(UserInputService.InputChanged, function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			SlideTo(input.Position.X)
		end
	end)
	Connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)

	local function ColorRow(title, key, cfgKey)
		local row = Row(title)
		local swatch = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = ParseColor(S[key]) or WHITE,
			BorderSizePixel = 0,
			Parent = row,
		})
		Corner(swatch, 3)
		Stroke(swatch)

		local box = New("TextBox", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -30, 0.5, 0),
			Size = UDim2.fromOffset(120, 18),
			Font = Font.GothamBold,
			TextSize = 10,
			ClearTextOnFocus = false,
			PlaceholderText = "R, G, B  or  #HEX",
			Text = ToRGBText(ParseColor(S[key]) or WHITE),
			Parent = row,
		})
		Corner(box, 4)
		BindSub(box)
		Bind(box, function()
			box.TextColor3 = Th.Text
			box.PlaceholderColor3 = Th.Dark
		end)

		Connect(box.FocusLost, function()
			local color = ParseColor(box.Text)
			if color then
				S[key] = ToHex(color)
				Cfg[cfgKey] = S[key]
				swatch.BackgroundColor3 = color
				SaveSoon()
			end
			box.Text = ToRGBText(ParseColor(S[key]) or WHITE)
		end)
	end

	ColorRow("Name Color", "NameColor", "nameColor")
	ColorRow("Font Color", "FontColor", "fontColor")

	function Window:SetScale(value)
		S.Scale = tonumber(value) or S.Scale
		ApplyScale()
	end

	local Grip = New("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 20,
		Parent = Main,
	})
	for _, spec in ipairs({{12, 0.5}, {6, 0.72}}) do
		local line = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(spec[2], spec[2]),
			Size = UDim2.fromOffset(spec[1], 1),
			Rotation = -45,
			BorderSizePixel = 0,
			ZIndex = 21,
			Parent = Grip,
		})
		Bind(line, function()
			line.BackgroundColor3 = Th.Dark
		end)
	end

	local resizing, resizeStart, resizeW, resizeH
	Connect(Grip.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			resizeStart = input.Position
			resizeW, resizeH = W, H
			CloseOverlay()
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					resizing = false
					c:Disconnect()
					Cfg.size = {W, H}
					SaveSoon()
				end
			end)
		end
	end)
	Connect(UserInputService.InputChanged, function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = (input.Position - resizeStart) / MainScale.Scale
			local newW = math.clamp(resizeW + d.X, MIN_W, MAX_W)
			local newH = math.clamp(resizeH + d.Y, MIN_H, MAX_H)
			local dw, dh = newW - W, newH - H
			if dw ~= 0 or dh ~= 0 then
				W, H = newW, newH
				Main.Size = UDim2.fromOffset(W, H)
				Main.Position = Main.Position + UDim2.fromOffset(dw * MainScale.Scale / 2, dh * MainScale.Scale / 2)
			end
		end
	end)

	local Collapsed = false
	function Window:Minimize()
		Collapsed = not Collapsed
		CloseOverlay()
		Body.Visible = not Collapsed
		Grip.Visible = not Collapsed
		MinButton.Image = Collapsed and "rbxassetid://10734924532" or "rbxassetid://10734896206"
		Tween(Main, {Size = UDim2.fromOffset(W, Collapsed and TOP or H)}, 0.25)
	end

	function Window:Toggle()
		Main.Visible = not Main.Visible
	end

	local FloatButton

	function Window:Destroy()
		Net:Close()
		for _, c in ipairs(Conns) do
			c:Disconnect()
		end
		Gui:Destroy()
	end

	function Window:Dialog(Cfg2)
		Cfg2 = Cfg2 or {}
		if Main:FindFirstChild("Dialog") then
			return
		end
		if Collapsed then
			Window:Minimize()
		end
		CloseOverlay()

		local title = Cfg2.Title or Cfg2[1] or "Dialog"
		local text = Cfg2.Text or Cfg2[2] or ""
		local options = Cfg2.Options or Cfg2[3] or {}
		local baseW, baseH = 270, 160

		local Screen = New("Frame", {
			Name = "Dialog",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Active = true,
			ZIndex = 80,
			Parent = Main,
		})
		Corner(Screen, 7)
		Bind(Screen, function()
			Screen.BackgroundColor3 = Th.Stroke
		end)

		local Frame = New("Frame", {
			Active = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(baseW * 1.06, baseH * 1.06),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.08,
			ClipsDescendants = true,
			Parent = Screen,
		})
		local FrameGradient = New("UIGradient", {Rotation = 270, Parent = Frame})
		Corner(Frame, 7)
		Bind(Frame, function()
			FrameGradient.Color = Th.Hub1
		end)

		local DialogTop = New("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundTransparency = 1,
			Parent = Frame,
		})
		local icon = New("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			Image = "rbxassetid://10723415903",
			Parent = DialogTop,
		})
		Bind(icon, function()
			icon.ImageColor3 = Th.Accent
		end)
		local titleLabel = New("TextLabel", {
			Position = UDim2.fromOffset(34, 0),
			Size = UDim2.new(1, -80, 1, 0),
			BackgroundTransparency = 1,
			Font = Font.GothamBold,
			TextSize = 13,
			TextXAlignment = AlignLeft,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = title,
			Parent = DialogTop,
		})
		BindText(titleLabel)

		local XBtn = New("ImageButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			BackgroundTransparency = 1,
			Image = "rbxassetid://10747384394",
			AutoButtonColor = false,
			Parent = DialogTop,
		})
		Bind(XBtn, function()
			XBtn.ImageColor3 = Th.Dark
		end)

		local divider = New("Frame", {
			Position = UDim2.fromOffset(12, 36),
			Size = UDim2.new(1, -24, 0, 1),
			BorderSizePixel = 0,
			Parent = Frame,
		})
		BindSub(divider, 0.75)

		local body = New("TextLabel", {
			Position = UDim2.fromOffset(12, 44),
			Size = UDim2.new(1, -24, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = Font.GothamMedium,
			TextSize = 11,
			TextWrapped = true,
			TextXAlignment = AlignLeft,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = text,
			Parent = Frame,
		})
		BindText(body, "Dark")

		local Holder = New("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 10, 1, -10),
			Size = UDim2.new(1, -20, 0, 28),
			BackgroundTransparency = 1,
			Parent = Frame,
		}, {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})

		Tween(Frame, {Size = UDim2.fromOffset(baseW, baseH)}, 0.25)
		Tween(Screen, {BackgroundTransparency = 0.35}, 0.15)

		local closed = false
		local function CloseDialog()
			if closed then
				return
			end
			closed = true
			Tween(Frame, {Size = UDim2.fromOffset(baseW * 1.06, baseH * 1.06)}, 0.2)
			Tween(Screen, {BackgroundTransparency = 1}, 0.15)
			task.delay(0.2, function()
				Screen:Destroy()
			end)
		end

		Connect(XBtn.Activated, CloseDialog)
		Connect(XBtn.MouseEnter, function()
			Tween(XBtn, {ImageColor3 = Color3.fromRGB(255, 80, 80)}, 0.15)
		end)
		Connect(XBtn.MouseLeave, function()
			Tween(XBtn, {ImageColor3 = Th.Dark}, 0.15)
		end)

		local count = #options
		for index, option in ipairs(options) do
			local label = option[1] or option.Name or ""
			local callback = option[2] or option.Callback
			local btn = New("TextButton", {
				LayoutOrder = index,
				Size = UDim2.new(1 / count, -((count - 1) * 8) / count, 1, 0),
				Font = Font.GothamBold,
				TextSize = 11,
				Text = label,
				AutoButtonColor = false,
				Parent = Holder,
			})
			Corner(btn, 5)
			BindSub(btn, 0.7)
			BindText(btn)
			Connect(btn.Activated, function()
				CloseDialog()
				if callback then
					callback()
				end
			end)
		end
	end

	Connect(MinButton.Activated, function()
		Window:Minimize()
	end)
	Connect(CloseButton.Activated, function()
		Window:Dialog({
			Title = "Close",
			Text = "Do you want to close Community Lib? The UI will be removed completely.",
			Options = {
				{"Confirm", function()
					Window:Destroy()
				end},
				{"Cancel"},
			},
		})
	end)

	function Window:SelectTab(name)
		if Tabs[name] then
			SelectTab(name)
		end
	end

	function Window:AddTag(Cfg2)
		Cfg2 = Cfg2 or {}
		local tag = New("Frame", {
			LayoutOrder = 3,
			Size = UDim2.fromOffset(0, 16),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Cfg2.Color or WHITE,
			BorderSizePixel = 0,
			Parent = TitleRow,
		}, {
			New("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}),
		})
		Corner(tag, 4)
		local label = New("TextLabel", {
			Size = UDim2.fromOffset(0, 16),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Font = Font.GothamBold,
			TextSize = 9,
			Text = Cfg2.Name or "tag",
			TextColor3 = Cfg2.TextColor or Color3.new(0, 0, 0),
			Parent = tag,
		})

		local Tag = {}
		function Tag:SetTitle(text)
			label.Text = text
		end
		function Tag:SetColor(color, textColor)
			tag.BackgroundColor3 = color or tag.BackgroundColor3
			label.TextColor3 = textColor or label.TextColor3
		end
		function Tag:Visible(value)
			tag.Visible = value
		end
		function Tag:Destroy()
			tag:Destroy()
		end
		return Tag
	end

	function Window:AddMinimizeButton(Cfg2)
		Cfg2 = Cfg2 or {}
		local size = Cfg2.Size or 35
		local flag = Cfg2.Flag
		local position = Cfg2.Position or UDim2.fromScale(0.15, 0.05)
		local saved = flag and Cfg.buttons[flag]
		if type(saved) == "table" and #saved == 4 then
			position = UDim2.new(saved[1], saved[2], saved[3], saved[4])
		end

		local button = New("ImageButton", {
			Size = UDim2.fromOffset(size, size),
			Position = position,
			BackgroundTransparency = Cfg2.Transparency or 0.1,
			Image = Cfg2.Image or "",
			AutoButtonColor = false,
			Parent = Gui,
		})
		Corner(button, math.floor(size / 4))
		Stroke(button)
		Bind(button, function()
			button.BackgroundColor3 = Th.Hub2
		end)

		local down, moved, startInput, startPos
		Connect(button.InputBegan, function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			down, moved = true, false
			startInput, startPos = input.Position, button.Position
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					c:Disconnect()
					down = false
					if moved then
						if flag then
							local p = button.Position
							Cfg.buttons[flag] = {p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset}
							SaveSoon()
						end
					else
						Window:Toggle()
					end
				end
			end)
		end)
		Connect(UserInputService.InputChanged, function(input)
			if down and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local d = input.Position - startInput
				if d.Magnitude > 6 then
					moved = true
				end
				if moved then
					button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
				end
			end
		end)

		FloatButton = button

		local Minimize = {}
		function Minimize:SetImage(image)
			button.Image = image
		end
		function Minimize:Visible(value)
			button.Visible = value
		end
		function Minimize:Destroy()
			button:Destroy()
			FloatButton = nil
		end
		return Minimize
	end

	SelectTab("Chat")
	ChatLayout()

	Window.Gui = Gui
	Window.Settings = S
	return Window
end

return Lib
