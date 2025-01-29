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
                end
            }
            return methods[key]
        end
    })
end

function ExecutorLibrary:HandleKeySystem(settings)
    local keyFile = settings.FileName .. ".txt"
    local validKeys = settings.Key
    
    local function ValidateKey(key)
        if settings.GrabKeyFromSite then
            return game:HttpGet(settings.KeyURL):find(key) ~= nil
        end
        return table.find(validKeys, key) ~= nil
    end

    if isfile(keyFile) then
        local savedKey = readfile(keyFile)
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
                        writefile(keyFile, input)
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
                end,
                CreateToggle = function(_, text, options)
                    return self:CreateToggle(text, options)
                end,
                CreateSlider = function(_, text, options)
                    return self:CreateSlider(text, options)
                end,
                CreateDropdown = function(_, text, options)
                    return self:CreateDropdown(text, options)
                end,
                CreateKeybind = function(_, text, options)
                    return self:CreateKeybind(text, options)
                end,
                CreateColorPicker = function(_, text, options)
                    return self:CreateColorPicker(text, options)
                end
            }
            return elements[key]
        end
    })
end

function ExecutorLibrary:CreateNotification(title, content, duration, color)
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(1, -10, 0, 60)
    notification.Position = UDim2.new(0, 5, 0, #activeNotifications * 65)
    notification.BackgroundColor3 = color or ColorTheme.Secondary
    notification.Parent = NotificationContainer
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = ColorTheme.Text
    titleLabel.Size = UDim2.new(1, -10, 0, 20)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = notification
    
    local contentLabel = Instance.new("TextLabel")
    contentLabel.Text = content
    contentLabel.Font = Enum.Font.Gotham
    contentLabel.TextSize = 12
    contentLabel.TextColor3 = ColorTheme.Text
    contentLabel.Size = UDim2.new(1, -10, 0, 30)
    contentLabel.Position = UDim2.new(0, 10, 0, 25)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Parent = notification
    
    table.insert(activeNotifications, notification)
    
    task.delay(duration or 3, function()
        TweenService:Create(notification, TweenInfo.new(0.25), {Position = UDim2.new(1, 0, notification.Position.Y.Scale, notification.Position.Y.Offset)}):Play()
        task.wait(0.25)
        notification:Destroy()
        table.remove(activeNotifications, table.find(activeNotifications, notification))
    end)
end

function ExecutorLibrary:SetUIVisible(state)
    ExecutorLibrary.UIState = state
    TweenService:Create(MainFrame, TWEEN_INFO, {
        Position = state and UDim2.new(0.5, -300, 0.5, -225) or UDim2.new(0.5, -300, 1.5, 225)
    }):Play()
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
    self:LoadConfig()

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
