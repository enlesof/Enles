-- ==========================================
-- ENLES HUB | STEAL AN EGG
-- Fitur: Auto Steal
-- ==========================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ------------------------------------------
-- LOADER UI (dengan link cadangan)
-- ------------------------------------------
local function tryLoad(name, urls)
    for _, url in ipairs(urls) do
        local ok, res = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        if ok and res then return res end
        warn("Enles Hub | Gagal memuat " .. name .. " dari " .. url .. " -> " .. tostring(res))
    end
end

local Fluent = tryLoad("Fluent", {
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua",
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Fluent.lua",
    "https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau",
})
if not Fluent then
    warn("Enles Hub | Library UI gagal dimuat. Script dihentikan.")
    return
end

local Window = Fluent:CreateWindow({
    Title = "Enles Hub",
    SubTitle = "Steal An Egg",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "egg" }),
}
local Options = Fluent.Options

-- ------------------------------------------
-- STATE & HELPERS
-- ------------------------------------------
local State = {
    autoSteal = false,
    delay = 1.5,
    home = nil, -- CFrame base
}

local BLACKLIST = { "hatch", "collect", "place", "buy", "claim", "sell", "upgrade", "pickup" }

local function getRoot()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if hum and root and hum.Health > 0 then return root end
end

local function containsAny(text, words)
    text = string.lower(text or "")
    for _, w in ipairs(words) do
        if string.find(text, w, 1, true) then return true end
    end
    return false
end

local function promptPosition(prompt)
    local parent = prompt.Parent
    if parent and parent:IsA("Attachment") then
        return parent.WorldPosition
    elseif parent and parent:IsA("BasePart") then
        return parent.Position
    end
    local model = prompt:FindFirstAncestorOfClass("Model")
    if model then
        local ok, pivot = pcall(function() return model:GetPivot().Position end)
        if ok then return pivot end
    end
end

local function hasEggInPath(prompt)
    local node = prompt
    for _ = 1, 4 do
        if not node then break end
        if string.find(string.lower(node.Name), "egg", 1, true) then return true end
        node = node.Parent
    end
    return false
end

local function isStealPrompt(prompt)
    if not prompt:IsA("ProximityPrompt") or not prompt.Enabled then return false end
    local action = string.lower(prompt.ActionText or "")
    local object = string.lower(prompt.ObjectText or "")
    if containsAny(action, BLACKLIST) then return false end
    if string.find(action, "steal", 1, true) then return true end
    return string.find(object, "egg", 1, true) ~= nil or hasEggInPath(prompt)
end

local function findNearestStealPrompt()
    local root = getRoot()
    if not root then return end
    local best, bestDist = nil, math.huge
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("ProximityPrompt") and isStealPrompt(inst) then
            local pos = promptPosition(inst)
            if pos then
                local d = (root.Position - pos).Magnitude
                if d < bestDist then
                    best, bestDist = inst, d
                end
            end
        end
    end
    return best
end

-- ------------------------------------------
-- AUTO STEAL
-- ------------------------------------------
local function stealOnce()
    local root = getRoot()
    if not root then return end

    local prompt = findNearestStealPrompt()
    if not prompt then return end
    local pos = promptPosition(prompt)
    if not pos then return end

    pcall(function() prompt.HoldDuration = 0 end)
    root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    task.wait(0.15)

    if fireproximityprompt then
        pcall(fireproximityprompt, prompt)
    else
        Fluent:Notify({ Title = "Auto Steal", Content = "Executor tidak mendukung fireproximityprompt.", Duration = 4 })
        State.autoSteal = false
        return
    end
    task.wait(0.3)

    -- Kembali ke base supaya telur curian aman
    if State.home then
        local r = getRoot()
        if r then r.CFrame = State.home end
    end
end

task.spawn(function()
    while true do
        task.wait(State.delay)
        if State.autoSteal then
            pcall(stealOnce)
        end
    end
end)

-- ------------------------------------------
-- UI
-- ------------------------------------------
Tabs.Main:AddSection("Auto Steal")

local StealToggle = Tabs.Main:AddToggle("AutoSteal", {
    Title = "Auto Steal",
    Description = "Cari telur terdekat, ambil, lalu kembali ke base.",
    Default = false
})
StealToggle:OnChanged(function()
    State.autoSteal = Options.AutoSteal.Value
    if State.autoSteal and not State.home then
        Fluent:Notify({
            Title = "Auto Steal",
            Content = "Posisi base belum disimpan. Berdiri di base lalu tekan 'Simpan posisi base'.",
            Duration = 5
        })
    end
end)

Tabs.Main:AddButton({
    Title = "Simpan posisi base",
    Description = "Berdiri di base kamu, lalu tekan tombol ini.",
    Callback = function()
        local root = getRoot()
        if root then
            State.home = root.CFrame
            Fluent:Notify({ Title = "Base", Content = "Posisi base disimpan.", Duration = 3 })
        end
    end
})

Tabs.Main:AddSlider("StealDelay", {
    Title = "Jeda antar curian",
    Description = "Detik",
    Default = 1.5,
    Min = 0.5,
    Max = 5,
    Rounding = 1,
    Callback = function(Value)
        State.delay = Value
    end
})

Tabs.Main:AddSection("Bantuan")

Tabs.Main:AddButton({
    Title = "Cetak daftar prompt (debug)",
    Description = "Menulis prompt terdekat ke Delta Console untuk kalibrasi.",
    Callback = function()
        local root = getRoot()
        local count = 0
        for _, inst in ipairs(workspace:GetDescendants()) do
            if inst:IsA("ProximityPrompt") then
                local pos = promptPosition(inst)
                local dist = (root and pos) and math.floor((root.Position - pos).Magnitude) or -1
                print(string.format("Enles Hub | [%s] action='%s' object='%s' dist=%s -> %s",
                    isStealPrompt(inst) and "STEAL" or "other",
                    inst.ActionText, inst.ObjectText, dist, inst:GetFullName()))
                count = count + 1
                if count >= 40 then break end
            end
        end
        Fluent:Notify({ Title = "Debug", Content = count .. " prompt dicetak ke console.", Duration = 3 })
    end
})

-- ------------------------------------------
-- TOMBOL BUKA/TUTUP (HP)
-- ------------------------------------------
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
Fluent:Notify({ Title = "Enles Hub", Content = "Steal An Egg dimuat!", Duration = 4 })
