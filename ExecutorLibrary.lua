local ExecutorLibrary = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

ExecutorLibrary.DebugMode = RunService:IsStudio()
ExecutorLibrary.PremiumFeatures = false
ExecutorLibrary.UIState = true

local DebugX = false
if DebugX then DebugX = true else DebugX = false end

local DEFAULT_CONFIG = {
    Keybind = Enum.KeyCode.K,
    Theme = "Dark",
    Settings = {
        Notifications = true,
        PremiumKey = "",
        AutoSave = true
    }
}

local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TopBar = Instance.new("Frame")
local SideBar = Instance.new("Frame")
local TabContainer = Instance.new("Frame")
local NotificationContainer = Instance.new("Frame")

local config = table.clone(DEFAULT_CONFIG)
local currentTabs = {}
local activeNotifications = {}
local keySystemEnabled = false
local TWEEN_INFO = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local ColorTheme = {
    Background = Color3.fromRGB(24, 24, 24),
    Secondary = Color3.fromRGB(32, 32, 32),
    Button = Color3.fromRGB(45, 45, 45),
    Text = Color3.new(0.9, 0.9, 0.9),
    Success = Color3.new(0.2, 0.8, 0.4),
    Error = Color3.new(0.9, 0.2, 0.2),
    Warning = Color3.new(0.9, 0.8, 0.2),
    Accent = Color3.fromRGB(0, 170, 255)
}

local CONFIG_FOLDER = "ExecutorLibrary_Config"
local CONFIG_FILE = "settings.json"

local function SaveConfig()
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
    writefile(CONFIG_FOLDER.."/"..CONFIG_FILE, HttpService:JSONEncode(config))
end

local function LoadConfig()
    if isfile(CONFIG_FOLDER.."/"..CONFIG_FILE) then
        config = HttpService:JSONDecode(readfile(CONFIG_FOLDER.."/"..CONFIG_FILE))
    else
        config = table.clone(DEFAULT_CONFIG)
        SaveConfig()
    end
end

function ExecutorLibrary:SetupTopBar()
    local title = Instance.new("TextLabel")
    title.Text = "EXECUTOR LIBRARY"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = ColorTheme.Accent
    title.Size = UDim2.new(0.4, 0, 1, 0)
    title.Position = UDim2.new(0.3, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Parent = TopBar

    local closeButton = Instance.new("ImageButton")
    closeButton.Size = UDim2.new(0, 28, 0, 28)
    closeButton.Position = UDim2.new(1, -36, 0.5, -14)
    closeButton.Image = "rbxassetid://11454279392"
    closeButton.ImageColor3 = ColorTheme.Text
    closeButton.MouseButton1Click:Connect(function()
        self:SetUIVisible(not self.UIState)
    end)
    closeButton.Parent = TopBar

    local settingsButton = Instance.new("ImageButton")
    settingsButton.Size = UDim2.new(0, 28, 0, 28)
    settingsButton.Position = UDim2.new(1, -72, 0.5, -14)
    settingsButton.Image = "rbxassetid://11454270709"
    settingsButton.ImageColor3 = ColorTheme.Text
    settingsButton.MouseButton1Click:Connect(function()
        self:SwitchTab("Settings")
    end)
    settingsButton.Parent = TopBar
end

function ExecutorLibrary:CreateWindow(options)
    local window = {
        Tabs = {},
        CurrentTab = nil,
        Config = options
    }
    
    if options.KeySystem then
        self:HandleKeySystem(options.KeySettings)
    end
    
    return setmetatable(window, {
        __index = function(t, key)
            local methods = {
                CreateTab = function(_, name, icon, premium)
                    local tab = self:CreateTab(name, icon, premium)
                    table.insert(window.Tabs, tab)
                    return tab
                end,
                CreateSection = function(_, name, premium)
                    return self:CreateSection(name, premium)
                end,
                Notify = function(_, options)
                    self:CreateNotification(options.Title, options.Content, options.Duration, options.Color)
                end,
                SaveConfiguration = function()
                    SaveConfig()
                end,
                LoadConfiguration = function()
                    LoadConfig()
                end
            }
            return methods[key]
        end
    })
end

function ExecutorLibrary:HandleKeySystem(settings)
    local keyFile = CONFIG_FOLDER.."/"..settings.FileName .. ".json"
    local validKeys = settings.Key
    
    local function ValidateKey(key)
        if settings.GrabKeyFromSite then
            return game:HttpGet(settings.KeyURL):find(key) ~= nil
        end
        return table.find(validKeys, key) ~= nil
    end

    if isfile(keyFile) then
        local savedKey = HttpService:JSONDecode(readfile(keyFile))
        if ValidateKey(savedKey) then
            ExecutorLibrary.PremiumFeatures = true
            return
        end
    end

    local popup = self:CreatePopup({
        Title = settings.Title,
        Content = settings.Subtitle,
        InputText = "Enter key...",
        Buttons = {
            {Text = "Submit", Callback = function(input)
                if ValidateKey(input) then
                    if settings.SaveKey then
                        writefile(keyFile, HttpService:JSONEncode(input))
                    end
                    ExecutorLibrary.PremiumFeatures = true
                    return true
                end
                return false
            end},
            {Text = "Cancel", Callback = function() return true end}
        }
    })
end

function ExecutorLibrary:CreateSection(name, premium)
    local section = {
        Name = name,
        Elements = {},
        PremiumLocked = premium or false
    }
    
    return setmetatable(section, {
        __index = function(t, key)
            local elements = {
                CreateButton = function(_, text, callback)
                    local btn = Instance.new("TextButton")
                    btn.Text = text
                    btn.Size = UDim2.new(1, -10, 0, 36)
                    btn.Position = UDim2.new(0, 5, 0, #section.Elements * 42 + 5)
                    btn.BackgroundColor3 = ColorTheme.Button
                    btn.Font = Enum.Font.Gotham
                    btn.TextSize = 13
                    btn.TextColor3 = ColorTheme.Text
                    btn.AutoButtonColor = false
                    btn.Parent = section.Frame
                    
                    btn.MouseEnter:Connect(function()
                        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = ColorTheme.Button:Lighten(0.1)}):Play()
                    end)
                    
                    btn.MouseLeave:Connect(function()
                        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = ColorTheme.Button}):Play()
                    end)
                    
                    btn.MouseButton1Click:Connect(function()
                        if self.PremiumFeatures or not section.PremiumLocked then
                            callback()
                        else
                            self:CreateNotification("Premium Feature Locked", 3, ColorTheme.Error)
                        end
                    end)
                    
                    table.insert(section.Elements, btn)
                    return btn
                end
            }
            return elements[key]
        end
    })
end

function ExecutorLibrary:Initialize()
    ScreenGui.Name = "ExecutorLibrary"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = self.DebugMode and game:GetService("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui")

    MainFrame.Size = UDim2.new(0, 600, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = ColorTheme.Background
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    LoadConfig()

    TopBar.Size = UDim2.new(1, 0, 0, 45)
    TopBar.BackgroundColor3 = ColorTheme.Secondary
    TopBar.Parent = MainFrame

    SideBar.Size = UDim2.new(0, 70, 1, -45)
    SideBar.Position = UDim2.new(0, 0, 0, 45)
    SideBar.BackgroundColor3 = ColorTheme.Secondary
    SideBar.Parent = MainFrame

    TabContainer.Size = UDim2.new(1, -70, 1, -45)
    TabContainer.Position = UDim2.new(0, 70, 0, 45)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = MainFrame

    NotificationContainer.Size = UDim2.new(0, 350, 0.5, 0)
    NotificationContainer.Position = UDim2.new(1, 10, 0.5, 0)
    NotificationContainer.AnchorPoint = Vector2.new(1, 0.5)
    NotificationContainer.BackgroundTransparency = 1
    NotificationContainer.Parent = ScreenGui

    self:SetupTopBar()

    if self.DebugMode or DebugX then
        self:CreateExampleWindow()
    end
end

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == config.Keybind then
        ExecutorLibrary:SetUIVisible(not ExecutorLibrary.UIState)
    end
end)

return ExecutorLibrary
