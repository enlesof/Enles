-- ==========================================
-- ENLES HUB - AUTO FARM + ANTI AFK/BAN
-- ==========================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Enles Hub",
    SubTitle = "Blox Fruits | Auto Farm",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Farm = Window:AddTab({ Title = "Farm", Icon = "sword" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

Fluent:Notify({ Title = "Enles Hub", Content = "Script berhasil dimuat!", Duration = 5 })

-- ==========================================
-- VARIABEL GLOBAL
-- ==========================================
local player = game.Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

local isFarming = false
local targetNPCName = "Bandit"
local attackDelay = 0.5

-- ==========================================
-- FITUR ANTI-AFK (Otomatis)
-- ==========================================
player.Idled:Connect(function()
    -- Jika player diam selama 20 menit, Roblox akan kick. 
    -- Script ini akan mem-bypass-nya dengan simulasi klik.
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    print("Enles Hub | Anti-AFK: Mencegah kick karena diam.")
end)

-- ==========================================
-- FITUR ANTI-KICK (Anti-Ban Sederhana)
-- ==========================================
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() and method == "Kick" then
        -- Jika game mencoba kick player, script ini akan membatalkannya
        print("Enles Hub | Anti-Kick: Upaya Kick dicegah!")
        Fluent:Notify({ Title = "Anti-Kick", Content = "Sistem mencoba mengeluarkanmu, tapi berhasil dicegah.", Duration = 4 })
        return nil
    end
    return oldNamecall(self, ...)
end)

-- ==========================================
-- LOGIKA AUTO FARM
-- ==========================================
local function getNearestNPC()
    local nearestNPC = nil
    local shortestDistance = math.huge
    local character = player.Character
    if not character then return nil end
    local myRoot = character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local npcFolder = workspace:FindFirstChild("NPCs")
    if not npcFolder then return nil end

    for _, npc in pairs(npcFolder:GetChildren()) do
        if npc.Name == targetNPCName and npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") then
            if npc.Humanoid.Health > 0 then
                local distance = (myRoot.Position - npc.HumanoidRootPart.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestNPC = npc
                end
            end
        end
    end
    return nearestNPC
end

local function attackNPC(npc)
    local character = player.Character
    if not character then return end
    local myRoot = character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    myRoot.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0)
    task.wait(0.1)

    local tool = character:FindFirstChildOfClass("Tool")
    if tool then
        tool:Activate()
    end
end

task.spawn(function()
    while task.wait(attackDelay) do
        if isFarming then
            local npc = getNearestNPC()
            if npc then
                attackNPC(npc)
            end
        end
    end
end)

-- ==========================================
-- UI: TAB FARM
-- ==========================================
local FarmGroup = Tabs.Farm:AddLeftGroupbox("Auto Farm")

FarmGroup:AddToggle("AutoFarmToggle", { 
    Title = "Aktifkan Auto Farm", 
    Default = false 
}):OnChanged(function(Value)
    isFarming = Value
    print("Enles | Auto Farm:", Value)
end)

FarmGroup:AddDropdown("SelectNPC", {
    Title = "Pilih Target NPC",
    Values = {"Bandit", "Monkey", "Brute", "Pirate", "Desert Bandit", "Reborn Skeleton"},
    Multi = false,
    Default = 1,
}):OnChanged(function(Value)
    targetNPCName = Value
    print("Enles | Target:", Value)
end)

FarmGroup:AddSlider("AttackSpeed", {
    Title = "Attack Delay",
    Default = 0.5,
    Min = 0.1,
    Max = 2,
    Rounding = 1,
    Callback = function(Value)
        attackDelay = Value
    end
})

-- ==========================================
-- UI: TAB PLAYER
-- ==========================================
local PlayerGroup = Tabs.Player:AddLeftGroupbox("Player Mods")

PlayerGroup:AddSlider("WalkSpeed", {
    Title = "Walk Speed",
    Default = 16,
    Min = 16,
    Max = 200,
    Rounding = 1,
    Callback = function(Value)
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = Value
        end
    end
})

local SecurityGroup = Tabs.Player:AddRightGroupbox("Security")

SecurityGroup:AddToggle("AntiKickToggle", {
    Title = "Anti-Kick (Aktifkan)",
    Description = "Mencegah kick dari game (Bukan jaminan anti-banned)",
    Default = false
}):OnChanged(function(Value)
    _G.EnlesAntiKick = Value
    if Value then
        Fluent:Notify({ Title = "Security", Content = "Anti-Kick diaktifkan.", Duration = 3 })
    end
end)

-- ==========================================
-- UI: TAB SETTINGS
-- ==========================================
local SettingsGroup = Tabs.Settings:AddLeftGroupbox("Settings")

SettingsGroup:AddButton({
    Title = "Simpan Config",
    Callback = function()
        SaveManager:Save()
        Fluent:Notify({ Title = "Enles Hub", Content = "Config disimpan!", Duration = 3 })
    end
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("EnlesHub")
SaveManager:SetFolder("EnlesHub/Configs")
SaveManager:LoadAutoloadConfig()
