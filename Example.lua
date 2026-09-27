local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUser/YourRepo/main/source.lua"))()

local Window = Library:CreateWindow({
	Title = "Leaf",
	Logo = "layers",
	Anonymous = false,
	ConfigFolder = "LeafConfigs"
})

Window:CreateConfigSystem()

local ExampleTab = Window:CreateTab("Example Tab", "layout-grid")

local ExampleLeftSection = ExampleTab:CreateSection("Example Section Left", "layers")

ExampleLeftSection:CreateToggle("Example Toggle", true, function(state) end, "ExampleToggle")

ExampleLeftSection:CreateParagraph("Example Paragraph", {
	"Example Line 1",
	"Example Line 2"
})

ExampleLeftSection:CreateButton("Example Button", nil, function() end)

ExampleLeftSection:CreateKeybind("Example Keybind", Enum.KeyCode.E, function() end, "ExampleKeybind")

ExampleLeftSection:CreateInput("Example Input", "Default Text", function(text) end, "ExampleInput")

local ExampleRightSection = ExampleTab:CreateSection("Example Section Right", "sparkles", "right")

ExampleRightSection:CreateDropdown("Example Dropdown", {"Option 1", "Option 2", "Option 3"}, "Option 1", function(selected) end, "ExampleDropdown")

ExampleRightSection:CreateMultiDropdown("Example Multi Dropdown", {"Item A", "Item B", "Item C"}, {"Item A"}, function(selectedList) end, "ExampleMultiDropdown")

ExampleRightSection:CreateSlider("Example Slider", 0, 100, 50, 0, function(value) end, "ExampleSlider")

ExampleRightSection:CreateColorPicker("Example Color Picker", Color3.fromRGB(79, 70, 229), function(color) end, "ExampleColorPicker")

Window.SwitchTab("Example Tab")
