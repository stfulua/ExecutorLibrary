local ExecutorLibrary = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

ExecutorLibrary.DebugMode = RunService:IsStudio()
ExecutorLibrary.PremiumFeatures = false
local DebugX = false

local DEFAULT_CONFIG = {
    Keybind = Enum.KeyCode.K,
    UIState = true,
    Theme = "Dark",
    Settings = {
        Notifications = true,
        PremiumKey = ""
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

local TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function ExecutorLibrary:Initialize()
    ScreenGui.Name = "ExecutorLibrary"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = self.DebugMode and game:GetService("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui")

    MainFrame.Size = UDim2.new(0, 600, 0, 450)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    TopBar.Parent = MainFrame

    SideBar.Size = UDim2.new(0, 60, 1, -40)
    SideBar.Position = UDim2.new(0, 0, 0, 40)
    SideBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    SideBar.Parent = MainFrame

    TabContainer.Size = UDim2.new(1, -60, 1, -40)
    TabContainer.Position = UDim2.new(0, 60, 0, 40)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = MainFrame

    NotificationContainer.Size = UDim2.new(0, 300, 0.5, 0)
    NotificationContainer.Position = UDim2.new(1, 5, 0.5, 0)
    NotificationContainer.AnchorPoint = Vector2.new(1, 0.5)
    NotificationContainer.BackgroundTransparency = 1
    NotificationContainer.Parent = ScreenGui

    self:SetupTopBar()
    self:LoadConfig()

    if self.DebugMode or DebugX then
        local exampleWindow = self:CreateWindow({
            Name = "Example Window",
            LoadingTitle = "Executor Library",
            LoadingSubtitle = "Debug Mode Active",
            KeySystem = true,
            KeySettings = {
                Title = "Premium Access",
                Subtitle = "Enter your key below",
                Note = "Contact developer for premium key",
                FileName = "ExecutorKey",
                SaveKey = true,
                GrabKeyFromSite = false,
                Key = {"DEFAULTKEY123"}
            }
        })
        
        local mainTab = exampleWindow:CreateTab("Main", "rbxassetid://0")
        local premiumTab = exampleWindow:CreateTab("Premium", "rbxassetid://0")
        
        mainTab:CreateSection("Free Features"):CreateButton("Test Notification", function()
            self:CreateNotification("Regular Feature", 3, Color3.new(0.2, 0.6, 1))
        end)
        
        local premiumSection = premiumTab:CreateSection("Premium Tools", true)
        premiumSection:CreateButton("Secret Feature", function()
            self:CreateNotification("Premium Feature Unlocked!", 3, Color3.new(0, 1, 0.5))
        end)
    end
end

function ExecutorLibrary:CreateWindow(options)
    local window = {
        Tabs = {},
        CurrentTab = nil,
        Config = {
            Name = options.Name,
            KeySystem = options.KeySystem
        }
    }
    
    if options.KeySystem then
        keySystemEnabled = true
        self:HandleKeySystem(options.KeySettings)
    end
    
    return setmetatable(window, {
        __index = function(_, key)
            if key == "CreateTab" then
                return function(_, tabName, tabIcon)
                    local newTab = self:CreateTab(tabName, tabIcon)
                    table.insert(window.Tabs, newTab)
                    return newTab
                end
            end
        end
    })
end

function ExecutorLibrary:HandleKeySystem(settings)
    local keyFile = settings.FileName .. ".txt"
    
    if isfile(keyFile) and readfile(keyFile) ~= "" then
        local savedKey = readfile(keyFile)
        if table.find(settings.Key, savedKey) then
            self.PremiumFeatures = true
            return
        end
    end
    
    local keyInput = self:CreatePopup({
        Title = settings.Title,
        Content = settings.Subtitle,
        InputText = "Enter key here...",
        Buttons = {
            {Text = "Submit", Callback = function(input)
                if table.find(settings.Key, input) then
                    if settings.SaveKey then
                        writefile(keyFile, input)
                    end
                    self.PremiumFeatures = true
                    return true
                end
                return false
            end},
            {Text = "Cancel", Callback = function() return true end}
        }
    })
end

function ExecutorLibrary:CreateTab(name, icon)
    local tab = {
        Name = name,
        Sections = {},
        PremiumLocked = false
    }
    
    local tabButton = Instance.new("ImageButton")
    tabButton.Size = UDim2.new(0, 40, 0, 40)
    tabButton.Position = UDim2.new(0.5, -20, 0, #currentTabs * 50 + 10)
    tabButton.Image = icon
    tabButton.Parent = SideBar
    
    local tabFrame = Instance.new("ScrollingFrame")
    tabFrame.Size = UDim2.new(1, 0, 1, 0)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = false
    tabFrame.Parent = TabContainer
    
    tabButton.MouseButton1Click:Connect(function()
        self:SwitchTab(tab)
    end)
    
    table.insert(currentTabs, tab)
    
    return setmetatable(tab, {
        __index = function(_, key)
            if key == "CreateSection" then
                return function(_, sectionName, premium)
                    local section = {
                        Name = sectionName,
                        Elements = {},
                        PremiumLocked = premium or false
                    }
                    
                    local sectionFrame = Instance.new("Frame")
                    sectionFrame.Size = UDim2.new(1, -20, 0, 0)
                    sectionFrame.Position = UDim2.new(0, 10, 0, #tab.Sections * 50 + 10)
                    sectionFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    sectionFrame.Parent = tabFrame
                    
                    local sectionLabel = Instance.new("TextLabel")
                    sectionLabel.Text = sectionName
                    sectionLabel.TextColor3 = Color3.new(1, 1, 1)
                    sectionLabel.Font = Enum.Font.GothamSemibold
                    sectionLabel.TextSize = 12
                    sectionLabel.Position = UDim2.new(0, 10, 0, 5)
                    sectionLabel.Size = UDim2.new(1, -20, 0, 20)
                    sectionLabel.BackgroundTransparency = 1
                    sectionLabel.Parent = sectionFrame
                    
                    if section.PremiumLocked then
                        sectionFrame.Visible = self.PremiumFeatures
                        sectionLabel.TextColor3 = Color3.new(0, 1, 0.5)
                    end
                    
                    table.insert(tab.Sections, section)
                    
                    return setmetatable(section, {
                        __index = function(_, elemKey)
                            local elements = {
                                CreateButton = function(_, btnText, callback)
                                    local btn = Instance.new("TextButton")
                                    btn.Text = btnText
                                    btn.Size = UDim2.new(1, -10, 0, 30)
                                    btn.Position = UDim2.new(0, 5, 0, #section.Elements * 35 + 5)
                                    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                                    btn.Font = Enum.Font.Gotham
                                    btn.TextSize = 12
                                    btn.Parent = sectionFrame
                                    
                                    btn.MouseButton1Click:Connect(function()
                                        if self.PremiumFeatures or not section.PremiumLocked then
                                            callback()
                                        else
                                            self:CreateNotification("Premium Feature Locked", 3, Color3.new(1, 0, 0))
                                        end
                                    end)
                                    
                                    table.insert(section.Elements, btn)
                                    return btn
                                end
                            }
                            return elements[elemKey]
                        end
                    })
                end
            end
        end
    })
end

function ExecutorLibrary:CreateNotification(text, duration, color)
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(1, -10, 0, 40)
    notification.Position = UDim2.new(0, 5, 0, #activeNotifications * 45)
    notification.BackgroundColor3 = color or Color3.fromRGB(45, 45, 45)
    notification.Parent = NotificationContainer
    
    local label = Instance.new("TextLabel")
    label.Text = text
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextColor3 = Color3.new(1, 1, 1)
    label.BackgroundTransparency = 1
    label.Parent = notification
    
    table.insert(activeNotifications, notification)
    
    task.delay(duration or 3, function()
        notification:Destroy()
        table.remove(activeNotifications, table.find(activeNotifications, notification))
    end)
end

function ExecutorLibrary:SetUIVisible(state)
    ExecutorLibrary.UIState = state
    TweenService:Create(MainFrame, TWEEN_INFO, {
        Position = state and UDim2.new(0.5, -300, 0.5, -225) or UDim2.new(0.5, -300, 1, 225)
    }):Play()
end

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == config.Keybind then
        ExecutorLibrary:SetUIVisible(not ExecutorLibrary.UIState)
    end
end)

return ExecutorLibrary
