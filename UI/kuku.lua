local DiscordLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/haijuga7/mencobaok/refs/heads/main/UI/libUI.lua"))()

-- Rest of your code
local win = DiscordLib:Window({
    Title = "AutoFish",
    AutoLoad = true,              -- Enable auto-load
    ShowNotification = true       -- Show notification saat load
})

-- Tabs 
local fishingTab = win:Server("Fishing Tab", "rbxassetid://10709761530")
-- local playerTab = win:Server("Player Tab", "rbxassetid://10747372167")
local autoTab = win:Server("Automation Tab", "rbxassetid://10723354521")
local teleTab = win:Server("Teleport Tab", "rbxassetid://10734886004")
local webTab = win:Server("Webhook Tab", "rbxassetid://10723426722")
local servTab = win:Server("Server Tab", "rbxassetid://10734949856")
local setTab = win:Server("Settings Tab", "rbxassetid://10734950309")

-- fishing channel
local fishSupport = fishingTab:Channel("Fishing Support")
local fishMain = fishingTab:Channel("Fishing Feature")
local fishFav = fishingTab:Channel("Auto Fav/UnFav")
local fishSell = fishingTab:Channel("Auto Sell")

-- player Tab
-- local moveTab = playerTab:Channel("Movement")
-- local abilityTab = playerTab:Channel("Ability")
-- local otherTab = playerTab:Channel("Other")

-- auto Tab
local merchantTab = autoTab:Channel("Auto Buy Merchant Items")
local weatherTab = autoTab:Channel("Auto Buy Weather")
local totemTab = autoTab:Channel("Auto Place Totem")
local potionTab = autoTab:Channel("Auto Use Potion")
local saveTab = autoTab:Channel("Auto Save Position")
local polaTab = autoTab:Channel("RNG Tester")
local autoEvent = autoTab:Channel("Auto Event")

-- Teleport Tab
local telePlayer = teleTab:Channel("Teleport To Player")
local teleLocation = teleTab:Channel("Teleport To Location")

-- webhook Tab
local webMain = webTab:Channel("WebHook")

-- server Tab
local servMain = servTab:Channel("Server Main")

-- Setting Tab
local setMISC = setTab:Channel("MISC")
local setConfig = setTab:Channel("Config Manajement")


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

local function get_path()
    local playerUsername = LocalPlayer.Name
    local playerUserId = tostring(LocalPlayer.UserId)
    
    -- Format: DiscordLibConfigs/Username_UserID
    local playerFolder = "DiscordLibConfigs" .. "/" .. playerUsername .. "_" .. playerUserId

    if not isfolder(playerFolder) then
        makefolder(playerFolder)
        print("[Config] ✅ Created auto-load folder:", playerFolder)
    end
    
    return playerFolder
end

local test = get_path()
local next_path = test .. "/" .. SAVE_FILE_NAME

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
    end
end

local function SavePosition(saved)
    local hrp = GetHRP()
    if not hrp then
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
    
    if saved then
        -- Simpan ke file JSON (jika executor support writefile)
        if writefile and readfile then
            writefile(next_path, HttpService:JSONEncode(posData))
        end
    end
end

local function LoadPosition()
    -- Coba load dari file dulu
    if readfile and isfile and isfile(next_path) then
        local success, fileData = pcall(function()
            return readfile(next_path)
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
    
    if writefile and delfile and isfile and isfile(next_path) then
        pcall(function()
            delfile(next_path)
        end)
    end
end

local function TeleportToSavedPosition()
    if not savedPosition then
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

do
    local RE_EquipToolFromHotbar = GetRemote("RE/EquipToolFromHotbar")
    local walkOnWaterConnection = nil
    local isWalkOnWater = false
    local waterPlatform = nil
    local autoERodState = false
    
    -- ✅ FIXED: Animation system variables
    local isNoAnimationActive = false
    local characterAddedConnection = nil
    local animatorRemovedConnection = nil
    
    -- ✅ FIXED: Disable animations function
    local function DisableAnimations()
        local character = LocalPlayer.Character
        if not character then 
            warn("[Animation] No character found")
            return 
        end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then 
            warn("[Animation] No humanoid found")
            return 
        end
        
        print("[Animation] 🚫 Disabling animations...")
        
        -- ✅ STEP 1: Stop all playing animations
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                track:Stop(0)
                track:Destroy()
            end
        end
        
        -- ✅ STEP 2: Disable Animate script
        local animateScript = character:FindFirstChild("Animate")
        if animateScript then
            animateScript.Disabled = true
            print("[Animation] ✅ Animate script disabled")
        end
        
        -- ✅ STEP 3: Destroy Animator (prevents new animations)
        if animator then
            animator:Destroy()
            print("[Animation] ✅ Animator destroyed")
        end
        
        -- ✅ STEP 4: Monitor and prevent new Animator creation
        if animatorRemovedConnection then
            animatorRemovedConnection:Disconnect()
        end
        
        animatorRemovedConnection = humanoid.ChildAdded:Connect(function(child)
            if isNoAnimationActive and child:IsA("Animator") then
                task.wait(0.05)
                child:Destroy()
                print("[Animation] 🚫 Blocked new Animator creation")
            end
        end)
        
        print("[Animation] ✅ Animation system fully disabled")
    end
    
    -- ✅ FIXED: Enable animations function
    local function EnableAnimations()
        local character = LocalPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        print("[Animation] ✅ Enabling animations...")
        
        -- Disconnect monitor
        if animatorRemovedConnection then
            animatorRemovedConnection:Disconnect()
            animatorRemovedConnection = nil
        end
        
        -- Re-enable Animate script
        local animateScript = character:FindFirstChild("Animate")
        if animateScript then
            animateScript.Disabled = false
            print("[Animation] ✅ Animate script enabled")
        end
        
        -- Create new Animator if needed
        if not humanoid:FindFirstChildOfClass("Animator") then
            local newAnimator = Instance.new("Animator")
            newAnimator.Parent = humanoid
            print("[Animation] ✅ Animator created")
        end
        
        print("[Animation] ✅ Animation system fully enabled")
    end
    
    -- ✅ FIXED: Handle character added/respawn
    local function OnCharacterAdded(newCharacter)
        print("[Animation] Character added/respawned")
        
        -- Wait for character to fully load
        if not newCharacter:FindFirstChildOfClass("Humanoid") then
            newCharacter:WaitForChild("Humanoid", 5)
        end
        
        -- Small delay to let default animations load first
        task.wait(0.5)
        
        if isNoAnimationActive then
            print("[Animation] Reapplying disable on new character...")
            DisableAnimations()
        end
    end
    
    
    local Stats = game:GetService("Stats")
    
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
            -- ✅ METHOD 1: From Player (same as your left display)
            -- local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
            
            -- ✅ METHOD 2: Alternative - from Stats.Network (backup)
            local networkStats = Stats.Network
            local ping = math.floor(networkStats.ServerStatsItem["Data Ping"]:GetValue())
            
            -- CPU
            local cpu = math.floor(Stats.PerformanceStats.CPU:GetValue())
            
            -- Update UI
            pingLabel.Text = string.format("Ping : %d ms", ping)
            pingLabel.TextColor3 = GetPingColor(ping)
            
            cpuLabel.Text = string.format("CPU  : %d ms", cpu)
            cpuLabel.TextColor3 = GetCPUColor(cpu)
        end
    end
        
    local function EnableMonitor()
        if MonitorEnabled then return end
        
        MonitorEnabled = true
        MonitorGui = CreateMonitorGui()
        
        -- Update every 0.5 seconds
        MonitorUpdateConnection = task.spawn(function()
            while MonitorEnabled do
                UpdateMonitorValues()
                task.wait(1)
            end
        end)
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
    end
    
    local function OnCharacterAdded(newCharacter)
        if isNoAnimationActive then
            task.wait(0.2) -- Tunggu sebentar agar LoadCharacter selesai
            DisableAnimations()
        end
    end
    
    local togMoni = fishSupport:Toggle("togMoni", {
        Title = "Enabled Monitor",
        Value = false,
        Callback = function(state)
            if state then
                EnableMonitor()
            else
                DisableMonitor()
            end
        end
    })
    -- togMoni:SetValue(true)
    
    local autoERod = fishSupport:Toggle("autoerod", {
        Title = "Auto Equip Rod",
        Value = false,
        Callback = function(b)
            autoERodState = b
            if b then
                task.spawn(function()
                    while autoERodState do
                        pcall(function() RE_EquipToolFromHotbar:FireServer(1) end) task.wait(1)
                    end
                end)
            end
        end
    })
    -- autoERod:SetValue(true)
    
    local walkonwater = fishSupport:Toggle("wlkonwtr", {
        Title = "Walk On Water",
        Value = false,
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
    
    -- ✅ FIXED: Disable Animation Toggle
    local disAnim = fishSupport:Toggle("disAnim", {
        Title = "Disable Animation",
        Value = false,
        Callback = function(state)
            isNoAnimationActive = state
            
            if state then
                print("[Animation] 🔴 Toggle ON - Disabling animations")
                DisableAnimations()
            else
                print("[Animation] 🟢 Toggle OFF - Enabling animations")
                
                -- Disconnect monitor
                if animatorRemovedConnection then
                    animatorRemovedConnection:Disconnect()
                    animatorRemovedConnection = nil
                end
                
                EnableAnimations()
            end
        end
    })
    
    -- ✅ FIXED: Setup character respawn handler
    if characterAddedConnection then
        characterAddedConnection:Disconnect()
    end
    
    characterAddedConnection = LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
    
    -- ✅ Handle current character if exists
    if LocalPlayer.Character then
        OnCharacterAdded(LocalPlayer.Character)
    end
    
    local disNotif = fishSupport:Toggle("disNotif", {
        Title = "Disable Fish Notif",
        Value = false,
        Callback = function(s)
            s = not s
            pcall(function() game:GetService("Players").LocalPlayer.PlayerGui["Small Notification"].Display.Visible = s end)
        end
    })
    -- disNotif:SetValue(true)
    
    local st_height = fishSupport:Textbox("st_height", {
        Title = "Stealth Height",
        Placeholder = "e.g : 110",
        Callback = function(val)
            stealthHight = tonumber(val)
        end
    })
    st_height:SetValue(110)
    
    local stealth = fishSupport:Toggle("stealth", {
        Title = "Stealth Mode",
        Value = false,
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
    -- stealth:SetValue(true)
    
    local accTrade = fishSupport:Toggle("accTrade", {
        Title = "Auto Accept Trade",
        Value = false,
        Callback = function(state)
            _G.BloxFish_AutoAcceptTradeEnabled = state
        end
    })
end

do 
    local RE_EquipToolFromHotbar = GetRemote("RE/EquipToolFromHotbar")
    local RF_ChargeFishingRod    = GetRemote("RF/ChargeFishingRod")
    local RF_RequestFishingMinigameStarted = GetRemote("RF/RequestFishingMinigameStarted")
    local RE_FishingCompleted    = GetRemote("RF/CatchFishCompleted")
    local RF_CancelFishingInputs = GetRemote("RF/CancelFishingInputs")
    local RF_UpdateAutoFishingState = GetRemote("RF/UpdateAutoFishingState")
    
    local InstantState = nil
    local blatantV1State = nil
    
    local insDe = nil
    local insCyc = nil
    local blatv1de = nil
    local blatv1cyc = nil
    
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
        RF_ChargeFishingRod:InvokeServer(nil, nil, nil, 1769972555.6933)
        RF_RequestFishingMinigameStarted:InvokeServer(1, 1, 1769972555.6933)
        task.wait(insDe)
        RE_FishingCompleted:InvokeServer()
    end

    local function blatantFishv1()
        for i = 1, 7 do
            task.wait(0.035)
            task.spawn(function()
                RF_ChargeFishingRod:InvokeServer(nil, nil, nil, 1769972555.6933)
            end)
            task.spawn(function()
                RF_RequestFishingMinigameStarted:InvokeServer(1, 1, 1769972555.6933)
            end)
        end
        task.wait(blatv1de)
        task.spawn(function()
            RE_FishingCompleted:InvokeServer()
        end)
        task.spawn(function()
            RF_CancelFishingInputs:InvokeServer()
        end)
    end

    fishMain:Label('Auto Fishing Manual')
    
    local slidlegit = fishMain:Textbox("klikd", {
        Title = "Legit Click Speed Delay",
        Placeholder = "ex: 0.1",
        Callback = function(val)
            SPEED_LEGIT = tonumber(val)
        end
    })
    
    local toggleLegit = fishMain:Toggle("legit", { -- ✅ DIPERBAIKI
        Title = "Auto Fish (Legit)",
        Value = false,
        Callback = function(state)
            ToggleAutoClick(state)
        end
    })

    fishMain:Seperator()

    fishMain:Label("Instan Fishing")

    local InstantDelay = fishMain:Textbox("instdelay", { -- ✅ DIPERBAIKI
        Title = "Complete Delay",
        Placeholder = "e.g : 1",
        Callback = function(val)
            insDe = tonumber(val)
        end
    })
    
    local toggleInstant = fishMain:Toggle("toginst", { -- ✅ DIPERBAIKI
        Title = "Instant Fish",
        Value = false,
        Callback = function(state)
            InstantState = state
            _G.BloxFish_BlatantActive = state
            pcall(function() RF_UpdateAutoFishingState:InvokeServer(state) end)
            
            if state then
                task.spawn(function()
                    while InstantState do
                        instantOk()
                        task.wait(0.01) 
                    end
                end)
            end
        end
    })

    fishMain:Seperator()

    fishMain:Label("BlatantV1 Fishing")

    local BlatantV1Cast = fishMain:Textbox("blatV1cast", { -- ✅ DIPERBAIKI
        Title = "Cast Delay",
        Placeholder = "ex: 1.97",
        Callback = function(val)
            blatv1cyc = tonumber(val)
        end
    })

    local BlatantV1Delay = fishMain:Textbox("blatV1delay", { -- ✅ DIPERBAIKI
        Title = "Complete Delay",
        Placeholder = "ex: 1",
        Callback = function(val)
            blatv1de = tonumber(val)
        end
    })
    
    local BlatantV1Toggle = fishMain:Toggle("togblatv1", { -- ✅ DIPERBAIKI
        Title = "BlatantV1 Fish",
        Value = false,
        Callback = function(state)
            blatantV1State = state
            _G.BloxFish_BlatantActive = state
            pcall(function() RF_UpdateAutoFishingState:InvokeServer(state) end)
            
            if state then
                for i = 1, 7 do
                    task.wait(0.035)
                    task.spawn(function()
                        RF_ChargeFishingRod:InvokeServer(nil, nil, nil, 1769972555.6933)
                    end)
                    task.spawn(function()
                        RF_RequestFishingMinigameStarted:InvokeServer(1, 1, 1769972555.6933)
                    end)
                end
                task.wait(0.1)
                task.spawn(function()
                    while blatantV1State do
                        task.spawn(blatantFishv1)
                        task.wait(blatv1cyc)
                    end
                end)
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

    local customName = {}
    local customRarity = {}
    local customMutation = {}
    
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
        local isCustomName = #customName > 0
    
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

            if not isMatch and isCustomName and table.find(customName, name) and table.find(customMutation, mutationFilterString) then
                isMatch = true
            end
            
            if not isMatch and isCustomName and table.find(customName, name) and table.find(customRarity, rarity) then
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
                    for _, itemUUID in ipairs(itemsToUnfavorite) do
                        SetItemFavoriteState(itemUUID, false)
                        task.wait(actionDelay)
                    end
                end
                
                task.wait(waitTime)
            end
        end)
    end
    
    local RarityDropdown = fishFav:Dropdown("drer", {
        Title = "by Rarity",
        List = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET"},
        Multi = true, 
        Callback = function(val)
            selectedRarities = val
        end
    })
    
    local ItemNameDropdown = fishFav:Dropdown("dtem", {
        Title = "by Item Name",
        List = allItemNames,
        Multi = true, 
        Callback = function(val)
            selectedItemNames = val
        end
    })
    
    local MutationDropdown = fishFav:Dropdown("dmut", {
        Title = "by Mutation",
        List = {"Shiny", "Gemstone", "Corrupt", "Galaxy", "Holographic", "Ghost", "Lightning", "Fairy Dust", "Gold", "Midnight", "Radioactive", "Stone", "Albino", "Sandy", "Acidic", "Disco", "Frozen", "Noob"},
        Multi = true, 
        Callback = function(val)
            selectedMutations = val
        end
    })
    
    local togglefav = fishFav:Toggle("tvav", {
        Title = "Enable Auto Favorite",
        Value = false,
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
    
    local toggleunfav = fishFav:Button({
        Title = "Enable Auto UnFavorite",
        Callback = function()
            RunAutoUnfavoriteLoop()
        end
    })

    fishFav:Seperator()
    fishFav:Label("Custom Name + Mutation Filter")
    
    fishFav:Dropdown("customRarit", {
        Title = "by Rarity",
        List = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET"},
        Multi = true, 
        Callback = function(val)
            customRarity = val
        end
    })

    fishFav:Dropdown("nameCostum", {
        Title = "Name Fish",
        List = allItemNames,
        Multi = true, 
        Callback = function(val)
            customName = val
        end
    })
    
    fishFav:Dropdown("mutCustom", {
        Title = "Mutation Fish",
        List = {"Shiny", "Gemstone", "Corrupt", "Galaxy", "Holographic", "Ghost", "Lightning", "Fairy Dust", "Gold", "Midnight", "Radioactive", "Stone", "Albino", "Sandy", "Acidic", "Disco", "Frozen", "Noob"},
        Multi = true, 
        Callback = function(val)
            customMutation = val
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

    local inputElement
    
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
                            task.wait(2) -- Cooldown sebentar setelah jual
                        end
                    end
                    task.wait(1) -- Cek setiap 1 detik
                end
            end
        end)
    end
    
    local dropMethod = fishSell:Dropdown("selldrop", {
        Title = "Select Method",
        List = {"Delay", "Count"},
        Multi = false,
        Callback = function(val)
            autoSellMethod = val
            if val == "Delay" then 
                inputElement:SetTitle("Sell Delay (Seconds")
            else
                inputElement:SetTitle("Sell Delay (Counts)")
            end

            if autoSellState then RunAutoSellLoop() end
        end
    })

    inputElement = fishSell:Textbox("sellval", {
        Title = "Sell Delay (Seconds / Counts)", -- Judul awal
        Placeholder = "e.g : 50",
        Callback = function(val)
            autoSellValue = tonumber(val)
        end
    })

    local CurrentCountDisplay = fishSell:Label("Current Fish Count: 0")

    task.spawn(function() 
        while true do 
            if CurrentCountDisplay and GetPlayerDataReplion() then 
                local count = GetFishCount() 
                CurrentCountDisplay:SetTitle("Current Fish Count: " .. tostring(count)) 
            end 
            task.wait(1) 
        end 
    end)

    local togSell = fishSell:Toggle("togSell", {
        Title = "Enable Auto Sell",
        Value = false,
        Callback = function(state)
            autoSellState = state
            if state then
                if not RF_SellAllItems then
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
    fishSell:Button({
        Title = "Sell Now",
        Callback = function()
            pcall(function() RF_SellAllItems:InvokeServer() end)
        end
    })
end

-- ================================================================================================
--                                             Auto Tab
-- ================================================================================================
do
    local RF_PurchaseMarketItem = GetRemote("RF/PurchaseMarketItem")
    
    local luckTotemActive = false
    local mutanTotemActive = false
    
    local buyLuckT = merchantTab:Toggle("buyLuckT", {
        Title = "Buy Luck Totem",
        Value = false,
        Callback = function(state)
            luckTotemActive = state
            
            if state then
                task.spawn(function()
                    while luckTotemActive do
                        pcall(function() 
                            RF_PurchaseMarketItem:InvokeServer(5) 
                        end)
                        task.wait(0.5)
                    end
                end)
            end
        end
    })

    local buyMutanT = merchantTab:Toggle("buyMutanT", {
        Title = "Buy Mutation Totem",
        Value = false,
        Callback = function(state)
            mutanTotemActive = state
            
            if state then
                task.spawn(function()
                    while mutanTotemActive do
                        pcall(function() 
                            RF_PurchaseMarketItem:InvokeServer(8) 
                        end)
                        task.wait(0.5)
                    end
                end)
            end
        end
    })

    merchantTab:Toggle("buyShinyT", {
        Title = "Buy Shiny Totem",
        Value = false,
        Callback = function(state)
            mutanTotemActive = state
            
            if state then
                task.spawn(function()
                    while mutanTotemActive do
                        pcall(function() 
                            RF_PurchaseMarketItem:InvokeServer(7) 
                        end)
                        task.wait(0.5)
                    end
                end)
            end
        end
    })

    merchantTab:Button({
        Title = "Buy Singularity Baits",
        Callback = function()
            pcall(function() RF_PurchaseMarketItem:InvokeServer(3) end)
        end
    })
end
    
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
    
    local weatherDrop = weatherTab:Dropdown("weatherDrop", {
        Title = "Select Weather to Buy",
        List = WeatherList,
        Multi = true,
        Callback = function(val)
            SelectedWeatherTypes = val -- Ambil daftar yang dipilih
            
            if AutoWeatherState then
                -- Jika sedang aktif, restart loop dengan weather baru
                RunAutoBuyWeatherLoop(SelectedWeatherTypes)
            end
        end
    })

    local weatherTog = weatherTab:Toggle("weatherTog", {
        Title  = "Auto Buy Weather",
        Value = false,
        Callback = function(state)
            AutoWeatherState = state
            if state then
                if #SelectedWeatherTypes == 0 then
                    -- NOTIFIKASI ERROR: Belum memilih Weather
                    AutoWeatherState = false
                    return false
                end
                RunAutoBuyWeatherLoop(SelectedWeatherTypes)
                
            else
                if AutoWeatherThread then AutoWeatherThread = nil end
                -- NOTIFIKASI WARNING: Auto Buy Dimatikan
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
    
    local TOTEM_STATUS_PARAGRAPH = totemTab:Paragraph({
        Title = "Status Totem", 
        Desc = "Waiting ...."
    })
    totemTab:Seperator()
    
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
    
    local choiceTotem = totemTab:Dropdown("9choiceTotem", {
        Title = "Choice Totem to Spawn",
        List = TOTEM_NAMES,
        Value = selectedTotemName,
        Multi = false,
        Callback = function(val)
            selectedTotemName = val
        end
    })
    
    local togTotem = totemTab:Toggle("9togTotem", {
        Title = "Auto Spawn Totem",
        Value = false,
        Callback = function(state)
            AUTO_TOTEM_ACTIVE = state
            
            if state then
                RunAutoTotemLoop()
            else
                AUTO_TOTEM_THREAD = nil
                currentTotemExpiry = 0
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
    
    local POTION_STATUS_PARAGRAPH = potionTab:Paragraph({
        Title = "Potion Status",
        Desc = "Status: OFF"
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
    
    local choicePotion = potionTab:Dropdown("choicePotion", {
        Title = "Choice Potion",
        List = POTION_NAMES_LIST,
        Value = selectedPotions,
        Multi = false,
        Callback = function(val)
            selectedPotions = val
        end
    })
    
    local togPotion = potionTab:Toggle("togPotion", {
        Title = "Auto Use Potion",
        Value = false,
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
    saveTab:Paragraph({
        Title = "Auto Save Place",
        Desc = [[Gunakan ini untuk save posisi character
ini akan aktif ketika awal join / respawn
cara gunakan nya cukup klik button save position
dan agar tidak tersave cukup klik reset position
]]
    })
    
    saveTab:Button({
        Title = "Save Position",
        Callback = function()
            SavePosition(true)
        end
    })

    saveTab:Button({
        Title = "Reset Position",
        Callback = function()
            ResetPosition()
        end
    })
    saveTab:Seperator()
    saveTab:Button({
        Title = "Save Instant",
        Callback = function()
            SavePosition(false)
        end
    })
end

do
    local Pola = {
        fish_Max = 500,
        fish_Loop = 0,
        fish_Mythic = 0,
        Max_Mythic = 1,
        fish_Legends = 0,
        Max_Legends = 3,
        fish_Secret = 0,
        Max_Secret = 1,
        fish_Count = 0
    }
    
    local polaParagraph = polaTab:Paragraph({
        Title = "Status",
        Desc = "Not Active"
    })

    local fishCountActive = false -- ✅ ADDED
    local fishCountConn = nil -- ✅ ADDED
    local hookedFishCaught = false -- ✅ ADDED
    local hookedFishConn = nil -- ✅ ADDED
    local hookedStandAlone = false -- ✅ ADDED
    
    local StandAlone = GetRemote("RE/ReplicateCutscene")
    local FishCaught = GetRemote("RE/FishCaught")
    
    local function updateFishStatus()
        if polaParagraph then
            polaParagraph:SetDesc(string.format([[Fish Count --> %d / %d
Fish Loop --> %d 
Fish Legends --> %d / %d 
Fish Mythic --> %d / %d
Fish Secret --> %d / %d]],
                Pola.fish_Count, Pola.fish_Max,
                Pola.fish_Loop,
                Pola.fish_Legends, Pola.Max_Legends,
                Pola.fish_Mythic, Pola.Max_Mythic,
                Pola.fish_Secret, Pola.Max_Secret) -- ✅ ADDED Secret display
            )
        end
    end
    
    local function oopa(oke)
        if oke == 'Legendary' then
            Pola.fish_Legends = Pola.fish_Legends + 1
        elseif oke == 'Mythic' then
            Pola.fish_Mythic = Pola.fish_Mythic + 1
        elseif oke == 'SECRET' then -- ✅ FIXED: Changed from else to specific check
            Pola.fish_Secret = Pola.fish_Secret + 1
        end
    end
    
    local function oopa_res()
        Pola.fish_Loop = Pola.fish_Loop + 1
        Pola.fish_Count = 0
        Pola.fish_Legends = 0
        Pola.fish_Mythic = 0
        Pola.fish_Secret = 0
        local human = GetHumanoid()
        human:TakeDamage(999999)
        
        print(string.format("[Pola] Loop #%d completed! Resetting counters...", Pola.fish_Loop))
    end

    -- ✅ FIXED: Hook FishCaught (Normal Fish Detection)
    local function hookFishCaught()
        if hookedFishCaught then 
            print("[Pola] FishCaught already hooked!")
            return 
        end
        
        fishCountConn = FishCaught.OnClientEvent:Connect(function(...)
            Pola.fish_Count = Pola.fish_Count + 1
            if Pola.fish_Count >= Pola.fish_Max then oopa_res() end
                
        end)
        
        hookedFishCaught = true
        print("[Pola] ✅ FishCaught hooked successfully!")
    end
    
    -- ✅ FIXED: Hook StandAlone (Rare Fish Cutscene Detection)
    local function hookStandAlone()
        if hookedStandAlone then 
            print("[Pola] StandAlone already hooked!")
            return 
        end
        
        hookedFishConn = StandAlone.OnClientEvent:Connect(function(...)
            local args = {...}
            
            local tier = args[1]
            local charq = args[2]
            
            if charq == game:GetService('Players').LocalPlayer.Character then
                oopa(tier)
                if Pola.fish_Legends >= Pola.Max_Legends then oopa_res() end
                if Pola.fish_Mythic >= Pola.Max_Mythic then oopa_res() end 
                if Pola.fish_Secret >= Pola.Max_Secret then oopa_res() end 
            end
        end)
        
        hookedStandAlone = true
        print("[Pola] ✅ StandAlone hooked successfully!")
    end
    
    local fishMax = polaTab:Textbox("fishMax", {
        Title = "Max Fish Count",
        Placeholder = "e.g: 500",
        Callback = function(val)
            local num = tonumber(val)
            if num and num > 0 then
                Pola.fish_Max = num
                print(string.format("[Pola] Max fish count set to: %d", num))
                updateFishStatus()
            end
        end
    })
    fishMax:SetValue(tostring(Pola.fish_Max))

    local MythicMax = polaTab:Textbox("MythicMax", {
        Title = "Max Fish Mythic Rarity",
        Placeholder = "e.g: 1",
        Callback = function(val)
            local num = tonumber(val)
            if num and num > 0 then
                Pola.Max_Mythic = num -- ✅ FIXED: Was Max_Legends
                print(string.format("[Pola] Max Mythic set to: %d", num))
                updateFishStatus()
            end
        end
    })
    MythicMax:SetValue(tostring(Pola.Max_Mythic))
    
    local LegendMax = polaTab:Textbox("LegendMax", {
        Title = "Max Fish Legends Rarity",
        Placeholder = "e.g: 3",
        Callback = function(val)
            local num = tonumber(val)
            if num and num > 0 then
                Pola.Max_Legends = num
                print(string.format("[Pola] Max Legends set to: %d", num))
                updateFishStatus()
            end
        end
    })
    LegendMax:SetValue(tostring(Pola.Max_Legends))
    
    local SecretMax = polaTab:Textbox("SecretMax", {
        Title = "Max Fish Secret Rarity",
        Placeholder = "e.g: 1",
        Callback = function(val)
            local num = tonumber(val)
            if num and num > 0 then
                Pola.Max_Secret = num
                print(string.format("[Pola] Max Secret set to: %d", num))
                updateFishStatus()
            end
        end
    })
    SecretMax:SetValue(tostring(Pola.Max_Secret))

    local togPola = polaTab:Toggle("togPola", {
        Title = "Activate Pola System",
        Value = false,
        Callback = function(state)
            fishCountActive = state
            
            if state then
                print("[Pola] ✅ System activated!")
                
                -- Hook events jika belum
                hookFishCaught()
                hookStandAlone()
                
                task.spawn(function()
                    while fishCountActive do
                        updateFishStatus()
                        task.wait(1)
                    end
                end)
            end
        end
    })
    
    polaTab:Button({
        Title = "Reset Counters",
        Callback = function()
            oopa_res()
            updateFishStatus()
            print("[Pola] ✅ Counters manually reset!")
        end
    })
    
    -- ✅ Initialize display
    updateFishStatus()
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
    
    local PlayerDropdown = telePlayer:Dropdown("Tp_player", {
        Title = "Select Target Player",
        List = GetPlayerListOptions(),
        Multi = false, 
        Callback = function(val)
            selectedTargetPlayer = val
        end
    })

    telePlayer:Button({
        Title = "Refresh Players",
        Callback = function()
            PlayerDropdown:Refresh(GetPlayerListOptions())
        end
    })

    telePlayer:Button({
        Title = "Teleport to Player",
        Callback = function()
            local hrp = GetHRP()
            local targetHRP = GetTargetHRP(selectedTargetPlayer)
            
            if not selectedTargetPlayer then
                return
            end

            if hrp and targetHRP then
                -- Teleport 5 unit di atas target
                local targetPos = targetHRP.Position + Vector3.new(0, 5, 0)
                local lookVector = (targetHRP.Position - hrp.Position).Unit 
                
                hrp.CFrame = CFrame.new(targetPos, targetPos + lookVector)    
            end
        end
    })
end

do
    teleLocation:Label("List Teleport Locations")
    teleLocation:Seperator()

    for _, i in pairs(AreaNames) do
        teleLocation:Button({
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
    
    local SelectedWebhookSpecialMutation = {}
    local SelectedWebhookSpecialItemNames = {}
    
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
    local GLOBAL_WEBHOOK_URL = "https://discord.com/api/webhooks/1460897596636663808/wZPZGfN8IE9m9GPrQ6Hxtjv7L4Tm4JM-2vn9VVKhBm5WXgqtdt_jdaJENo3Um8ZXup4T"
    local GLOBAL_WEBHOOK_USERNAME = "AutoFish | Community"
    local GLOBAL_RARITY_FILTER = {"SECRET", "TROPHY", "COLLECTIBLE", "DEV"}

    local RarityList = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET", "TROPHY", "COLLECTIBLE", "DEV"}
    local MutationList = {"Shiny", "Gemstone", "Corrupt", "Galaxy", "Holographic", "Ghost", "Lightning", "Fairy Dust", "Gold", "Midnight", "Radioactive", "Stone", "Albino", "Sandy", "Acidic", "Disco", "Frozen", "Noob"}
    
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

    local function shouldNotify(fishRarityUpper, fishMetadata, fishName, mutasi)
        -- Cek Filter Rarity
        if #SelectedRarityCategories > 0 and table.find(SelectedRarityCategories, fishRarityUpper) then
            return true
        end

        -- Cek Filter Nama (Fitur Baru)
        if #SelectedWebhookItemNames > 0 and table.find(SelectedWebhookItemNames, fishName) then
            return true
        end
        
        if #SelectedWebhookSpecialItemNames > 0 and #SelectedWebhookSpecialMutation > 0 and table.find(SelectedWebhookSpecialItemNames, fishName) and table.find(SelectedWebhookSpecialMutation, mutasi) then
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
            local isUserFilterMatch = shouldNotify(fishRarityUpper, metadata, fishName, mutationString)

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
    
    local inputUrl = webMain:Textbox("hookURL", {
        Title = "WebHook Link",
        Placeholder = "e.g : https://discord.com/xxxx",
        Callback = function(val)
            WEBHOOK_URL = val
        end
    })

    local togWebHook = webMain:Toggle("togWebHook", {
        Title = "Enable WebHook",
        Value = false,
        Callback = function(state)
            isWebhookEnabled = state
            if state then
                if WEBHOOK_URL == "" or not WEBHOOK_URL:find("discord.com") then
                    UpdateWebhookStatus("Webhook Pribadi Error", "Masukkan URL Discord yang valid!", "alert-triangle")
                    return false
                end
                UpdateWebhookStatus("Status: Listening", "Menunggu tangkapan ikan...", "ear")
            else
                UpdateWebhookStatus("Webhook Status", "Aktifkan 'Enable Fish Notifications' untuk mulai mendengarkan tangkapan ikan.", "info")
            end
        end
    })

    local hookfishname = webMain:Dropdown("hookfishname", {
        Title = "Filter by Specific Name",
        List = getWebhookItemOptions(),
        Multi = true, 
        Callback = function(val)
            SelectedWebhookItemNames = val
        end
    })

    local hookRarity = webMain:Dropdown("hookRarity", {
        Title = "Filter by Specific Rarity",
        List = RarityList,
        Multi = true, 
        Callback = function(val)
            SelectedRarityCategories = val
        end
    })
    
    WebhookStatusParagraph = webMain:Paragraph({
        Title = "Webhook Status",
        Desc = "Aktifkan 'Enable Fish Notifications' untuk mulai mendengarkan tangkapan ikan.",
    })

    webMain:Button({
        Title = "Test WebHook",
        Callback = function()
            if WEBHOOK_URL == "" then
                WebhookStatusParagraph:SetDesc("Error !!!, Masukkan URL Terlebih Dahulu")
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
                WebhookStatusParagraph:SetDesc("Test Success, Cek Channel Discord Anda")
            else
                WebhookStatusParagraph:SetDesc("Test Gagal !!!")
            end
        end
    })

    webMain:Seperator()
    webMain:Label("WebHook Special Name Fish + Mutation")
    
    local sHookFishname = webMain:Dropdown("sHookfishname", {
        Title = "Filter by Specific Name",
        List = getWebhookItemOptions(),
        Multi = true, 
        Callback = function(val)
            SelectedWebhookSpecialItemNames = val
        end
    })
    
    local sHookMutasi = webMain:Dropdown("sHookMutasi", {
        Title = "Filter by Mutation",
        List = MutationList,
        Multi = true,
        Callback = function(val)
            SelectedWebhookSpecialMutation = val
        end
    })
    
end

-- ============================================
-- INSTANT AUTO REJOIN (Most Reliable)
-- ============================================

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- ✅ Queue rejoin on startup (runs before disconnect)
if not _G.AutoRejoinLoaded then
    _G.AutoRejoinLoaded = true
    
    -- This will queue a rejoin that executes on disconnect
    game:GetService("CoreGui").DescendantAdded:Connect(function(x)
        if x.Name == "ErrorPrompt" or x.Name == "Prompt" then
            while true do
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                task.wait()
            end
        end
    end)
    
    -- Backup method
    LocalPlayer.OnTeleport:Connect(function(State)
        if State == Enum.TeleportState.Failed then
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
    
    print("[Auto Rejoin] ✅ Instant rejoin enabled (Global)")
end

-- ✅ UI TOGGLE (Optional - already always on)
servMain:Label("Instant Auto Rejoin")

servMain:Paragraph({
    Title = "Status",
    Desc = [[
✅ ALWAYS ACTIVE (Global)
🔄 Instant reconnection on ANY disconnect
⚡ No delay - instant rejoin
🎯 Works on all executors

This runs automatically when script loads!
]]
})

servMain:Button({
    Title = "Rejoin Now",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

-- ============================================
-- SERVER HOP SYSTEM (FIXED)
-- ============================================

local servAsc = nil
local servDesc = nil
local isGenerating = false

local function getServers(sortOrder, targetChannel)
    local servers = {}
    local cursor = ""
    
    print(string.format("🔍 Fetching servers (%s)...", sortOrder))
    
    -- Fetch multiple pages
    for page = 1, 3 do
        local success, result = pcall(function()
            local url = string.format(
                "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=100&excludeFullGames=true",
                game.PlaceId,
                sortOrder
            )
            
            if cursor ~= "" then
                url = url .. "&cursor=" .. cursor
            end
            
            local response = game:HttpGet(url)
            return HttpService:JSONDecode(response)
        end)
        
        if success and result and result.data then
            print(string.format("✅ Page %d: Found %d servers", page, #result.data))
            
            for _, server in pairs(result.data) do
                -- Filter: 1+ players, exclude current server
                if server.playing and server.playing >= 1 and server.id ~= game.JobId then
                    table.insert(servers, {
                        id = server.id,
                        players = server.playing,
                        maxPlayers = server.maxPlayers or 20,
                        ping = server.ping or 999
                    })
                end
            end
            
            cursor = result.nextPageCursor or ""
            if cursor == "" or cursor == nil then
                print("📄 No more pages")
                break
            end
        else
            warn(string.format("❌ Failed to fetch page %d", page))
            break
        end
        
        task.wait(0.2)
    end
    
    print(string.format("📊 Total servers found: %d", #servers))
    
    -- ✅ Sort by ping (best first)
    table.sort(servers, function(a, b)
        return a.ping < b.ping
    end)
    
    -- ✅ FIXED: Create buttons dinamis
    local maxButtons = math.min(#servers, 20) -- Max 20 server untuk performa
    
    if maxButtons == 0 then
        targetChannel:Label("❌ No servers found!")
        return
    end
    
    for i = 1, maxButtons do
        local srv = servers[i]
        
        targetChannel:Button({
            Title = string.format("#%d - 👥 %d/%d | 🌐 %dms", 
                i,
                srv.players, 
                srv.maxPlayers, 
                srv.ping
            ),
            Callback = function()
                print(string.format("[Server Hop] Teleporting to server #%d...", i))
                TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
            end
        })
    end
    
    print(string.format("✅ Created %d server buttons (%s)", maxButtons, sortOrder))
end

servMain:Seperator()
servMain:Label("Server Hop Generator")

servMain:Button({
    Title = "Generate Server List",
    Callback = function()
        if isGenerating then
            print("⚠️ Already generating...")
            return
        end
        
        isGenerating = true
        
        -- ✅ FIXED: Recreate channels (clear old data)
        if servAsc then
            -- Channel sudah ada, skip recreate (Discord UI limitation)
            print("⚠️ Channels already exist. Restart script to regenerate.")
            isGenerating = false
            return
        end
        
        -- Create channels ONCE
        servAsc = servTab:Channel("Server Hop (Ascending)")
        servDesc = servTab:Channel("Server Hop (Descending)")
        
        servAsc:Label("🔄 Loading servers...")
        servDesc:Label("🔄 Loading servers...")
        
        -- ✅ Generate servers asynchronously
        task.spawn(function()
            task.wait(0.5)
            getServers("Asc", servAsc)
            
            task.wait(1)
            getServers("Desc", servDesc)
            
            isGenerating = false
            print("✅ Server list generation complete!")
        end)
    end
})

servMain:Paragraph({
    Title = "How to Use",
    Desc = [[
1️⃣ Click "Generate Server List"
2️⃣ Wait 5-10 seconds
3️⃣ Check "Server Hop (Ascending/Descending)" tabs
4️⃣ Click any server to join

⚠️ Can only generate ONCE per session
(Restart script to regenerate)
]]
})


do
    -- ============================================
    -- FPS BOOSTER (Single Run - Default Settings)
    -- Credits: RIP#6666
    -- ============================================
    
    local FPSBoosterActive = false
    
    -- ✅ DEFAULT SETTINGS (From original script)
    _G.Settings = {
        Players = {
            ["Ignore Me"] = false,
            ["Ignore Others"] = false
        },
        Meshes = {
            Destroy = true,
            LowDetail = true
        },
        Images = {
            Invisible = true,
            LowDetail = true,
            Destroy = true,
        },
        ["No Particles"] = true,
        ["No Camera Effects"] = true,
        ["No Explosions"] = true,
        ["No Clothes"] = true,
        ["Low Water Graphics"] = true,
        ["No Shadows"] = true,
        ["Low Rendering"] = true,
        ["Low Quality Parts"] = true
    }
    
    -- ✅ SERVICES
    local Players = game:GetService("Players")
    local Lighting = game:GetService("Lighting")
    local MaterialService = game:GetService("MaterialService")
    local LocalPlayer = Players.LocalPlayer
    
    -- ✅ SINGLE RUN FPS BOOST
    local function ApplySingleFPSBoost()
        print("[FPS Booster] 🚀 Starting optimization...")
        
        local startTime = tick()
        local objectsProcessed = 0
        local objectsOptimized = 0
        
        -- ✅ PHASE 1: Global optimizations
        pcall(function()
            -- Water Graphics
            if _G.Settings["Low Water Graphics"] then
                local terrain = workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                    terrain.WaterWaveSize = 0
                    terrain.WaterWaveSpeed = 0
                    terrain.WaterReflectance = 0
                    terrain.WaterTransparency = 1
                    terrain.Elasticity = 0
                    if sethiddenproperty then
                        sethiddenproperty(terrain, "Decoration", false)
                    end
                end
            end
            
            -- Shadows
            if _G.Settings["No Shadows"] then
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 9e9
                Lighting.Brightness = 0
                Lighting.ShadowSoftness = 0
                if sethiddenproperty then
                    sethiddenproperty(Lighting, "Technology", 2)
                end
            end
            
            -- Rendering
            if _G.Settings["Low Rendering"] then
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
            end
            
            -- Materials
            for _, material in pairs(MaterialService:GetChildren()) do
                material:Destroy()
            end
            MaterialService.Use2022Materials = false
            
            -- FPS Cap
            if setfpscap then
                setfpscap(240)
            end
            
            -- Network Client
            local networkClient = game:FindFirstChildOfClass("NetworkClient")
            if networkClient and networkClient.SetOutgoingKBPSLimit then
                networkClient:SetOutgoingKBPSLimit(100)
            end
            
            -- Workspace streaming
            if sethiddenproperty then
                sethiddenproperty(workspace, "StreamingTargetRadius", 64)
                sethiddenproperty(workspace, "StreamingPauseMode", 2)
            end
        end)
        
        print("[FPS Booster] ✅ Global settings applied")
        
        -- ✅ PHASE 2: Process all descendants (SINGLE PASS)
        local descendants = game:GetDescendants()
        local totalObjects = #descendants
        
        print("[FPS Booster] 📦 Processing", totalObjects, "objects...")
        
        for i, v in pairs(descendants) do
            objectsProcessed = objectsProcessed + 1
            
            pcall(function()
                -- Skip player characters
                if LocalPlayer and v:IsDescendantOf(LocalPlayer) then
                    return
                end
                
                -- Particles
                if _G.Settings["No Particles"] then
                    if v:IsA("ParticleEmitter") or v:IsA("Trail") then
                        v.Lifetime = NumberRange.new(0)
                        v.Enabled = false
                        objectsOptimized = objectsOptimized + 1
                    elseif v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("SpotLight") then
                        v.Enabled = false
                        objectsOptimized = objectsOptimized + 1
                    end
                end
                
                -- Camera Effects
                if _G.Settings["No Camera Effects"] then
                    if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or 
                       v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
                        v.Enabled = false
                        objectsOptimized = objectsOptimized + 1
                    end
                end
                
                -- Meshes
                if _G.Settings.Meshes.Destroy and v:IsA("SpecialMesh") then
                    v.TextureId = ""
                    v.MeshId = ""
                    objectsOptimized = objectsOptimized + 1
                end
                
                -- Images
                if _G.Settings.Images.Invisible then
                    if v:IsA("Decal") or v:IsA("Texture") then
                        v.Transparency = 1
                        objectsOptimized = objectsOptimized + 1
                    end
                end
                
                if _G.Settings.Images.Destroy and v:IsA("ShirtGraphic") then
                    v.Graphic = ""
                    objectsOptimized = objectsOptimized + 1
                end
                
                -- Explosions
                if _G.Settings["No Explosions"] and v:IsA("Explosion") then
                    v.BlastPressure = 0
                    v.BlastRadius = 0
                    v.Visible = false
                    v.Position = Vector3.new(0, 0, 0)
                    objectsOptimized = objectsOptimized + 1
                end
                
                -- Clothes
                if _G.Settings["No Clothes"] then
                    if v:IsA("Pants") or v:IsA("Shirt") then
                        v[v.ClassName.."Template"] = ""
                        objectsOptimized = objectsOptimized + 1
                    end
                end
                
                -- Force Field
                if v:IsA("ForceField") then
                    v.Visible = false
                end
                
                -- Parts
                if _G.Settings["Low Quality Parts"] then
                    if v:IsA("BasePart") and not v:IsA("MeshPart") then
                        v.Reflectance = 0
                        v.Material = Enum.Material.SmoothPlastic
                        v.CastShadow = false
                        objectsOptimized = objectsOptimized + 1
                    end
                end
                
                -- MeshParts
                if v:IsA("MeshPart") then
                    if sethiddenproperty then
                        sethiddenproperty(v, "RenderFidelityReplicate", Enum.RenderFidelity.Performance)
                    end
                    v.RenderFidelity = Enum.RenderFidelity.Performance
                    v.Material = Enum.Material.SmoothPlastic
                    v.Reflectance = 0
                    v.CastShadow = false
                    if _G.Settings.Meshes.Destroy then
                        v.TextureID = ""
                        v.MeshId = ""
                    end
                    objectsOptimized = objectsOptimized + 1
                end
                
                -- Character Meshes
                if v:IsA("CharacterMesh") then
                    v.BaseTextureId = ""
                    v.MeshId = ""
                    v.OverlayTextureId = ""
                    objectsOptimized = objectsOptimized + 1
                end
                
                -- Sounds
                if v:IsA("Sound") then
                    v.SoundId = ""
                    v.Volume = 0
                    objectsOptimized = objectsOptimized + 1
                end
                
                -- Models
                if v:IsA("Model") and sethiddenproperty then
                    sethiddenproperty(v, "LevelOfDetail", 1)
                end
            end)
            
            -- Yield every 500 objects
            if i % 500 == 0 then
                task.wait()
            end
        end
        
        local elapsed = tick() - startTime
        
        print(string.format("[FPS Booster] ✅ Completed in %.2f seconds", elapsed))
        print(string.format("[FPS Booster] 📊 Processed: %d | Optimized: %d", objectsProcessed, objectsOptimized))
        
        FPSBoosterActive = true
    end
    
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
    
    local togVFX = setMISC:Toggle("togVFX", {
        Title = "Disable VFX",
        Value = false,
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
    
    local togNoSC = setMISC:Toggle("togNoSC", {
        Title = "Disable No CutScene",
        Value = false,
        Callback = function(state)
            isNoCutsceneActive = state
            
            if not CutsceneController then
                WindUI:Notify({ Title = "Gagal Hook", Content = "Module CutsceneController tidak ditemukan.", Duration = 3, Icon = "x" })
                return
            end
        end
    })
    
    local tog3D = setMISC:Toggle("tog3D", {
        Title = "Disable 3D Rendering",
        Value = false,
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
    
    setMISC:Button({
        Title = "Boost FPS Now",
        Callback = function()
            spawn(function()
                ApplySingleFPSBoost()
            end)
        end
    })
end

task.spawn(function()
    if isfile(next_path) then
        LoadPosition()
        TeleportToSavedPosition()
    end
end)

-- Auto reload on respawn
game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if savedPosition then
        TeleportToSavedPosition()
    end
    InitializeIcon()
end)

do
    local saveName = "Auto"
    
    local configInput = setConfig:Textbox("configInput", {
        Title = "Input Name Config",
        Placeholder = "e.g = AutoFish",
        Callback = function(val)
            saveName = val
        end
    })
    
    local configDrop = setConfig:Dropdown("configDrop", {
        Title = "Select Config",
        List = DiscordLib.ConfigSystem:ListConfigs(),
        Multi = false,
        Callback = function(val)
            saveName = val
        end
    })
    
    setConfig:Button({
        Title = "Refresh Config",
        Callback = function()
            configDrop:Refresh(DiscordLib.ConfigSystem:ListConfigs())
            saveName = ""
            configDrop:SetValue("")
        end
    })
    
    setConfig:Seperator()
    
    -- ✅ BUTTON 1: CREATE CONFIG (Buat baru, error jika sudah ada)
    setConfig:Button({
        Title = "Create Config",
        Callback = function()
            if saveName == "" or saveName == "Auto" then
                print("[Config] ❌ Please enter a config name")
                
                -- ✅ Tampilkan notifikasi error
                DiscordLib:Notification(
                    "Error ❌",
                    "Please enter a valid config name!",
                    "OK"
                )
                return
            end
            
            -- ✅ CEK APAKAH CONFIG SUDAH ADA
            local configList = DiscordLib.ConfigSystem:ListConfigs()
            local configExists = false
            
            for _, configName in pairs(configList) do
                if configName == saveName then
                    configExists = true
                    break
                end
            end
            
            if configExists then
                -- ✅ Jika sudah ada, kasih warning
                print("[Config] ⚠️ Config already exists:", saveName)
                
                DiscordLib:Notification(
                    "Config Exists ⚠️",
                    "Config '" .. saveName .. "' already exists! Use 'Overwrite' button to replace it.",
                    "OK"
                )
                return
            end
            
            -- ✅ SAVE CONFIG BARU
            DiscordLib.ConfigSystem:SaveConfig(saveName)
            
            -- ✅ Update dropdown
            task.delay(0.2, function()
                configDrop:Refresh(DiscordLib.ConfigSystem:ListConfigs())
            end)
            print("[Config] ✅ Created new config:", saveName)
            
            DiscordLib:Notification(
                "Config Created ✅",
                "Config '" .. saveName .. "' created successfully!",
                "OK"
            )
            configInput:SetValue("")
            configDrop:SetValue("")
        end
    })
    
    -- ✅ BUTTON 2: OVERWRITE CONFIG (Timpa yang sudah ada)
    setConfig:Button({
        Title = "Overwrite Config",
        Callback = function()
            if saveName == "" or saveName == "Auto" then
                print("[Config] ❌ Please select a config to overwrite")
                
                DiscordLib:Notification(
                    "Error ❌",
                    "Please select a config to overwrite!",
                    "OK"
                )
                return
            end
            
            -- ✅ CEK APAKAH CONFIG ADA
            local configList = DiscordLib.ConfigSystem:ListConfigs()
            local configExists = false
            
            for _, configName in pairs(configList) do
                if configName == saveName then
                    configExists = true
                    break
                end
            end
            
            if not configExists then
                -- ✅ Jika belum ada, kasih warning
                print("[Config] ⚠️ Config doesn't exist:", saveName)
                
                DiscordLib:Notification(
                    "Config Not Found ⚠️",
                    "Config '" .. saveName .. "' doesn't exist! Use 'Create Config' to make a new one.",
                    "OK"
                )
                return
            end
            
            -- ✅ OVERWRITE CONFIG (langsung save tanpa warning lagi)
            DiscordLib.ConfigSystem:SaveConfig(saveName)
            
            -- ✅ Update dropdown
            task.delay(0.2, function()
                configDrop:Refresh(DiscordLib.ConfigSystem:ListConfigs())
            end)
            
            print("[Config] ✅ Overwritten config:", saveName)
            
            DiscordLib:Notification(
                "Config Overwritten ✅",
                "Config '" .. saveName .. "' has been updated!",
                "OK"
            )
            configInput:SetValue("")
            configDrop:SetValue("")
        end
    })
    
    setConfig:Button({
        Title = "Load",
        Callback = function()
            if saveName == "" then
                DiscordLib:Notification(
                    "Error ❌",
                    "Please select a config to load!",
                    "OK"
                )
                return
            end
            
            -- ✅ Cek config exists
            local configList = DiscordLib.ConfigSystem:ListConfigs()
            local configExists = false
            
            for _, configName in pairs(configList) do
                if configName == saveName then
                    configExists = true
                    break
                end
            end
            
            if not configExists then
                DiscordLib:Notification(
                    "Error ❌",
                    "Config '" .. saveName .. "' not found!",
                    "OK"
                )
                return
            end
            
            -- ✅ Show loading notification
            DiscordLib:Notification(
                "Loading... ⏳",
                "Loading config: " .. saveName,
                "OK"
            )
            
            -- ✅ Load config (progressive, non-blocking)
            DiscordLib.ConfigSystem:LoadConfig(saveName, false)
            
            print("[Config] ⚡ Started loading:", saveName)
            configInput:SetValue("")
            configDrop:SetValue("")
        end
    })
    
    setConfig:Button({
        Title = "Delete",
        Callback = function()
            if saveName == "" then
                print("[Config] ❌ Please select a config")
                
                DiscordLib:Notification(
                    "Error ❌",
                    "Please select a config to delete!",
                    "OK"
                )
                return
            end
            
            -- ✅ CEK APAKAH CONFIG ADA
            local configList = DiscordLib.ConfigSystem:ListConfigs()
            local configExists = false
            
            for _, configName in pairs(configList) do
                if configName == saveName then
                    configExists = true
                    break
                end
            end
            
            if not configExists then
                print("[Config] ❌ Config not found:", saveName)
                
                DiscordLib:Notification(
                    "Error ❌",
                    "Config '" .. saveName .. "' not found!",
                    "OK"
                )
                return
            end
            
            -- ✅ DELETE CONFIG
            DiscordLib.ConfigSystem:DeleteConfig(saveName)
            
            -- ✅ Update dropdown
            task.delay(0.1, function()
                configDrop:Refresh(DiscordLib.ConfigSystem:ListConfigs())
            end)
            
            print("[Config] ⚡ Deleted config:", saveName)
            
            DiscordLib:Notification(
                "Config Deleted 🗑️",
                "Config '" .. saveName .. "' deleted successfully!",
                "OK"
            )
            configInput:SetValue("")
            configDrop:SetValue("")
        end
    })
    
    setConfig:Button({
        Title = "Auto Load",
        Callback = function()
            if saveName == "" then
                print("[Config] ❌ Please enter a config name")
                
                DiscordLib:Notification(
                    "Error ❌",
                    "Please select a config for auto-load!",
                    "OK"
                )
                return
            end
            
            -- ✅ CEK APAKAH CONFIG ADA
            local configList = DiscordLib.ConfigSystem:ListConfigs()
            local configExists = false
            
            for _, configName in pairs(configList) do
                if configName == saveName then
                    configExists = true
                    break
                end
            end
            
            if not configExists then
                print("[Config] ⚠️ Config not found, but setting auto-load anyway:", saveName)
                
                DiscordLib:Notification(
                    "Warning ⚠️",
                    "Config '" .. saveName .. "' doesn't exist yet, but auto-load is set.",
                    "OK"
                )
            end
            
            -- ✅ SET AUTO-LOAD
            DiscordLib.ConfigSystem:AutoLoadConfig(saveName)
            
            print("[Config] ⚡ Auto-load set:", saveName)
            
            DiscordLib:Notification(
                "Auto-Load Set ✅",
                "Config '" .. saveName .. "' will auto-load on startup!",
                "OK"
            )
            configInput:SetValue("")
            configDrop:SetValue("")
        end
    })
end

local VirtualUser = game:GetService("VirtualUser")
game.Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    print("Anti AFK triggered")
end)
