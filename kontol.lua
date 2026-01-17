local Fluent = loadstring(game:HttpGet("https://github.com/haijuga7/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/haijuga7/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/haijuga7/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "AutoFish " .. Fluent.Version,
    SubTitle = "by Kadal_Galau",
    TabWidth = 100,
    Size = UDim2.fromOffset(480, 380),
    Acrylic = true, -- The blur may be detectable, setting this to false disables blur entirely
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
})

--Fluent provides Lucide Icons https://lucide.dev/icons/ for the tabs, icons are optional
local Tabs = {
    farm = Window:AddTab({ Title = "Fishing", Icon = "anchor" }),
    playerTab = Window:AddTab({ Title = "Player", Icon = "user" }),
    autoTab = Window:AddTab({ Title = "Automatic", Icon = "fast-forward" }),
    menuTab = Window:AddTab({ Title = "Menu", Icon = "menu" }),
    teleportTab = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    serverTab = Window:AddTab({ Title = "Server", Icon = "server" }),
    webhook = Window:AddTab({ Title = "WebHook", Icon = "link"}),
    MISC = Window:AddTab({ Title = "MISC", Icon = "book-audio" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local SectFarm = {
    fishSupport = Tabs.farm:AddSection("Fishing Support"),
    legitfish = Tabs.farm:AddSection("Legit Fishing"),
    insfish = Tabs.farm:AddSection("Instant Fishing"),
    blatantv1 = Tabs.farm:AddSection("Blatant V1"),
    blatantv2 = Tabs.farm:AddSection("Blatant V2"),
    favsec = Tabs.farm:AddSection("Auto Fav/Unfav"),
    sellall = Tabs.farm:AddSection("Auto Sell")
}

local SectAuto = {
    weatherTab = Tabs.autoTab:AddSection("Auto Buy Weather"),
    totemTab = Tabs.autoTab:AddSection("Totem Feature"),
    potionTab = Tabs.autoTab:AddSection("Potion Feature"),
    saveTab = Tabs.autoTab:AddSection("Auto Save Location")
}

local SectTeleport = {
    telePlayer = Tabs.teleportTab:AddSection("Teleport To Players"),
    teleLocation = Tabs.teleportTab:AddSection("Teleport To Location")
}

local HttpService = game:GetService("HttpService")

local savedPosition = nil

-- ====================================
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = game.Players.LocalPlayer
local RepStorage = game:GetService("ReplicatedStorage") 
local ItemUtility = require(RepStorage:WaitForChild("Shared"):WaitForChild("ItemUtility", 10))
local TierUtility = require(RepStorage:WaitForChild("Shared"):WaitForChild("TierUtility", 10))

local stealthMode = false
local stealthHight = 110

local SAVE_FILE_NAME = "Saved_Posision.json"

local RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}

local PlayerDataReplion = nil

local function GetRemote(name, timeout)
    local currentInstance = RepStorage
    for _, childName in ipairs(RPath) do
        currentInstance = currentInstance:WaitForChild(childName, timeout or 0.5)
        if not currentInstance then return nil end
    end
    return currentInstance:FindFirstChild(name)
end

local function GetHumanoid()
    local Character = LocalPlayer.Character
    if not Character then
        Character = LocalPlayer.CharacterAdded:Wait()
    end
    return Character:FindFirstChildOfClass("Humanoid")
end

local function GetHRP()
    local Character = game.Players.LocalPlayer.Character
    if not Character then
        Character = game.Players.LocalPlayer.CharacterAdded:Wait()
    end
    return Character:WaitForChild("HumanoidRootPart", 5)
end

local function TeleportStealth(cframe, lookup)
    local hrp = GetHRP()
    
    if hrp and typeof(cframe) == "Vector3" and typeof(lookup) == "Vector3" then
        local targetCFrame = CFrame.new(cframe, cframe + lookup)
        hrp.CFrame = targetCFrame * CFrame.new(0, stealthHight, 0)
    end
end

local function TeleportToLookAt(cframe, lookup)
    local hrp = GetHRP()
    
    hrp.Anchored = false
    if hrp and typeof(cframe) == "Vector3" and typeof(lookup) == "Vector3" then
        local targetCFrame = CFrame.new(cframe, cframe + lookup)
        hrp.CFrame = targetCFrame * CFrame.new(0, 0.5, 0)
        
        if stealthMode then
            TeleportStealth(cframe, lookup)
            wait(0.1)
            hrp.Anchored = true
        end
        
        Fluent:Notify({ Title = "Teleport Sukses!", Duration = 3})
    else
        Fluent:Notify({ Title = "Teleport Gagal", Content = "Data posisi tidak valid.", Duration = 3})
    end
end

local function SavePosition()
    local hrp = GetHRP()
    if not hrp then
        Fluent:Notify({ 
            Title = "Save Error", 
            Content = "Character tidak ditemukan!", 
            Duration = 3 
        })
        return false
    end
    
    local posData = {
        Position = {
            X = hrp.Position.X,
            Y = hrp.Position.Y,
            Z = hrp.Position.Z
        },
        LookVector = {
            X = hrp.CFrame.LookVector.X,
            Y = hrp.CFrame.LookVector.Y,
            Z = hrp.CFrame.LookVector.Z
        },
        Timestamp = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    -- Simpan ke variabel global
    savedPosition = posData
    
    -- Simpan ke file JSON (jika executor support writefile)
    if writefile and readfile then
        writefile(SAVE_FILE_NAME, HttpService:JSONEncode(posData))
        Fluent:Notify({ 
            Title = "✅ Position Saved!", 
            Content = "Locked",
            Duration = 4 
        })
    end
end

local function LoadPosition()
    -- Coba load dari file dulu
    if readfile and isfile and isfile(SAVE_FILE_NAME) then
        local success, fileData = pcall(function()
            return readfile(SAVE_FILE_NAME)
        end)
        
        if success and fileData then
            local ok, decoded = pcall(function()
                return HttpService:JSONDecode(fileData)
            end)
            
            if ok and decoded and decoded.Position and decoded.LookVector then
                savedPosition = decoded
                return true
            end
        end
    end
    
    return savedPosition ~= nil
end

local function ResetPosition()
    savedPosition = nil
    
    if writefile and delfile and isfile and isfile(SAVE_FILE_NAME) then
        pcall(function()
            delfile(SAVE_FILE_NAME)
        end)
    end
    
    Fluent:Notify({ 
        Title = "🗑️ Position Reset", 
        Content = "Saved position telah dihapus.",
        Duration = 3 
    })
end

local function TeleportToSavedPosition()
    if not savedPosition then
        Fluent:Notify({ 
            Title = "❌ No Saved Position", 
            Content = "Belum ada posisi yang disave!",
            Duration = 3 
        })
        return false
    end
    
    local hrp = GetHRP()
    if not hrp then
        warn("[AutoSave] Waiting for character...")
        return false
    end
    
    local pos = savedPosition.Position
    local look = savedPosition.LookVector
    
    local targetPos = Vector3.new(pos.X, pos.Y, pos.Z)
    local lookVector = Vector3.new(look.X, look.Y, look.Z)
    
    -- Gunakan fungsi teleport yang sudah ada
    TeleportToLookAt(targetPos, lookVector)
    
    return true
end

pcall(function()
    local player = game:GetService("Players").LocalPlayer
    
    -- Cek semua koneksi yang terhubung ke event Idled pemain lokal
    for i, v in pairs(getconnections(player.Idled)) do
        if v.Disable then
            v:Disable() -- Menonaktifkan koneksi event
            print("[BloxFishHub Anti-AFK] ON")
        end
    end
end)

local function GetPlayerDataReplion()
    if PlayerDataReplion then return PlayerDataReplion end
    local ReplionModule = RepStorage:WaitForChild("Packages"):WaitForChild("Replion", 10)
    if not ReplionModule then return nil end
    local ReplionClient = require(ReplionModule).Client
    PlayerDataReplion = ReplionClient:WaitReplion("Data", 5)
    return PlayerDataReplion
end

local RF_SellAllItems = GetRemote("RF/SellAllItems", 5)

local function GetFishNameAndRarity(item)
    local name = item.Identifier or "Unknown"
    local rarity = item.Metadata and item.Metadata.Rarity or "COMMON"
    local itemID = item.Id

    local itemData = nil

    if ItemUtility and itemID then
        pcall(function()
            itemData = ItemUtility:GetItemData(itemID)
            if not itemData then
                local numericID = tonumber(item.Id) or tonumber(item.Identifier)
                if numericID then
                    itemData = ItemUtility:GetItemData(numericID)
                end
            end
        end)
    end

    if itemData and itemData.Data and itemData.Data.Name then
        name = itemData.Data.Name
    end

    if item.Metadata and item.Metadata.Rarity then
        rarity = item.Metadata.Rarity
    elseif itemData and itemData.Probability and itemData.Probability.Chance and TierUtility then
        local tierObj = nil
        pcall(function()
            tierObj = TierUtility:GetTierFromRarity(itemData.Probability.Chance)
        end)

        if tierObj and tierObj.Name then
            rarity = tierObj.Name
        end
    end

    return name, rarity
end

local function GetItemMutationString(item)
    if item.Metadata and item.Metadata.Shiny == true then return "Shiny" end
    return item.Metadata and item.Metadata.VariantId or ""
end

local function CensorName(name)
    if not name or type(name) ~= "string" or #name < 1 then
        return "N/A" 
    end
    
    if #name <= 3 then
        return name
    end

    local prefix = name:sub(1, 3)
    
    local censureLength = #name - 3
    
    local censorString = string.rep("*", censureLength)
    
    return prefix .. censorString
end

do
    local PromptController = nil
    local Promise = nil
    
    pcall(function()
        PromptController = require(RepStorage:WaitForChild("Controllers").PromptController)
        Promise = require(RepStorage:WaitForChild("Packages").Promise)
    end)
    
    _G.BloxFish_AutoAcceptTradeEnabled = false 

    if PromptController and PromptController.FirePrompt and Promise then
        local oldFirePrompt = PromptController.FirePrompt
        PromptController.FirePrompt = function(self, promptText, ...)
            
            if _G.BloxFish_AutoAcceptTradeEnabled and type(promptText) == "string" and promptText:find("Accept") and promptText:find("from:") then
                
                local initiatorName = string.match(promptText, "from: ([^\n]+)") or "Seseorang"
                
                
                return Promise.new(function(resolve)
                    task.wait(2)
                    resolve(true)
                end)
            end
            
            return oldFirePrompt(self, promptText, ...)
        end
    else
        warn("[BloxFishHub] Gagal memuat PromptController/Promise untuk Auto Accept Trade.")
    end
end


local FishingAreas = {
    ["Ancient Jungle"] = { cframe = Vector3.new(1896.9, 8.4, -578.7), lookup = Vector3.new(0.973, 0.000, 0.229) },
    ["Ancient Ruins"] = { cframe = Vector3.new(6081.4, -585.9, 4634.5), lookup = Vector3.new(-0.619, -0.000, 0.785) },
    ["Ancient Ruins Door "] = { cframe = Vector3.new(6051.0, -538.9, 4386.0), lookup = Vector3.new(-0.000, -0.000, -1.000) },
    ["Christmast Island"] = { cframe = Vector3.new(1175.3,23.5,1545.3), lookup = Vector3.new(-0.787,-0.000,0.616) },
    ["Christmast Cave"] = { cframe = Vector3.new(743.5,-487.1,8863.5), lookup = Vector3.new(-0.020,-0.000,1.000) },
    ["Coral Reefs"] = { cframe = Vector3.new(-2935.1,4.8,2050.9), lookup = Vector3.new(-0.306,-0.000,0.952) },
    ["Crater Island "] = { cframe = Vector3.new(1077.6, 2.8, 5080.9), lookup = Vector3.new(-0.987, 0.000, -0.159) },
    ["Esoteric Deep"] = { cframe = Vector3.new(3202.2, -1302.9, 1432.7), lookup = Vector3.new(0.896, 0.000, -0.444) },
    ["Kohana"] = { cframe = Vector3.new(-367.8, 6.8, 521.9), lookup = Vector3.new(0.000, -0.000, -1.000) },
    ["Kohana Volcano "] = { cframe = Vector3.new(-561.6, 21.1, 158.6), lookup = Vector3.new(-0.403, -0.000, 0.915) },
    ["Sacred Temple "] = { cframe = Vector3.new(1466.6, -22.8, -618.8), lookup = Vector3.new(-0.389, 0.000, 0.921) },
    ["Sisyphus Statue "] = { cframe = Vector3.new(-3715.1, -136.8, -1010.6), lookup = Vector3.new(-0.764, 0.000, 0.646) },
    ["Treasure Room "] = { cframe = Vector3.new(-3604.2, -283.2, -1613.7), lookup = Vector3.new(-0.557, -0.000, -0.831) },
    ["Tropical Grove "] = { cframe = Vector3.new(-2173.3,53.5,3632.3), lookup = Vector3.new(0.729,0.000,0.684) },
    ["Underground Cellar"] = { cframe = Vector3.new(2136.0, -91.2, -699.0), lookup = Vector3.new(-0.000, 0.000, -1.000) }
}
local AreaNames = {}
for name, _ in pairs(FishingAreas) do
    table.insert(AreaNames, name)
end
table.sort(AreaNames)

-- ======================================================================
do
    local RE_EquipToolFromHotbar = GetRemote("RE/EquipToolFromHotbar")
    local walkOnWaterConnection = nil
    local isWalkOnWater = false
    local waterPlatform = nil
    local autoERodConn = nil
    local autoERodState = false
    
    local isNoAnimationActive = false
    local originalAnimator = nil
    local originalAnimateScript = nil
    
    local function WoW()
        -- Buat Platform jika belum ada
        if not waterPlatform then
            waterPlatform = Instance.new("Part")
            waterPlatform.Name = "WaterPlatform"
            waterPlatform.Anchored = true
            waterPlatform.CanCollide = true
            waterPlatform.Transparency = 1 
            waterPlatform.Size = Vector3.new(15, 1, 15) -- Ukuran diperbesar sedikit
            waterPlatform.Parent = workspace
        end
        
        -- Pastikan koneksi lama mati dulu sebelum buat baru
        if walkOnWaterConnection then walkOnWaterConnection:Disconnect() end
        
        walkOnWaterConnection = game:GetService("RunService").RenderStepped:Connect(function()
            -- [FIX] Ambil Karakter TERBARU setiap frame
            local character = LocalPlayer.Character
            if not isWalkOnWater or not character then return end
            
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
        
            -- Pastikan platform masih ada (kadang kehapus oleh game cleanup)
            if not waterPlatform or not waterPlatform.Parent then
                waterPlatform = Instance.new("Part")
                waterPlatform.Name = "WaterPlatform"
                waterPlatform.Anchored = true
                waterPlatform.CanCollide = true
                waterPlatform.Transparency = 1 
                waterPlatform.Size = Vector3.new(15, 1, 15)
                waterPlatform.Parent = workspace
            end
        
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {workspace.Terrain} 
            rayParams.FilterType = Enum.RaycastFilterType.Include -- MODE WHITELIST
            rayParams.IgnoreWater = false -- Pastikan Air terdeteksi
        
            -- Tembak dari ketinggian di atas kepala
            local rayOrigin = hrp.Position + Vector3.new(0, 5, 0) 
            local rayDirection = Vector3.new(0, -200, 0)
        
            local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)
        
            -- 2. LOGIKA DETEKSI
            if result and result.Material == Enum.Material.Water then
                -- Jika menabrak AIR (Terrain Water)
                local waterSurfaceHeight = result.Position.Y
                
                -- Taruh platform tepat di permukaan air
                waterPlatform.Position = Vector3.new(hrp.Position.X, waterSurfaceHeight, hrp.Position.Z)
                
                -- Jika kaki player tenggelam sedikit di bawah air, angkat ke atas
                if hrp.Position.Y < (waterSurfaceHeight + 2) and hrp.Position.Y > (waterSurfaceHeight - 5) then
                     -- Cek input jump biar gak stuck pas mau loncat dari air
                    if not UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        hrp.CFrame = CFrame.new(hrp.Position.X, waterSurfaceHeight + 3.2, hrp.Position.Z)
                    end
                end
            else
                -- Sembunyikan platform jika di darat
                waterPlatform.Position = Vector3.new(hrp.Position.X, -500, hrp.Position.Z)
            end
        end)
    end
    
    local function DisableAnimations()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = GetHumanoid()
        
        if not humanoid then return end
    
        -- 1. Blokir script 'Animate' bawaan (yang memuat default anim)
        local animateScript = character:FindFirstChild("Animate")
        if animateScript and animateScript:IsA("LocalScript") and animateScript.Enabled then
            originalAnimateScript = animateScript.Enabled
            animateScript.Enabled = false
        end
    
        -- 2. Hapus Animator (menghalangi semua animasi dimainkan/dimuat)
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            -- Simpan referensi objek Animator aslinya
            originalAnimator = animator 
            animator:Destroy()
        end
    end
    
    local function EnableAnimations()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        
        -- 1. Restore script 'Animate'
        local animateScript = character:FindFirstChild("Animate")
        if animateScript and originalAnimateScript ~= nil then
            animateScript.Enabled = originalAnimateScript
        end
        
        local humanoid = GetHumanoid()
        if not humanoid then return end
    
        -- 2. Restore/Tambahkan Animator
        local existingAnimator = humanoid:FindFirstChildOfClass("Animator")
        if not existingAnimator then
            -- Jika Animator tidak ada, dan kita memiliki objek aslinya, restore
            if originalAnimator and not originalAnimator.Parent then
                originalAnimator.Parent = humanoid
            else
                -- Jika objek asli hilang, buat yang baru
                Instance.new("Animator").Parent = humanoid
            end
        end
        originalAnimator = nil -- Bersihkan referensi lama
    end
    
    -- Performance Monitor System
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Stats = game:GetService("Stats")
    
    local MonitorEnabled = false
    local MonitorGui = nil
    local MonitorUpdateConnection = nil
    
    local function GetPingColor(ping)
        if ping <= 50 then
            return Color3.fromRGB(0, 255, 0) -- Green
        elseif ping <= 100 then
            return Color3.fromRGB(255, 255, 0) -- Yellow
        elseif ping <= 300 then
            return Color3.fromRGB(255, 165, 0) -- Orange
        else
            return Color3.fromRGB(255, 0, 0) -- Red
        end
    end
    
    local function GetCPUColor(cpu)
        if cpu <= 50 then
            return Color3.fromRGB(0, 255, 0)
        elseif cpu <= 100 then
            return Color3.fromRGB(255, 255, 0)
        elseif cpu <= 300 then
            return Color3.fromRGB(255, 165, 0)
        else
            return Color3.fromRGB(255, 0, 0)
        end
    end
    
    local function CreateMonitorGui()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        
        -- Main Screen GUI
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "PerformanceMonitor"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Parent = playerGui
        
        -- Main Frame
        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "MainFrame"
        mainFrame.Size = UDim2.new(0, 90, 0, 80)
        mainFrame.Position = UDim2.new(1, -220, 0, 20) -- Top right corner
        mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        mainFrame.BorderSizePixel = 0
        mainFrame.Parent = screenGui
        
        -- Corner Radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = mainFrame
        
        -- Stroke/Border
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(60, 60, 80)
        stroke.Thickness = 2
        stroke.Parent = mainFrame
        
        -- Title Label
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.Size = UDim2.new(1, 0, 0, 25)
        titleLabel.Position = UDim2.new(0, 0, 0, 0)
        titleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        titleLabel.BorderSizePixel = 0
        titleLabel.Text = "Monitor"
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextSize = 14
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Parent = mainFrame
        
        -- Title Corner
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 8)
        titleCorner.Parent = titleLabel
        
        -- Separator Line
        local separator = Instance.new("Frame")
        separator.Name = "Separator"
        separator.Size = UDim2.new(1, -10, 0, 1)
        separator.Position = UDim2.new(0, 5, 0, 25)
        separator.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        separator.BorderSizePixel = 0
        separator.Parent = mainFrame
        
        -- Ping Label
        local pingLabel = Instance.new("TextLabel")
        pingLabel.Name = "PingLabel"
        pingLabel.Size = UDim2.new(1, -20, 0, 20)
        pingLabel.Position = UDim2.new(0, 10, 0, 32)
        pingLabel.BackgroundTransparency = 1
        pingLabel.Text = "Ping : 0 ms"
        pingLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        pingLabel.TextSize = 12
        pingLabel.Font = Enum.Font.GothamMedium
        pingLabel.TextXAlignment = Enum.TextXAlignment.Left
        pingLabel.Parent = mainFrame
        
        -- CPU Label
        local cpuLabel = Instance.new("TextLabel")
        cpuLabel.Name = "CPULabel"
        cpuLabel.Size = UDim2.new(1, -20, 0, 20)
        cpuLabel.Position = UDim2.new(0, 10, 0, 52)
        cpuLabel.BackgroundTransparency = 1
        cpuLabel.Text = "CPU  : 0 ms"
        cpuLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        cpuLabel.TextSize = 12
        cpuLabel.Font = Enum.Font.GothamMedium
        cpuLabel.TextXAlignment = Enum.TextXAlignment.Left
        cpuLabel.Parent = mainFrame
        
        -- Make draggable (Mobile & PC Support)
        local dragging = false
        local dragInput, dragStart, startPos
        
        mainFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = mainFrame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        mainFrame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                mainFrame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
        
        return screenGui
    end
    
    local function UpdateMonitorValues()
        if not MonitorGui then return end
        
        local mainFrame = MonitorGui:FindFirstChild("MainFrame")
        if not mainFrame then return end
        
        local pingLabel = mainFrame:FindFirstChild("PingLabel")
        local cpuLabel = mainFrame:FindFirstChild("CPULabel")
        
        if pingLabel and cpuLabel then
            -- Get Real Ping
            local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
            
            -- Get Real CPU Usage (Frame Time)
            local cpu = math.floor(Stats.PerformanceStats.CPU:GetValue())
            
            -- Update Ping
            pingLabel.Text = string.format("Ping : %d ms", ping)
            pingLabel.TextColor3 = GetPingColor(ping)
            
            -- Update CPU
            cpuLabel.Text = string.format("CPU  : %d ms", cpu)
            cpuLabel.TextColor3 = GetCPUColor(cpu)
        end
    end
    
    local function EnableMonitor()
        if MonitorEnabled then return end
        
        MonitorEnabled = true
        MonitorGui = CreateMonitorGui()
        
        -- Update every 0.5 seconds
        MonitorUpdateConnection = RunService.Heartbeat:Connect(function()
            if MonitorEnabled then
                UpdateMonitorValues()
            end
        end)
        
        Fluent:Notify({
            Title = "Monitor Enabled",
            Content = "Performance monitor is now active.",
            Duration = 2
        })
    end
    
    local function DisableMonitor()
        if not MonitorEnabled then return end
        
        MonitorEnabled = false
        
        if MonitorUpdateConnection then
            MonitorUpdateConnection:Disconnect()
            MonitorUpdateConnection = nil
        end
        
        if MonitorGui then
            MonitorGui:Destroy()
            MonitorGui = nil
        end
        
        Fluent:Notify({
            Title = "Monitor Disabled",
            Content = "Performance monitor has been disabled.",
            Duration = 2
        })
    end
    
    local function OnCharacterAdded(newCharacter)
        if isNoAnimationActive then
            task.wait(0.2) -- Tunggu sebentar agar LoadCharacter selesai
            DisableAnimations()
        end
    end
    
    local togMoni = SectFarm.fishSupport:AddToggle("togMoni", {
        Title = "Enabled Monitor",
        Default = false,
        Callback = function(state)
            if state then
                EnableMonitor()
            else
                DisableMonitor()
            end
        end
    })
    local autoERod = SectFarm.fishSupport:AddToggle("autoerod", {
        Title = "Auto Equip Rod",
        Default = false,
        Callback = function(b)
            autoERodState = b
            if b then
                autoERodConn = task.spawn(function()
                    while autoERodState do
                        pcall(function() RE_EquipToolFromHotbar:FireServer(1) end) task.wait(1)
                    end
                    autoERodConn = nil
                end)
            else
                autoERodConn = nil
            end
        end
    })
    
    local walkonwater = SectFarm.fishSupport:AddToggle("wlkonwtr", {
        Title = "Walk On Water",
        Default = false,
        Callback = function(c)
            if c then
                isWalkOnWater = true
                WoW()
            else
                isWalkOnWater = false
                if walkOnWaterConnection then walkOnWaterConnection:Disconnect() walkOnWaterConnection = nil end
                if waterPlatform then waterPlatform:Destroy() waterPlatform = nil end
            end
        end
    })
    
    local disAnim = SectFarm.fishSupport:AddToggle("disAnim", {
        Title = "Disable Animation",
        Default = false,
        Callback = function(b)
            isNoAnimationActive = b
            if b then
                DisableAnimations()
            else
                EnableAnimations()
            end
        end
    })
    
    local disNotif = SectFarm.fishSupport:AddToggle("disNotif", {
        Title = "Disable Fish Notif",
        Default = false,
        Callback = function(s)
            s = not s
            pcall(function() game:GetService("Players").LocalPlayer.PlayerGui["Small Notification"].Display.Visible = s end)
        end
    })
    
    local st_height = SectFarm.fishSupport:AddInput("st_height", {
        Title = "Stealth Height",
        Placeholder = "ex: 110",
        Numeric = true,
        Finished = true,
        Callback = function(val)
            stealthHight = tonumber(val)
        end
    })
    
    local stealth = SectFarm.fishSupport:AddToggle("stealth", {
        Title = "Stealth Mode",
        Default = false,
        Callback = function(state)
            local hrp = GetHRP()
            local pos_saved = hrp.Position
            local look_saved = hrp.CFrame.LookVector
            
            stealthMode = state
            if state then
                TeleportToLookAt(pos_saved, look_saved)
            else
                hrp.Anchored = state
                wait(0.1)
                TeleportToLookAt(pos_saved, look_saved)
            end
        end
    })
end

do 
    local RE_EquipToolFromHotbar = GetRemote("RE/EquipToolFromHotbar")
    local RF_ChargeFishingRod    = GetRemote("RF/ChargeFishingRod")
    local RF_RequestFishingMinigameStarted = GetRemote("RF/RequestFishingMinigameStarted")
    local RE_FishingCompleted    = GetRemote("RE/FishingCompleted")
    local RF_CancelFishingInputs = GetRemote("RF/CancelFishingInputs")
    local RF_UpdateAutoFishingState = GetRemote("RF/UpdateAutoFishingState")
    
    local instantLoopThread = nil
    local blatantFishv1LoopThread = nil
    local blatantFishv2LoopThread = nil
    
    local InstantState = nil
    local blatantV1State = nil
    local blatantV2State = nil
    
    local insDe = nil
    local insCyc = nil
    local blatv1de = nil
    local blatv1cyc = nil
    local blatv2de = nil
    local blatv2cyc = nil
    
    local SPEED_LEGIT = 0.05
    local legitClickThread = nil
    
    local FishingController = require(RepStorage:WaitForChild("Controllers").FishingController)
    local AutoFishingController = require(RepStorage:WaitForChild("Controllers").AutoFishingController)
    
    local AutoFishState = {
        IsActive = false,
        MinigameActive = false
    }
    
    local function performClick()
        if FishingController then
            FishingController:RequestFishingMinigameClick()
            task.wait(SPEED_LEGIT)
        end
    end
    
    -- Hook FishingRodStarted (Minigame Aktif)
    local originalRodStarted = FishingController.FishingRodStarted
    FishingController.FishingRodStarted = function(self, arg1, arg2)
        originalRodStarted(self, arg1, arg2)
    
        if AutoFishState.IsActive and not AutoFishState.MinigameActive then
            AutoFishState.MinigameActive = true
    
            if legitClickThread then
                legitClickThread = nil
            end
    
            legitClickThread = task.spawn(function()
                while AutoFishState.IsActive and AutoFishState.MinigameActive do
                    performClick()
                end
            end)
        end
    end
    
    -- Hook FishingStopped
    local originalFishingStopped = FishingController.FishingStopped
    FishingController.FishingStopped = function(self, arg1)
        originalFishingStopped(self, arg1)
    
        if AutoFishState.MinigameActive then
            AutoFishState.MinigameActive = false
        end
    end
    
    local function ToggleAutoClick(shouldActivate)
        if not FishingController or not AutoFishingController then
            Fluent:Notify({ Title = "Error", Content = "Gagal memuat Fishing Controllers.", Duration = 4 })
            return
        end
        
        AutoFishState.IsActive = shouldActivate
    
        local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local fishingGui = playerGui:FindFirstChild("Fishing") and playerGui.Fishing:FindFirstChild("Main")
        local chargeGui = playerGui:FindFirstChild("Charge") and playerGui.Charge:FindFirstChild("Main")
    
    
        if shouldActivate then
            -- 1. Equip Rod Awal
            pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)
            
            -- 2. Force Server AutoFishing State
            pcall(function() RF_UpdateAutoFishingState:InvokeServer(true) end)
            
            -- 3. Sembunyikan UI Minigame
            if fishingGui then fishingGui.Visible = false end
            if chargeGui then chargeGui.Visible = false end
        else
            pcall(function() RF_UpdateAutoFishingState:InvokeServer(false) end)
            if legitClickThread then
                legitClickThread = nil
            end
            AutoFishState.MinigameActive = false
            
            -- 4. Tampilkan kembali UI Minigame
            if fishingGui then fishingGui.Visible = true end
            if chargeGui then chargeGui.Visible = true end
        end
    end
    
    _G.BloxFish_BlatantActive = false
    
    -- [[ 1. LOGIC KILLER: LUMPUHKAN CONTROLLER ]]
    task.spawn(function()
        local S1, FishingController = pcall(function() return require(game:GetService("ReplicatedStorage").Controllers.FishingController) end)
        if S1 and FishingController then
            local Old_Charge = FishingController.RequestChargeFishingRod
            local Old_Cast = FishingController.SendFishingRequestToServer
            
            -- Matikan fungsi charge & cast game asli saat Blatant ON
            FishingController.RequestChargeFishingRod = function(...)
                if _G.BloxFish_BlatantActive then return end 
                return Old_Charge(...)
            end
            FishingController.SendFishingRequestToServer = function(...)
                if _G.BloxFish_BlatantActive then return false, "Blocked by BloxFishHub" end
                return Old_Cast(...)
            end
        end
    end)
    
    -- [[ 2. REMOTE KILLER: BLOKIR KOMUNIKASI ]]
    local mt = getrawmetatable(game)
    local old_namecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if _G.BloxFish_BlatantActive and not checkcaller() then
            -- Cegah game mengirim request mancing atau request update state
            if method == "InvokeServer" and (self.Name == "RequestFishingMinigameStarted" or self.Name == "ChargeFishingRod" or self.Name == "UpdateAutoFishingState") then
                return nil 
            end
            if method == "FireServer" and self.Name == "FishingCompleted" then
                return nil
            end
        end
        return old_namecall(self, ...)
    end)
    setreadonly(mt, true)
    
    local function instantOk()
        RF_ChargeFishingRod:InvokeServer(1, 0.999)
        RF_RequestFishingMinigameStarted:InvokeServer(1, 0.999)
        task.wait(insDe)
        RE_FishingCompleted:FireServer()
        task.wait(0.3)
        RF_CancelFishingInputs:InvokeServer()
    end
    
    local function blatantFishv1()
        task.spawn(function()
            RF_CancelFishingInputs:InvokeServer(1, 0.99)
        end)
        task.spawn(function()
            RF_ChargeFishingRod:InvokeServer(1, 0.99)
        end)
        task.spawn(function()
            task.wait(0.016)
            RF_RequestFishingMinigameStarted:InvokeServer(1, 0.99)
            task.wait(blatv1de)
            RE_FishingCompleted:FireServer()
        end)
    end
    
    local function blatantFishv2()
        task.spawn(function()
            pcall(function() RF_CancelFishingInputs:InvokeServer() end)
        end)
        task.spawn(function()
            task.wait(0.001)
            pcall(function() RF_ChargeFishingRod:InvokeServer(1, 0.999) end)
        end)
        task.spawn(function()
            task.wait(0.016)
            pcall(function() RF_RequestFishingMinigameStarted:InvokeServer(1, 0.999) end)
        end)
        task.spawn(function()
            task.wait(blatv2de)
            pcall(function() RE_FishingCompleted:FireServer() end)
        end)
    end
    
    local slidlegit = SectFarm.legitfish:AddInput("klikd", {
        Title = "Legit Click Speed Delay",
        Placeholder = "ex: 0.1",
        Numeric = true,
        Finished = true,
        Callback = function(val)
            SPEED_LEGIT = tonumber(val)
        end
    })
    
    local toggleLegit = SectFarm.legitfish:AddToggle("legit", { -- ✅ DIPERBAIKI
        Title = "Auto Fish (Legit)",
        Default = false,
        Callback = function(state)
            ToggleAutoClick(state)
        end
    })

    local InstantDelay = SectFarm.insfish:AddInput("instdelay", { -- ✅ DIPERBAIKI
        Title = "Complete Delay",
        Placeholder = "ex: 1",
        Numeric = true,
        Finished = true,
        Callback = function(val)
            insDe = tonumber(val)
        end
    })
    
    local toggleInstant = SectFarm.insfish:AddToggle("toginst", { -- ✅ DIPERBAIKI
        Title = "Instant Fish",
        Default = false,
        Callback = function(state)
            InstantState = state
            _G.BloxFish_BlatantActive = state
            pcall(function() RF_UpdateAutoFishingState:InvokeServer(state) end)
            
            if state then
                instantLoopThread = task.spawn(function()
                    while InstantState do
                        instantOk()
                        task.wait(0.1) 
                    end
                end)
            else
                if instantLoopThread then instantLoopThread = nil end
            end
        end
    })

    local BlatantV1Cast = SectFarm.blatantv1:AddInput("blatV1cast", { -- ✅ DIPERBAIKI
        Title = "Cast Delay",
        Placeholder = "ex: 1.97",
        Numeric = true,
        Finished = true,
        Callback = function(val)
            blatv1cyc = tonumber(val)
        end
    })

    local BlatantV1Delay = SectFarm.blatantv1:AddInput("blatV1delay", { -- ✅ DIPERBAIKI
        Title = "Complete Delay",
        Placeholder = "ex: 1",
        Numeric = true,
        Finished = true,
        Callback = function(val)
            blatv1de = tonumber(val)
        end
    })
    
    local BlatantV1Toggle = SectFarm.blatantv1:AddToggle("togblatv1", { -- ✅ DIPERBAIKI
        Title = "BlatantV1 Fish",
        Default = false,
        Callback = function(state)
            blatantV1State = state
            _G.BloxFish_BlatantActive = state
            pcall(function() RF_UpdateAutoFishingState:InvokeServer(state) end)
            
            if state then
                blatantFishv1LoopThread = task.spawn(function()
                    while blatantV1State do
                        blatantFishv1()
                        task.wait(blatv1cyc)
                    end
                end)
            else
                if blatantFishv1LoopThread then blatantFishv1LoopThread = nil end
            end
        end
    })

    local BlatantV2Bait = SectFarm.blatantv2:AddInput("blatV2bait", { -- ✅ DIPERBAIKI
        Title = "Bait Delay",
        Placeholder = "ex: 0.3",
        Numeric = true,
        Finished = true,
        Callback = function(val)
            blatv2cyc = tonumber(val)
        end
    })
    
    local BlatantV2Delay = SectFarm.blatantv2:AddInput("blatV2delay", { -- ✅ DIPERBAIKI
        Title = "Complete Delay",
        Placeholder = "ex: 0.7",
        Numeric = true,
        Finished = true,
        Callback = function(val)
            blatv2de = tonumber(val)
        end
    })
    
    local BlatantV2Toggle = SectFarm.blatantv2:AddToggle("togblatv2", { -- ✅ DIPERBAIKI
        Title = "BlatantV2 Fish",
        Default = false,
        Callback = function(state)
            blatantV2State = state -- ✅ DIPERBAIKI (tadinya blatantV1State)
            _G.BloxFish_BlatantActive = state
            pcall(function() RF_UpdateAutoFishingState:InvokeServer(state) end)
            
            if state then
                blatantFishv2LoopThread = task.spawn(function()
                    while blatantV2State do
                        blatantFishv2()
                        task.wait(blatv2cyc + blatv2de)
                    end
                end)
            else
                if blatantFishv2LoopThread then blatantFishv2LoopThread = nil end
            end
        end
    })
end 

do 
    local autoFavoriteState = false
    local autoFavoriteThread = nil
    local autoUnfavoriteState = false
    local autoUnfavoriteThread = nil
    local selectedRarities = {}
    local selectedItemNames = {}
    local selectedMutations = {}
    
    local RE_FavoriteItem = GetRemote("RE/FavoriteItem")
    
    local function getAutoFavoriteItemOptions()
        local itemNames = {}
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local itemsContainer = ReplicatedStorage:FindFirstChild("Items")
    
        if not itemsContainer then
            return {"(Kontainer 'Items' di ReplicatedStorage Tidak Ditemukan)"}
        end
    
        for _, itemObject in ipairs(itemsContainer:GetChildren()) do
            local itemName = itemObject.Name
            
            if type(itemName) == "string" and #itemName >= 3 then
                -- Menggunakan string:sub untuk mengecek prefix '!!!'
                local prefix = itemName:sub(1, 3)
                
                if prefix ~= "!!!" then
                    table.insert(itemNames, itemName)
                end
            end
        end
    
        table.sort(itemNames)
        
        if #itemNames == 0 then
            return {"(Kontainer 'Items' Kosong atau Semua Item '!!!')"}
        end
        
        return itemNames
    end
        
    local allItemNames = getAutoFavoriteItemOptions()
        
        -- FUNGSI HELPER: Mendapatkan semua item yang memenuhi kriteria (DIFORWARD KE FAVORITE)
        -- GANTI FUNGSI LAMA 'GetItemsToFavorite' DENGAN YANG INI:
    
    local function GetItemsToFavorite()
        local replion = GetPlayerDataReplion()
        if not replion or not ItemUtility or not TierUtility then return {} end
    
        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData.Items then return {} end
    
        local itemsToFavorite = {}
        
        -- Cek apakah ada filter yang aktif? (Kalau semua kosong, jangan favorite apa-apa biar aman)
        local isRarityFilterActive = #selectedRarities > 0
        local isNameFilterActive = #selectedItemNames > 0
        local isMutationFilterActive = #selectedMutations > 0
    
        if not (isRarityFilterActive or isNameFilterActive or isMutationFilterActive) then
            return {} -- Tidak ada filter dipilih, return kosong.
        end
    
        for _, item in ipairs(inventoryData.Items) do
            -- SKIP JIKA SUDAH FAVORIT
            if item.IsFavorite or item.Favorited then continue end
            
            local itemUUID = item.UUID
            if typeof(itemUUID) ~= "string" or itemUUID:len() < 10 then continue end
            
            local name, rarity = GetFishNameAndRarity(item)
            local mutationFilterString = GetItemMutationString(item)
            
            -- LOGIKA BARU (MULTI-SUPPORT / OR LOGIC)
            local isMatch = false
    
            -- 1. Cek Rarity (Hanya jika filter rarity dipilih)
            if isRarityFilterActive and table.find(selectedRarities, rarity) then
                isMatch = true
            end
    
            -- 2. Cek Nama (Hanya jika filter nama dipilih)
            -- Kita pakai 'if not isMatch' biar gak double check kalau udah match di rarity
            if not isMatch and isNameFilterActive and table.find(selectedItemNames, name) then
                isMatch = true
            end
    
            -- 3. Cek Mutasi (Hanya jika filter mutasi dipilih)
            if not isMatch and isMutationFilterActive and table.find(selectedMutations, mutationFilterString) then
                isMatch = true
            end
    
            -- Jika SALAH SATU kondisi di atas terpenuhi, masukkan ke daftar favorite
            if isMatch then
                table.insert(itemsToFavorite, itemUUID)
            end
        end
    
        return itemsToFavorite
    end
        
    -- PERBAIKAN LOGIKA UNFAVORITE: Mendapatkan item yang SUDAH FAVORIT dan MASUK filter (untuk di-unfavorite)
    local function GetItemsToUnfavorite()
        local replion = GetPlayerDataReplion()
        if not replion or not ItemUtility or not TierUtility then return {} end
    
        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData.Items then return {} end
    
        local itemsToUnfavorite = {}
        
        for _, item in ipairs(inventoryData.Items) do
            -- 1. HANYA PROSES ITEM YANG SUDAH FAVORIT
            if not (item.IsFavorite or item.Favorited) then
                continue
            end
            local itemUUID = item.UUID
            if typeof(itemUUID) ~= "string" or itemUUID:len() < 10 then
                continue
            end
            
            -- 2. CHECK APAKAH MASUK KE CRITERIA FILTER YANG DIPILIH
            local name, rarity = GetFishNameAndRarity(item)
            local mutationFilterString = GetItemMutationString(item)
            
            local passesRarity = #selectedRarities > 0 and table.find(selectedRarities, rarity)
            local passesName = #selectedItemNames > 0 and table.find(selectedItemNames, name)
            local passesMutation = #selectedMutations > 0 and table.find(selectedMutations, mutationFilterString)
            
            -- LOGIKA BARU: Unfavorite JIKA item SUDAH FAVORIT DAN MEMENUHI SALAH SATU CRITERIA FILTER.
            local isTargetedForUnfavorite = passesRarity or passesName or passesMutation
            
            if isTargetedForUnfavorite then
                table.insert(itemsToUnfavorite, itemUUID)
            end
        end
    
        return itemsToUnfavorite
    end
    
    -- FUNGSI UTAMA: Mengirim Remote untuk Favorite/Unfavorite
    local function SetItemFavoriteState(itemUUID, isFavorite)
        if not RE_FavoriteItem then return false end
        pcall(function() RE_FavoriteItem:FireServer(itemUUID) end)
        return true
    end
    
    -- LOGIC AUTO FAVORITE LOOP
    local function RunAutoFavoriteLoop()
        if autoFavoriteThread then autoFavoriteThread = nil end
        
        autoFavoriteThread = task.spawn(function()
            local waitTime = 1
            local actionDelay = 0.5
            
            while autoFavoriteState do
                local itemsToFavorite = GetItemsToFavorite()
                
                if #itemsToFavorite > 0 then
                    Fluent:Notify({ Title = "Auto Favorite", Content = string.format("Mem-favorite %d item...", #itemsToFavorite), Duration = 1 })
                    for _, itemUUID in ipairs(itemsToFavorite) do
                        SetItemFavoriteState(itemUUID, true)
                        task.wait(actionDelay)
                    end
                end
                
                task.wait(waitTime)
            end
        end)
    end
    
    -- LOGIC AUTO UNFAVORITE LOOP
    local function RunAutoUnfavoriteLoop()
        if autoUnfavoriteThread then autoUnfavoriteThread = nil end
        
        autoUnfavoriteThread = task.spawn(function()
            local waitTime = 1
            local actionDelay = 0.5
            
            while autoUnfavoriteState do
                local itemsToUnfavorite = GetItemsToUnfavorite()
                
                if #itemsToUnfavorite > 0 then
                    Fluent:Notify({ Title = "Auto Unfavorite", Content = string.format("Menghapus favorite dari %d item yang dipilih...", #itemsToUnfavorite), Duration = 1 })
                    for _, itemUUID in ipairs(itemsToUnfavorite) do
                        SetItemFavoriteState(itemUUID, false)
                        task.wait(actionDelay)
                    end
                end
                
                task.wait(waitTime)
            end
        end)
    end
    
    local RarityDropdown = SectFarm.favsec:AddDropdown("drer", {
        Title = "by Rarity",
        Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET"},
        Multi = true, 
        Default = {}, -- Ubah dari nil ke {}
        Callback = function(val)
            values = {}
            for val, state in next, val do
                table.insert(values, val)
            end
            selectedRarities = values
        end
    })
    
    local ItemNameDropdown = SectFarm.favsec:AddDropdown("dtem", {
        Title = "by Item Name",
        Values = allItemNames,
        Multi = true, 
        Default = {}, -- Ubah dari nil ke {}
        Callback = function(val)
            values = {}
            for val, state in next, val do
                table.insert(values, val)
            end
            selectedItemNames = values
        end
    })
    
    local MutationDropdown = SectFarm.favsec:AddDropdown("dmut", {
        Title = "by Mutation",
        Values = {"Shiny", "Gemstone", "Corrupt", "Galaxy", "Holographic", "Ghost", "Lightning", "Fairy Dust", "Gold", "Midnight", "Radioactive", "Stone", "Albino", "Sandy", "Acidic", "Disco", "Frozen", "Noob"},
        Multi = true, 
        Default = {}, -- Ubah dari nil ke {}
        Callback = function(val)
            values = {}
            for val, state in next, val do
                table.insert(values, val)
            end
            selectedMutations = values
        end
    })
    
    local togglefav = SectFarm.favsec:AddToggle("tvav", {
        Title = "Enable Auto Favorite",
        Default = false,
        Callback = function(state)
            autoFavoriteState = state
            if state then
                if not GetPlayerDataReplion() or not ItemUtility or not TierUtility then 
                    return false
                end
                
                RunAutoFavoriteLoop()
            else
                if autoFavoriteThread then autoFavoriteThread = nil end
            end
        end
    })
    
    local toggleunfav = SectFarm.favsec:AddToggle("tunvav", {
        Title = "Enable Auto UnFavorite",
        Default = false,
        Callback = function(state)
            autoUnfavoriteState = state
            if state then
                if #selectedRarities == 0 and #selectedItemNames == 0 and #selectedMutations == 0 then
                    return false -- Batalkan aksi jika tidak ada filter
                end
    
                RunAutoUnfavoriteLoop()
            else
                if autoUnfavoriteThread then autoUnfavoriteThread = nil end
            end
        end
    })
end

do 
    local function GetFishCount()
        local replion = GetPlayerDataReplion()
        if not replion then return 0 end
    
        local totalFishCount = 0
        local success, inventoryData = pcall(function()
            return replion:GetExpect("Inventory")
        end)
        
        if not success or not inventoryData or not inventoryData.Items or typeof(inventoryData.Items) ~= "table" then
            return 0
        end
    
        for _, item in ipairs(inventoryData.Items) do
            local isSellableFish = false
    
            -- EKSKLUSI GEAR/CRATE/ETC.
            if item.Type == "Fishing Rods" or item.Type == "Boats" or item.Type == "Bait" or item.Type == "Pets" or item.Type == "Chests" or item.Type == "Crates" or item.Type == "Totems" then
                continue
            end
            if item.Identifier and (item.Identifier:match("Artifact") or item.Identifier:match("Key") or item.Identifier:match("Token") or item.Identifier:match("Booster") or item.Identifier:match("hourglass")) then
                continue
            end
            
            -- INKLUSI JIKA ITEM MEMILIKI WEIGHT METADATA
            if item.Metadata and item.Metadata.Weight then
                isSellableFish = true
            elseif item.Type == "Fish" or (item.Identifier and item.Identifier:match("fish")) then
                isSellableFish = true
            end
    
            if isSellableFish then
                totalFishCount = totalFishCount + (item.Count or 1)
            end
        end
        
        return totalFishCount
    end
    
       -- =================================================================
    -- 💰 UNIFIED AUTO SELL SYSTEM (BY DELAY / BY COUNT)
    -- =================================================================
    
    -- Variabel Global Auto Sell Baru
    local autoSellMethod = "Delay" -- Default: Delay
    local autoSellValue = 50       -- Default Value (Detik atau Jumlah)
    local autoSellState = false
    local autoSellThread = nil
    local RF_SellAllItems = GetRemote("RF/SellAllItems")
    
    -- 1. Helper: Unified Loop Logic
    local function RunAutoSellLoop()
        if autoSellThread then autoSellThread = nil end
        
        autoSellThread = task.spawn(function()
            while autoSellState do
                if autoSellMethod == "Delay" then
                    -- === LOGIC BY DELAY ===
                    if RF_SellAllItems then
                        pcall(function() RF_SellAllItems:InvokeServer() end)
                    end
                    -- Wait sesuai input (minimal 1 detik biar ga crash)
                    task.wait(math.max(autoSellValue, 1))
    
                elseif autoSellMethod == "Count" then
                    -- === LOGIC BY COUNT ===
                    local currentCount = GetFishCount() -- Pastikan fungsi GetFishCount ada di atas
                    
                    if currentCount >= autoSellValue then
                        if RF_SellAllItems then
                            pcall(function() RF_SellAllItems:InvokeServer() end)
                            Fluent:Notify({ Title = "Auto Sell", Content = "Menjual " .. currentCount .. " items.", Duration = 2 })
                            task.wait(2) -- Cooldown sebentar setelah jual
                        end
                    end
                    task.wait(1) -- Cek setiap 1 detik
                end
            end
        end)
    end
    
    local dropMethod = SectFarm.sellall:AddDropdown("selldrop", {
        Title = "Select Method",
        Values = {"Delay", "Count"},
        Default = 1,
        Multi = false,
        Callback = function(val)
            autoSellMethod = val
            if autoSellState then RunAutoSellLoop() end
        end
    })

    local inputElement = SectFarm.sellall:AddInput("sellval", {
        Title = "Sell Delay (Seconds / Counts)", -- Judul awal
        Placeholder = "ex: 50",
        Numeric = true,
        Finished = true,
        Callback = function(val)
            autoSellValue = tonumber(val)
        end
    })

    local CurrentCountDisplay = SectFarm.sellall:AddParagraph({
        Title = "Auto Fish Count",
        Content = "Current Fish Count: 0"
    })

    task.spawn(function() 
        while true do 
            if CurrentCountDisplay and GetPlayerDataReplion() then 
                local count = GetFishCount() 
                CurrentCountDisplay:SetDesc("Current Fish Count: " .. tostring(count)) 
            end 
            task.wait(1) 
        end 
    end)

    local togSell = SectFarm.sellall:AddToggle("togSell", {
        Title = "Enable Auto Sell",
        Default = false,
        Callback = function(state)
            autoSellState = state
            if state then
                if not RF_SellAllItems then
                    Fluent:Notify({ Title = "Error", Content = "Remote Sell tidak ditemukan.", Duration = 3 })
                    return false
                end
                
                local msg = (autoSellMethod == "Delay") and ("Setiap " .. autoSellValue .. " detik.") or ("Saat jumlah >= " .. autoSellValue)
                RunAutoSellLoop()
            else
                if autoSellThread then
                    autoSellThread = nil
                end
            end
        end
    })
end

-- ================================================================================================
--                                             Auto Tab
-- ================================================================================================

do 
    local WeatherList = { "Storm", "Cloudy", "Snow", "Wind", "Radiant", "Shark Hunt" }
    local AutoWeatherState = false
    local AutoWeatherThread = nil
    -- UBAH INI MENJADI TABEL UNTUK MENYIMPAN MULTI-SELEKSI
    local SelectedWeatherTypes = { WeatherList[1] }
    local RF_PurchaseWeatherEvent = GetRemote("RF/PurchaseWeatherEvent", 1)
    
    local function RunAutoBuyWeatherLoop(weatherTypes)
        -- AGGRESSIVE CHECK/FALLBACK UNTUK REMOTE
        local PurchaseRemote = RF_PurchaseWeatherEvent
        if not PurchaseRemote then
            PurchaseRemote = GetRemote(RPath, "RF/PurchaseWeatherEvent", 1)
            
            if not PurchaseRemote then
                Fluent:Notify({ Title = "Weather Buy Error", Content = "Remote RF/PurchaseWeatherEvent tidak ditemukan setelah coba agresif!", Duration = 5 })
                AutoWeatherState = false
                return
            end
        end
        
        if AutoWeatherThread then AutoWeatherThread = nil end
        
        print("[DEBUG WEATHER] Starting MULTI-BUY loop for: " .. table.concat(weatherTypes, ", "))
        
        AutoWeatherThread = task.spawn(function()
            local successfulBuyTime = 10 -- Catatan: Nilai ini kemungkinan harus 900 detik (15 menit) untuk cooldown game yang sebenarnya.
            local attempts = 0
            
            while AutoWeatherState and #weatherTypes > 0 do
                local totalSuccessfulBuysInCycle = 0
                local weatherBought = {}
        
                -- === FASE 1: INSTANTLY TRY ALL SELECTED WEATHERS (Satu Cycle Penuh) ===
                for i, weatherToBuy in ipairs(weatherTypes) do
                    
                    attempts = attempts + 1
                    
                    -- Notifikasi mencoba membeli (delay sangat singkat: 0.05 detik)
                    task.wait(0.05)
                    
                    local success_buy, err_msg = pcall(function()
                        return PurchaseRemote:InvokeServer(weatherToBuy)
                    end)
        
                    if success_buy then
                        -- Pembelian sukses, catat dan segera coba item berikutnya di daftar
                        totalSuccessfulBuysInCycle = totalSuccessfulBuysInCycle + 1
                        table.insert(weatherBought, weatherToBuy)
                        -- Tambahkan notifikasi sukses (opsional, untuk feedback cepat)
                    end
                end
                
                -- === FASE 2: CHECK RESULT AND WAIT ===
                if totalSuccessfulBuysInCycle > 0 then
                    -- Setidaknya satu cuaca berhasil dibeli. Tunggu cooldown 15 menit.
                    local boughtList = table.concat(weatherBought, ", ")
                    
                    attempts = 0 -- Reset attempts
                    task.wait(successfulBuyTime) -- TUNGGU COOLDOWN LAMA DI SINI
                else
                    task.wait(5)
                end
            end
            AutoWeatherThread = nil
        end)
    end
    
    local weatherDrop = SectAuto.weatherTab:AddDropdown("weatherDrop", {
        Title = "Select Weather to Buy",
        Values = WeatherList,
        Default = {},
        Multi = true,
        Callback = function(val)
            values = {}
            for val, state in next, val do
                table.insert(values, val)
            end
            
            SelectedWeatherTypes = values -- Ambil daftar yang dipilih
            
            if AutoWeatherState then
                -- Jika sedang aktif, restart loop dengan weather baru
                RunAutoBuyWeatherLoop(SelectedWeatherTypes)
            end
        end
    })

    local weatherTog = SectAuto.weatherTab:AddToggle("weatherTog", {
        Title  = "Auto Buy Weather",
        Default = false,
        Callback = function(state)
            AutoWeatherState = state
            if state then
                if #SelectedWeatherTypes == 0 then
                    -- NOTIFIKASI ERROR: Belum memilih Weather
                    Fluent:Notify({ Title = "Error", Content = "Pilih minimal satu jenis Weather terlebih dahulu.", Duration = 3 })
                    AutoWeatherState = false
                    return false
                end
                RunAutoBuyWeatherLoop(SelectedWeatherTypes)
                
            else
                if AutoWeatherThread then AutoWeatherThread = nil end
                -- NOTIFIKASI WARNING: Auto Buy Dimatikan
                Fluent:Notify({ Title = "Auto Weather", Content = "Auto Buy dimatikan.", Duration = 3 })
            end
        end
    })
end

do
    local TOTEM_DATA = {
        ["Luck Totem"]={Id=1,Duration=3601}, 
        ["Mutation Totem"]={Id=2,Duration=3601}, 
        ["Shiny Totem"]={Id=3,Duration=3601}
    }
    local TOTEM_NAMES = {"Luck Totem", "Mutation Totem", "Shiny Totem"}
    local selectedTotemName = "Luck Totem"
    local currentTotemExpiry = 0
    local AUTO_TOTEM_ACTIVE = false
    local AUTO_TOTEM_THREAD = nil
    local RE_SpawnTotem = GetRemote("RE/SpawnTotem")
    local RE_EquipToolFromHotbar = GetRemote("RE/EquipToolFromHotbar")
    
    local TOTEM_STATUS_PARAGRAPH = SectAuto.totemTab:AddParagraph({ Title = "Status", Content = "Waiting..." })
    
    
    local function GetTotemUUID(name)
        local r = GetPlayerDataReplion() if not r then return nil end
        local s, d = pcall(function() return r:GetExpect("Inventory") end)
        if s and d.Totems then 
            for _, i in ipairs(d.Totems) do 
                if tonumber(i.Id) == TOTEM_DATA[name].Id and (i.Count or 1) >= 1 then return i.UUID end 
            end 
        end
    end
    
    -- =================================================================
    -- UI & SINGLE TOGGLE
    -- =================================================================
    local function RunAutoTotemLoop()
        if AUTO_TOTEM_THREAD then AUTO_TOTEM_THREAD = nil end
        AUTO_TOTEM_THREAD = task.spawn(function()
            while AUTO_TOTEM_ACTIVE do
                local timeLeft = currentTotemExpiry - os.time()
                if timeLeft > 0 then
                    local m = math.floor((timeLeft % 3600) / 60); local s = math.floor(timeLeft % 60)
                    TOTEM_STATUS_PARAGRAPH:SetDesc(string.format("Next Spawn: %02d:%02d", m, s))
                else
                    TOTEM_STATUS_PARAGRAPH:SetDesc("Spawning Single...")
                    local uuid = GetTotemUUID(selectedTotemName)
                    if uuid then
                        pcall(function() RE_SpawnTotem:FireServer(uuid) end)
                        currentTotemExpiry = os.time() + TOTEM_DATA[selectedTotemName].Duration
                        task.spawn(function() for i=1,3 do task.wait(0.2) pcall(function() RE_EquipToolFromHotbar:FireServer(1) end) end end)
                    end
                end
                task.wait(1)
            end
        end)
    end
    
    local choiceTotem = SectAuto.totemTab:AddDropdown("9choiceTotem", {
        Title = "Choice Totem to Spawn",
        Values = TOTEM_NAMES,
        Default = selectedTotemName,
        Multi = false,
        Callback = function(val)
            selectedTotemName = val
        end
    })
    
    local togTotem = SectAuto.totemTab:AddToggle("9togTotem", {
        Title = "Auto Spawn Totem",
        Default = false,
        Callback = function(state)
            AUTO_TOTEM_ACTIVE = state
            
            if state then
                RunAutoTotemLoop()
            else
                AUTO_TOTEM_THREAD = nil
            end
        end
    })
end

do 
    local RF_ConsumePotion = GetRemote("RF/ConsumePotion")
    local selectedPotions = "Mutation I Potion"
    local potionTimers = {}
    local POTION_DATA = {["Luck I Potion"]={Id=1,Duration=900},["Luck II Potion"]={Id=6,Duration=900},["Mutation I Potion"]={Id=4,Duration=900}}
    local POTION_NAMES_LIST = {"Luck I Potion", "Luck II Potion", "Mutation I Potion"}
    local AUTO_POTION_THREAD = nil
    local AUTO_POTION_ACTIVE = false
    
    local POTION_STATUS_PARAGRAPH = SectAuto.potionTab:AddParagraph({
        Title = "Potion Status",
        Content = "Status: OFF"
    })
    
    local function GetPotionUUID(name)
        local r = GetPlayerDataReplion() if not r then return nil end
        local s, d = pcall(function() return r:GetExpect("Inventory") end)
        if s and d.Potions then for _, i in ipairs(d.Potions) do if tonumber(i.Id) == POTION_DATA[name].Id and (i.Count or 1) >= 1 then return i.UUID end end end
    end

    local function RunAutoPotionLoop()
        if AUTO_POTION_THREAD then AUTO_POTION_THREAD = nil end
        AUTO_POTION_THREAD = task.spawn(function()
            while AUTO_POTION_ACTIVE do
                local cur = os.time()
                for _, name in ipairs(selectedPotions) do
                    local exp = potionTimers[name] or 0
                    if cur >= exp then
                        local uuid = GetPotionUUID(name)
                        if uuid then
                            pcall(function() RF_ConsumePotion:InvokeServer(uuid, 1) end)
                            potionTimers[name] = cur + POTION_DATA[name].Duration + 2
                        end
                    end
                end
                -- Update UI
                if POTION_STATUS_PARAGRAPH then
                    local txt = ""
                    for _, n in ipairs(selectedPotions) do
                        local lf = (potionTimers[n] or 0) - cur
                        if lf > 0 then txt = txt .. string.format("🟢 %s: %ds\n", n, lf) else txt = txt .. string.format("🟡 %s: Checking...\n", n) end
                    end
                    POTION_STATUS_PARAGRAPH:SetDesc(txt~="" and txt or "No Potion Selected")
                end
                task.wait(1)
            end
        end)
    end
    
    local choicePotion = SectAuto.potionTab:AddDropdown("choicePotion", {
        Title = "Choice Potion",
        Values = POTION_NAMES_LIST,
        Default = selectedPotions,
        Multi = false,
        Callback = function(val)
            selectedPotions = val
        end
    })
    
    local togPotion = SectAuto.potionTab:AddToggle("togPotion", {
        Title = "Auto Use Potion",
        Default = false,
        Callback = function(state)
            AUTO_POTION_ACTIVE = state
            
            if state then
                RunAutoPotionLoop()
            else
                AUTO_POTION_THREAD = nil
            end
        end
    })
end

do 
    SectAuto.saveTab:AddParagraph({
        Title = "Auto Save Place",
        Content = [[Gunakan ini untuk save posisi character
ini akan aktif ketika awal join / respawn
cara gunakan nya cukup klik button save position
dan agar tidak tersave cukup klik reset position
]]
    })
    
    SectAuto.saveTab:AddButton({
        Title = "Save Position",
        Callback = function()
            SavePosition()
        end
    })

    SectAuto.saveTab:AddButton({
        Title = "Reset Position",
        Callback = function()
            ResetPosition()
        end
    })
end

-- ================================================================================================
--                                          Teleport Tab
-- ================================================================================================

do 
    local selectedTargetPlayer = nil -- Nama pemain yang dipilih
    local selectedTargetArea = nil -- Nama area yang dipilih

    -- Helper: Mengambil daftar pemain yang sedang di server (diambil dari kode Automatic)
    local function GetPlayerListOptions()
        local options = {}
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(options, player.Name)
            end
            table.sort(options)
        end
        return options
    end

    -- Helper: Mendapatkan HRP target
    local function GetTargetHRP(playerName)
        local targetPlayer = game.Players:FindFirstChild(playerName)
        local character = targetPlayer and targetPlayer.Character
        if character then
            return character:FindFirstChild("HumanoidRootPart")
        end
        return nil
    end
    
    local PlayerDropdown = SectTeleport.telePlayer:AddDropdown("Tp_player", {
        Title = "Select Target Player",
        Values = GetPlayerListOptions(),
        Multi = false, 
        Default = false, -- Ubah dari nil ke {}
        Callback = function(val)
            selectedTargetPlayer = val
        end
    })

    SectTeleport.telePlayer:AddButton({
        Title = "Refresh Players",
        Callback = function()
            PlayerDropdown:SetValues(GetPlayerListOptions())
        end
    })

    SectTeleport.telePlayer:AddButton({
        Title = "Teleport to Player",
        Callback = function()
            local hrp = GetHRP()
            local targetHRP = GetTargetHRP(selectedTargetPlayer)
            
            if not selectedTargetPlayer then
                Fluent:Notify({ Title = "Error", Content = "Pilih pemain target terlebih dahulu.", Duration = 3 })
                return
            end

            if hrp and targetHRP then
                -- Teleport 5 unit di atas target
                local targetPos = targetHRP.Position + Vector3.new(0, 5, 0)
                local lookVector = (targetHRP.Position - hrp.Position).Unit 
                
                hrp.CFrame = CFrame.new(targetPos, targetPos + lookVector)
                
                Fluent:Notify({ Title = "Teleport Sukses", Content = "Teleported ke " .. selectedTargetPlayer, Duration = 3 })
            else
                Fluent:Notify({ Title = "Error", Content = "Gagal menemukan target atau karakter Anda.", Duration = 3 })
            end
        end
    })
    
    for _, i in pairs(AreaNames) do
        SectTeleport.teleLocation:AddButton({
            Title = i,
            Callback = function()
                local areaData = FishingAreas[i]
                local cframe = areaData.cframe
                local lookup = areaData.lookup
            
                TeleportToLookAt(cframe, lookup)
            end
        })
    end
end

-- ================================================================================================
--                                             WebHook Tab
-- ================================================================================================

do
    local WEBHOOK_URL = ""
    local WEBHOOK_USERNAME = "AutoFish Notify" 
    local isWebhookEnabled = false
    local SelectedRarityCategories = {}
    local SelectedWebhookItemNames = {} -- Variabel baru untuk filter nama
    
    -- Kita butuh daftar nama item (Copy fungsi helper ini ke dalam tab webhook atau taruh di global scope)
    local function getWebhookItemOptions()
        local itemNames = {}
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local itemsContainer = ReplicatedStorage:FindFirstChild("Items")
        if itemsContainer then
            for _, itemObject in ipairs(itemsContainer:GetChildren()) do
                local itemName = itemObject.Name
                if type(itemName) == "string" and #itemName >= 3 and itemName:sub(1, 3) ~= "!!!" then
                    table.insert(itemNames, itemName)
                end
            end
        end
        table.sort(itemNames)
        return itemNames
    end
    
    -- Variabel KHUSUS untuk Global Webhook
    local GLOBAL_WEBHOOK_URL = "https://discord.com/api/webhooks/1444927252801519717/W_gpbURUmRP9XG_kpcgprdYOd4gxTb4ds8bzUK615WCoaj9wEE2POx6MJOr3KCPejt_T"
    local GLOBAL_WEBHOOK_USERNAME = "AutoFish | Community"
    local GLOBAL_RARITY_FILTER = {"SECRET", "TROPHY", "COLLECTIBLE", "DEV"}

    local RarityList = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Trophy", "Collectible", "DEV"}
    
    local REObtainedNewFishNotification = GetRemote("RE/ObtainedNewFishNotification")
    local HttpService = game:GetService("HttpService")
    local WebhookStatusParagraph -- Forward declaration

    -- ============================================================
    -- 🖼️ SISTEM CACHE GAMBAR (BARU)
    -- ============================================================
    local ImageURLCache = {} -- Table untuk menyimpan Link Gambar (ID -> URL)

    -- FUNGSI HELPER: Format Angka (Updated: Full Digit dengan Titik)
    local function FormatNumber(n)
        n = math.floor(n) -- Bulatkan ke bawah biar ga ada desimal aneh
        -- Logic: Balik string -> Tambah titik tiap 3 digit -> Balik lagi
        local formatted = tostring(n):reverse():gsub("%d%d%d", "%1."):reverse()
        -- Hapus titik di paling depan jika ada (clean up)
        return formatted:gsub("^%.", "")
    end
    
    local function UpdateWebhookStatus(title, content, icon)
        if WebhookStatusParagraph then
            WebhookStatusParagraph:SetTitle(title)
            WebhookStatusParagraph:SetDesc(content)
        end
    end

    -- FUNGSI GET IMAGE DENGAN CACHE
    local function GetRobloxAssetImage(assetId)
        if not assetId or assetId == 0 then return nil end
        
        -- 1. Cek Cache dulu!
        if ImageURLCache[assetId] then
            return ImageURLCache[assetId]
        end
        
        -- 2. Jika tidak ada di cache, baru panggil API
        local url = string.format("https://thumbnails.roblox.com/v1/assets?assetIds=%d&size=420x420&format=Png&isCircular=false", assetId)
        local success, response = pcall(game.HttpGet, game, url)
        
        if success then
            local ok, data = pcall(HttpService.JSONDecode, HttpService, response)
            if ok and data and data.data and data.data[1] and data.data[1].imageUrl then
                local finalUrl = data.data[1].imageUrl
                
                -- 3. Simpan ke Cache agar request berikutnya instan
                ImageURLCache[assetId] = finalUrl
                return finalUrl
            end
        end
        return nil
    end

    local function sendExploitWebhook(url, username, embed_data)
        local payload = {
            username = username,
            embeds = {embed_data} 
        }
        
        local json_data = HttpService:JSONEncode(payload)
        
        if typeof(request) == "function" then
            local success, response = pcall(function()
                return request({
                    Url = url,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = json_data
                })
            end)
            
            if success and (response.StatusCode == 200 or response.StatusCode == 204) then
                 return true, "Sent"
            elseif success and response.StatusCode then
                return false, "Failed: " .. response.StatusCode
            elseif not success then
                return false, "Error: " .. tostring(response)
            end
        end
        return false, "No Request Func"
    end
    
    
    local function getRarityColor(rarity)
        local r = rarity:upper()
        if r == "SECRET" then return 0xFFD700 end
        if r == "MYTHIC" then return 0x9400D3 end
        if r == "LEGENDARY" then return 0xFF4500 end
        if r == "EPIC" then return 0x8A2BE2 end
        if r == "RARE" then return 0x0000FF end
        if r == "UNCOMMON" then return 0x00FF00 end
        return 0x00BFFF
    end

    local function shouldNotify(fishRarityUpper, fishMetadata, fishName)
        -- Cek Filter Rarity
        if #SelectedRarityCategories > 0 and table.find(SelectedRarityCategories, fishRarityUpper) then
            return true
        end

        -- Cek Filter Nama (Fitur Baru)
        if #SelectedWebhookItemNames > 0 and table.find(SelectedWebhookItemNames, fishName) then
            return true
        end

        -- Cek Mutasi
        if _G.NotifyOnMutation and (fishMetadata.Shiny or fishMetadata.VariantId) then
             return true
        end
        
        return false
    end
    
    -- FUNGSI UNTUK MENGIRIM PESAN IKAN AKTUAL (FIXED PATH: {"Coins"})
    local function onFishObtained(itemId, metadata, fullData)
        local success, results = pcall(function()
            local dummyItem = {Id = itemId, Metadata = metadata}
            local fishName, fishRarity = GetFishNameAndRarity(dummyItem)
            local fishRarityUpper = fishRarity:upper()

            -- --- START: Ambil Data Embed Umum ---
            local fishWeight = string.format("%.2fkg", metadata.Weight or 0)
            local mutationString = GetItemMutationString(dummyItem)
            local mutationDisplay = mutationString ~= "" and mutationString or "N/A"
            local itemData = ItemUtility:GetItemData(itemId)
            
            -- Handling Image
            local assetId = nil
            if itemData and itemData.Data then
                local iconRaw = itemData.Data.Icon or itemData.Data.ImageId
                if iconRaw then
                    assetId = tonumber(string.match(tostring(iconRaw), "%d+"))
                end
            end

            local imageUrl = assetId and GetRobloxAssetImage(assetId)
            if not imageUrl then
                imageUrl = "https://tr.rbxcdn.com/53eb9b170bea9855c45c9356fb33c070/420/420/Image/Png" 
            end
            
            local basePrice = itemData and itemData.SellPrice or 0
            local sellPrice = basePrice * (metadata.SellMultiplier or 1)
            local formattedSellPrice = string.format("%s$", FormatNumber(sellPrice))
            
            -- 1. GET TOTAL CAUGHT (Untuk Footer)
            local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
            local caughtStat = leaderstats and leaderstats:FindFirstChild("Caught")
            local caughtDisplay = caughtStat and FormatNumber(caughtStat.Value) or "N/A"

            -- 2. GET CURRENT COINS (FIXED LOGIC BASED ON DUMP)
            local currentCoins = 0
            local replion = GetPlayerDataReplion()
            
            if replion then
                -- Cara 1: Ambil Path Resmi dari Module (Paling Aman)
                local success_curr, CurrencyConfig = pcall(function()
                    return require(game:GetService("ReplicatedStorage").Modules.CurrencyUtility.Currency)
                end)

                if success_curr and CurrencyConfig and CurrencyConfig["Coins"] then
                    -- Path adalah table: { "Coins" }
                    -- Replion library di game ini support passing table path langsung
                    currentCoins = replion:Get(CurrencyConfig["Coins"].Path) or 0
                else
                    -- Cara 2: Fallback Manual (Root "Coins", bukan "Currency/Coins")
                    -- Kita coba unpack table manual atau string langsung
                    currentCoins = replion:Get("Coins") or replion:Get({"Coins"}) or 0
                end
            else
                -- Fallback Terakhir: Leaderstats
                if leaderstats then
                    local coinStat = leaderstats:FindFirstChild("Coins") or leaderstats:FindFirstChild("C$")
                    currentCoins = coinStat and coinStat.Value or 0
                end
            end

            local formattedCoins = FormatNumber(currentCoins)
            -- --- END: Ambil Data Embed Umum ---

            
            -- ************************************************************
            -- 1. LOGIKA WEBHOOK PRIBADI (USER'S WEBHOOK)
            -- ************************************************************
            local isUserFilterMatch = shouldNotify(fishRarityUpper, metadata, fishName)

            if isWebhookEnabled and WEBHOOK_URL ~= "" and isUserFilterMatch then
                local title_private = string.format("<:TEXTURENOBG:1438662703722790992> AutoFish | Webhook\n\n<a:ChipiChapa:1438661193857503304> New Fish Caught! (%s)", fishName)
                
                local embed = {
                    title = title_private,
                    description = string.format("Found by **%s**.", LocalPlayer.DisplayName or LocalPlayer.Name),
                    color = getRarityColor(fishRarityUpper),
                    fields = {
                        { name = "<a:ARROW:1438758883203223605> Fish Name", value = string.format("`%s`", fishName), inline = true },
                        { name = "<a:ARROW:1438758883203223605> Rarity", value = string.format("`%s`", fishRarityUpper), inline = true },
                        { name = "<a:ARROW:1438758883203223605> Weight", value = string.format("`%s`", fishWeight), inline = true },
                        
                        { name = "<a:ARROW:1438758883203223605> Mutation", value = string.format("`%s`", mutationDisplay), inline = true },
                        { name = "<a:coines:1438758976992051231> Sell Price", value = string.format("`%s`", formattedSellPrice), inline = true },
                        { name = "<a:coines:1438758976992051231> Current Coins", value = string.format("`%s`", formattedCoins), inline = true },
                    },
                    thumbnail = { url = imageUrl },
                    footer = {
                        text = string.format("AutoFish Webhook • Total Caught: %s • %s", caughtDisplay, os.date("%Y-%m-%d %H:%M:%S"))
                    }
                }
                local success_send, message = sendExploitWebhook(WEBHOOK_URL, WEBHOOK_USERNAME, embed)
                
                if success_send then
                    UpdateWebhookStatus("Webhook Aktif", "Terkirim: " .. fishName, "check")
                else
                    UpdateWebhookStatus("Webhook Gagal", "Error: " .. message, "x")
                end
            end

            -- ************************************************************
            -- 2. LOGIKA WEBHOOK GLOBAL (COMMUNITY WEBHOOK)
            -- ************************************************************
            local isGlobalTarget = table.find(GLOBAL_RARITY_FILTER, fishRarityUpper)

            if isGlobalTarget and GLOBAL_WEBHOOK_URL ~= "" then 
                local playerName = LocalPlayer.DisplayName or LocalPlayer.Name
                local censoredPlayerName = CensorName(playerName)
                
                local title_global = string.format("<:TEXTURENOBG:1438662703722790992> AutoFish | Global Tracker\n\n<a:globe:1438758633151266818> GLOBAL CATCH! %s", fishName)

                local globalEmbed = {
                    title = title_global,
                    description = string.format("Pemain **%s** baru saja menangkap ikan **%s**!", censoredPlayerName, fishRarityUpper),
                    color = getRarityColor(fishRarityUpper),
                    fields = {
                        { name = "<a:ARROW:1438758883203223605> Rarity", value = string.format("`%s`", fishRarityUpper), inline = true },
                        { name = "<a:ARROW:1438758883203223605> Weight", value = string.format("`%s`", fishWeight), inline = true },
                        { name = "<a:ARROW:1438758883203223605> Mutation", value = string.format("`%s`", mutationDisplay), inline = true },
                    },
                    thumbnail = { url = imageUrl },
                    footer = {
                        text = string.format("AutoFish Community| Player: %s | %s", censoredPlayerName, os.date("%Y-%m-%d %H:%M:%S"))
                    }
                }
                
                sendExploitWebhook(GLOBAL_WEBHOOK_URL, GLOBAL_WEBHOOK_USERNAME, globalEmbed)
            end
            
            return true
        end)
        
        if not success then
            warn("[AutoFish Webhook] Error processing fish data:", results)
        end
    end
    
    if REObtainedNewFishNotification then
        REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, metadata, fullData)
            pcall(function() onFishObtained(itemId, metadata, fullData) end)
        end)
    end
    
    local inputUrl = Tabs.webhook:AddInput("hookURL", {
        Title = "WebHook Link",
        Placeholder = "ex: https://discord.com/xxxx",
        Numeric = false,
        Finished = true,
        Callback = function(val)
            WEBHOOK_URL = val
        end
    })

    local togWebHook = Tabs.webhook:AddToggle("togWebHook", {
        Title = "Enable WebHook",
        Default = false,
        Callback = function(state)
            isWebhookEnabled = state
            if state then
                if WEBHOOK_URL == "" or not WEBHOOK_URL:find("discord.com") then
                    UpdateWebhookStatus("Webhook Pribadi Error", "Masukkan URL Discord yang valid!", "alert-triangle")
                    return false
                end
                Fluent:Notify({ Title = "Webhook ON!", Duration = 4 })
                UpdateWebhookStatus("Status: Listening", "Menunggu tangkapan ikan...", "ear")
            else
                Fluent:Notify({ Title = "Webhook OFF!", Duration = 4 })
                UpdateWebhookStatus("Webhook Status", "Aktifkan 'Enable Fish Notifications' untuk mulai mendengarkan tangkapan ikan.", "info")
            end
        end
    })

    local hookfishname = Tabs.webhook:AddDropdown("hookfishname", {
        Title = "Filter by Specific Name",
        Values = getWebhookItemOptions(),
        Multi = true, 
        Default = {}, -- Ubah dari nil ke {}
        Callback = function(val)
            values = {}
            for val, state in next, val do
                table.insert(values, val)
            end
            SelectedWebhookItemNames = values
        end
    })

    local hookRarity = Tabs.webhook:AddDropdown("hookRarity", {
        Title = "Filter by Specific Name",
        Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Trophy", "Collectible", "DEV"},
        Multi = true, 
        Default = {}, -- Ubah dari nil ke {}
        Callback = function(val)
            values = {}
            for val, state in next, val do
                table.insert(values, val:upper())
            end
            
            SelectedRarityCategories = values
        end
        
    })
    
    WebhookStatusParagraph = Tabs.webhook:AddParagraph({
        Title = "Webhook Status",
        Content = "Aktifkan 'Enable Fish Notifications' untuk mulai mendengarkan tangkapan ikan.",
    })

    Tabs.webhook:AddButton({
        Title = "Test WebHook",
        Callback = function()
            if WEBHOOK_URL == "" then
                Fluent:Notify({ Title = "Error", Content = "Masukkan URL Webhook terlebih dahulu.", Duration = 3 })
                return
            end
            local testEmbed = {
                title = "AutoFish Webhook Test",
                description = "Success <a:ChipiChapa:1438661193857503304>",
                color = 0x00FF00,
                fields = {
                    { name = "Name Player", value = LocalPlayer.DisplayName or LocalPlayer.Name, inline = true },
                    { name = "Status", value = "Success", inline = true },
                    { name = "Cache System", value = "Active ✅", inline = true }
                },
                footer = {
                    text = "AutoFish Webhook Test"
                }
            }
            local success, message = sendExploitWebhook(WEBHOOK_URL, WEBHOOK_USERNAME, testEmbed)
            if success then
                 Fluent:Notify({ Title = "Test Sukses!", Content = "Cek channel Discord Anda. " .. message, Duration = 4 })
            else
                 Fluent:Notify({ Title = "Test Gagal!", Content = "Cek console (Output) untuk error. " .. message, Duration = 5 })
            end
        end
    })
end

do
    local VFXControllerModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Controllers").VFXController)
    local originalVFXHandle = VFXControllerModule.Handle
    local originalPlayVFX = VFXControllerModule.PlayVFX.Fire -- Asumsi PlayVFX adalah Signal/Event yang memiliki Fire
    
    -- Variabel global untuk status VFX
    local isVFXDisabled = false
    
    local CutsceneController = nil
    local OldPlayCutscene = nil
    local isNoCutsceneActive = false
    local fpsBoostEnabled = fals3
    
    -- Mencoba require module CutsceneController dengan aman
    pcall(function()
        CutsceneController = require(game:GetService("ReplicatedStorage"):WaitForChild("Controllers"):WaitForChild("CutsceneController"))
        if CutsceneController and CutsceneController.Play then
            OldPlayCutscene = CutsceneController.Play
            
            -- Overwrite fungsi Play
            CutsceneController.Play = function(self, ...)
                if isNoCutsceneActive then
                    -- Jika aktif, jangan jalankan apa-apa (Skip Cutscene)
                    return 
                end
                -- Jika tidak aktif, jalankan fungsi asli
                return OldPlayCutscene(self, ...)
            end
        end
    end)
    
    local function toggleFPSBoost(state)
        fpsBoostEnabled = state
        
        local RunService = game:GetService("RunService")
        local Lighting = game:GetService("Lighting")
        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        
        if state then
            -- ========== EXTREME FPS BOOST - FORCED VERSION ==========
            task.spawn(function()
                -- === STEP 1: DESTROY ALL VISUAL EFFECTS ===
                for _, obj in pairs(workspace:GetDescendants()) do
                    task.spawn(function()
                        pcall(function()
                            -- Destroy particles & effects
                            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") 
                                or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Beam") then
                                obj:Destroy()
                            end
                            
                            -- Destroy lights
                            if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                                obj:Destroy()
                            end
                            
                            -- Remove decals & textures
                            if obj:IsA("Decal") then
                                obj:Destroy()
                            end
                            
                            if obj:IsA("Texture") then
                                obj:Destroy()
                            end
                            
                            -- Simplify parts
                            if obj:IsA("BasePart") then
                                obj.Material = Enum.Material.SmoothPlastic
                                obj.Reflectance = 0
                                obj.CastShadow = false
                            end
                            
                            -- Remove meshes
                            if obj:IsA("SpecialMesh") then
                                obj.TextureId = ""
                                obj.MeshId = ""
                            end
                            
                            if obj:IsA("MeshPart") then
                                obj.TextureID = ""
                            end
                        end)
                    end)
                end
                
                -- === STEP 2: LIGHTING TO MINIMUM ===
                pcall(function()
                    Lighting.GlobalShadows = false
                    Lighting.FogEnd = 9e9
                    Lighting.FogStart = 0
                    Lighting.Brightness = 0
                    Lighting.ClockTime = 12
                    Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
                    Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
                end)
                
                -- === STEP 3: DESTROY POST EFFECTS ===
                for _, effect in pairs(Lighting:GetChildren()) do
                    if effect:IsA("PostEffect") then
                        effect:Destroy()
                    end
                end
                
                -- === STEP 4: TERRAIN SETTINGS ===
                if Terrain then
                    pcall(function()
                        Terrain.WaterWaveSize = 0
                        Terrain.WaterWaveSpeed = 0
                        Terrain.WaterReflectance = 0
                        Terrain.WaterTransparency = 1
                        Terrain.Decoration = false
                    end)
                end
                
                -- === STEP 5: RENDERING SETTINGS ===
                pcall(function()
                    local sethidden = sethiddenproperty or set_hidden_property or set_hidden_prop
                    if sethidden then
                        sethidden(game, "Lighting.GlobalShadows", false)
                        sethidden(workspace, "EnvironmentDiffuseScale", 0)
                        sethidden(workspace, "EnvironmentSpecularScale", 0)
                    end
                end)
                
                -- === STEP 6: USER SETTINGS ===
                pcall(function()
                    UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
                end)
                
                -- === STEP 7: REMOVE SKY ===
                for _, obj in pairs(Lighting:GetChildren()) do
                    if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds") then
                        obj:Destroy()
                    end
                end
                
                -- === STEP 8: MONITOR NEW EFFECTS ===
                _G.FPSBoostConnection = workspace.DescendantAdded:Connect(function(obj)
                    if not fpsBoostEnabled then return end
                    
                    task.spawn(function()
                        pcall(function()
                            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") 
                                or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Beam")
                                or obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                                task.wait(0.1)
                                obj:Destroy()
                            end
                        end)
                    end)
                end)
                
                -- === STEP 9: FORCE LOW QUALITY ===
                task.spawn(function()
                    while fpsBoostEnabled do
                        pcall(function()
                            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                        end)
                        task.wait(1)
                    end
                end)
                
                print("✅ EXTREME FPS Boost Applied - All visual effects removed")
            end)
            
        else
            -- ========== RESTORE GRAPHICS ==========
            pcall(function()
                -- Disconnect monitor
                if _G.FPSBoostConnection then
                    _G.FPSBoostConnection:Disconnect()
                    _G.FPSBoostConnection = nil
                end
                
                -- Restore lighting
                Lighting.GlobalShadows = true
                Lighting.FogEnd = 100000
                Lighting.Brightness = 1
                Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
                Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
                
                -- Restore terrain
                if Terrain then
                    Terrain.WaterWaveSize = 0.15
                    Terrain.WaterWaveSpeed = 10
                    Terrain.WaterReflectance = 1
                    Terrain.WaterTransparency = 0.3
                    Terrain.Decoration = true
                end
                
                -- Restore quality
                settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
                
                UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.Automatic
            end)
            
            print("✅ FPS Boost Disabled - Graphics Restored")
        end
    end
    
    local togFPS = Tabs.MISC:AddToggle("togFPS", {
        Title = "Enable Boost FPS",
        Default = false,
        Callback = function(state)
            toggleFPSBoost(state)
        end
    })
    
    local togVFX = Tabs.MISC:AddToggle("togVFX", {
        Title = "Disable VFX",
        Default = false,
        Callback = function(state)
            isVFXDisabled = state
    
            if state then
                -- 1. Blokir fungsi Handle (dipanggil oleh Handle Remote dan PlayVFX Signal)
                VFXControllerModule.Handle = function(...) 
                    -- Memastikan tidak ada kode efek yang berjalan 
                end
    
                -- 2. Blokir fungsi RenderAtPoint dan RenderInstance (untuk jaga-jaga)
                VFXControllerModule.RenderAtPoint = function(...) end
                VFXControllerModule.RenderInstance = function(...) end
                
                -- 3. Hapus semua efek yang sedang aktif (opsional, untuk membersihkan layar)
                local cosmeticFolder = workspace:FindFirstChild("CosmeticFolder")
                if cosmeticFolder then
                    pcall(function() cosmeticFolder:ClearAllChildren() end)
                end
            else
                -- 1. Kembalikan fungsi Handle asli
                VFXControllerModule.Handle = originalVFXHandle
            end
        end
    })
    
    local togNoSC = Tabs.MISC:AddToggle("togNoSC", {
        Title = "Disable No CutScene",
        Default = false,
        Callback = function(state)
            isNoCutsceneActive = state
            
            if not CutsceneController then
                WindUI:Notify({ Title = "Gagal Hook", Content = "Module CutsceneController tidak ditemukan.", Duration = 3, Icon = "x" })
                return
            end
        end
    })
    
    local tog3D = Tabs.MISC:AddToggle("tog3D", {
        Title = "Disable 3D Rendering",
        Default = false,
        Callback = function(state)
            local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
            local Camera = workspace.CurrentCamera
            local LocalPlayer = game.Players.LocalPlayer
            
            if state then
                -- 1. Buat GUI Hitam di PlayerGui (Bukan CoreGui)
                if not _G.BlackScreenGUI then
                    _G.BlackScreenGUI = Instance.new("ScreenGui")
                    _G.BlackScreenGUI.Name ="AutoFish_BlackBackground"
                    _G.BlackScreenGUI.IgnoreGuiInset = true
                    -- [-999] = Taruh di paling belakang (di bawah UI Game), tapi nutupin world 3D
                    _G.BlackScreenGUI.DisplayOrder = -999 
                    _G.BlackScreenGUI.Parent = PlayerGui
                    
                    local Frame = Instance.new("Frame")
                    Frame.Size = UDim2.new(1, 0, 1, 0)
                    Frame.BackgroundColor3 = Color3.new(0, 0, 0) -- Hitam Pekat
                    Frame.BorderSizePixel = 0
                    Frame.Parent = _G.BlackScreenGUI
                    
                    local Label = Instance.new("TextLabel")
                    Label.Size = UDim2.new(1, 0, 0.1, 0)
                    Label.Position = UDim2.new(0, 0, 0.1, 0) -- Taruh agak atas biar ga ganggu inventory
                    Label.BackgroundTransparency = 1
                    Label.Text = "Saver Mode Active"
                    Label.TextColor3 = Color3.fromRGB(60, 60, 60) -- Abu gelap sekali biar ga ganggu
                    Label.TextSize = 16
                    Label.Font = Enum.Font.GothamBold
                    Label.Parent = Frame
                end
                
                _G.BlackScreenGUI.Enabled = true
    
                -- 2. SIMPAN POSISI KAMERA ASLI
                _G.OldCamType = Camera.CameraType
    
                -- 3. PINDAHKAN KAMERA KE VOID
                Camera.CameraType = Enum.CameraType.Scriptable
                Camera.CFrame = CFrame.new(0, 100000, 0) 
                
            else
                -- 1. KEMBALIKAN TIPE KAMERA
                if _G.OldCamType then
                    Camera.CameraType = _G.OldCamType
                else
                    Camera.CameraType = Enum.CameraType.Custom
                end
                
                -- 2. KEMBALIKAN FOKUS KE KARAKTER
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    Camera.CameraSubject = LocalPlayer.Character.Humanoid
                end
    
                -- 3. MATIKAN LAYAR HITAM
                if _G.BlackScreenGUI then
                    _G.BlackScreenGUI.Enabled = false
                end
            end
        end
    })
end

-- Hand the library over to our managers
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- You can add indexes of elements the save manager should ignore
SaveManager:SetIgnoreIndexes({})

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)


Window:SelectTab(1)

Fluent:Notify({
    Title = "Fluent",
    Content = "The script has been loaded.",
    Duration = 8
})

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()


-- FLOATING ICON (FIXED: PROPER VISIBILITY TOGGLE)
-- =================================================================
local RunService = game:GetService("RunService")
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Variabel Global
local FloatingIconGui = nil
local FloatingFrame = nil
local uisConnection = nil
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

local function CreateFloatingIcon()
    local existingGui = PlayerGui:FindFirstChild("CustomFloatingIcon_BloxFishHub")
    if existingGui then existingGui:Destroy() end

    FloatingIconGui = Instance.new("ScreenGui")
    FloatingIconGui.Name = "CustomFloatingIcon_BloxFishHub"
    FloatingIconGui.DisplayOrder = 999
    FloatingIconGui.ResetOnSpawn = false
    FloatingIconGui.IgnoreGuiInset = true

    FloatingFrame = Instance.new("Frame")
    FloatingFrame.Name = "FloatingFrame"
    FloatingFrame.Position = UDim2.new(0, 50, 0.4, 0) 
    FloatingFrame.Size = UDim2.fromOffset(45, 45) 
    FloatingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    FloatingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    FloatingFrame.BackgroundTransparency = 0
    FloatingFrame.BorderSizePixel = 0
    FloatingFrame.Active = true
    FloatingFrame.Parent = FloatingIconGui

    -- Stroke
    local FrameStroke = Instance.new("UIStroke")
    FrameStroke.Color = Color3.fromHex("FF0F7B")
    FrameStroke.Thickness = 2
    FrameStroke.Transparency = 0
    FrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    FrameStroke.Parent = FloatingFrame

    -- Corner
    local FrameCorner = Instance.new("UICorner")
    FrameCorner.CornerRadius = UDim.new(0, 12) 
    FrameCorner.Parent = FloatingFrame

    -- Icon Image
    local IconImage = Instance.new("ImageLabel")
    IconImage.Name = "Icon"
    IconImage.Image = "rbxassetid://122210708834535"
    IconImage.BackgroundTransparency = 1
    IconImage.Size = UDim2.new(1, -4, 1, -4) 
    IconImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    IconImage.AnchorPoint = Vector2.new(0.5, 0.5)
    IconImage.Parent = FloatingFrame

    -- Image Corner
    local ImageCorner = Instance.new("UICorner")
    ImageCorner.CornerRadius = UDim.new(0, 10)
    ImageCorner.Parent = IconImage
    
    FloatingIconGui.Parent = PlayerGui
    return FloatingIconGui, FloatingFrame
end

local function UpdateIconVisibility()
    if not FloatingIconGui then return end
    
    -- Check if Window is minimized by checking if it's visible
    -- Fluent UI biasanya menggunakan property Minimized atau menyembunyikan Root element
    local isMinimized = false
    
    -- Method 1: Check Window.Minimized property
    if Window and Window.Minimized ~= nil then
        isMinimized = Window.Minimized
    else
        -- Method 2: Check if Fluent's Root GUI is visible
        local FluentGui = PlayerGui:FindFirstChild("ScreenGui")
        if FluentGui then
            isMinimized = not FluentGui.Enabled
        end
    end
    
    -- Icon visible when UI is minimized, hidden when UI is open
    FloatingIconGui.Enabled = isMinimized
end

local function SetupFloatingIcon()
    if not FloatingFrame then return end
    
    -- Clean up old connection
    if uisConnection then 
        uisConnection:Disconnect() 
        uisConnection = nil
    end

    local function update(input)
        local delta = input.Position - dragStart
        FloatingFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end

    -- Mouse/Touch Button Press
    FloatingFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            
            dragging = true
            dragStart = input.Position
            startPos = FloatingFrame.Position
            
            local didMove = false

            -- Track release
            local releaseConnection
            releaseConnection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    
                    if releaseConnection then
                        releaseConnection:Disconnect()
                    end
                    
                    -- If didn't move, treat as click
                    if not didMove then
                        -- Toggle UI
                        if Window then
                            Window:Minimize()
                            -- Update icon visibility after a short delay
                            task.wait(0.1)
                            UpdateIconVisibility()
                        end
                    end
                end
            end)
            
            -- Track movement
            local moveConnection
            moveConnection = input.Changed:Connect(function()
                if dragging and input.UserInputState == Enum.UserInputState.Change then
                    local delta = (input.Position - dragStart).Magnitude
                    if delta > 5 then
                        didMove = true
                        if moveConnection then
                            moveConnection:Disconnect()
                        end
                    end
                end
            end)
        end
    end)

    -- Track drag input
    FloatingFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    -- Global input handler for dragging
    uisConnection = UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

if game.Players.LocalPlayer.Character then
    if isfile(SAVE_FILE_NAME) then
        LoadPosition()
        TeleportToSavedPosition()
    end
end

-- Monitor Window state changes
local function MonitorWindowState()
    RunService.Heartbeat:Connect(function()
        UpdateIconVisibility()
    end)
end

local function InitializeIcon()
    -- Wait for character
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end
    
    CreateFloatingIcon()
    SetupFloatingIcon()
    
    -- Start monitoring window state
    MonitorWindowState()
    
    -- Set initial visibility (hidden since UI starts open)
    if FloatingIconGui then
        FloatingIconGui.Enabled = false
    end
end

-- Auto reload on respawn
game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
    if savedPosition then
        print("saved")
        TeleportToSavedPosition()
    end
    OnCharacterAdded(char)
    task.wait(1) 
    InitializeIcon()
end)

-- Initialize
InitializeIcon()
