local BASE = "https://raw.githubusercontent.com/enlesofficialll-cpu/Enles/main/"

local Games = {
    [10563114921] = "stealanegg",
}

local function notify(text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Enles Hub",
            Text = text,
            Duration = 6,
        })
    end)
end

if not game:IsLoaded() then game.Loaded:Wait() end

local file = Games[game.PlaceId] or Games[game.GameId]
if not file then
    notify("Game belum didukung. PlaceId: " .. tostring(game.PlaceId) .. " | GameId: " .. tostring(game.GameId))
    warn("Enles Hub | Belum terdaftar. PlaceId:", game.PlaceId, "GameId:", game.GameId)
    return
end

local url = BASE .. "games/" .. file .. ".lua"
local ok, err = pcall(function()
    local src = game:HttpGet(url)
    local fn, syntaxErr = loadstring(src)
    if not fn then error(syntaxErr) end
    fn()
end)

if not ok then
    notify("Gagal memuat skrip. Lihat console.")
    warn("Enles Hub | Gagal memuat " .. url .. " -> " .. tostring(err))
end
