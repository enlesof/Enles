-- ==========================================
-- ENLES HUB - AUTO FARM + ANTI AFK (FIXED)
-- ==========================================

if not game:IsLoaded() then game.Loaded:Wait() end

local function tryLoad(name, urls)
    for _, url in ipairs(urls) do
        local ok, res = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        if ok and res then
            print("Enles Hub | " .. name .. " dimuat dari: " .. url)
            return res
        end
        warn("Enles Hub | Gagal memuat " .. name .. " dari " .. url .. " -> " .. tostring(res))
    end
    return nil
end

-- Library utama (wajib). Mencoba beberapa sumber secara berurutan.
local Fluent = tryLoad("Fluent", {
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua",
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Fluent.lua",
    "https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau",
})

if not Fluent then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Enles Hub",
            Text = "Gagal memuat library UI (HTTP error). Cek koneksi atau coba lagi nanti.",
            Duration = 8,
        })
    end)
    warn("Enles Hub | Library Fluent tidak bisa dimuat dari semua sumber. Script dihentikan.")
    return
end

-- Addon config & tema (opsional). Kalau gagal, script tetap jalan tanpa fitur simpan config.
local SaveManager = tryLoad("SaveManager", {
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua",
    "https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau",
})
local InterfaceManager = tryLoad("InterfaceManager", {
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua",
    "https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau",
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer

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
    Raid = Window:AddTab({ Title = "Raid", Icon = "swords" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- ==========================================
-- STATE
-- ==========================================
local State = {
    farming = false,
    target = "Bandit",
    attackDelay = 0.5,
    height = 8,
    walkSpeed = 16,
    antiKick = false,
    currentEnemy = nil,
    raid = false,
    raidChip = "Flame",
    raidAutoStart = true,
    raidIslandIdx = 1,
    lastRaidStart = 0,
}

-- ==========================================
-- HELPERS
-- ==========================================
local function getChar()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if hum and root and hum.Health > 0 then
        return char, hum, root
    end
end

local function getEnemyFolder()
    return workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("NPCs")
end

-- ==========================================
-- ANTI-AFK
-- ==========================================
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ==========================================
-- ANTI-KICK (client-side saja, hanya untuk LocalPlayer)
-- ==========================================
if hookmetamethod and getnamecallmethod and checkcaller then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if State.antiKick and self == player and not checkcaller() then
            local method = getnamecallmethod()
            if method == "Kick" or method == "kick" then
                task.defer(function()
                    Fluent:Notify({ Title = "Anti-Kick", Content = "Upaya kick dari client dicegah.", Duration = 4 })
                end)
                return nil
            end
        end
        return oldNamecall(self, ...)
    end)
end

-- ==========================================
-- AUTO FARM
-- ==========================================
local function getNearestEnemy(anyName, maxDist)
    local _, _, myRoot = getChar()
    if not myRoot then return end

    local folder = getEnemyFolder()
    if not folder then return end

    local nearest, shortest = nil, math.huge
    for _, npc in ipairs(folder:GetChildren()) do
        local hum = npc:FindFirstChildOfClass("Humanoid")
        local root = npc:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health > 0 and (anyName or string.find(npc.Name, State.target, 1, true)) then
            local dist = (myRoot.Position - root.Position).Magnitude
            if dist < shortest and (not maxDist or dist <= maxDist) then
                shortest = dist
                nearest = npc
            end
        end
    end
    return nearest
end

local function equipTool(char)
    if char:FindFirstChildOfClass("Tool") then return end
    local backpack = player:FindFirstChildOfClass("Backpack")
    local tool = backpack and backpack:FindFirstChildOfClass("Tool")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if tool and hum then
        hum:EquipTool(tool)
    end
end

local function attack(char)
    equipTool(char)
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
    end
    pcall(function()
        local cam = workspace.CurrentCamera
        VirtualUser:Button1Down(Vector2.new(0, 1), cam.CFrame)
        VirtualUser:Button1Up(Vector2.new(0, 1), cam.CFrame)
    end)
end

-- Loop pemilihan target + serangan
task.spawn(function()
    while true do
        task.wait(State.attackDelay)
        if State.farming or State.raid then
            local char, hum = getChar()
            if char then
                local enemy = State.currentEnemy
                local eHum = enemy and enemy:FindFirstChildOfClass("Humanoid")
                if not enemy or not enemy.Parent or not eHum or eHum.Health <= 0 then
                    if State.raid then
                        -- Raid: serang musuh apa pun di sekitar (radius 1500 stud)
                        State.currentEnemy = getNearestEnemy(true, 1500)
                    else
                        State.currentEnemy = getNearestEnemy()
                    end
                end
                if State.currentEnemy then
                    attack(char)
                end
            else
                State.currentEnemy = nil
            end
        else
            State.currentEnemy = nil
        end
    end
end)

-- Menjaga posisi di atas musuh
RunService.Heartbeat:Connect(function()
    if not (State.farming or State.raid) or not State.currentEnemy then return end
    local _, _, myRoot = getChar()
    local eRoot = State.currentEnemy:FindFirstChild("HumanoidRootPart")
    if myRoot and eRoot then
        local pos = eRoot.Position + Vector3.new(0, State.height, 0)
        myRoot.CFrame = CFrame.lookAt(pos, eRoot.Position)
        myRoot.AssemblyLinearVelocity = Vector3.zero
    end
end)

-- ==========================================
-- AUTO RAID
-- ==========================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getRaidIslands()
    local origin = workspace:FindFirstChild("_WorldOrigin")
    local locations = origin and origin:FindFirstChild("Locations")
    local islands = {}
    if locations then
        for i = 1, 5 do
            local island = locations:FindFirstChild("Island " .. i)
            if island then table.insert(islands, island) end
        end
    end
    return islands
end

local function startRaid()
    if os.clock() - State.lastRaidStart < 6 then return end
    State.lastRaidStart = os.clock()

    local _, _, myRoot = getChar()
    if not myRoot then return end

    -- 1) Pilih chip (butuh Special Microchip di inventory)
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local commF = remotes and remotes:FindFirstChild("CommF_")
        if commF then
            commF:InvokeServer("RaidsNpc", "Select", State.raidChip)
        end
    end)

    -- 2) Pastikan punya Microchip (hilang saat mati/keluar game)
    local function hasChip()
        local char = player.Character
        local backpack = player:FindFirstChildOfClass("Backpack")
        for _, container in ipairs({ char, backpack }) do
            if container then
                for _, item in ipairs(container:GetChildren()) do
                    if item:IsA("Tool") and string.find(item.Name, "Microchip", 1, true) then
                        return true
                    end
                end
            end
        end
        return false
    end
    task.wait(0.5)
    if not hasChip() then
        Fluent:Notify({
            Title = "Auto Raid",
            Content = "Microchip tidak ditemukan. Beli dulu dari Mysterious Scientist (level 1100+ untuk host).",
            Duration = 4
        })
        return
    end

    -- 3) Tekan tombol raid (di samping kapsul biru tua)
    if not fireclickdetector then return end
    local map = workspace:FindFirstChild("Map")
    local summon = map and map:FindFirstChild("RaidSummon2", true)
    local button = summon and summon:FindFirstChild("Button")
    local main = button and button:FindFirstChild("Main")
    local detector = main and main:FindFirstChildOfClass("ClickDetector")
    if detector and main then
        myRoot.CFrame = main.CFrame * CFrame.new(0, 4, 8)
        task.wait(0.5)
        pcall(fireclickdetector, detector)
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        if State.raid then
            local islands = getRaidIslands()
            if #islands == 0 then
                -- Raid belum berjalan
                State.currentEnemy = nil
                State.raidIslandIdx = 1
                if State.raidAutoStart then
                    startRaid()
                end
            elseif not State.currentEnemy then
                -- Raid berjalan tapi tidak ada musuh dekat: pindah ke pulau berikutnya
                local _, _, myRoot = getChar()
                if myRoot then
                    if State.raidIslandIdx > #islands then State.raidIslandIdx = 1 end
                    local island = islands[State.raidIslandIdx]
                    State.raidIslandIdx = State.raidIslandIdx + 1
                    local ok, pivot = pcall(function() return island:GetPivot() end)
                    if ok then
                        myRoot.CFrame = pivot * CFrame.new(0, 40, 0)
                    end
                end
            end
        end
    end
end)

-- ==========================================
-- WALKSPEED (tetap berlaku setelah respawn)
-- ==========================================
local function applyWalkSpeed()
    local _, hum = getChar()
    if hum and State.walkSpeed > 16 and hum.WalkSpeed ~= State.walkSpeed then
        hum.WalkSpeed = State.walkSpeed
    end
end

player.CharacterAdded:Connect(function()
    State.currentEnemy = nil
    task.wait(1)
    applyWalkSpeed()
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        applyWalkSpeed()
    end
end)

-- ==========================================
-- UI: FARM
-- ==========================================
Tabs.Farm:AddSection("Auto Farm")

local FarmToggle = Tabs.Farm:AddToggle("AutoFarmToggle", {
    Title = "Aktifkan Auto Farm",
    Default = false
})
FarmToggle:OnChanged(function()
    State.farming = Options.AutoFarmToggle.Value
    if not State.farming then State.currentEnemy = nil end
end)

local NPCDropdown = Tabs.Farm:AddDropdown("SelectNPC", {
    Title = "Pilih Target NPC",
    Values = { "Bandit", "Monkey", "Brute", "Pirate", "Desert Bandit", "Reborn Skeleton" },
    Multi = false,
    Default = 1,
})
NPCDropdown:OnChanged(function(Value)
    State.target = Value
    State.currentEnemy = nil
end)

Tabs.Farm:AddSlider("AttackDelay", {
    Title = "Attack Delay",
    Description = "Jeda antar serangan (detik)",
    Default = 0.5,
    Min = 0.1,
    Max = 2,
    Rounding = 1,
    Callback = function(Value)
        State.attackDelay = Value
    end
})

Tabs.Farm:AddSlider("FarmHeight", {
    Title = "Tinggi di Atas Musuh",
    Default = 8,
    Min = 3,
    Max = 30,
    Rounding = 0,
    Callback = function(Value)
        State.height = Value
    end
})

-- ==========================================
-- UI: RAID
-- ==========================================
Tabs.Raid:AddSection("Auto Raid")

local RaidToggle = Tabs.Raid:AddToggle("AutoRaidToggle", {
    Title = "Aktifkan Auto Raid",
    Description = "Mengutamakan raid dibanding Auto Farm biasa.",
    Default = false
})
RaidToggle:OnChanged(function()
    State.raid = Options.AutoRaidToggle.Value
    State.currentEnemy = nil
end)

local ChipDropdown = Tabs.Raid:AddDropdown("RaidChip", {
    Title = "Pilih Chip",
    Values = { "Flame", "Ice", "Quake", "Light", "Dark", "String", "Rumble",
               "Magma", "Buddha", "Sand", "Phoenix", "Dough" },
    Multi = false,
    Default = 1,
})
ChipDropdown:OnChanged(function(Value)
    State.raidChip = Value
end)

local AutoStartToggle = Tabs.Raid:AddToggle("RaidAutoStart", {
    Title = "Auto Start Raid",
    Description = "Pilih chip lalu tekan tombol raid otomatis (butuh Special Microchip).",
    Default = true
})
AutoStartToggle:OnChanged(function()
    State.raidAutoStart = Options.RaidAutoStart.Value
end)

-- ==========================================
-- UI: PLAYER
-- ==========================================
Tabs.Player:AddSection("Player Mods")

Tabs.Player:AddSlider("WalkSpeed", {
    Title = "Walk Speed",
    Default = 16,
    Min = 16,
    Max = 200,
    Rounding = 0,
    Callback = function(Value)
        State.walkSpeed = Value
        if Value <= 16 then
            local _, hum = getChar()
            if hum then hum.WalkSpeed = 16 end
        else
            applyWalkSpeed()
        end
    end
})

Tabs.Player:AddSection("Security")

local AntiKick = Tabs.Player:AddToggle("AntiKickToggle", {
    Title = "Anti-Kick (client-side)",
    Description = "Hanya memblokir Kick dari client. Tidak melindungi dari kick/ban server.",
    Default = true
})
AntiKick:OnChanged(function()
    State.antiKick = Options.AntiKickToggle.Value
end)
State.antiKick = true

-- ==========================================
-- UI: SETTINGS (config & tema)
-- ==========================================
if InterfaceManager then
    pcall(function()
        InterfaceManager:SetLibrary(Fluent)
        InterfaceManager:SetFolder("EnlesHub")
        InterfaceManager:BuildInterfaceSection(Tabs.Settings)
    end)
end

if SaveManager then
    pcall(function()
        SaveManager:SetLibrary(Fluent)
        SaveManager:IgnoreThemeSettings()
        SaveManager:SetIgnoreIndexes({})
        SaveManager:SetFolder("EnlesHub/Configs")
        SaveManager:BuildConfigSection(Tabs.Settings)
    end)
end

-- Tombol buka/tutup untuk HP (Delta mobile)
pcall(function()
    local parent = (gethui and gethui()) or game:GetService("CoreGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "EnlesToggle"
    gui.ResetOnSpawn = false
    gui.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(44, 44)
    btn.Position = UDim2.new(0, 10, 0.5, -22)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = "E"
    btn.TextSize = 20
    btn.Font = Enum.Font.GothamBold
    btn.Parent = gui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    btn.MouseButton1Click:Connect(function()
        pcall(function() Window:Minimize() end)
    end)
end)

Window:SelectTab(1)
Fluent:Notify({ Title = "Enles Hub", Content = "Script berhasil dimuat!", Duration = 5 })
if SaveManager then
    pcall(function() SaveManager:LoadAutoloadConfig() end)
end
