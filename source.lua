local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local gui = player.PlayerGui

local UI_FONT = Enum.Font.FredokaOne

local Library = {}
Library.Flags = {}
Library.Windows = {}

local Lucide
pcall(function()
	Lucide = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/icons.lua"))()
end)

local function ResolveIcon(Icon)
	if type(Icon) == "number" then return "rbxassetid://" .. Icon end
	if type(Icon) == "string" then
		if string.match(Icon, "^rbxassetid://") then return Icon end
		if string.match(Icon, "^%d+$") then return "rbxassetid://" .. Icon end
		local Name = string.lower(Icon)
		if type(Lucide) == "function" then
			local ok, Data = pcall(Lucide, Name)
			if ok and type(Data) == "table" then
				local Id = Data.id or Data.Id or Data[1]
				local Size = Data.imageRectSize or Data.ImageRectSize or Data[2]
				local Offset = Data.imageRectOffset or Data.imageRectPosition or Data.ImageRectOffset or Data[3]
				if Id then return "rbxassetid://" .. tostring(Id), Offset, Size end
			end
		elseif type(Lucide) == "table" then
			for _, Set in { Lucide["48px"], Lucide["256px"], Lucide } do
				if type(Set) == "table" then
					local Data = Set[Name]
					if type(Data) == "table" and Data[1] then
						return "rbxassetid://" .. tostring(Data[1]), Data[3], Data[2]
					end
				end
			end
		end
	end
	return "rbxassetid://0"
end

local function ToVector2(Value)
	if typeof(Value) == "Vector2" then return Value end
	if type(Value) == "table" then return Vector2.new(Value[1] or Value.X or 0, Value[2] or Value.Y or 0) end
	return Vector2.new(0, 0)
end

local function ApplyIcon(Object, Icon)
	if not Icon then return end
	local Image, Offset, Size = ResolveIcon(Icon)
	Object.Image = Image
	if Offset then Object.ImageRectOffset = ToVector2(Offset) end
	if Size then Object.ImageRectSize = ToVector2(Size) end
end

local function MakeDraggable(guiObject, handleObject)
	handleObject = handleObject or guiObject
	local dragging = false
	local dragInput = nil
	local dragStart = nil
	local startPos = nil

	local function update(input)
		local delta = input.Position - dragStart
		guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	handleObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = guiObject.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	handleObject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

function Library:CreateWindow(Options)
	Options = Options or {}
	local Title = Options.Title or "Leaf"
	local Logo = Options.Logo
	local Anonymous = Options.Anonymous or false
	local ConfigFolder = Options.ConfigFolder or "LeafConfigs"

	if not isfolder(ConfigFolder) then
		makefolder(ConfigFolder)
	end

	local Window = {}
	Window.ConfigFolder = ConfigFolder
	Window.Tabs = {}
	Window.TabButtons = {}
	Window.TabFrames = {}
	Window.DynamicThemeElements = {}
	Window.SearchItems = {}
	Window.ActiveTabName = ""
	Window.ActiveTheme = "Dark"
	Window.SavedConfigs = {}
	Window.SelectedConfig = nil
	Window.AutoloadConfig = nil

	Window.Themes = {
		Dark = { Main = Color3.fromRGB(15, 15, 18), Top = Color3.fromRGB(18, 18, 22), Accent = Color3.fromRGB(245, 170, 50), Card = Color3.fromRGB(22, 22, 27) },
		Purple = { Main = Color3.fromRGB(16, 12, 24), Top = Color3.fromRGB(22, 16, 34), Accent = Color3.fromRGB(170, 130, 255), Card = Color3.fromRGB(25, 20, 35) },
		Blue = { Main = Color3.fromRGB(10, 16, 26), Top = Color3.fromRGB(14, 22, 36), Accent = Color3.fromRGB(80, 160, 255), Card = Color3.fromRGB(18, 26, 40) },
		Emerald = { Main = Color3.fromRGB(10, 20, 16), Top = Color3.fromRGB(14, 28, 22), Accent = Color3.fromRGB(50, 215, 130), Card = Color3.fromRGB(18, 32, 26) },
		Midnight = { Main = Color3.fromRGB(10, 10, 12), Top = Color3.fromRGB(14, 14, 16), Accent = Color3.fromRGB(220, 80, 100), Card = Color3.fromRGB(20, 20, 24) }
	}

	local sc = Instance.new("ScreenGui")
	sc.Name = "LeafUI"
	sc.ResetOnSpawn = false
	sc.Parent = gui
	Window.ScreenGui = sc

	local mobileToggleBtn = Instance.new("ImageButton")
	mobileToggleBtn.Name = "MobileToggleBtn"
	mobileToggleBtn.Size = UDim2.new(0, 42, 0, 42)
	mobileToggleBtn.Position = UDim2.new(0, 15, 0.5, -21)
	mobileToggleBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	mobileToggleBtn.BorderSizePixel = 0
	mobileToggleBtn.ZIndex = 300
	ApplyIcon(mobileToggleBtn, "layers")
	mobileToggleBtn.ImageColor3 = Window.Themes.Dark.Accent
	mobileToggleBtn.Visible = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	mobileToggleBtn.Parent = sc

	MakeDraggable(mobileToggleBtn)

	local mobileBtnCorner = Instance.new("UICorner")
	mobileBtnCorner.CornerRadius = UDim.new(1, 0)
	mobileBtnCorner.Parent = mobileToggleBtn

	local mobileBtnStroke = Instance.new("UIStroke")
	mobileBtnStroke.Color = Color3.fromRGB(35, 35, 45)
	mobileBtnStroke.Thickness = 1.5
	mobileBtnStroke.Parent = mobileToggleBtn

	table.insert(Window.DynamicThemeElements, {Object = mobileToggleBtn, Type = "Accent"})

	local notifContainer = Instance.new("Frame")
	notifContainer.Name = "NotificationContainer"
	notifContainer.Size = UDim2.new(0, 220, 1, -20)
	notifContainer.Position = UDim2.new(1, -230, 0, 10)
	notifContainer.BackgroundTransparency = 1
	notifContainer.ZIndex = 100
	notifContainer.Parent = sc

	local notifLayout = Instance.new("UIListLayout")
	notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
	notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	notifLayout.Padding = UDim.new(0, 6)
	notifLayout.Parent = notifContainer

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0.92, 0, 0.88, 0)
	mainFrame.Position = UDim2.new(0.04, 0, 0.06, 0)
	mainFrame.BackgroundColor3 = Window.Themes.Dark.Main
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = sc
	Window.MainFrame = mainFrame

	local uiToggleKey = Enum.KeyCode.RightShift

	local function toggleUI()
		mainFrame.Visible = not mainFrame.Visible
	end

	mobileToggleBtn.MouseButton1Click:Connect(toggleUI)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == uiToggleKey then
			toggleUI()
		end
	end)

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 8)
	mainCorner.Parent = mainFrame

	local mainConstraint = Instance.new("UISizeConstraint")
	mainConstraint.MaxSize = Vector2.new(780, 480)
	mainConstraint.Parent = mainFrame

	local topbar = Instance.new("Frame")
	topbar.Name = "TopPanel"
	topbar.Size = UDim2.new(1, 0, 0, 80)
	topbar.BackgroundColor3 = Window.Themes.Dark.Top
	topbar.BorderSizePixel = 0
	topbar.Parent = mainFrame
	Window.Topbar = topbar

	MakeDraggable(mainFrame, topbar)

	local topbarCorner = Instance.new("UICorner")
	topbarCorner.CornerRadius = UDim.new(0, 8)
	topbarCorner.Parent = topbar

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 42)
	header.BackgroundTransparency = 1
	header.Parent = topbar

	local logo = Instance.new("ImageLabel")
	logo.Name = "AppLogo"
	logo.Size = UDim2.new(0, 20, 0, 20)
	logo.Position = UDim2.new(0, 10, 0, 11)
	logo.BackgroundTransparency = 1
	logo.Parent = header

	if Logo then
		ApplyIcon(logo, Logo)
		logo.ImageColor3 = Color3.fromRGB(255, 255, 255)
	else
		ApplyIcon(logo, "layers")
		logo.ImageColor3 = Window.Themes.Dark.Accent
		table.insert(Window.DynamicThemeElements, {Object = logo, Type = "Accent"})
	end

	local title = Instance.new("TextLabel")
	title.Name = "AppTitle"
	title.Size = UDim2.new(0.3, 0, 0, 22)
	title.Position = UDim2.new(0, 36, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = Title
	title.TextColor3 = Color3.fromRGB(240, 240, 245)
	title.TextSize = 12
	title.Font = UI_FONT
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = header

	local rightGroup = Instance.new("Frame")
	rightGroup.Name = "RightGroup"
	rightGroup.Size = UDim2.new(0.65, 0, 1, 0)
	rightGroup.Position = UDim2.new(0.35, 0, 0, 0)
	rightGroup.BackgroundTransparency = 1
	rightGroup.Parent = header

	local rightLayout = Instance.new("UIListLayout")
	rightLayout.FillDirection = Enum.FillDirection.Horizontal
	rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	rightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rightLayout.Padding = UDim.new(0, 6)
	rightLayout.Parent = rightGroup

	local rightPadding = Instance.new("UIPadding")
	rightPadding.PaddingRight = UDim.new(0, 8)
	rightPadding.Parent = rightGroup

	local bellBtn = Instance.new("ImageButton")
	bellBtn.Name = "BellBtn"
	bellBtn.Size = UDim2.new(0, 16, 0, 16)
	bellBtn.BackgroundTransparency = 1
	ApplyIcon(bellBtn, "bell")
	bellBtn.ImageColor3 = Color3.fromRGB(150, 150, 165)
	bellBtn.LayoutOrder = 1
	bellBtn.Parent = rightGroup

	local gearBtn = Instance.new("ImageButton")
	gearBtn.Name = "GearBtn"
	gearBtn.Size = UDim2.new(0, 16, 0, 16)
	gearBtn.BackgroundTransparency = 1
	ApplyIcon(gearBtn, "settings")
	gearBtn.ImageColor3 = Color3.fromRGB(150, 150, 165)
	gearBtn.LayoutOrder = 2
	gearBtn.Parent = rightGroup

	local profileCard = Instance.new("Frame")
	profileCard.Name = "ProfileCard"
	profileCard.Size = UDim2.new(0, 90, 0, 28)
	profileCard.BackgroundTransparency = 1
	profileCard.LayoutOrder = 3
	profileCard.Parent = rightGroup

	local avatar = Instance.new("ImageLabel")
	avatar.Name = "UserAvatar"
	avatar.Size = UDim2.new(0, 22, 0, 22)
	avatar.Position = UDim2.new(0, 0, 0, 3)
	avatar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	if not Anonymous then
		avatar.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	else
		ApplyIcon(avatar, "user")
		avatar.ImageColor3 = Color3.fromRGB(150, 150, 165)
	end
	avatar.Parent = profileCard

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(0, 5)
	avatarCorner.Parent = avatar

	local username = Instance.new("TextLabel")
	username.Name = "UserLabel"
	username.Size = UDim2.new(1, -26, 0, 13)
	username.Position = UDim2.new(0, 26, 0, 1)
	username.BackgroundTransparency = 1
	username.Text = Anonymous and "Anonymous" or player.Name
	username.TextColor3 = Color3.fromRGB(240, 240, 245)
	username.TextSize = 10
	username.Font = UI_FONT
	username.TextXAlignment = Enum.TextXAlignment.Left
	username.TextTruncate = Enum.TextTruncate.AtEnd
	username.Parent = profileCard

	local rank = Instance.new("TextLabel")
	rank.Name = "RankLabel"
	rank.Size = UDim2.new(1, -26, 0, 11)
	rank.Position = UDim2.new(0, 26, 0, 14)
	rank.BackgroundTransparency = 1
	rank.Text = Title
	rank.TextColor3 = Color3.fromRGB(130, 130, 145)
	rank.TextSize = 8
	rank.Font = UI_FONT
	rank.TextXAlignment = Enum.TextXAlignment.Left
	rank.Parent = profileCard

	local searchBoxFrame = Instance.new("Frame")
	searchBoxFrame.Name = "SearchBoxFrame"
	searchBoxFrame.Size = UDim2.new(0, 95, 0, 26)
	searchBoxFrame.BackgroundTransparency = 1
	searchBoxFrame.LayoutOrder = 4
	searchBoxFrame.Parent = rightGroup

	local searchBox = Instance.new("TextBox")
	searchBox.Name = "SearchBox"
	searchBox.Size = UDim2.new(1, 0, 1, 0)
	searchBox.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
	searchBox.BorderSizePixel = 0
	searchBox.Text = ""
	searchBox.PlaceholderText = "Search"
	searchBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 125)
	searchBox.TextColor3 = Color3.fromRGB(240, 240, 245)
	searchBox.TextSize = 11
	searchBox.Font = UI_FONT
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.Parent = searchBoxFrame

	local searchCorner = Instance.new("UICorner")
	searchCorner.CornerRadius = UDim.new(0, 5)
	searchCorner.Parent = searchBox

	local searchPadding = Instance.new("UIPadding")
	searchPadding.PaddingLeft = UDim.new(0, 22)
	searchPadding.Parent = searchBox

	local searchIcon = Instance.new("ImageLabel")
	searchIcon.Name = "SearchIcon"
	searchIcon.Size = UDim2.new(0, 11, 0, 11)
	searchIcon.Position = UDim2.new(0, -16, 0.5, -5)
	searchIcon.BackgroundTransparency = 1
	ApplyIcon(searchIcon, "search")
	searchIcon.ImageColor3 = Color3.fromRGB(110, 110, 125)
	searchIcon.Parent = searchBox

	local searchDropdown = Instance.new("Frame")
	searchDropdown.Name = "SearchDropdown"
	searchDropdown.Size = UDim2.new(0, 160, 0, 0)
	searchDropdown.Position = UDim2.new(1, -160, 0, 30)
	searchDropdown.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	searchDropdown.BorderSizePixel = 0
	searchDropdown.ZIndex = 250
	searchDropdown.ClipsDescendants = true
	searchDropdown.Visible = false
	searchDropdown.Parent = searchBoxFrame

	local searchDropCorner = Instance.new("UICorner")
	searchDropCorner.CornerRadius = UDim.new(0, 6)
	searchDropCorner.Parent = searchDropdown

	local searchDropStroke = Instance.new("UIStroke")
	searchDropStroke.Color = Color3.fromRGB(35, 35, 45)
	searchDropStroke.Thickness = 1
	searchDropStroke.Parent = searchDropdown

	local searchDropList = Instance.new("ScrollingFrame")
	searchDropList.Name = "List"
	searchDropList.Size = UDim2.new(1, 0, 1, -8)
	searchDropList.Position = UDim2.new(0, 0, 0, 4)
	searchDropList.BackgroundTransparency = 1
	searchDropList.BorderSizePixel = 0
	searchDropList.ScrollBarThickness = 2
	searchDropList.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 65)
	searchDropList.CanvasSize = UDim2.new(0, 0, 0, 0)
	searchDropList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	searchDropList.ZIndex = 251
	searchDropList.Parent = searchDropdown

	local searchDropLayout = Instance.new("UIListLayout")
	searchDropLayout.SortOrder = Enum.SortOrder.LayoutOrder
	searchDropLayout.Padding = UDim.new(0, 4)
	searchDropLayout.Parent = searchDropList

	local searchDropPadding = Instance.new("UIPadding")
	searchDropPadding.PaddingLeft = UDim.new(0, 6)
	searchDropPadding.PaddingRight = UDim.new(0, 6)
	searchDropPadding.Parent = searchDropList

	local notifHistoryPanel = Instance.new("Frame")
	notifHistoryPanel.Name = "NotifHistoryPanel"
	notifHistoryPanel.Size = UDim2.new(0, 230, 0, 0)
	notifHistoryPanel.Position = UDim2.new(1, -238, 0, 42)
	notifHistoryPanel.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	notifHistoryPanel.BorderSizePixel = 0
	notifHistoryPanel.ZIndex = 200
	notifHistoryPanel.ClipsDescendants = true
	notifHistoryPanel.Visible = false
	notifHistoryPanel.Parent = mainFrame

	local historyCorner = Instance.new("UICorner")
	historyCorner.CornerRadius = UDim.new(0, 8)
	historyCorner.Parent = notifHistoryPanel

	local historyStroke = Instance.new("UIStroke")
	historyStroke.Color = Color3.fromRGB(35, 35, 45)
	historyStroke.Thickness = 1
	historyStroke.Parent = notifHistoryPanel

	local historyHeader = Instance.new("Frame")
	historyHeader.Name = "Header"
	historyHeader.Size = UDim2.new(1, 0, 0, 30)
	historyHeader.BackgroundTransparency = 1
	historyHeader.ZIndex = 201
	historyHeader.Parent = notifHistoryPanel

	local historyTitle = Instance.new("TextLabel")
	historyTitle.Name = "Title"
	historyTitle.Size = UDim2.new(0.5, 0, 1, 0)
	historyTitle.Position = UDim2.new(0, 10, 0, 0)
	historyTitle.BackgroundTransparency = 1
	historyTitle.Text = "Notifications"
	historyTitle.TextColor3 = Color3.fromRGB(240, 240, 245)
	historyTitle.TextSize = 10
	historyTitle.Font = UI_FONT
	historyTitle.TextXAlignment = Enum.TextXAlignment.Left
	historyTitle.ZIndex = 201
	historyTitle.Parent = historyHeader

	local clearAllBtn = Instance.new("TextButton")
	clearAllBtn.Name = "ClearAllBtn"
	clearAllBtn.Size = UDim2.new(0, 55, 0, 18)
	clearAllBtn.Position = UDim2.new(1, -63, 0.5, -9)
	clearAllBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	clearAllBtn.BorderSizePixel = 0
	clearAllBtn.Text = "Clear All"
	clearAllBtn.TextColor3 = Color3.fromRGB(200, 100, 100)
	clearAllBtn.TextSize = 8
	clearAllBtn.Font = UI_FONT
	clearAllBtn.ZIndex = 201
	clearAllBtn.Parent = historyHeader

	local clearCorner = Instance.new("UICorner")
	clearCorner.CornerRadius = UDim.new(0, 4)
	clearCorner.Parent = clearAllBtn

	local historyDivider = Instance.new("Frame")
	historyDivider.Name = "Divider"
	historyDivider.Size = UDim2.new(1, -16, 0, 1)
	historyDivider.Position = UDim2.new(0, 8, 0, 30)
	historyDivider.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	historyDivider.BorderSizePixel = 0
	historyDivider.ZIndex = 201
	historyDivider.Parent = notifHistoryPanel

	local historyList = Instance.new("ScrollingFrame")
	historyList.Name = "List"
	historyList.Size = UDim2.new(1, 0, 1, -36)
	historyList.Position = UDim2.new(0, 0, 0, 34)
	historyList.BackgroundTransparency = 1
	historyList.BorderSizePixel = 0
	historyList.ScrollBarThickness = 2
	historyList.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 65)
	historyList.CanvasSize = UDim2.new(0, 0, 0, 0)
	historyList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	historyList.ZIndex = 201
	historyList.Parent = notifHistoryPanel

	local historyListLayout = Instance.new("UIListLayout")
	historyListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	historyListLayout.Padding = UDim.new(0, 4)
	historyListLayout.Parent = historyList

	local historyPadding = Instance.new("UIPadding")
	historyPadding.PaddingLeft = UDim.new(0, 8)
	historyPadding.PaddingRight = UDim.new(0, 8)
	historyPadding.Parent = historyList

	local settingsPanel = Instance.new("Frame")
	settingsPanel.Name = "SettingsPanel"
	settingsPanel.Size = UDim2.new(0, 260, 0, 0)
	settingsPanel.Position = UDim2.new(1, -268, 0, 42)
	settingsPanel.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	settingsPanel.BorderSizePixel = 0
	settingsPanel.ZIndex = 200
	settingsPanel.ClipsDescendants = true
	settingsPanel.Visible = false
	settingsPanel.Parent = mainFrame

	local settingsCorner = Instance.new("UICorner")
	settingsCorner.CornerRadius = UDim.new(0, 8)
	settingsCorner.Parent = settingsPanel

	local settingsStroke = Instance.new("UIStroke")
	settingsStroke.Color = Color3.fromRGB(35, 35, 45)
	settingsStroke.Thickness = 1
	settingsStroke.Parent = settingsPanel

	local settingsHeader = Instance.new("Frame")
	settingsHeader.Name = "Header"
	settingsHeader.Size = UDim2.new(1, 0, 0, 30)
	settingsHeader.BackgroundTransparency = 1
	settingsHeader.ZIndex = 201
	settingsHeader.Parent = settingsPanel

	local settingsTitle = Instance.new("TextLabel")
	settingsTitle.Name = "Title"
	settingsTitle.Size = UDim2.new(1, -20, 1, 0)
	settingsTitle.Position = UDim2.new(0, 10, 0, 0)
	settingsTitle.BackgroundTransparency = 1
	settingsTitle.Text = "Theme"
	settingsTitle.TextColor3 = Color3.fromRGB(240, 240, 245)
	settingsTitle.TextSize = 10
	settingsTitle.Font = UI_FONT
	settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
	settingsTitle.ZIndex = 201
	settingsTitle.Parent = settingsHeader

	local settingsDivider = Instance.new("Frame")
	settingsDivider.Name = "Divider"
	settingsDivider.Size = UDim2.new(1, -16, 0, 1)
	settingsDivider.Position = UDim2.new(0, 8, 0, 30)
	settingsDivider.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	settingsDivider.BorderSizePixel = 0
	settingsDivider.ZIndex = 201
	settingsDivider.Parent = settingsPanel

	local settingsList = Instance.new("ScrollingFrame")
	settingsList.Name = "List"
	settingsList.Size = UDim2.new(1, 0, 1, -36)
	settingsList.Position = UDim2.new(0, 0, 0, 34)
	settingsList.BackgroundTransparency = 1
	settingsList.BorderSizePixel = 0
	settingsList.ScrollBarThickness = 2
	settingsList.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 65)
	settingsList.CanvasSize = UDim2.new(0, 0, 0, 0)
	settingsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	settingsList.ZIndex = 201
	settingsList.Parent = settingsPanel

	local settingsListLayout = Instance.new("UIListLayout")
	settingsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	settingsListLayout.Padding = UDim.new(0, 8)
	settingsListLayout.Parent = settingsList

	local settingsPadding = Instance.new("UIPadding")
	settingsPadding.PaddingLeft = UDim.new(0, 8)
	settingsPadding.PaddingRight = UDim.new(0, 8)
	settingsPadding.PaddingTop = UDim.new(0, 4)
	settingsPadding.Parent = settingsList

	local tabButtons = Window.TabButtons
	local dynamicThemeElements = Window.DynamicThemeElements

	local function updateGradients()
		local theme = Window.Themes[Window.ActiveTheme]
		if not theme then return end
		local startColor = theme.Accent
		local endColor = Color3.new(
			math.clamp(theme.Accent.R * 0.4, 0, 1),
			math.clamp(theme.Accent.G * 0.4, 0, 1),
			math.clamp(theme.Accent.B * 0.4, 0, 1)
		)

		for _, item in ipairs(dynamicThemeElements) do
			if item.Type == "Gradient" and item.Object then
				item.Object.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, startColor),
					ColorSequenceKeypoint.new(1, endColor)
				})
			end
		end
	end

	local function applyTheme(themeName)
		local theme = Window.Themes[themeName]
		if not theme then return end
		Window.ActiveTheme = themeName
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

		TweenService:Create(mainFrame, tweenInfo, {BackgroundColor3 = theme.Main}):Play()
		TweenService:Create(topbar, tweenInfo, {BackgroundColor3 = theme.Top}):Play()

		for _, item in ipairs(dynamicThemeElements) do
			if item.Object and item.Object.Parent then
				if item.Type == "Accent" then
					if item.Object:IsA("ImageLabel") or item.Object:IsA("ImageButton") then
						TweenService:Create(item.Object, tweenInfo, {ImageColor3 = theme.Accent}):Play()
					elseif item.Object:IsA("TextLabel") or item.Object:IsA("TextButton") then
						TweenService:Create(item.Object, tweenInfo, {TextColor3 = theme.Accent}):Play()
					elseif item.Object:IsA("Frame") then
						TweenService:Create(item.Object, tweenInfo, {BackgroundColor3 = theme.Accent}):Play()
					end
				elseif item.Type == "Card" then
					TweenService:Create(item.Object, tweenInfo, {BackgroundColor3 = theme.Card}):Play()
				elseif item.Type == "DynamicToggle" then
					if item.GetValue and item.GetValue() then
						TweenService:Create(item.Object, tweenInfo, {BackgroundColor3 = theme.Accent}):Play()
					end
				elseif item.Type == "DynamicAccentText" then
					if item.GetValue and item.GetValue() then
						TweenService:Create(item.Object, tweenInfo, {TextColor3 = theme.Accent}):Play()
					end
				end
			end
		end

		for tName, btnObj in pairs(tabButtons) do
			if tName == Window.ActiveTabName then
				TweenService:Create(btnObj.Icon, tweenInfo, {ImageColor3 = theme.Accent}):Play()
			end
		end

		updateGradients()
	end

	Window.ApplyTheme = applyTheme
	Window.UpdateGradients = updateGradients

	local historyOpen = false
	local settingsOpen = false

	local function addHistoryEntry(msgText)
		local item = Instance.new("Frame")
		item.Name = "HistoryItem"
		item.Size = UDim2.new(1, 0, 0, 24)
		item.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
		item.BorderSizePixel = 0
		item.ZIndex = 202
		item.Parent = historyList

		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 4)
		itemCorner.Parent = item

		local itemIcon = Instance.new("ImageLabel")
		itemIcon.Name = "Icon"
		itemIcon.Size = UDim2.new(0, 10, 0, 10)
		itemIcon.Position = UDim2.new(0, 6, 0.5, -5)
		itemIcon.BackgroundTransparency = 1
		ApplyIcon(itemIcon, "bell")
		itemIcon.ImageColor3 = Window.Themes[Window.ActiveTheme].Accent
		itemIcon.ZIndex = 203
		itemIcon.Parent = item
		table.insert(dynamicThemeElements, {Object = itemIcon, Type = "Accent"})

		local itemTxt = Instance.new("TextLabel")
		itemTxt.Name = "Text"
		itemTxt.Size = UDim2.new(1, -22, 1, 0)
		itemTxt.Position = UDim2.new(0, 20, 0, 0)
		itemTxt.BackgroundTransparency = 1
		itemTxt.Text = msgText
		itemTxt.TextColor3 = Color3.fromRGB(210, 210, 220)
		itemTxt.TextSize = 8
		itemTxt.Font = UI_FONT
		itemTxt.TextXAlignment = Enum.TextXAlignment.Left
		itemTxt.TextTruncate = Enum.TextTruncate.AtEnd
		itemTxt.ZIndex = 203
		itemTxt.Parent = item
	end

	local function showNotification(msgText)
		addHistoryEntry(msgText)

		local notif = Instance.new("Frame")
		notif.Name = "Notif"
		notif.Size = UDim2.new(1, 0, 0, 32)
		notif.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
		notif.BorderSizePixel = 0
		notif.ZIndex = 101
		notif.Parent = notifContainer

		local notifCorner = Instance.new("UICorner")
		notifCorner.CornerRadius = UDim.new(0, 6)
		notifCorner.Parent = notif

		local notifIcon = Instance.new("ImageLabel")
		notifIcon.Name = "Icon"
		notifIcon.Size = UDim2.new(0, 14, 0, 14)
		notifIcon.Position = UDim2.new(0, 8, 0.5, -7)
		notifIcon.BackgroundTransparency = 1
		ApplyIcon(notifIcon, "bell")
		notifIcon.ImageColor3 = Window.Themes[Window.ActiveTheme].Accent
		notifIcon.ZIndex = 102
		notifIcon.Parent = notif
		table.insert(dynamicThemeElements, {Object = notifIcon, Type = "Accent"})

		local txt = Instance.new("TextLabel")
		txt.Name = "Text"
		txt.Size = UDim2.new(1, -30, 1, 0)
		txt.Position = UDim2.new(0, 26, 0, 0)
		txt.BackgroundTransparency = 1
		txt.Text = msgText
		txt.TextColor3 = Color3.fromRGB(240, 240, 245)
		txt.TextSize = 10
		txt.Font = UI_FONT
		txt.TextXAlignment = Enum.TextXAlignment.Left
		txt.ZIndex = 102
		txt.Parent = notif

		task.delay(3, function()
			if notif and notif.Parent then
				notif:Destroy()
			end
		end)
	end

	Window.Notify = showNotification

	local function toggleHistory()
		historyOpen = not historyOpen
		local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		if historyOpen then
			if settingsOpen then
				settingsOpen = false
				TweenService:Create(settingsPanel, tweenInfo, {Size = UDim2.new(0, 260, 0, 0)}):Play()
				TweenService:Create(gearBtn, tweenInfo, {ImageColor3 = Color3.fromRGB(150, 150, 165)}):Play()
				task.delay(0.25, function() if not settingsOpen then settingsPanel.Visible = false end end)
			end
			notifHistoryPanel.Visible = true
			TweenService:Create(notifHistoryPanel, tweenInfo, {Size = UDim2.new(0, 230, 0, 180)}):Play()
			TweenService:Create(bellBtn, tweenInfo, {ImageColor3 = Window.Themes[Window.ActiveTheme].Accent}):Play()
		else
			local tw = TweenService:Create(notifHistoryPanel, tweenInfo, {Size = UDim2.new(0, 230, 0, 0)})
			tw:Play()
			TweenService:Create(bellBtn, tweenInfo, {ImageColor3 = Color3.fromRGB(150, 150, 165)}):Play()
			tw.Completed:Connect(function()
				if not historyOpen then
					notifHistoryPanel.Visible = false
				end
			end)
		end
	end

	local function toggleSettings()
		settingsOpen = not settingsOpen
		local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		if settingsOpen then
			if historyOpen then
				historyOpen = false
				TweenService:Create(notifHistoryPanel, tweenInfo, {Size = UDim2.new(0, 230, 0, 0)}):Play()
				TweenService:Create(bellBtn, tweenInfo, {ImageColor3 = Color3.fromRGB(150, 150, 165)}):Play()
				task.delay(0.25, function() if not historyOpen then notifHistoryPanel.Visible = false end end)
			end
			settingsPanel.Visible = true
			TweenService:Create(settingsPanel, tweenInfo, {Size = UDim2.new(0, 260, 0, 400)}):Play()
			TweenService:Create(gearBtn, tweenInfo, {ImageColor3 = Window.Themes[Window.ActiveTheme].Accent}):Play()
		else
			local tw = TweenService:Create(settingsPanel, tweenInfo, {Size = UDim2.new(0, 260, 0, 0)})
			tw:Play()
			TweenService:Create(gearBtn, tweenInfo, {ImageColor3 = Color3.fromRGB(150, 150, 165)}):Play()
			tw.Completed:Connect(function()
				if not settingsOpen then
					settingsPanel.Visible = false
				end
			end)
		end
	end

	bellBtn.MouseButton1Click:Connect(toggleHistory)
	gearBtn.MouseButton1Click:Connect(toggleSettings)

	clearAllBtn.MouseButton1Click:Connect(function()
		for _, child in ipairs(historyList:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
	end)

	local function buildThemeGUI()
		local themeLabel = Instance.new("TextLabel")
		themeLabel.Name = "ThemeLabel"
		themeLabel.Size = UDim2.new(1, 0, 0, 14)
		themeLabel.BackgroundTransparency = 1
		themeLabel.Text = "Theme Selector"
		themeLabel.TextColor3 = Color3.fromRGB(210, 210, 220)
		themeLabel.TextSize = 9
		themeLabel.Font = UI_FONT
		themeLabel.TextXAlignment = Enum.TextXAlignment.Left
		themeLabel.ZIndex = 202
		themeLabel.Parent = settingsList

		local themeGrid = Instance.new("Frame")
		themeGrid.Name = "ThemeGrid"
		themeGrid.Size = UDim2.new(1, 0, 0, 0)
		themeGrid.AutomaticSize = Enum.AutomaticSize.Y
		themeGrid.BackgroundTransparency = 1
		themeGrid.ZIndex = 202
		themeGrid.Parent = settingsList

		local gridLayout = Instance.new("UIGridLayout")
		gridLayout.CellSize = UDim2.new(0.48, 0, 0, 24)
		gridLayout.CellPadding = UDim2.new(0.04, 0, 0, 6)
		gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
		gridLayout.Parent = themeGrid

		local themeButtons = {}

		for tName, tData in pairs(Window.Themes) do
			local tBtn = Instance.new("TextButton")
			tBtn.Name = tName
			tBtn.Size = UDim2.new(1, 0, 1, 0)
			tBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
			tBtn.BorderSizePixel = 0
			tBtn.Text = ""
			tBtn.AutoButtonColor = false
			tBtn.ZIndex = 203
			tBtn.Parent = themeGrid

			local tCorner = Instance.new("UICorner")
			tCorner.CornerRadius = UDim.new(0, 5)
			tCorner.Parent = tBtn

			local tStroke = Instance.new("UIStroke")
			tStroke.Color = (tName == Window.ActiveTheme) and tData.Accent or Color3.fromRGB(40, 40, 50)
			tStroke.Thickness = 1
			tStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			tStroke.Parent = tBtn

			local previewDot = Instance.new("Frame")
			previewDot.Name = "Dot"
			previewDot.Size = UDim2.new(0, 8, 0, 8)
			previewDot.Position = UDim2.new(0, 8, 0.5, -4)
			previewDot.BackgroundColor3 = tData.Accent
			previewDot.BorderSizePixel = 0
			previewDot.ZIndex = 204
			previewDot.Parent = tBtn

			local dotCorner = Instance.new("UICorner")
			dotCorner.CornerRadius = UDim.new(1, 0)
			dotCorner.Parent = previewDot

			local tTxt = Instance.new("TextLabel")
			tTxt.Name = "Text"
			tTxt.Size = UDim2.new(1, -22, 1, 0)
			tTxt.Position = UDim2.new(0, 22, 0, 0)
			tTxt.BackgroundTransparency = 1
			tTxt.Text = tName
			tTxt.TextColor3 = (tName == Window.ActiveTheme) and Color3.fromRGB(240, 240, 245) or Color3.fromRGB(160, 160, 175)
			tTxt.TextSize = 8
			tTxt.Font = UI_FONT
			tTxt.TextXAlignment = Enum.TextXAlignment.Left
			tTxt.ZIndex = 204
			tTxt.Parent = tBtn

			themeButtons[tName] = {Stroke = tStroke, Text = tTxt}

			tBtn.MouseButton1Click:Connect(function()
				applyTheme(tName)
				for name, items in pairs(themeButtons) do
					local isSelected = (name == tName)
					items.Stroke.Color = isSelected and Window.Themes[name].Accent or Color3.fromRGB(40, 40, 50)
					items.Text.TextColor3 = isSelected and Color3.fromRGB(240, 240, 245) or Color3.fromRGB(160, 160, 175)
				end
				showNotification("Theme changed to " .. tName)
			end)
		end
	end

	buildThemeGUI()

	local function buildConfigManager(parent)
			local nameRow = Instance.new("Frame")
			nameRow.Name = "ConfigNameRow"
			nameRow.Size = UDim2.new(1, 0, 0, 40)
			nameRow.BackgroundTransparency = 1
			nameRow.Parent = parent

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "Label"
			nameLabel.Size = UDim2.new(1, 0, 0, 14)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = "Config Name"
			nameLabel.TextColor3 = Color3.fromRGB(210, 210, 220)
			nameLabel.TextSize = 10
			nameLabel.Font = UI_FONT
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = nameRow

			local nameInputFrame = Instance.new("Frame")
			nameInputFrame.Name = "Box"
			nameInputFrame.Size = UDim2.new(1, 0, 0, 22)
			nameInputFrame.Position = UDim2.new(0, 0, 0, 18)
			nameInputFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
			nameInputFrame.BorderSizePixel = 0
			nameInputFrame.Parent = nameRow

			local nameInputCorner = Instance.new("UICorner")
			nameInputCorner.CornerRadius = UDim.new(0, 5)
			nameInputCorner.Parent = nameInputFrame

			local nameBox = Instance.new("TextBox")
			nameBox.Name = "TextBox"
			nameBox.Size = UDim2.new(1, -12, 1, 0)
			nameBox.Position = UDim2.new(0, 6, 0, 0)
			nameBox.BackgroundTransparency = 1
			nameBox.Text = ""
			nameBox.PlaceholderText = "New config name"
			nameBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 125)
			nameBox.TextColor3 = Color3.fromRGB(200, 200, 215)
			nameBox.TextSize = 9
			nameBox.Font = UI_FONT
			nameBox.TextXAlignment = Enum.TextXAlignment.Left
			nameBox.Parent = nameInputFrame

			local selectLabel = Instance.new("TextLabel")
			selectLabel.Name = "SelectLabel"
			selectLabel.Size = UDim2.new(1, 0, 0, 14)
			selectLabel.BackgroundTransparency = 1
			selectLabel.Text = "Saved Configs"
			selectLabel.TextColor3 = Color3.fromRGB(210, 210, 220)
			selectLabel.TextSize = 10
			selectLabel.Font = UI_FONT
			selectLabel.TextXAlignment = Enum.TextXAlignment.Left
			selectLabel.Parent = parent

			local cfgDropBox = Instance.new("TextButton")
			cfgDropBox.Name = "CfgBox"
			cfgDropBox.Size = UDim2.new(1, 0, 0, 24)
			cfgDropBox.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
			cfgDropBox.BorderSizePixel = 0
			cfgDropBox.Text = ""
			cfgDropBox.AutoButtonColor = false
			cfgDropBox.Parent = parent

			local cfgDropCorner = Instance.new("UICorner")
			cfgDropCorner.CornerRadius = UDim.new(0, 5)
			cfgDropCorner.Parent = cfgDropBox

			local cfgValLabel = Instance.new("TextLabel")
			cfgValLabel.Name = "Value"
			cfgValLabel.Size = UDim2.new(1, -20, 1, 0)
			cfgValLabel.Position = UDim2.new(0, 8, 0, 0)
			cfgValLabel.BackgroundTransparency = 1
			cfgValLabel.Text = "None Selected"
			cfgValLabel.TextColor3 = Color3.fromRGB(140, 140, 155)
			cfgValLabel.TextSize = 9
			cfgValLabel.Font = UI_FONT
			cfgValLabel.TextXAlignment = Enum.TextXAlignment.Left
			cfgValLabel.Parent = cfgDropBox

			local cfgArrow = Instance.new("ImageLabel")
			cfgArrow.Name = "Arrow"
			cfgArrow.Size = UDim2.new(0, 10, 0, 10)
			cfgArrow.Position = UDim2.new(1, -14, 0.5, -5)
			cfgArrow.BackgroundTransparency = 1
			ApplyIcon(cfgArrow, "chevron-down")
			cfgArrow.ImageColor3 = Color3.fromRGB(110, 110, 125)
			cfgArrow.Parent = cfgDropBox

			local cfgDropContainer = Instance.new("Frame")
			cfgDropContainer.Name = "CfgDropContainer"
			cfgDropContainer.Size = UDim2.new(1, 0, 0, 0)
			cfgDropContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
			cfgDropContainer.BorderSizePixel = 0
			cfgDropContainer.Visible = false
			cfgDropContainer.ClipsDescendants = true
			cfgDropContainer.ZIndex = 25
			cfgDropContainer.Parent = parent

			local cfgDropListCorner = Instance.new("UICorner")
			cfgDropListCorner.CornerRadius = UDim.new(0, 5)
			cfgDropListCorner.Parent = cfgDropContainer

			local cfgDropLayout = Instance.new("UIListLayout")
			cfgDropLayout.SortOrder = Enum.SortOrder.LayoutOrder
			cfgDropLayout.Parent = cfgDropContainer

			local autoloadLabel = Instance.new("TextLabel")
			autoloadLabel.Name = "AutoloadLabel"
			autoloadLabel.Size = UDim2.new(1, 0, 0, 14)
			autoloadLabel.BackgroundTransparency = 1
			autoloadLabel.Text = "Autoload: None"
			autoloadLabel.TextColor3 = Color3.fromRGB(150, 150, 165)
			autoloadLabel.TextSize = 8
			autoloadLabel.Font = UI_FONT
			autoloadLabel.TextXAlignment = Enum.TextXAlignment.Left
			autoloadLabel.Parent = parent

			local actionGroup1 = Instance.new("Frame")
			actionGroup1.Name = "ActionGroup1"
			actionGroup1.Size = UDim2.new(1, 0, 0, 22)
			actionGroup1.BackgroundTransparency = 1
			actionGroup1.Parent = parent

			local actionLayout1 = Instance.new("UIListLayout")
			actionLayout1.FillDirection = Enum.FillDirection.Horizontal
			actionLayout1.Padding = UDim.new(0, 6)
			actionLayout1.Parent = actionGroup1

			local function makeActionButton(parentGroup, w, text, color)
				local b = Instance.new("TextButton")
				b.Name = text .. "Btn"
				b.Size = UDim2.new(w, 0, 1, 0)
				b.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
				b.BorderSizePixel = 0
				b.Text = text
				b.TextColor3 = color
				b.TextSize = 8
				b.Font = UI_FONT
				b.Parent = parentGroup

				local c = Instance.new("UICorner")
				c.CornerRadius = UDim.new(0, 4)
				c.Parent = b

				return b
			end

			local saveBtn = makeActionButton(actionGroup1, 0.32, "Save", Color3.fromRGB(100, 220, 120))
			local loadBtn = makeActionButton(actionGroup1, 0.32, "Load", Color3.fromRGB(80, 160, 255))
			local overwriteBtn = makeActionButton(actionGroup1, 0.36, "Overwrite", Color3.fromRGB(245, 170, 50))

			local actionGroup2 = Instance.new("Frame")
			actionGroup2.Name = "ActionGroup2"
			actionGroup2.Size = UDim2.new(1, 0, 0, 22)
			actionGroup2.BackgroundTransparency = 1
			actionGroup2.Parent = parent

			local actionLayout2 = Instance.new("UIListLayout")
			actionLayout2.FillDirection = Enum.FillDirection.Horizontal
			actionLayout2.Padding = UDim.new(0, 6)
			actionLayout2.Parent = actionGroup2

			local autoloadBtn = makeActionButton(actionGroup2, 0.48, "Set As Autoload", Color3.fromRGB(170, 130, 255))
			local removeAutoloadBtn = makeActionButton(actionGroup2, 0.48, "Remove Autoload", Color3.fromRGB(220, 90, 90))

			table.insert(dynamicThemeElements, {Object = loadBtn, Type = "Accent"})

			local function getConfigPath(name)
				return Window.ConfigFolder .. "/" .. name .. ".json"
			end

			local function refreshConfigList()
				Window.SavedConfigs = {}
				if isfolder(Window.ConfigFolder) then
					for _, file in ipairs(listfiles(Window.ConfigFolder)) do
						local name = file:match("([^/\\]+)%.json$")
						if name then
							table.insert(Window.SavedConfigs, name)
						end
					end
				end
			end

			local function collectFlagValues()
				local data = {}
				for flagName, element in pairs(Library.Flags) do
					if element.Get then
						local ok, value = pcall(element.Get)
						if ok then
							data[flagName] = value
						end
					end
				end
				return data
			end

			local function applyFlagValues(data)
				for flagName, value in pairs(data) do
					local element = Library.Flags[flagName]
					if element and element.Set then
						pcall(element.Set, value)
					end
				end
			end

			local function saveConfig(name, overwrite)
				if not name or name == "" then
					showNotification("Config name empty")
					return
				end

				local path = getConfigPath(name)
				if isfile(path) and not overwrite then
					showNotification("Config already exists")
					return
				end

				local data = collectFlagValues()
				local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
				if ok then
					writefile(path, encoded)
					refreshConfigList()
					rebuildCfgDropdown()
					showNotification((overwrite and "Overwritten: " or "Saved: ") .. name)
				else
					showNotification("Failed to save config")
				end
			end

			local function loadConfig(name)
				if not name then
					showNotification("No config selected")
					return
				end

				local path = getConfigPath(name)
				if not isfile(path) then
					showNotification("Config not found")
					return
				end

				local ok, content = pcall(readfile, path)
				if not ok then
					showNotification("Failed to read config")
					return
				end

				local ok2, data = pcall(HttpService.JSONDecode, HttpService, content)
				if ok2 and type(data) == "table" then
					applyFlagValues(data)
					showNotification("Loaded: " .. name)
				else
					showNotification("Failed to parse config")
				end
			end

			local function getAutoloadPath()
				return Window.ConfigFolder .. "/autoload.txt"
			end

			local function setAutoload(name)
				writefile(getAutoloadPath(), name)
				Window.AutoloadConfig = name
				autoloadLabel.Text = "Autoload: " .. name
				showNotification("Autoload set to " .. name)
			end

			local function removeAutoload()
				if isfile(getAutoloadPath()) then
					delfile(getAutoloadPath())
				end
				Window.AutoloadConfig = nil
				autoloadLabel.Text = "Autoload: None"
				showNotification("Autoload removed")
			end

			local function loadAutoloadIfExists()
				local path = getAutoloadPath()
				if isfile(path) then
					local ok, name = pcall(readfile, path)
					if ok and name and name ~= "" then
						Window.AutoloadConfig = name
						autoloadLabel.Text = "Autoload: " .. name
						loadConfig(name)
					end
				end
			end

			local isCfgOpen = false
			local rebuildCfgDropdown

			rebuildCfgDropdown = function()
				for _, c in ipairs(cfgDropContainer:GetChildren()) do
					if c:IsA("TextButton") then c:Destroy() end
				end

				if #Window.SavedConfigs == 0 then
					cfgValLabel.Text = "No Configs"
					cfgValLabel.TextColor3 = Color3.fromRGB(140, 140, 155)
					return
				end

				for _, cfgName in ipairs(Window.SavedConfigs) do
					local optBtn = Instance.new("TextButton")
					optBtn.Name = cfgName
					optBtn.Size = UDim2.new(1, 0, 0, 22)
					optBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
					optBtn.BorderSizePixel = 0
					optBtn.Text = cfgName
					optBtn.TextColor3 = Color3.fromRGB(180, 180, 195)
					optBtn.TextSize = 9
					optBtn.Font = UI_FONT
					optBtn.ZIndex = 26
					optBtn.Parent = cfgDropContainer

					optBtn.MouseButton1Click:Connect(function()
						Window.SelectedConfig = cfgName
						cfgValLabel.Text = cfgName
						cfgValLabel.TextColor3 = Color3.fromRGB(220, 220, 235)
						if isCfgOpen then
							isCfgOpen = false
							cfgDropContainer.Visible = false
							cfgDropContainer.Size = UDim2.new(1, 0, 0, 0)
						end
					end)
				end
			end

			local function toggleCfgDrop()
				refreshConfigList()
				rebuildCfgDropdown()
				if #Window.SavedConfigs == 0 then return end
				isCfgOpen = not isCfgOpen
				cfgDropContainer.Visible = isCfgOpen
				if isCfgOpen then
					cfgDropContainer.Size = UDim2.new(1, 0, 0, math.min(#Window.SavedConfigs, 5) * 22)
				else
					cfgDropContainer.Size = UDim2.new(1, 0, 0, 0)
				end
			end

			cfgDropBox.MouseButton1Click:Connect(toggleCfgDrop)

			saveBtn.MouseButton1Click:Connect(function()
				saveConfig(nameBox.Text, false)
				nameBox.Text = ""
			end)

			loadBtn.MouseButton1Click:Connect(function()
				loadConfig(Window.SelectedConfig)
			end)

			overwriteBtn.MouseButton1Click:Connect(function()
				if Window.SelectedConfig then
					saveConfig(Window.SelectedConfig, true)
				else
					showNotification("No config selected")
				end
			end)

			autoloadBtn.MouseButton1Click:Connect(function()
				if Window.SelectedConfig then
					setAutoload(Window.SelectedConfig)
				else
					showNotification("No config selected")
				end
			end)

			removeAutoloadBtn.MouseButton1Click:Connect(function()
				removeAutoload()
			end)

			refreshConfigList()
			rebuildCfgDropdown()
			loadAutoloadIfExists()
	end

	Window.ConfigSystemBuilt = false

	function Window:CreateConfigSystem()
		if Window.ConfigSystemBuilt then return end
		Window.ConfigSystemBuilt = true

		local configDivider = Instance.new("Frame")
		configDivider.Name = "ConfigDivider"
		configDivider.Size = UDim2.new(1, 0, 0, 1)
		configDivider.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
		configDivider.BorderSizePixel = 0
		configDivider.Parent = settingsList

		buildConfigManager(settingsList)
	end

	Window:CreateConfigSystem()


	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.new(0, 0, 0, 42)
	divider.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
	divider.BorderSizePixel = 0
	divider.Parent = topbar

	local navBar = Instance.new("ScrollingFrame")
	navBar.Name = "NavContainer"
	navBar.Size = UDim2.new(1, -25, 0, 38)
	navBar.Position = UDim2.new(0, 8, 0, 42)
	navBar.BackgroundTransparency = 1
	navBar.BorderSizePixel = 0
	navBar.CanvasSize = UDim2.new(0, 0, 0, 0)
	navBar.AutomaticCanvasSize = Enum.AutomaticSize.X
	navBar.ScrollBarThickness = 0
	navBar.ScrollingDirection = Enum.ScrollingDirection.X
	navBar.Parent = topbar

	local navLayout = Instance.new("UIListLayout")
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	navLayout.Padding = UDim.new(0, 6)
	navLayout.Parent = navBar

	local arrowNext = Instance.new("ImageButton")
	arrowNext.Name = "ArrowNext"
	arrowNext.Size = UDim2.new(0, 14, 0, 14)
	arrowNext.Position = UDim2.new(1, -16, 0, 54)
	arrowNext.BackgroundTransparency = 1
	ApplyIcon(arrowNext, "chevron-right")
	arrowNext.ImageColor3 = Color3.fromRGB(110, 110, 125)
	arrowNext.Parent = topbar

	arrowNext.MouseButton1Click:Connect(function()
		navBar.CanvasPosition = Vector2.new(navBar.CanvasPosition.X + 80, 0)
	end)

	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, -16, 1, -118)
	contentArea.Position = UDim2.new(0, 8, 0, 86)
	contentArea.BackgroundTransparency = 1
	contentArea.Parent = mainFrame
	Window.ContentArea = contentArea

	local footer = Instance.new("Frame")
	footer.Name = "Footer"
	footer.Size = UDim2.new(1, 0, 0, 24)
	footer.Position = UDim2.new(0, 0, 1, -24)
	footer.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
	footer.BorderSizePixel = 0
	footer.Parent = mainFrame

	local footerCorner = Instance.new("UICorner")
	footerCorner.CornerRadius = UDim.new(0, 8)
	footerCorner.Parent = footer

	local function switchTab(tabName)
		Window.ActiveTabName = tabName
		for name, data in pairs(Window.TabFrames) do
			data.Page.Visible = (name == tabName)
		end

		for name, btnObj in pairs(tabButtons) do
			local isActive = (name == tabName)
			btnObj.Btn.BackgroundColor3 = isActive and Color3.fromRGB(28, 24, 22) or Color3.fromRGB(0, 0, 0)
			btnObj.Btn.BackgroundTransparency = isActive and 0 or 1
			btnObj.Icon.ImageColor3 = isActive and Window.Themes[Window.ActiveTheme].Accent or Color3.fromRGB(110, 110, 125)
			btnObj.Txt.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(110, 110, 125)
			btnObj.Underline.Visible = isActive
		end
	end

	Window.SwitchTab = switchTab

	local searchItems = Window.SearchItems

	local function updateSearchDropdown()
		local query = string.lower(searchBox.Text)
		for _, child in ipairs(searchDropList:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end

		if query == "" then
			searchDropdown.Visible = false
			searchDropdown.Size = UDim2.new(0, 160, 0, 0)
			return
		end

		local count = 0
		for _, item in ipairs(searchItems) do
			if string.find(string.lower(item.Name), query) then
				count = count + 1
				local resBtn = Instance.new("TextButton")
				resBtn.Name = "SearchResult"
				resBtn.Size = UDim2.new(1, 0, 0, 22)
				resBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
				resBtn.BorderSizePixel = 0
				resBtn.Text = "  " .. item.Name
				resBtn.TextColor3 = Color3.fromRGB(200, 200, 215)
				resBtn.TextSize = 9
				resBtn.Font = UI_FONT
				resBtn.TextXAlignment = Enum.TextXAlignment.Left
				resBtn.TextTruncate = Enum.TextTruncate.AtEnd
				resBtn.ZIndex = 252
				resBtn.Parent = searchDropList

				local resCorner = Instance.new("UICorner")
				resCorner.CornerRadius = UDim.new(0, 4)
				resCorner.Parent = resBtn

				resBtn.MouseEnter:Connect(function()
					resBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
				end)
				resBtn.MouseLeave:Connect(function()
					resBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
				end)

				resBtn.MouseButton1Click:Connect(function()
					if item.Tab then
						switchTab(item.Tab)
					end
					searchBox.Text = ""
					searchDropdown.Visible = false

					if item.Frame then
						local origTrans = item.Frame.BackgroundTransparency
						item.Frame.BackgroundTransparency = 0.5
						item.Frame.BackgroundColor3 = Window.Themes[Window.ActiveTheme].Accent
						task.delay(0.5, function()
							item.Frame.BackgroundTransparency = origTrans
						end)
					end
				end)
			end
		end

		if count > 0 then
			searchDropdown.Visible = true
			searchDropdown.Size = UDim2.new(0, 160, 0, math.min(count, 5) * 26 + 8)
		else
			searchDropdown.Visible = false
			searchDropdown.Size = UDim2.new(0, 160, 0, 0)
		end
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(updateSearchDropdown)



	function Window:CreateTab(tabName, icon)
		local page = Instance.new("Frame")
		page.Name = tabName .. "Page"
		page.Size = UDim2.new(1, 0, 1, 0)
		page.BackgroundTransparency = 1
		page.Visible = false
		page.Parent = contentArea

		local leftColumn = Instance.new("ScrollingFrame")
		leftColumn.Name = "LeftColumn"
		leftColumn.Size = UDim2.new(0.49, 0, 1, 0)
		leftColumn.Position = UDim2.new(0, 0, 0, 0)
		leftColumn.BackgroundTransparency = 1
		leftColumn.BorderSizePixel = 0
		leftColumn.ScrollBarThickness = 2
		leftColumn.ScrollBarImageColor3 = Color3.fromRGB(40, 40, 50)
		leftColumn.CanvasSize = UDim2.new(0, 0, 0, 0)
		leftColumn.AutomaticCanvasSize = Enum.AutomaticSize.Y
		leftColumn.Parent = page

		local leftLayout = Instance.new("UIListLayout")
		leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
		leftLayout.Padding = UDim.new(0, 8)
		leftLayout.Parent = leftColumn

		local rightColumn = Instance.new("ScrollingFrame")
		rightColumn.Name = "RightColumn"
		rightColumn.Size = UDim2.new(0.49, 0, 1, 0)
		rightColumn.Position = UDim2.new(0.51, 0, 0, 0)
		rightColumn.BackgroundTransparency = 1
		rightColumn.BorderSizePixel = 0
		rightColumn.ScrollBarThickness = 2
		rightColumn.ScrollBarImageColor3 = Color3.fromRGB(40, 40, 50)
		rightColumn.CanvasSize = UDim2.new(0, 0, 0, 0)
		rightColumn.AutomaticCanvasSize = Enum.AutomaticSize.Y
		rightColumn.Parent = page

		local rColLayout = Instance.new("UIListLayout")
		rColLayout.SortOrder = Enum.SortOrder.LayoutOrder
		rColLayout.Padding = UDim.new(0, 8)
		rColLayout.Parent = rightColumn

		Window.TabFrames[tabName] = {Page = page, Left = leftColumn, Right = rightColumn}

		local btn = Instance.new("TextButton")
		btn.Name = tabName .. "Tab"
		btn.Size = UDim2.new(0, 0, 0, 26)
		btn.AutomaticSize = Enum.AutomaticSize.X
		btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		btn.BackgroundTransparency = 1
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.Parent = navBar

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 5)
		btnCorner.Parent = btn

		local innerFrame = Instance.new("Frame")
		innerFrame.Name = "Inner"
		innerFrame.Size = UDim2.new(1, 0, 1, 0)
		innerFrame.BackgroundTransparency = 1
		innerFrame.Parent = btn

		local btnPadding = Instance.new("UIPadding")
		btnPadding.PaddingLeft = UDim.new(0, 8)
		btnPadding.PaddingRight = UDim.new(0, 8)
		btnPadding.Parent = innerFrame

		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0, 5)
		layout.Parent = innerFrame

		local icon2 = Instance.new("ImageLabel")
		icon2.Name = "Icon"
		icon2.Size = UDim2.new(0, 12, 0, 12)
		icon2.BackgroundTransparency = 1
		ApplyIcon(icon2, icon or "square")
		icon2.ImageColor3 = Color3.fromRGB(110, 110, 125)
		icon2.Parent = innerFrame

		local txt = Instance.new("TextLabel")
		txt.Name = "Title"
		txt.Size = UDim2.new(0, 0, 1, 0)
		txt.AutomaticSize = Enum.AutomaticSize.X
		txt.BackgroundTransparency = 1
		txt.Text = tabName
		txt.TextColor3 = Color3.fromRGB(110, 110, 125)
		txt.TextSize = 10
		txt.Font = UI_FONT
		txt.Parent = innerFrame

		local underline = Instance.new("Frame")
		underline.Name = "Underline"
		underline.Size = UDim2.new(1, 0, 0, 2)
		underline.Position = UDim2.new(0, 0, 1, -2)
		underline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		underline.BorderSizePixel = 0
		underline.Visible = false
		underline.Parent = btn

		local uGrad = Instance.new("UIGradient")
		uGrad.Name = "Grad"
		uGrad.Rotation = 0
		local initialAccent = Window.Themes[Window.ActiveTheme].Accent
		local initialDarker = Color3.new(
			math.clamp(initialAccent.R * 0.4, 0, 1),
			math.clamp(initialAccent.G * 0.4, 0, 1),
			math.clamp(initialAccent.B * 0.4, 0, 1)
		)
		uGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, initialAccent),
			ColorSequenceKeypoint.new(1, initialDarker)
		})
		uGrad.Parent = underline
		table.insert(dynamicThemeElements, {Object = uGrad, Type = "Gradient"})

		tabButtons[tabName] = {Btn = btn, Icon = icon2, Txt = txt, Underline = underline}

		btn.MouseButton1Click:Connect(function()
			switchTab(tabName)
		end)

		if Window.ActiveTabName == "" then
			switchTab(tabName)
		end

		local Tab = {}
		Tab.Name = tabName
		Tab.Left = leftColumn
		Tab.Right = rightColumn
		Tab.Window = Window

		function Tab:CreateSection(titleText, iconName, side)
			local parent = (side == "right") and rightColumn or leftColumn

			local sec = Instance.new("Frame")
			sec.Name = titleText .. "Section"
			sec.Size = UDim2.new(1, 0, 0, 0)
			sec.AutomaticSize = Enum.AutomaticSize.Y
			sec.BackgroundColor3 = Window.Themes[Window.ActiveTheme].Card
			sec.BorderSizePixel = 0
			sec.Parent = parent
			table.insert(dynamicThemeElements, {Object = sec, Type = "Card"})

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = sec

			local padding = Instance.new("UIPadding")
			padding.PaddingLeft = UDim.new(0, 8)
			padding.PaddingRight = UDim.new(0, 8)
			padding.PaddingTop = UDim.new(0, 8)
			padding.PaddingBottom = UDim.new(0, 8)
			padding.Parent = sec

			local layout2 = Instance.new("UIListLayout")
			layout2.SortOrder = Enum.SortOrder.LayoutOrder
			layout2.Padding = UDim.new(0, 6)
			layout2.Parent = sec

			local secHeader = Instance.new("Frame")
			secHeader.Name = "SectionHeader"
			secHeader.Size = UDim2.new(1, 0, 0, 20)
			secHeader.BackgroundTransparency = 1
			secHeader.LayoutOrder = 0
			secHeader.Parent = sec

			local hIcon = Instance.new("ImageLabel")
			hIcon.Name = "HeaderIcon"
			hIcon.Size = UDim2.new(0, 14, 0, 14)
			hIcon.Position = UDim2.new(0, 0, 0, 3)
			hIcon.BackgroundTransparency = 1
			ApplyIcon(hIcon, iconName or "square")
			hIcon.ImageColor3 = Window.Themes[Window.ActiveTheme].Accent
			hIcon.Parent = secHeader
			table.insert(dynamicThemeElements, {Object = hIcon, Type = "Accent"})

			local titleLabel = Instance.new("TextLabel")
			titleLabel.Name = "HeaderTitle"
			titleLabel.Size = UDim2.new(1, -20, 1, 0)
			titleLabel.Position = UDim2.new(0, 20, 0, 0)
			titleLabel.BackgroundTransparency = 1
			titleLabel.Text = titleText
			titleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
			titleLabel.TextSize = 11
			titleLabel.Font = UI_FONT
			titleLabel.TextXAlignment = Enum.TextXAlignment.Left
			titleLabel.Parent = secHeader

			local Section = {}
			Section.Frame = sec
			Section.Tab = tabName

			local function registerSearch(name, frame)
				table.insert(searchItems, {Name = name, Frame = frame, Tab = tabName})
			end

			function Section:CreateToggle(text, default, callback, flag)
				local row = Instance.new("Frame")
				row.Name = text .. "ToggleRow"
				row.Size = UDim2.new(1, 0, 0, 24)
				row.BackgroundTransparency = 1
				row.Parent = sec

				registerSearch(text, row)

				local label = Instance.new("TextLabel")
				label.Name = "Label"
				label.Size = UDim2.new(1, -40, 1, 0)
				label.BackgroundTransparency = 1
				label.Text = text
				label.TextColor3 = Color3.fromRGB(210, 210, 220)
				label.TextSize = 10
				label.Font = UI_FONT
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Parent = row

				local active = default

				local switch = Instance.new("TextButton")
				switch.Name = "Switch"
				switch.Size = UDim2.new(0, 32, 0, 16)
				switch.Position = UDim2.new(1, -32, 0.5, -8)
				switch.BackgroundColor3 = active and Window.Themes[Window.ActiveTheme].Accent or Color3.fromRGB(45, 45, 55)
				switch.BorderSizePixel = 0
				switch.Text = ""
				switch.Parent = row

				table.insert(dynamicThemeElements, {
					Object = switch,
					Type = "DynamicToggle",
					GetValue = function() return active end
				})

				local switchCorner = Instance.new("UICorner")
				switchCorner.CornerRadius = UDim.new(1, 0)
				switchCorner.Parent = switch

				local knob = Instance.new("Frame")
				knob.Name = "Knob"
				knob.Size = UDim2.new(0, 12, 0, 12)
				knob.Position = active and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
				knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				knob.BorderSizePixel = 0
				knob.Parent = switch

				local knobCorner = Instance.new("UICorner")
				knobCorner.CornerRadius = UDim.new(1, 0)
				knobCorner.Parent = knob

				local element = {Set = function(v)
					active = v
					switch.BackgroundColor3 = active and Window.Themes[Window.ActiveTheme].Accent or Color3.fromRGB(45, 45, 55)
					knob.Position = active and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
				end, Get = function() return active end}

				if flag then Library.Flags[flag] = element end

				switch.MouseButton1Click:Connect(function()
					active = not active
					local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
					TweenService:Create(switch, tweenInfo, {BackgroundColor3 = active and Window.Themes[Window.ActiveTheme].Accent or Color3.fromRGB(45, 45, 55)}):Play()
					TweenService:Create(knob, tweenInfo, {Position = active and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
					showNotification(text .. ": " .. (active and "ON" or "OFF"))
					if callback then callback(active) end
				end)

				return element
			end

			function Section:CreateParagraph(titleText2, textLines)
				local para = Instance.new("Frame")
				para.Name = "InfoParagraph"
				para.Size = UDim2.new(1, 0, 0, 0)
				para.AutomaticSize = Enum.AutomaticSize.Y
				para.BackgroundTransparency = 1
				para.Parent = sec

				local layout3 = Instance.new("UIListLayout")
				layout3.SortOrder = Enum.SortOrder.LayoutOrder
				layout3.Padding = UDim.new(0, 2)
				layout3.Parent = para

				for i, lineText in ipairs(textLines) do
					local line = Instance.new("TextLabel")
					line.Name = "Line" .. i
					line.Size = UDim2.new(1, 0, 0, 12)
					line.BackgroundTransparency = 1
					line.Text = lineText
					line.TextColor3 = Color3.fromRGB(120, 120, 135)
					line.TextSize = 8
					line.Font = UI_FONT
					line.TextXAlignment = Enum.TextXAlignment.Left
					line.Parent = para
				end
			end

			function Section:CreateButton(text, subtext, callback)
				local row = Instance.new("Frame")
				row.Name = text .. "BtnRow"
				row.Size = UDim2.new(1, 0, 0, subtext and 42 or 26)
				row.BackgroundTransparency = 1
				row.Parent = sec

				registerSearch(text, row)

				local layout4 = Instance.new("UIListLayout")
				layout4.SortOrder = Enum.SortOrder.LayoutOrder
				layout4.Padding = UDim.new(0, 2)
				layout4.Parent = row

				if subtext then
					local subLabel = Instance.new("TextLabel")
					subLabel.Name = "ButtonHeaderLabel"
					subLabel.Size = UDim2.new(1, 0, 0, 14)
					subLabel.BackgroundTransparency = 1
					subLabel.Text = text
					subLabel.TextColor3 = Color3.fromRGB(210, 210, 220)
					subLabel.TextSize = 10
					subLabel.Font = UI_FONT
					subLabel.TextXAlignment = Enum.TextXAlignment.Left
					subLabel.Parent = row
				end

				local btn2 = Instance.new("TextButton")
				btn2.Name = text .. "Button"
				btn2.Size = UDim2.new(1, 0, 0, 26)
				btn2.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
				btn2.BorderSizePixel = 0
				btn2.Text = subtext or text
				btn2.TextColor3 = Color3.fromRGB(200, 200, 215)
				btn2.TextSize = 9
				btn2.Font = UI_FONT
				btn2.AutoButtonColor = false
				btn2.Parent = row

				local btnCorner2 = Instance.new("UICorner")
				btnCorner2.CornerRadius = UDim.new(0, 5)
				btnCorner2.Parent = btn2

				local btnStroke = Instance.new("UIStroke")
				btnStroke.Color = Color3.fromRGB(42, 42, 52)
				btnStroke.Thickness = 1
				btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				btnStroke.Parent = btn2

				btn2.MouseEnter:Connect(function()
					btn2.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
				end)
				btn2.MouseLeave:Connect(function()
					btn2.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
				end)

				btn2.MouseButton1Click:Connect(function()
					showNotification(text .. " clicked")
					if callback then callback() end
				end)

				return btn2
			end

			function Section:CreateDropdown(text, options, defaultSelected, callback, flag)
				local row = Instance.new("Frame")
				row.Name = text .. "DropdownRow"
				row.Size = UDim2.new(1, 0, 0, 42)
				row.BackgroundTransparency = 1
				row.ClipsDescendants = false
				row.ZIndex = 5
				row.Parent = sec

				registerSearch(text, row)

				local label = Instance.new("TextLabel")
				label.Name = "Label"
				label.Size = UDim2.new(1, 0, 0, 14)
				label.BackgroundTransparency = 1
				label.Text = text
				label.TextColor3 = Color3.fromRGB(210, 210, 220)
				label.TextSize = 10
				label.Font = UI_FONT
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Parent = row

				local dropBox = Instance.new("TextButton")
				dropBox.Name = "Box"
				dropBox.Size = UDim2.new(1, 0, 0, 24)
				dropBox.Position = UDim2.new(0, 0, 0, 18)
				dropBox.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
				dropBox.BorderSizePixel = 0
				dropBox.Text = ""
				dropBox.AutoButtonColor = false
				dropBox.ZIndex = 6
				dropBox.Parent = row

				local dropCorner = Instance.new("UICorner")
				dropCorner.CornerRadius = UDim.new(0, 5)
				dropCorner.Parent = dropBox

				local dropStroke = Instance.new("UIStroke")
				dropStroke.Color = Color3.fromRGB(40, 40, 50)
				dropStroke.Thickness = 1
				dropStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				dropStroke.Parent = dropBox

				local valLabel = Instance.new("TextLabel")
				valLabel.Name = "Value"
				valLabel.Size = UDim2.new(1, -24, 1, 0)
				valLabel.Position = UDim2.new(0, 8, 0, 0)
				valLabel.BackgroundTransparency = 1
				valLabel.Text = defaultSelected or options[1]
				valLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
				valLabel.TextSize = 9
				valLabel.Font = UI_FONT
				valLabel.TextXAlignment = Enum.TextXAlignment.Left
				valLabel.TextTruncate = Enum.TextTruncate.AtEnd
				valLabel.ZIndex = 7
				valLabel.Parent = dropBox

				local arrow = Instance.new("ImageLabel")
				arrow.Name = "Arrow"
				arrow.Size = UDim2.new(0, 10, 0, 10)
				arrow.Position = UDim2.new(1, -14, 0.5, -5)
				arrow.BackgroundTransparency = 1
				ApplyIcon(arrow, "chevron-down")
				arrow.ImageColor3 = Color3.fromRGB(120, 120, 135)
				arrow.ZIndex = 7
				arrow.Parent = dropBox

				local dropContainer = Instance.new("Frame")
				dropContainer.Name = "DropContainer"
				dropContainer.Size = UDim2.new(1, 0, 0, 0)
				dropContainer.Position = UDim2.new(0, 0, 0, 44)
				dropContainer.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
				dropContainer.BorderSizePixel = 0
				dropContainer.Visible = false
				dropContainer.ClipsDescendants = true
				dropContainer.ZIndex = 20
				dropContainer.Parent = row

				local dropListCorner = Instance.new("UICorner")
				dropListCorner.CornerRadius = UDim.new(0, 5)
				dropListCorner.Parent = dropContainer

				local listStroke = Instance.new("UIStroke")
				listStroke.Color = Color3.fromRGB(38, 38, 48)
				listStroke.Thickness = 1
				listStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				listStroke.Parent = dropContainer

				local dropLayout = Instance.new("UIListLayout")
				dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
				dropLayout.Parent = dropContainer

				local isOpen = false
				local optionButtons = {}

				local function toggleDrop()
					isOpen = not isOpen
					local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
					TweenService:Create(arrow, tweenInfo, {Rotation = isOpen and 180 or 0}):Play()
					TweenService:Create(dropStroke, tweenInfo, {Color = isOpen and Window.Themes[Window.ActiveTheme].Accent or Color3.fromRGB(40, 40, 50)}):Play()

					if isOpen then
						dropContainer.Visible = true
						local targetHeight = math.min(#options, 5) * 22
						TweenService:Create(dropContainer, tweenInfo, {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
						row.Size = UDim2.new(1, 0, 0, 44 + targetHeight + 2)
					else
						local tw = TweenService:Create(dropContainer, tweenInfo, {Size = UDim2.new(1, 0, 0, 0)})
						tw:Play()
						tw.Completed:Connect(function()
							if not isOpen then
								dropContainer.Visible = false
								row.Size = UDim2.new(1, 0, 0, 42)
							end
						end)
					end
				end

				dropBox.MouseButton1Click:Connect(toggleDrop)

				local function setValue(v, silent)
					valLabel.Text = v
					for _, ob in ipairs(dropContainer:GetChildren()) do
						if ob:IsA("TextButton") then
							ob.TextColor3 = (ob.Name == v) and Window.Themes[Window.ActiveTheme].Accent or Color3.fromRGB(160, 160, 175)
						end
					end
					if not silent and callback then callback(v) end
				end

				for _, opt in ipairs(options) do
					local optBtn = Instance.new("TextButton")
					optBtn.Name = opt
					optBtn.Size = UDim2.new(1, 0, 0, 22)
					optBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
					optBtn.BorderSizePixel = 0
					optBtn.Text = "  " .. opt
					optBtn.TextColor3 = (opt == valLabel.Text) and Window.Themes[Window.ActiveTheme].Accent or Color3.fromRGB(160, 160, 175)
					optBtn.TextSize = 8
					optBtn.Font = UI_FONT
					optBtn.TextXAlignment = Enum.TextXAlignment.Left
					optBtn.AutoButtonColor = false
					optBtn.ZIndex = 21
					optBtn.Parent = dropContainer

					table.insert(dynamicThemeElements, {
						Object = optBtn,
						Type = "DynamicAccentText",
						GetValue = function() return optBtn.Name == valLabel.Text end
					})

					optionButtons[opt] = optBtn

					optBtn.MouseEnter:Connect(function()
						optBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
					end)
					optBtn.MouseLeave:Connect(function()
						optBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
					end)

					optBtn.MouseButton1Click:Connect(function()
						setValue(opt)
						toggleDrop()
						showNotification(text .. " -> " .. opt)
					end)
				end

				local element = {
					Set = function(v) setValue(v, true) end,
					Get = function() return valLabel.Text end,
					Refresh = function(newOptions)
						options = newOptions
						for _, ob in ipairs(dropContainer:GetChildren()) do
							if ob:IsA("TextButton") then ob:Destroy() end
						end
						optionButtons = {}
						for _, opt in ipairs(options) do
							local optBtn = Instance.new("TextButton")
							optBtn.Name = opt
							optBtn.Size = UDim2.new(1, 0, 0, 22)
							optBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
							optBtn.BorderSizePixel = 0
							optBtn.Text = "  " .. opt
							optBtn.TextColor3 = (opt == valLabel.Text) and Window.Themes[Window.ActiveTheme].Accent or Color3.fromRGB(160, 160, 175)
							optBtn.TextSize = 8
							optBtn.Font = UI_FONT
							optBtn.TextXAlignment = Enum.TextXAlignment.Left
							optBtn.AutoButtonColor = false
							optBtn.ZIndex = 21
							optBtn.Parent = dropContainer
							optionButtons[opt] = optBtn
							optBtn.MouseButton1Click:Connect(function()
								setValue(opt)
								toggleDrop()
							end)
						end
					end
				}

				if flag then Library.Flags[flag] = element end

				return element
			end

			function Section:CreateMultiDropdown(text, options, defaultSelected, callback, flag)
				local row = Instance.new("Frame")
				row.Name = text .. "MultiDropdownRow"
				row.Size = UDim2.new(1, 0, 0, 42)
				row.BackgroundTransparency = 1
				row.ClipsDescendants = false
				row.ZIndex = 5
				row.Parent = sec

				registerSearch(text, row)

				local selectedTable = {}
				if type(defaultSelected) == "table" then
					for _, v in ipairs(defaultSelected) do
						selectedTable[v] = true
					end
				end

				local label = Instance.new("TextLabel")
				label.Name = "Label"
				label.Size = UDim2.new(1, 0, 0, 14)
				label.BackgroundTransparency = 1
				label.Text = text
				label.TextColor3 = Color3.fromRGB(210, 210, 220)
				label.TextSize = 10
				label.Font = UI_FONT
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Parent = row

				local dropBox = Instance.new("TextButton")
				dropBox.Name = "Box"
				dropBox.Size = UDim2.new(1, 0, 0, 24)
				dropBox.Position = UDim2.new(0, 0, 0, 18)
				dropBox.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
				dropBox.BorderSizePixel = 0
				dropBox.Text = ""
				dropBox.AutoButtonColor = false
				dropBox.ZIndex = 6
				dropBox.Parent = row

				local dropCorner = Instance.new("UICorner")
				dropCorner.CornerRadius = UDim.new(0, 5)
				dropCorner.Parent = dropBox

				local dropStroke = Instance.new("UIStroke")
				dropStroke.Color = Color3.fromRGB(40, 40, 50)
				dropStroke.Thickness = 1
				dropStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				dropStroke.Parent = dropBox

				local valLabel = Instance.new("TextLabel")
				valLabel.Name = "Value"
				valLabel.Size = UDim2.new(1, -24, 1, 0)
				valLabel.Position = UDim2.new(0, 8, 0, 0)
				valLabel.BackgroundTransparency = 1
				valLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
				valLabel.TextSize = 9
				valLabel.Font = UI_FONT
				valLabel.TextXAlignment = Enum.TextXAlignment.Left
				valLabel.TextTruncate = Enum.TextTruncate.AtEnd
				valLabel.ZIndex = 7
				valLabel.Parent = dropBox

				local function updateDisplay()
					local list = {}
					for k, v in pairs(selectedTable) do
						if v then table.insert(list, k) end
					end
					if #list == 0 then
						valLabel.Text = "None"
						valLabel.TextColor3 = Color3.fromRGB(130, 130, 145)
					else
						valLabel.Text = table.concat(list, ", ")
						valLabel.TextColor3 = Color3.fromRGB(220, 220, 235)
					end
				end

				updateDisplay()

				local arrow = Instance.new("ImageLabel")
				arrow.Name = "Arrow"
				arrow.Size = UDim2.new(0, 10, 0, 10)
				arrow.Position = UDim2.new(1, -14, 0.5, -5)
				arrow.BackgroundTransparency = 1
				ApplyIcon(arrow, "chevron-down")
				arrow.ImageColor3 = Color3.fromRGB(120, 120, 135)
				arrow.ZIndex = 7
				arrow.Parent = dropBox

				local dropContainer = Instance.new("Frame")
				dropContainer.Name = "DropContainer"
				dropContainer.Size = UDim2.new(1, 0, 0, 0)
				dropContainer.Position = UDim2.new(0, 0, 0, 44)
				dropContainer.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
				dropContainer.BorderSizePixel = 0
				dropContainer.Visible = false
				dropContainer.ClipsDescendants = true
				dropContainer.ZIndex = 20
				dropContainer.Parent = row

				local dropListCorner = Instance.new("UICorner")
				dropListCorner.CornerRadius = UDim.new(0, 5)
				dropListCorner.Parent = dropContainer

				local listStroke = Instance.new("UIStroke")
				listStroke.Color = Color3.fromRGB(38, 38, 48)
				listStroke.Thickness = 1
				listStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				listStroke.Parent = dropContainer

				local dropLayout = Instance.new("UIListLayout")
				dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
				dropLayout.Parent = dropContainer

				local isOpen = false

				local function toggleDrop()
					isOpen = not isOpen
					local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
					TweenService:Create(arrow, tweenInfo, {Rotation = isOpen and 180 or 0}):Play()
					TweenService:Create(dropStroke, tweenInfo, {Color = isOpen and Window.Themes[Window.ActiveTheme].Accent or Color3.fromRGB(40, 40, 50)}):Play()

					if isOpen then
						dropContainer.Visible = true
						local targetHeight = math.min(#options, 5) * 22
						TweenService:Create(dropContainer, tweenInfo, {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
						row.Size = UDim2.new(1, 0, 0, 44 + targetHeight + 2)
					else
						local tw = TweenService:Create(dropContainer, tweenInfo, {Size = UDim2.new(1, 0, 0, 0)})
						tw:Play()
						tw.Completed:Connect(function()
							if not isOpen then
								dropContainer.Visible = false
								row.Size = UDim2.new(1, 0, 0, 42)
							end
						end)
					end
				end

				dropBox.MouseButton1Click:Connect(toggleDrop)

				for _, opt in ipairs(options) do
					local optBtn = Instance.new("TextButton")
					optBtn.Name = opt
					optBtn.Size = UDim2.new(1, 0, 0, 22)
					optBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
					optBtn.BorderSizePixel = 0
					optBtn.Text = "  " .. opt
					optBtn.TextColor3 = selectedTable[opt] and Window.Themes[Window.ActiveTheme].Accent or Color3.fromRGB(160, 160, 175)
					optBtn.TextSize = 8
					optBtn.Font = UI_FONT
					optBtn.TextXAlignment = Enum.TextXAlignment.Left
					optBtn.AutoButtonColor = false
					optBtn.ZIndex = 21
					optBtn.Parent = dropContainer

					table.insert(dynamicThemeElements, {
						Object = optBtn,
						Type = "DynamicAccentText",
						GetValue = function() return selectedTable[opt] == true end
					})

					local statusDot = Instance.new("Frame")
					statusDot.Name = "StatusDot"
					statusDot.Size = UDim2.new(0, 4, 0, 4)
					statusDot.Position = UDim2.new(1, -12, 0.5, -2)
					statusDot.BackgroundColor3 = Window.Themes[Window.ActiveTheme].Accent
					statusDot.BorderSizePixel = 0
					statusDot.Visible = selectedTable[opt] == true
					statusDot.ZIndex = 22
					statusDot.Parent = optBtn
					table.insert(dynamicThemeElements, {Object = statusDot, Type = "Accent"})

					local dotCorner = Instance.new("UICorner")
					dotCorner.CornerRadius = UDim.new(1, 0)
					dotCorner.Parent = statusDot

					optBtn.MouseEnter:Connect(function()
						optBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
					end)
					optBtn.MouseLeave:Connect(function()
						optBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
					end)

					optBtn.MouseButton1Click:Connect(function()
						selectedTable[opt] = not selectedTable[opt]
						optBtn.TextColor3 = selectedTable[opt] and Window.Themes[Window.ActiveTheme].Accent or Color3.fromRGB(160, 160, 175)
						statusDot.Visible = selectedTable[opt] == true
						updateDisplay()

						local resultList = {}
						for k, v in pairs(selectedTable) do
							if v then table.insert(resultList, k) end
						end
						if callback then callback(resultList) end
					end)
				end

				local element = {
					Get = function()
						local resultList = {}
						for k, v in pairs(selectedTable) do
							if v then table.insert(resultList, k) end
						end
						return resultList
					end
				}

				if flag then Library.Flags[flag] = element end

				return element
			end

			function Section:CreateInput(text, defaultValue, callback, flag)
				local row = Instance.new("Frame")
				row.Name = text .. "InputRow"
				row.Size = UDim2.new(1, 0, 0, 40)
				row.BackgroundTransparency = 1
				row.Parent = sec

				registerSearch(text, row)

				local label = Instance.new("TextLabel")
				label.Name = "Label"
				label.Size = UDim2.new(1, 0, 0, 14)
				label.BackgroundTransparency = 1
				label.Text = text
				label.TextColor3 = Color3.fromRGB(210, 210, 220)
				label.TextSize = 10
				label.Font = UI_FONT
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Parent = row

				local inputFrame = Instance.new("Frame")
				inputFrame.Name = "Box"
				inputFrame.Size = UDim2.new(1, 0, 0, 22)
				inputFrame.Position = UDim2.new(0, 0, 0, 18)
				inputFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
				inputFrame.BorderSizePixel = 0
				inputFrame.Parent = row

				local inputCorner = Instance.new("UICorner")
				inputCorner.CornerRadius = UDim.new(0, 5)
				inputCorner.Parent = inputFrame

				local box = Instance.new("TextBox")
				box.Name = "TextBox"
				box.Size = UDim2.new(1, -12, 1, 0)
				box.Position = UDim2.new(0, 6, 0, 0)
				box.BackgroundTransparency = 1
				box.Text = defaultValue or ""
				box.TextColor3 = Color3.fromRGB(200, 200, 215)
				box.TextSize = 9
				box.Font = UI_FONT
				box.TextXAlignment = Enum.TextXAlignment.Left
				box.Parent = inputFrame

				box.FocusLost:Connect(function()
					showNotification(text .. " set to " .. box.Text)
					if callback then callback(box.Text) end
				end)

				local element = {
					Set = function(v) box.Text = v end,
					Get = function() return box.Text end
				}

				if flag then Library.Flags[flag] = element end

				return element
			end

			function Section:CreateSlider(text, minVal, maxVal, defaultVal, decimals, callback, flag)
				local row = Instance.new("Frame")
				row.Name = text .. "SliderRow"
				row.Size = UDim2.new(1, 0, 0, 32)
				row.BackgroundTransparency = 1
				row.Parent = sec

				registerSearch(text, row)

				local label = Instance.new("TextLabel")
				label.Name = "Label"
				label.Size = UDim2.new(0.7, 0, 0, 14)
				label.BackgroundTransparency = 1
				label.Text = text
				label.TextColor3 = Color3.fromRGB(210, 210, 220)
				label.TextSize = 9
				label.Font = UI_FONT
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Parent = row

				local val = Instance.new("TextLabel")
				val.Name = "Val"
				val.Size = UDim2.new(0.3, 0, 0, 14)
				val.Position = UDim2.new(0.7, 0, 0, 0)
				val.BackgroundTransparency = 1
				val.Text = string.format("%." .. tostring(decimals) .. "f", defaultVal)
				val.TextColor3 = Color3.fromRGB(150, 150, 165)
				val.TextSize = 8
				val.Font = UI_FONT
				val.TextXAlignment = Enum.TextXAlignment.Right
				val.Parent = row

				local btn3 = Instance.new("TextButton")
				btn3.Name = "Interact"
				btn3.Size = UDim2.new(1, 0, 0, 14)
				btn3.Position = UDim2.new(0, 0, 0, 18)
				btn3.BackgroundTransparency = 1
				btn3.Text = ""
				btn3.Parent = row

				local track = Instance.new("Frame")
				track.Name = "Track"
				track.Size = UDim2.new(1, 0, 0, 2)
				track.Position = UDim2.new(0, 0, 0.5, -1)
				track.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
				track.BorderSizePixel = 0
				track.Parent = btn3

				local rel = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)

				local fill = Instance.new("Frame")
				fill.Name = "Fill"
				fill.Size = UDim2.new(rel, 0, 1, 0)
				fill.BackgroundColor3 = Window.Themes[Window.ActiveTheme].Accent
				fill.BorderSizePixel = 0
				fill.Parent = track
				table.insert(dynamicThemeElements, {Object = fill, Type = "Accent"})

				local thumb = Instance.new("Frame")
				thumb.Name = "Thumb"
				thumb.Size = UDim2.new(0, 10, 0, 10)
				thumb.Position = UDim2.new(rel, -5, 0.5, -5)
				thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				thumb.BorderSizePixel = 0
				thumb.Parent = track

				local thumbCorner = Instance.new("UICorner")
				thumbCorner.CornerRadius = UDim.new(1, 0)
				thumbCorner.Parent = thumb

				local dragging = false
				local currentValue = defaultVal

				local function update(input)
					local pos = input.Position.X
					local absPos = track.AbsolutePosition.X
					local absSize = track.AbsoluteSize.X
					local alpha = math.clamp((pos - absPos) / absSize, 0, 1)
					local v = minVal + alpha * (maxVal - minVal)

					currentValue = v
					fill.Size = UDim2.new(alpha, 0, 1, 0)
					thumb.Position = UDim2.new(alpha, -5, 0.5, -5)
					val.Text = string.format("%." .. tostring(decimals) .. "f", v)
					if callback then callback(v) end
				end

				btn3.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						update(input)
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						update(input)
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						if dragging then
							dragging = false
							showNotification(text .. " set to " .. val.Text)
						end
					end
				end)

				local element = {
					Set = function(v)
						currentValue = v
						local alpha = math.clamp((v - minVal) / (maxVal - minVal), 0, 1)
						fill.Size = UDim2.new(alpha, 0, 1, 0)
						thumb.Position = UDim2.new(alpha, -5, 0.5, -5)
						val.Text = string.format("%." .. tostring(decimals) .. "f", v)
					end,
					Get = function() return currentValue end
				}

				if flag then Library.Flags[flag] = element end

				return element
			end

			function Section:CreateKeybind(text, defaultKey, callback, flag)
				local row = Instance.new("Frame")
				row.Name = text .. "KeybindRow"
				row.Size = UDim2.new(1, 0, 0, 24)
				row.BackgroundTransparency = 1
				row.Parent = sec

				registerSearch(text, row)

				local label = Instance.new("TextLabel")
				label.Name = "Label"
				label.Size = UDim2.new(1, -65, 1, 0)
				label.BackgroundTransparency = 1
				label.Text = text
				label.TextColor3 = Color3.fromRGB(210, 210, 220)
				label.TextSize = 10
				label.Font = UI_FONT
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Parent = row

				local bindBtn = Instance.new("TextButton")
				bindBtn.Name = "BindButton"
				bindBtn.Size = UDim2.new(0, 60, 0, 18)
				bindBtn.Position = UDim2.new(1, -60, 0.5, -9)
				bindBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
				bindBtn.BorderSizePixel = 0
				bindBtn.Text = defaultKey.Name
				bindBtn.TextColor3 = Color3.fromRGB(200, 200, 215)
				bindBtn.TextSize = 9
				bindBtn.Font = UI_FONT
				bindBtn.Parent = row

				local btnCorner3 = Instance.new("UICorner")
				btnCorner3.CornerRadius = UDim.new(0, 4)
				btnCorner3.Parent = bindBtn

				local currentKey = defaultKey
				local binding = false

				bindBtn.MouseButton1Click:Connect(function()
					binding = true
					bindBtn.Text = "..."
				end)

				UserInputService.InputBegan:Connect(function(input, gpe)
					if binding then
						if input.UserInputType == Enum.UserInputType.Keyboard then
							currentKey = input.KeyCode
							bindBtn.Text = currentKey.Name
							binding = false
							showNotification(text .. " bound to " .. currentKey.Name)
						end
					elseif not gpe and input.KeyCode == currentKey then
						if callback then callback() end
					end
				end)

				local element = {
					Set = function(v) currentKey = v bindBtn.Text = v.Name end,
					Get = function() return currentKey end
				}

				if flag then Library.Flags[flag] = element end

				return element
			end

			function Section:CreateColorPicker(text, defaultColor, callback, flag)
				local row = Instance.new("Frame")
				row.Name = text .. "ColorPickerRow"
				row.Size = UDim2.new(1, 0, 0, 24)
				row.BackgroundTransparency = 1
				row.ClipsDescendants = false
				row.ZIndex = 5
				row.Parent = sec

				registerSearch(text, row)

				local label = Instance.new("TextLabel")
				label.Name = "Label"
				label.Size = UDim2.new(1, -40, 1, 0)
				label.BackgroundTransparency = 1
				label.Text = text
				label.TextColor3 = Color3.fromRGB(210, 210, 220)
				label.TextSize = 10
				label.Font = UI_FONT
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Parent = row

				local swatchBtn = Instance.new("TextButton")
				swatchBtn.Name = "Swatch"
				swatchBtn.Size = UDim2.new(0, 32, 0, 16)
				swatchBtn.Position = UDim2.new(1, -32, 0.5, -8)
				swatchBtn.BackgroundColor3 = defaultColor
				swatchBtn.BorderSizePixel = 0
				swatchBtn.Text = ""
				swatchBtn.AutoButtonColor = false
				swatchBtn.ZIndex = 6
				swatchBtn.Parent = row

				local swatchCorner = Instance.new("UICorner")
				swatchCorner.CornerRadius = UDim.new(0, 4)
				swatchCorner.Parent = swatchBtn

				local swatchStroke = Instance.new("UIStroke")
				swatchStroke.Color = Color3.fromRGB(45, 45, 55)
				swatchStroke.Thickness = 1
				swatchStroke.Parent = swatchBtn

				local popup = Instance.new("Frame")
				popup.Name = "Popup"
				popup.Size = UDim2.new(0, 220, 0, 0)
				popup.Position = UDim2.new(1, -220, 0, 26)
				popup.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
				popup.BorderSizePixel = 0
				popup.ClipsDescendants = true
				popup.Visible = false
				popup.ZIndex = 30
				popup.Parent = row

				local popupCorner = Instance.new("UICorner")
				popupCorner.CornerRadius = UDim.new(0, 8)
				popupCorner.Parent = popup

				local popupStroke = Instance.new("UIStroke")
				popupStroke.Color = Color3.fromRGB(40, 40, 50)
				popupStroke.Thickness = 1
				popupStroke.Parent = popup

				local popupPadding = Instance.new("UIPadding")
				popupPadding.PaddingLeft = UDim.new(0, 10)
				popupPadding.PaddingRight = UDim.new(0, 10)
				popupPadding.PaddingTop = UDim.new(0, 10)
				popupPadding.PaddingBottom = UDim.new(0, 10)
				popupPadding.Parent = popup

				local popupLayout = Instance.new("UIListLayout")
				popupLayout.SortOrder = Enum.SortOrder.LayoutOrder
				popupLayout.Padding = UDim.new(0, 8)
				popupLayout.Parent = popup

				local svBox = Instance.new("Frame")
				svBox.Name = "SVBox"
				svBox.Size = UDim2.new(1, 0, 0, 120)
				svBox.BorderSizePixel = 0
				svBox.ZIndex = 31
				svBox.Parent = popup

				local svCorner = Instance.new("UICorner")
				svCorner.CornerRadius = UDim.new(0, 6)
				svCorner.Parent = svBox

				local whiteOverlay = Instance.new("Frame")
				whiteOverlay.Name = "WhiteOverlay"
				whiteOverlay.Size = UDim2.new(1, 0, 1, 0)
				whiteOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				whiteOverlay.BorderSizePixel = 0
				whiteOverlay.ZIndex = 32
				whiteOverlay.Parent = svBox

				local whiteGradient = Instance.new("UIGradient")
				whiteGradient.Transparency = NumberSequence.new(0, 1)
				whiteGradient.Parent = whiteOverlay

				local whiteCorner = Instance.new("UICorner")
				whiteCorner.CornerRadius = UDim.new(0, 6)
				whiteCorner.Parent = whiteOverlay

				local blackOverlay = Instance.new("Frame")
				blackOverlay.Name = "BlackOverlay"
				blackOverlay.Size = UDim2.new(1, 0, 1, 0)
				blackOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				blackOverlay.BorderSizePixel = 0
				blackOverlay.ZIndex = 33
				blackOverlay.Parent = svBox

				local blackGradient = Instance.new("UIGradient")
				blackGradient.Rotation = 90
				blackGradient.Transparency = NumberSequence.new(1, 0)
				blackGradient.Parent = blackOverlay

				local blackCorner = Instance.new("UICorner")
				blackCorner.CornerRadius = UDim.new(0, 6)
				blackCorner.Parent = blackOverlay

				local svHandle = Instance.new("Frame")
				svHandle.Name = "Handle"
				svHandle.Size = UDim2.new(0, 10, 0, 10)
				svHandle.AnchorPoint = Vector2.new(0.5, 0.5)
				svHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				svHandle.BorderSizePixel = 0
				svHandle.ZIndex = 34
				svHandle.Parent = svBox

				local svHandleCorner = Instance.new("UICorner")
				svHandleCorner.CornerRadius = UDim.new(1, 0)
				svHandleCorner.Parent = svHandle

				local svHandleStroke = Instance.new("UIStroke")
				svHandleStroke.Color = Color3.fromRGB(20, 20, 25)
				svHandleStroke.Thickness = 2
				svHandleStroke.Parent = svHandle

				local hueBar = Instance.new("Frame")
				hueBar.Name = "HueBar"
				hueBar.Size = UDim2.new(1, 0, 0, 14)
				hueBar.BorderSizePixel = 0
				hueBar.ZIndex = 31
				hueBar.Parent = popup

				local hueCorner = Instance.new("UICorner")
				hueCorner.CornerRadius = UDim.new(1, 0)
				hueCorner.Parent = hueBar

				local hueGradient = Instance.new("UIGradient")
				hueGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
					ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
					ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
					ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
					ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
					ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
				})
				hueGradient.Parent = hueBar

				local hueHandle = Instance.new("Frame")
				hueHandle.Name = "Handle"
				hueHandle.Size = UDim2.new(0, 6, 1, 4)
				hueHandle.Position = UDim2.new(0, 0, 0.5, -9)
				hueHandle.AnchorPoint = Vector2.new(0.5, 0)
				hueHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				hueHandle.BorderSizePixel = 0
				hueHandle.ZIndex = 32
				hueHandle.Parent = hueBar

				local hueHandleCorner = Instance.new("UICorner")
				hueHandleCorner.CornerRadius = UDim.new(0, 3)
				hueHandleCorner.Parent = hueHandle

				local hueHandleStroke = Instance.new("UIStroke")
				hueHandleStroke.Color = Color3.fromRGB(20, 20, 25)
				hueHandleStroke.Thickness = 1
				hueHandleStroke.Parent = hueHandle

				local fieldsRow = Instance.new("Frame")
				fieldsRow.Name = "Fields"
				fieldsRow.Size = UDim2.new(1, 0, 0, 22)
				fieldsRow.BackgroundTransparency = 1
				fieldsRow.ZIndex = 31
				fieldsRow.Parent = popup

				local fieldsLayout = Instance.new("UIListLayout")
				fieldsLayout.FillDirection = Enum.FillDirection.Horizontal
				fieldsLayout.Padding = UDim.new(0, 4)
				fieldsLayout.Parent = fieldsRow

				local function makeField(w, placeholder)
					local box = Instance.new("Frame")
					box.Size = UDim2.new(w, -3, 1, 0)
					box.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
					box.BorderSizePixel = 0
					box.ZIndex = 31
					box.Parent = fieldsRow

					local c = Instance.new("UICorner")
					c.CornerRadius = UDim.new(0, 4)
					c.Parent = box

					local input = Instance.new("TextBox")
					input.Size = UDim2.new(1, -6, 1, 0)
					input.Position = UDim2.new(0, 3, 0, 0)
					input.BackgroundTransparency = 1
					input.Text = ""
					input.PlaceholderText = placeholder
					input.PlaceholderColor3 = Color3.fromRGB(110, 110, 125)
					input.TextColor3 = Color3.fromRGB(210, 210, 220)
					input.TextSize = 9
					input.Font = UI_FONT
					input.ZIndex = 32
					input.Parent = box

					return input
				end

				local hexInput = makeField(0.4, "Hex")
				local rInput = makeField(0.2, "R")
				local gInput = makeField(0.2, "G")
				local bInput = makeField(0.2, "B")

				local confirmBtn = Instance.new("TextButton")
				confirmBtn.Name = "ConfirmBtn"
				confirmBtn.Size = UDim2.new(1, 0, 0, 22)
				confirmBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
				confirmBtn.BorderSizePixel = 0
				confirmBtn.Text = "Confirm"
				confirmBtn.TextColor3 = Color3.fromRGB(245, 170, 50)
				confirmBtn.TextSize = 9
				confirmBtn.Font = UI_FONT
				confirmBtn.ZIndex = 31
				confirmBtn.Parent = popup

				local confirmCorner = Instance.new("UICorner")
				confirmCorner.CornerRadius = UDim.new(0, 4)
				confirmCorner.Parent = confirmBtn

				table.insert(dynamicThemeElements, {Object = confirmBtn, Type = "Accent"})

				local hue, sat, val = defaultColor:ToHSV()
				local updatingFields = false

				local function refreshVisuals()
					hueHandle.Position = UDim2.new(hue, 0, 0.5, -9)
					svBox.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
					svHandle.Position = UDim2.new(sat, 0, 1 - val, 0)
				end

				local function refreshFields(color)
					updatingFields = true
					hexInput.Text = "#" .. color:ToHex()
					local r = math.floor(color.R * 255 + 0.5)
					local g = math.floor(color.G * 255 + 0.5)
					local b = math.floor(color.B * 255 + 0.5)
					rInput.Text = tostring(r)
					gInput.Text = tostring(g)
					bInput.Text = tostring(b)
					updatingFields = false
				end

				local function updateColor()
					local color = Color3.fromHSV(hue, sat, val)
					swatchBtn.BackgroundColor3 = color
					refreshFields(color)
				end

				refreshVisuals()
				refreshFields(defaultColor)

				local svDragging = false
				local hueDragging = false

				local function updateSV(input)
					local pos = input.Position
					local absPos = svBox.AbsolutePosition
					local absSize = svBox.AbsoluteSize
					sat = math.clamp((pos.X - absPos.X) / absSize.X, 0, 1)
					val = 1 - math.clamp((pos.Y - absPos.Y) / absSize.Y, 0, 1)
					svHandle.Position = UDim2.new(sat, 0, 1 - val, 0)
					updateColor()
				end

				local function updateHue(input)
					local pos = input.Position
					local absPos = hueBar.AbsolutePosition
					local absSize = hueBar.AbsoluteSize
					hue = math.clamp((pos.X - absPos.X) / absSize.X, 0, 1)
					hueHandle.Position = UDim2.new(hue, 0, 0.5, -9)
					svBox.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
					updateColor()
				end

				svBox.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						svDragging = true
						updateSV(input)
					end
				end)

				hueBar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						hueDragging = true
						updateHue(input)
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						if svDragging then updateSV(input) end
						if hueDragging then updateHue(input) end
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						svDragging = false
						hueDragging = false
					end
				end)

				hexInput.FocusLost:Connect(function()
					if updatingFields then return end
					local ok, color = pcall(Color3.fromHex, hexInput.Text)
					if ok then
						hue, sat, val = color:ToHSV()
						refreshVisuals()
						updateColor()
					else
						refreshFields(swatchBtn.BackgroundColor3)
					end
				end)

				local function onRGBChanged()
					if updatingFields then return end
					local r = tonumber(rInput.Text)
					local g = tonumber(gInput.Text)
					local b = tonumber(bInput.Text)
					if r and g and b then
						local color = Color3.fromRGB(math.clamp(r, 0, 255), math.clamp(g, 0, 255), math.clamp(b, 0, 255))
						hue, sat, val = color:ToHSV()
						refreshVisuals()
						updateColor()
					else
						refreshFields(swatchBtn.BackgroundColor3)
					end
				end

				rInput.FocusLost:Connect(onRGBChanged)
				gInput.FocusLost:Connect(onRGBChanged)
				bInput.FocusLost:Connect(onRGBChanged)

				local isOpen = false

				local function togglePopup()
					isOpen = not isOpen
					local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
					if isOpen then
						popup.Visible = true
						TweenService:Create(popup, tweenInfo, {Size = UDim2.new(0, 220, 0, 240)}):Play()
						row.Size = UDim2.new(1, 0, 0, 266)
					else
						local tw = TweenService:Create(popup, tweenInfo, {Size = UDim2.new(0, 220, 0, 0)})
						tw:Play()
						tw.Completed:Connect(function()
							if not isOpen then
								popup.Visible = false
								row.Size = UDim2.new(1, 0, 0, 24)
							end
						end)
					end
				end

				swatchBtn.MouseButton1Click:Connect(togglePopup)

				confirmBtn.MouseButton1Click:Connect(function()
					local color = Color3.fromHSV(hue, sat, val)
					if callback then callback(color) end
					showNotification(text .. " confirmed")
					if isOpen then togglePopup() end
				end)

				local element = {
					Set = function(v)
						hue, sat, val = v:ToHSV()
						refreshVisuals()
						updateColor()
					end,
					Get = function() return swatchBtn.BackgroundColor3 end
				}

				if flag then Library.Flags[flag] = element end

				return element
			end

			function Section:CreateConfigSystem()
				buildConfigManager(sec)
			end


			return Section
		end

		return Tab
	end

	Library.Windows[Title] = Window
	return Window
end

return Library
