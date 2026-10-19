-- ==========================================
-- ENLES HUB UI - PREMIUM VERSION
-- ==========================================

-- Load Library Fluent (UI modern & smooth)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Setup Window Utama
local Window = Fluent:CreateWindow({
    Title = "Enles Hub",
    SubTitle = "Blox Fruits | v1.0",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460), -- Ukuran Window
    Acrylic = true, -- Efek Kaca/Transparan (Bikin keren)
    Theme = "Dark", -- Tema Gelap
    MinimizeKey = Enum.KeyCode.RightControl -- Tekan Right-Ctrl untuk sembunyikan UI
})

-- Daftar Tab (Menu)
local Tabs = {
    Farm = Window:AddTab({ Title = "Farm", Icon = "sword" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Notifikasi saat script dimuat
Fluent:Notify({
    Title = "Enles Hub",
    Content = "Script berhasil dimuat! Selamat bermain.",
    Duration = 5
})

-- ==========================================
-- ISI TAB FARM
-- ==========================================
local FarmGroup = Tabs.Farm:AddLeftGroupbox("Auto Farm")

FarmGroup:AddToggle("AutoFarmToggle", { 
    Title = "Aktifkan Auto Farm", 
    Default = false 
}):OnChanged(function(Value)
    _G.EnlesAutoFarm = Value
    print("Enles | Auto Farm:", Value)
end)

FarmGroup:AddDropdown("SelectNPC", {
    Title = "Pilih Target NPC",
    Values = {"Bandit", "Monkey", "Brute", "Pirate"},
    Multi = false,
    Default = 1,
}):OnChanged(function(Value)
    _G.EnlesTargetNPC = Value
    print("Enles | Target:", Value)
end)

FarmGroup:AddSlider("AttackSpeed", {
    Title = "Attack Delay",
    Description = "Kecepatan serangan",
    Default = 0.5,
    Min = 0,
    Max = 2,
    Rounding = 1,
    Callback = function(Value)
        _G.EnlesDelay = Value
    end
})

-- ==========================================
-- ISI TAB PLAYER
-- ==========================================
local PlayerGroup = Tabs.Player:AddLeftGroupbox("Player Mods")

PlayerGroup:AddSlider("WalkSpeed", {
    Title = "Walk Speed",
    Description = "Atur kecepatan lari",
    Default = 16,
    Min = 16,
    Max = 200,
    Rounding = 1,
    Callback = function(Value)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = Value
        end
    end
})

PlayerGroup:AddToggle("InfJump", { 
    Title = "Infinite Jump", 
    Default = false 
}):OnChanged(function(Value)
    _G.EnlesInfJump = Value
end)

-- ==========================================
-- ISI TAB TELEPORT
-- ==========================================
local TeleportGroup = Tabs.Teleport:AddLeftGroupbox("Fast Travel")

TeleportGroup:AddButton({
    Title = "Teleport ke Bandit",
    Description = "Pindah instan ke pulau Bandit",
    Callback = function()
        print("Enles | Teleport ke Bandit...")
        -- Nanti logika teleport ditaruh di sini
    end
})

TeleportGroup:AddButton({
    Title = "Teleport ke Monkey",
    Description = "Pindah instan ke pulau Monkey",
    Callback = function()
        print("Enles | Teleport ke Monkey...")
    end
})

-- ==========================================
-- ISI TAB SETTINGS
-- ==========================================
local SettingsGroup = Tabs.Settings:AddLeftGroupbox("UI Settings")

SettingsGroup:AddButton({
    Title = "Simpan Config",
    Callback = function()
        SaveManager:Save()
        Fluent:Notify({ Title = "Enles Hub", Content = "Config berhasil disimpan!", Duration = 3 })
    end
})

-- Load Config otomatis
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("EnlesHub")
SaveManager:SetFolder("EnlesHub/Configs")
SaveManager:LoadAutoloadConfig()
