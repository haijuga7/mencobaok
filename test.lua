-- edited by @example
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "Mr.A_S - Fish It",
    Icon = "rbxassetid://116236936447443",
    Author = "Premium Version",
    Folder = "AutoFish",
    Size = UDim2.fromOffset(600, 360),
    MinSize = Vector2.new(560, 250),
    MaxSize = Vector2.new(950, 760),
    Transparent = true,
    Theme = "Rose",
    Resizable = true,
    SideBarWidth = 190,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = true,
})

local SelectedConfigName = "AutoFish" -- Default
-- [[ 1. CONFIGURATION SYSTEM SETUP ]] --
local RockHubConfig = Window.ConfigManager:CreateConfig(SelectedConfigName)

-- [BARU] Tabel untuk menyimpan semua elemen UI agar bisa dicek valuenya
local ElementRegistry = {} 

-- Fungsi Helper Reg yang sudah di-upgrade
local function Reg(id, element)
    RockHubConfig:Register(id, element)
    -- Simpan elemen ke tabel lokal kita
    ElementRegistry[id] = element 
    return element
end

local HttpService = game:GetService("HttpService")

-- ====================================
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = game.Players.LocalPlayer
local RepStorage = game:GetService("ReplicatedStorage") 
local ItemUtility = require(RepStorage:WaitForChild("Shared"):WaitForChild("ItemUtility", 10))
local TierUtility = require(RepStorage:WaitForChild("Shared"):WaitForChild("TierUtility", 10))

local pos_saved = nil
local look_saved = nil

local stealthMode = false
local stealthHight = 110

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

local function TeleportStealth()
    local hrp = GetHRP()
    
    if hrp and typeof(pos_saved) == "Vector3" and typeof(look_saved) == "Vector3" then
        local targetCFrame = CFrame.new(pos_saved, pos_saved + look_saved)
        hrp.CFrame = targetCFrame * CFrame.new(0, stealthHight, 0)
    end
end

local function TeleportToLookAt()
    local hrp = GetHRP()
    
    hrp.Anchored = false
    if hrp and typeof(pos_saved) == "Vector3" and typeof(look_saved) == "Vector3" then
        local targetCFrame = CFrame.new(pos_saved, pos_saved + look_saved)
        hrp.CFrame = targetCFrame * CFrame.new(0, 0.5, 0)
        
        if stealthMode then
            TeleportStealth()
            wait(0.1)
            hrp.Anchored = true
        end
        
        WindUI:Notify({ Title = "Teleport Sukses!", Duration = 3, Icon = "map-pin", })
    else
        WindUI:Notify({ Title = "Teleport Gagal", Content = "Data posisi tidak valid.", Duration = 3, Icon = "x", })
    end
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

local FishingAreas = {
    ["Ancient Jungle"] = { cframe = Vector3.new(1896.9, 8.4, -578.7), lookup = Vector3.new(0.973, 0.000, 0.229) },
    ["Ancient Ruins"] = { cframe = Vector3.new(6081.4, -585.9, 4634.5), lookup = Vector3.new(-0.619, -0.000, 0.785) },
    ["Ancient Ruins Door "] = { cframe = Vector3.new(6051.0, -538.9, 4386.0), lookup = Vector3.new(-0.000, -0.000, -1.000) },
    ["Christmast Island"] = { cframe = Vector3.new(1175.3,23.5,1545.3), lookup = Vector3.new(-0.787,-0.000,0.616) },
    ["Christmast Cave"] = { cfrane = Vector3.new(743.5,-487.1,8863.5), lookup = Vector3.new(-0.020,-0.000,1.000) },
    ["Classic Event"] = { cframe = Vector3.new(1171.3, 4.0, 2839.4), lookup = Vector3.new(-0.994, 0.000, -0.107) },
    ["Classic Event River "] = { cframe = Vector3.new(1439.7, 46.0, 2778.1), lookup = Vector3.new(0.894, 0.000, -0.448) },
    ["Coral Reefs"] = { cframe = Vector3.new(-2935.1,4.8,2050.9), lookup = Vector3.new(-0.306,-0.000,0.952) },
    ["Crater Island "] = { cframe = Vector3.new(1077.6, 2.8, 5080.9), lookup = Vector3.new(-0.987, 0.000, -0.159) },
    ["Esoteric Deep"] = { cframe = Vector3.new(3202.2, -1302.9, 1432.7), lookup = Vector3.new(0.896, 0.000, -0.444) },
    ["Iron Cavern "] = { cframe = Vector3.new(-8794.5, -585.0, 89.0), lookup = Vector3.new(0.741, -0.000, -0.672) },
    ["Iron Cave"] = { cframe = Vector3.new(-8641.3, -547.5, 162.0), lookup = Vector3.new(1.000, 0.000, -0.016) },
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

-- ======================================= Fishing Tab ========================
do
    local FishingTab = Window:Section({
        Title = "Fishing",
        Icon = "fish",
        Locked = false,
    })
    
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
    
    local toggleLegit = nil
    local toggleInstant = nil
    local BlatantV1Toggle = nil
    local BlatantV2Toggle = nil
    
    local minigameDelay = nil
    local cycleDelay = nil
    
    local walkOnWaterConnection = nil
    local isWalkOnWater = false
    local waterPlatform = nil
    
    local autoERodConn = nil
    
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
    
    local function OnCharacterAdded(newCharacter)
        if isNoAnimationActive then
            task.wait(0.2) -- Tunggu sebentar agar LoadCharacter selesai
            DisableAnimations()
        end
    end
    
    local function instantOk()
        RF_ChargeFishingRod:InvokeServer(1, 0.999)
        RF_RequestFishingMinigameStarted:InvokeServer(1, 0.999)
        task.wait(minigameDelay)
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
            task.wait(minigameDelay)
            RE_FishingCompleted:FireServer()
        end)
    end
    
    local function blatantFishv2()
        task.spawn(function()
            pcall(function() RF_CancelFishingInputs:InvokeServer() end)
        end)
        task.spawn(function()
            pcall(function() RF_ChargeFishingRod:InvokeServer(1, 0.999) end)
        end)
        task.spawn(function()
            task.wait(0.016)
            pcall(function() RF_RequestFishingMinigameStarted:InvokeServer(1, 0.999) end)
        end)
        task.spawn(function()
            task.wait(minigameDelay)
            pcall(function() RE_FishingCompleted:FireServer() end)
        end)
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
    
    -- ===================================================================
    -- LOGIKA BARU UNTUK AUTO FISH LEGIT
    -- ===================================================================
    
    local FishingController = require(RepStorage:WaitForChild("Controllers").FishingController)
    local AutoFishingController = require(RepStorage:WaitForChild("Controllers").AutoFishingController)
    
    local AutoFishState = {
        IsActive = false,
        MinigameActive = false
    }
    
    local SPEED_LEGIT = 0.05
    local legitClickThread = nil
    
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
                task.cancel(legitClickThread)
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
            WindUI:Notify({ Title = "Error", Content = "Gagal memuat Fishing Controllers.", Duration = 4, Icon = "x" })
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
                task.cancel(legitClickThread)
                legitClickThread = nil
            end
            AutoFishState.MinigameActive = false
            
            -- 4. Tampilkan kembali UI Minigame
            if fishingGui then fishingGui.Visible = true end
            if chargeGui then chargeGui.Visible = true end
        end
    end
    
    local fishSupport = FishingTab:Tab({
        Title = "Fishing Support",
        TextSize = 20,
        FontWeight = Enum.FontWeight.SemiBold,
    })
    
    local walkonwater = Reg("wlkonwtr", fishSupport:Toggle({
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
    }))
    
    local autoERod = Reg("autoerod", fishSupport:Toggle({
        Title = "Auto Equip Rod",
        Value = false,
        Callback = function(b)
            if b then
                if autoERodConn then
                    task.cancel(autoERodConn)
                    autoERodConn = nil
                end
                autoERodConn = task.spawn(function()
                    while b do
                        pcall(function() RE_EquipToolFromHotbar:FireServer(1) end) task.wait(1)
                    end
                end)
            else
                task.cancel(autoERodConn) autoERodConn = nil
            end
        end
    }))
    
    local disAnim = Reg("disAnim", fishSupport:Toggle({
        Title = "Disable Animation",
        Value = false,
        Callback = function(b)
            isNoAnimationActive = b
            if b then
                DisableAnimations()
            else
                EnableAnimations()
            end
        end
    }))
    
    local disNotif = Reg("disNotif", fishSupport:Toggle({
        Title = "Disable Fish Notif",
        Value = false,
        Callback = function(s)
            s = not s
            pcall(function() game:GetService("Players").LocalPlayer.PlayerGui["Small Notification"].Display.Visible = s end)
        end
    }))

    local stealthcc = Reg("stealthcc", fishSupport:Input({
        Title = "Stealth Hight",
        Type = "Input",
        Value = tonumber(stealthHight),
        Placeholder = "default: 110",
        Callback = function(s)
            stealthHight = tonumber(s)
        end
    }))

    local stealth = Reg("stealth", fishSupport:Toggle({
        Title = "Stealth Mode",
        Value = false,
        Callback = function(state)
            local hrp = GetHRP()
            pos_saved = hrp.Position
            look_saved = hrp.CFrame.LookVector
            
            stealthMode = state
            if state then
                TeleportToLookAt()
            else
                hrp.Anchored = state
                wait(0.1)
                TeleportToLookAt()
            end
        end
    }))

    local fishMethode = FishingTab:Tab({
        Title = "Fishing"
    })
    
    local autoFish = fishMethode:Section({
        Title = "Auto Fishing",
        TextSize = 20,
        FontWeight = Enum.FontWeight.SemiBold,
    })
    
    local slidlegit = Reg("klikd", autoFish:Slider({ -- ✅ DIPERBAIKI
        Title = "Legit Click Speed (Delay)",
        Step = 0.01,
        Value = { Min = 0.01, Max = 0.5, Default = SPEED_LEGIT },
        Callback = function(value)
            local newSpeed = tonumber(value)
            if newSpeed and newSpeed >= 0.01 then
                SPEED_LEGIT = newSpeed
            end
        end
    }))
    
    local toggleLegit = Reg("legit", autoFish:Toggle({ -- ✅ DIPERBAIKI
        Title = "Auto Fish (Legit)",
        Value = false,
        Callback = function(state)
            ToggleAutoClick(state)
        end
    }))
    
    local InstantFish = fishMethode:Section({
        Title = "Instant Fishing",
        TextSize = 20,
        FontWeight = Enum.FontWeight.SemiBold,
    })
    
    -- ⚠️ FIX: Gunakan `:Input()` bukan `()`
    local InstantDelay = Reg("instdelay", InstantFish:Input({ -- ✅ DIPERBAIKI
        Title = "Complete Delay",
        Value = tostring(minigameDelay or 1), -- ✅ DIPERBAIKI
        Type = "Input",
        Placeholder = "example : 1",
        Callback = function(s)
            minigameDelay = tonumber(s)
        end
    }))
    
    local toggleInstant = Reg("toginst", InstantFish:Toggle({ -- ✅ DIPERBAIKI
        Title = "Instant Fish",
        Value = false,
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
                if instantLoopThread then task.cancel(instantLoopThread) instantLoopThread = nil end
            end
        end
    }))
    
    local BlatantV1 = fishMethode:Section({
        Title = "BlatantV1 Fishing",
        TextSize = 20,
        FontWeight = Enum.FontWeight.SemiBold,
    })
    
    local BlatantV1Cast = Reg("blatV1cast", BlatantV1:Input({ -- ✅ DIPERBAIKI
        Title = "Cast Delay",
        Value = "1.97",
        Type = "Input",
        Placeholder = "example : 1.97",
        Callback = function(s)
            cycleDelay = tonumber(s)
        end
    }))
    
    local BlatantV1Delay = Reg("blatV1delay", BlatantV1:Input({ -- ✅ DIPERBAIKI
        Title = "Complete Delay",
        Value = "0.97",
        Type = "Input",
        Placeholder = "example : 0.97",
        Callback = function(s)
            minigameDelay = tonumber(s)
        end
    }))
    
    local BlatantV1Toggle = Reg("togblatv1", BlatantV1:Toggle({ -- ✅ DIPERBAIKI
        Title = "BlatantV1 Fish",
        Value = false,
        Callback = function(state)
            blatantV1State = state
            _G.BloxFish_BlatantActive = state
            pcall(function() RF_UpdateAutoFishingState:InvokeServer(state) end)
            
            if state then
                blatantFishv1LoopThread = task.spawn(function()
                    while blatantV1State do
                        blatantFishv1()
                        task.wait(cycleDelay)
                    end
                end)
            else
                if blatantFishv1LoopThread then task.cancel(blatantFishv1LoopThread) blatantFishv1LoopThread = nil end
            end
        end
    }))
    
    local BlatantV2 = fishMethode:Section({
        Title = "BlatantV2 Fishing",
        TextSize = 20,
        FontWeight = Enum.FontWeight.SemiBold,
    })
    
    local BlatantV2Bait = Reg("blatV2bait", BlatantV2:Input({ -- ✅ DIPERBAIKI
        Title = "Bait Delay",
        Value = "0.36",
        Type = "Input",
        Placeholder = "example : 0.36",
        Callback = function(s)
            cycleDelay = tonumber(s)
        end
    }))
    
    local BlatantV2Delay = Reg("blatV2delay", BlatantV2:Input({ -- ✅ DIPERBAIKI
        Title = "Complete Delay",
        Value = "0.97",
        Type = "Input",
        Placeholder = "example : 1.265",
        Callback = function(s)
            minigameDelay = tonumber(s)
        end
    }))
    
    local BlatantV2Toggle = Reg("togblatv2", BlatantV2:Toggle({ -- ✅ DIPERBAIKI
        Title = "BlatantV2 Fish",
        Value = false,
        Callback = function(state)
            blatantV2State = state -- ✅ DIPERBAIKI (tadinya blatantV1State)
            _G.BloxFish_BlatantActive = state
            pcall(function() RF_UpdateAutoFishingState:InvokeServer(state) end)
            
            if state then
                blatantFishv2LoopThread = task.spawn(function()
                    while blatantV2State do
                        blatantFishv2()
                        task.wait(cycleDelay + minigameDelay)
                    end
                end)
            else
                if blatantFishv2LoopThread then task.cancel(blatantFishv2LoopThread) blatantFishv2LoopThread = nil end
            end
        end
    }))
    
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
    
    local favsec = FishingTab:Tab({ Title = "Auto Favorite / Unfavorite", TextSize = 20, })
    
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
        if autoFavoriteThread then task.cancel(autoFavoriteThread) end
        
        autoFavoriteThread = task.spawn(function()
            local waitTime = 1
            local actionDelay = 0.5
            
            while autoFavoriteState do
                local itemsToFavorite = GetItemsToFavorite()
                
                if #itemsToFavorite > 0 then
                    WindUI:Notify({ Title = "Auto Favorite", Content = string.format("Mem-favorite %d item...", #itemsToFavorite), Duration = 1, Icon = "star" })
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
        if autoUnfavoriteThread then task.cancel(autoUnfavoriteThread) end
        
        autoUnfavoriteThread = task.spawn(function()
            local waitTime = 1
            local actionDelay = 0.5
            
            while autoUnfavoriteState do
                local itemsToUnfavorite = GetItemsToUnfavorite()
                
                if #itemsToUnfavorite > 0 then
                    WindUI:Notify({ Title = "Auto Unfavorite", Content = string.format("Menghapus favorite dari %d item yang dipilih...", #itemsToUnfavorite), Duration = 1, Icon = "x" })
                    for _, itemUUID in ipairs(itemsToUnfavorite) do
                        SetItemFavoriteState(itemUUID, false)
                        task.wait(actionDelay)
                    end
                end
                
                task.wait(waitTime)
            end
        end)
    end
    
    
    -- UI ELEMENTS FAVORITE / UNFAVORITE --
    
    local RarityDropdown = Reg("drer", favsec:Dropdown({
        Title = "by Rarity",
        Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET"},
        Multi = true, 
        AllowNone = true, 
        Value = {},
        Callback = function(values) 
            selectedRarities = values or {}
            print("[CALLBACK TRIGGERED] Rarity Filter =", table.concat(selectedRarities, ", "))
        end
    }))
    
    local ItemNameDropdown = Reg("dtem", favsec:Dropdown({
        Title = "by Item Name",
        Values = allItemNames,
        Multi = true, 
        AllowNone = true, 
        Value = {},
        Callback = function(values) 
            selectedItemNames = values or {}
            print("[CALLBACK TRIGGERED] Item Name Filter =", table.concat(selectedItemNames, ", "))
        end
    }))
    
    local MutationDropdown = Reg("dmut", favsec:Dropdown({
        Title = "by Mutation",
        Values = {"Shiny", "Gemstone", "Corrupt", "Galaxy", "Holographic", "Ghost", "Lightning", "Fairy Dust", "Gold", "Midnight", "Radioactive", "Stone", "Albino", "Sandy", "Acidic", "Disco", "Frozen", "Noob"},
        Multi = true, 
        AllowNone = true, 
        Value = {},
        Callback = function(values) 
            selectedMutations = values or {}
            print("[CALLBACK TRIGGERED] Mutation Filter =", table.concat(selectedMutations, ", "))
        end
    }))
    
    -- Toggle Auto Favorite
    local togglefav = Reg("tvav",favsec:Toggle({
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
                if autoFavoriteThread then
                    task.cancel(autoFavoriteThread) autoFavoriteThread = nil
                end
            end
        end
    }))
    
    -- Toggle Auto Unfavorite (LOGIKA YANG DIPERBAIKI)
    local toggleunfav = Reg("tunfa",favsec:Toggle({
        Title = "Enable Auto Unfavorite",
        Value = false,
        Callback = function(state)
            autoUnfavoriteState = state
            if state then
                if #selectedRarities == 0 and #selectedItemNames == 0 and #selectedMutations == 0 then
                    return false -- Batalkan aksi jika tidak ada filter
                end
    
                RunAutoUnfavoriteLoop()
            else
                if autoUnfavoriteThread then task.cancel(autoUnfavoriteThread) autoUnfavoriteThread = nil end
            end
        end
    }))
    
    -- Variabel untuk Auto Sell
    local sellDelay = 50
    local autoSellDelayState = false
    local autoSellDelayThread = nil
    local sellCount = 50
    local autoSellCountState = false
    local autoSellCountThread = nil
    
    -- Helper Function: Get Fish/Item Count
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
    
    -- Helper Function: Menonaktifkan mode Auto Sell lain
    local function disableOtherAutoSell(currentMode)
        if currentMode ~= "delay" and autoSellDelayState then
            autoSellDelayState = false
            local toggle = automatic:GetElementByTitle("Auto Sell All (Delay)")
            if toggle and toggle.Set then toggle:Set(false) end
            if autoSellDelayThread then task.cancel(autoSellDelayThread) autoSellDelayThread = nil end
        end
        if currentMode ~= "count" and autoSellCountState then
            autoSellCountState = false
            local toggle = automatic:GetElementByTitle("Auto Sell by Count")
            if toggle and toggle.Set then toggle:Set(false) end
            if autoSellCountThread then task.cancel(autoSellCountThread) autoSellCountThread = nil end
        end
    end
    
    -- LOGIC AUTO SELL BY DELAY
    local function RunAutoSellDelayLoop()
        if autoSellDelayThread then task.cancel(autoSellDelayThread) end
        autoSellDelayThread = task.spawn(function()
            while autoSellDelayState do
                if RF_SellAllItems then
                    pcall(function() RF_SellAllItems:InvokeServer() end)
                end
                task.wait(math.max(sellDelay, 1))
            end
        end)
    end
    
    -- LOGIC AUTO SELL BY COUNT
    local function RunAutoSellCountLoop()
        if autoSellCountThread then task.cancel(autoSellCountThread) end
        autoSellCountThread = task.spawn(function()
            while autoSellCountState do
                local currentCount = GetFishCount()
                
                if currentCount >= sellCount then
                    if RF_SellAllItems then
                        pcall(function() RF_SellAllItems:InvokeServer() end)
                        task.wait(1)
                    end
                end
                task.wait(1)
            end
        end)
    end
    
       -- =================================================================
    -- 💰 UNIFIED AUTO SELL SYSTEM (BY DELAY / BY COUNT)
    -- =================================================================
    local sellall = FishingTab:Tab({ Title = "Autosell Fish", TextSize = 20 })
    
    -- Variabel Global Auto Sell Baru
    local autoSellMethod = "Delay" -- Default: Delay
    local autoSellValue = 50       -- Default Value (Detik atau Jumlah)
    local autoSellState = false
    local autoSellThread = nil
    
    -- 1. Helper: Unified Loop Logic
    local function RunAutoSellLoop()
        if autoSellThread then task.cancel(autoSellThread) end
        
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
                            WindUI:Notify({ Title = "Auto Sell", Content = "Menjual " .. currentCount .. " items.", Duration = 2, Icon = "dollar-sign" })
                            task.wait(2) -- Cooldown sebentar setelah jual
                        end
                    end
                    task.wait(1) -- Cek setiap 1 detik
                end
            end
        end)
    end
    
    -- 2. UI Elements
    
    -- Dropdown untuk memilih metode
    local inputElement -- Forward declaration untuk update judul input
    
    local dropMethod = sellall:Dropdown({
        Title = "Select Method",
        Values = {"Delay", "Count"},
        Value = "Delay",
        Multi = false,
        AllowNone = false,
        Callback = function(val)
            autoSellMethod = val
            
            -- Update Judul Input agar user paham
            if inputElement then
                if val == "Delay" then
                    inputElement:SetTitle("Sell Delay (Seconds)")
                    inputElement:SetPlaceholder("e.g. 50")
                else
                    inputElement:SetTitle("Sell at Item Count")
                    inputElement:SetPlaceholder("e.g. 100")
                end
            end
            
            -- Restart loop jika sedang aktif agar logika langsung berubah
            if autoSellState then
                RunAutoSellLoop()
            end
        end
    })
    
    -- Input Tunggal (Dinamis)
    inputElement = Reg("sellval",sellall:Input({
        Title = "Sell Delay (Seconds)", -- Judul awal
        Value = tostring(autoSellValue),
        Placeholder = "50",
        Icon = "hash",
        Callback = function(text)
            local num = tonumber(text)
            if num then
                autoSellValue = num
            end
        end
    }))
    
    -- Display Jumlah Ikan Saat Ini (Berguna untuk mode Count)
    local CurrentCountDisplay = sellall:Paragraph({ Title = "Current Fish Count: 0", Icon = "package" })
    task.spawn(function() 
        while true do 
            if CurrentCountDisplay and GetPlayerDataReplion() then 
                local count = GetFishCount() 
                CurrentCountDisplay:SetTitle("Current Fish Count: " .. tostring(count)) 
            end 
            task.wait(1) 
        end 
    end)
    
    -- Toggle Tunggal
    local togSell = Reg("tsell",sellall:Toggle({
        Title = "Enable Auto Sell",
        Desc = "Menjalankan auto sell sesuai metode di atas.",
        Value = false,
        Callback = function(state)
            autoSellState = state
            if state then
                if not RF_SellAllItems then
                    WindUI:Notify({ Title = "Error", Content = "Remote Sell tidak ditemukan.", Duration = 3, Icon = "x" })
                    return false
                end
                
                local msg = (autoSellMethod == "Delay") and ("Setiap " .. autoSellValue .. " detik.") or ("Saat jumlah >= " .. autoSellValue)
                RunAutoSellLoop()
            else
                if autoSellThread then task.cancel(autoSellThread) autoSellThread = nil end
            end
        end
    }))
end

-- ==================================== Player Tab ===========================
do
    local player = Window:Tab({
        Title = "Player",
        Icon = "user",
        Locked = false,
    })

    local InfinityJumpConnection = nil
    local DEFAULT_SPEED = 18
    local DEFAULT_JUMP = 50
    
    local InitialHumanoid = GetHumanoid()
    local currentSpeed = DEFAULT_SPEED
    local currentJump = DEFAULT_JUMP

    -- MOVEMENT
    local movement = player:Section({
        Title = "Movement",
        TextSize = 20,
    })

    -- 1. SLIDER WALKSPEED
    local SliderSpeed = Reg("Walkspeed",movement:Slider({
        Title = "WalkSpeed",
        Step = 1,
        Value = {
            Min = 16,
            Max = 200,
            Default = currentSpeed,
        },
        Callback = function(value)
            local speedValue = tonumber(value)
            if speedValue and speedValue >= 0 then
                local Humanoid = GetHumanoid()
                if Humanoid then
                    Humanoid.WalkSpeed = speedValue
                end
            end
        end,
    }))

    -- 2. SLIDER JUMPOWER
    local SliderJump = Reg("slidjump",movement:Slider({
        Title = "JumpPower",
        Step = 1,
        Value = {
            Min = 50,
            Max = 200,
            Default = currentJump,
        },
        Callback = function(value)
            local jumpValue = tonumber(value)
            if jumpValue and jumpValue >= 50 then
                local Humanoid = GetHumanoid()
                if Humanoid then
                    Humanoid.JumpPower = jumpValue
                end
            end
        end,
    }))
    
    -- 3. RESET BUTTON
    local reset = movement:Button({
        Title = "Reset Movement",
        Icon = "rotate-ccw",
        Locked = false,
        Callback = function()
            local Humanoid = GetHumanoid()
            if Humanoid then
                Humanoid.WalkSpeed = DEFAULT_SPEED
                Humanoid.JumpPower = DEFAULT_JUMP
                SliderSpeed:Set(DEFAULT_SPEED)
                SliderJump:Set(DEFAULT_JUMP)
            end
        end
    })

    -- 4. TOGGLE FREEZE PLAYER
    local freezeplr = Reg("frezee",movement:Toggle({
        Title = "Freeze Player",
        Desc = "Membekukan karakter di posisi saat ini (Anti-Push).",
        Value = false,
        Callback = function(state)
            local character = LocalPlayer.Character
            if not character then return end
            
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Set Anchored sesuai status toggle
                hrp.Anchored = state
                
                if state then
                    -- Hentikan momentum agar berhenti instan (tidak meluncur)
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    hrp.Velocity = Vector3.new(0, 0, 0)
                end
            end
        end
    }))

    -- ABILITIES
    local ability = player:Section({
        Title = "Abilities",
        TextSize = 20,
    })

    -- 1. TOGGLE INFINITE JUMP
    local infjump = Reg("infj", ability:Toggle({
        Title = "Infinite Jump",
        Value = false,
        Callback = function(state)
            if state then
                InfinityJumpConnection = UserInputService.JumpRequest:Connect(function()
                    local Humanoid = GetHumanoid()
                    if Humanoid and Humanoid.Health > 0 then
                        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end)
            else
                if InfinityJumpConnection then
                    InfinityJumpConnection:Disconnect()
                    InfinityJumpConnection = nil
                end
            end
        end
    }))

    -- 2. TOGGLE NO CLIP
    local noclipConnection = nil
    local isNoClipActive = false
    local noclip = Reg("nclip",ability:Toggle({
        Title = "No Clip",
        Value = false,
        Callback = function(state)
            isNoClipActive = state

            if state then
                noclipConnection = game:GetService("RunService").Stepped:Connect(function()
                    local character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
                    if isNoClipActive and character then
                        for _, part in ipairs(character:GetDescendants()) do
                            if part:IsA("BasePart") and part.CanCollide then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
            else
                if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end

                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    }))

    -- 3. TOGGLE FLY MODE
    local flyConnection = nil
    local isFlying = false
    local flySpeed = 60
    local bodyGyro, bodyVel
    local flytog = Reg("flym",ability:Toggle({
        Title = "Fly Mode",
        Value = false,
        Callback = function(state)
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            local humanoid = character:WaitForChild("Humanoid")

            if state then
                isFlying = true

                bodyGyro = Instance.new("BodyGyro")
                bodyGyro.P = 9e4
                bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bodyGyro.CFrame = humanoidRootPart.CFrame
                bodyGyro.Parent = humanoidRootPart

                bodyVel = Instance.new("BodyVelocity")
                bodyVel.Velocity = Vector3.zero
                bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bodyVel.Parent = humanoidRootPart

                local cam = workspace.CurrentCamera
                local moveDir = Vector3.zero
                local jumpPressed = false

                UserInputService.JumpRequest:Connect(function()
                    if isFlying then jumpPressed = true task.delay(0.2, function() jumpPressed = false end) end
                end)

                flyConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    if not isFlying or not humanoidRootPart or not bodyGyro or not bodyVel then return end
                    
                    bodyGyro.CFrame = cam.CFrame
                    moveDir = humanoid.MoveDirection

                    if jumpPressed then
                        moveDir = moveDir + Vector3.new(0, 1, 0)
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                        moveDir = moveDir - Vector3.new(0, 1, 0)
                    end

                    if moveDir.Magnitude > 0 then moveDir = moveDir.Unit * flySpeed end

                    bodyVel.Velocity = moveDir
                end)

            else
                isFlying = false

                if flyConnection then flyConnection:Disconnect() flyConnection = nil end
                if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
                if bodyVel then bodyVel:Destroy() bodyVel = nil end
            end
        end
    }))

    -- OTHER
    local other = player:Section({
        Title = "Other",
        TextSize = 20,
    })

    local isHideActive = false
    local hideConnection = nil
    
    local customName = "AutoFishHub"
    local customLevel = "Lvl. 01" 

    local custname = Reg("cfakennme",other:Input({
        Title = "Custom Fake Name",
        Desc = "Nama samaran yang akan muncul di atas kepala player.",
        Value = customName,
        Placeholder = "Hidden User",
        Icon = "user-x",
        Callback = function(text)
            customName = text
        end
    }))

   local custlvl = Reg("cfkelvl",other:Input({
        Title = "Custom Fake Level",
        Desc = "Level samaran (misal: 'Lvl. 100' atau 'Max').",
        Value = customLevel,
        Placeholder = "Lvl. 01",
        Icon = "bar-chart-2",
        Callback = function(text)
            customLevel = text
        end
    }))

    local hideusn = Reg("hideallusr",other:Toggle({
        Title = "Hide All Usernames (Streamer Mode)",
        Value = false,
        Callback = function(state)
            isHideActive = state
            
            -- 1. Atur Visibilitas Leaderboard (PlayerList)
            pcall(function()
                game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, not state)
            end)

            if state then
                -- 2. Loop Agresif (RenderStepped)
                if hideConnection then hideConnection:Disconnect() end
                hideConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    for _, plr in ipairs(game.Players:GetPlayers()) do
                        if plr.Character then
                            -- A. Ubah Humanoid Name (Standard)
                            local hum = plr.Character:FindFirstChild("Humanoid")
                            if hum and hum.DisplayName ~= customName then 
                                hum.DisplayName = customName 
                            end

                            -- B. Ubah Custom UI (BillboardGui) - Logic Deteksi Cerdas
                            for _, obj in ipairs(plr.Character:GetDescendants()) do
                                if obj:IsA("BillboardGui") then
                                    for _, lbl in ipairs(obj:GetDescendants()) do
                                        if lbl:IsA("TextLabel") or lbl:IsA("TextButton") then
                                            if lbl.Visible then
                                                local txt = lbl.Text
                                                
                                                -- LOGIKA DETEKSI:
                                                -- 1. Jika teks mengandung Nama Asli Player -> Ubah jadi Custom Name
                                                if txt:find(plr.Name) or txt:find(plr.DisplayName) then
                                                    if txt ~= customName then
                                                        lbl.Text = customName
                                                    end
                                                
                                                -- 2. Jika teks terlihat seperti Level (angka atau 'Lvl.') -> Ubah jadi Custom Level
                                                -- Regex sederhana: mengecek apakah ada angka atau kata 'Lvl'
                                                elseif txt:match("%d+") or txt:lower():find("lvl") or txt:lower():find("level") then
                                                    -- Hindari mengubah teks UI lain yang bukan level (misal HP bar angka)
                                                    -- Biasanya level teksnya pendek (< 10 karakter)
                                                    if #txt < 15 and txt ~= customLevel then 
                                                        lbl.Text = customLevel
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            else
                if hideConnection then 
                    hideConnection:Disconnect() 
                    hideConnection = nil 
                end
                
                -- Restore Nama Humanoid
                for _, plr in ipairs(game.Players:GetPlayers()) do
                    if plr.Character then
                        local hum = plr.Character:FindFirstChild("Humanoid")
                        if hum then hum.DisplayName = plr.DisplayName end
                    end
                end
            end
        end
    }))

    -- 2. TOGGLE PLAYER ESP
    local runService = game:GetService("RunService")
    local players = game:GetService("Players")
    local STUD_TO_M = 0.28
    local espEnabled = false
    local espConnections = {}

    local function removeESP(targetPlayer)
        if not targetPlayer then return end
        local data = espConnections[targetPlayer]
        if data then
            if data.distanceConn then pcall(function() data.distanceConn:Disconnect() end) end
            if data.charAddedConn then pcall(function() data.charAddedConn:Disconnect() end) end
            if data.billboard and data.billboard.Parent then pcall(function() data.billboard:Destroy() end) end
            espConnections[targetPlayer] = nil
        else
            if targetPlayer.Character then
                for _, v in ipairs(targetPlayer.Character:GetChildren()) do
                    if v.Name == "BloxFishHubESP" and v:IsA("BillboardGui") then pcall(function() v:Destroy() end) end
                end
            end
        end
    end

    local function createESP(targetPlayer)
        if not targetPlayer or not targetPlayer.Character or targetPlayer == LocalPlayer then return end

        removeESP(targetPlayer)
        local char = targetPlayer.Character
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        if not hrp then return end

        local BillboardGui = Instance.new("BillboardGui")
        BillboardGui.Name = "BloxFishHubESP"
        BillboardGui.Adornee = hrp
        BillboardGui.Size = UDim2.new(0, 140, 0, 40)
        BillboardGui.AlwaysOnTop = true
        BillboardGui.StudsOffset = Vector3.new(0, 2.6, 0)
        BillboardGui.Parent = char

        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(1, 0, 1, 0)
        Frame.BackgroundTransparency = 1
        Frame.BorderSizePixel = 0
        Frame.Parent = BillboardGui

        local NameLabel = Instance.new("TextLabel")
        NameLabel.Parent = Frame
        NameLabel.Size = UDim2.new(1, 0, 0.6, 0)
        NameLabel.Position = UDim2.new(0, 0, 0, 0)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = tostring(targetPlayer.DisplayName or targetPlayer.Name)
        NameLabel.TextColor3 = Color3.fromRGB(255, 230, 230)
        NameLabel.TextStrokeTransparency = 0.7
        NameLabel.Font = Enum.Font.GothamBold
        NameLabel.TextScaled = true

        local DistanceLabel = Instance.new("TextLabel")
        DistanceLabel.Parent = Frame
        DistanceLabel.Size = UDim2.new(1, 0, 0.4, 0)
        DistanceLabel.Position = UDim2.new(0, 0, 0.6, 0)
        DistanceLabel.BackgroundTransparency = 1
        DistanceLabel.Text = "0.0 m"
        DistanceLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
        NameLabel.TextStrokeTransparency = 0.85
        DistanceLabel.Font = Enum.Font.GothamSemibold
        DistanceLabel.TextScaled = true

        espConnections[targetPlayer] = { billboard = BillboardGui }

        local distanceConn = runService.RenderStepped:Connect(function()
            if not espEnabled or not hrp or not hrp.Parent then removeESP(targetPlayer) return end
            local localChar = LocalPlayer.Character
            local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")
            if localHRP then
                local distStuds = (localHRP.Position - hrp.Position).Magnitude
                local distMeters = distStuds * STUD_TO_M
                DistanceLabel.Text = string.format("%.1f m", distMeters)
            end
        end)
        espConnections[targetPlayer].distanceConn = distanceConn

        local charAddedConn = targetPlayer.CharacterAdded:Connect(function()
            task.wait(0.8)
            if espEnabled then createESP(targetPlayer) end
        end)
        espConnections[targetPlayer].charAddedConn = charAddedConn
    end

    local espplay = Reg("esp",other:Toggle({
        Title = "Player ESP",
        Value = false,
        Callback = function(state)
            espEnabled = state
            if state then
                for _, plr in ipairs(players:GetPlayers()) do
                    if plr ~= LocalPlayer then createESP(plr) end
                end
                espConnections["playerAddedConn"] = players.PlayerAdded:Connect(function(plr)
                    task.wait(1)
                    if espEnabled then createESP(plr) end
                end)
                espConnections["playerRemovingConn"] = players.PlayerRemoving:Connect(function(plr)
                    removeESP(plr)
                end)
            else
                for plr, _ in pairs(espConnections) do
                    if plr and typeof(plr) == "Instance" then removeESP(plr) end
                end
                if espConnections["playerAddedConn"] then espConnections["playerAddedConn"]:Disconnect() end
                if espConnections["playerRemovingConn"] then espConnections["playerRemovingConn"]:Disconnect() end
                espConnections = {}
            end
        end
    }))

    local respawnin = other:Button({
        Title = "Reset Character (In Place)",
        Icon = "refresh-cw",
        Callback = function()
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if not character or not hrp or not humanoid then
                WindUI:Notify({ Title = "Gagal Reset", Content = "Karakter tidak ditemukan!", Duration = 3, Icon = "x", })
                return
            end

            local lastPos = hrp.Position

            WindUI:Notify({ Title = "Reset Character...", Content = "Respawning di posisi yang sama...", Duration = 2, Icon = "rotate-cw", })
            humanoid:TakeDamage(999999)

            LocalPlayer.CharacterAdded:Wait()
            task.wait(0.5)
            local newChar = LocalPlayer.Character
            local newHRP = newChar:WaitForChild("HumanoidRootPart", 5)

            if newHRP then
                newHRP.CFrame = CFrame.new(lastPos + Vector3.new(0, 3, 0))
                WindUI:Notify({ Title = "Character Reset Sukses!", Content = "Kamu direspawn di posisi yang sama ✅", Duration = 3, Icon = "check", })
            else
                WindUI:Notify({ Title = "Gagal Reset", Content = "HumanoidRootPart baru tidak ditemukan.", Duration = 3, Icon = "x", })
            end
        end
    })
end


-- ==================================== automation Tab ===========================
local automatic = Window:Tab({
    Title = "Automatic",
    Icon = "loader",
    Locked = false,
})

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
            WindUI:Notify({ Title = "Weather Buy Error", Content = "Remote RF/PurchaseWeatherEvent tidak ditemukan setelah coba agresif!", Duration = 5, Icon = "x" })
            AutoWeatherState = false
            return
        end
    end
    
    if AutoWeatherThread then task.cancel(AutoWeatherThread) end
    
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
        local toggle = shop:GetElementByTitle("Enable Auto Buy Weather")
        if toggle and toggle.Set then toggle:Set(false) end
    end)
end

-- 3. UI UNTUK AUTO BUY WEATHER
local weathershop = automatic:Section({ Title = "Auto Buy Weather", TextSize = 20, })

local WeatherDropdown = Reg("weahterd", weathershop:Dropdown({
    Title = "Select Weather Type",
    Values = WeatherList,
    Value = SelectedWeatherTypes, -- Menggunakan tabel
    Multi = true, -- UBAH MENJADI MULTI SELECTION
    AllowNone = false,
    Callback = function(selected)
        SelectedWeatherTypes = selected or {} -- Ambil daftar yang dipilih
        if #SelectedWeatherTypes == 0 then
            -- Jika tidak ada yang dipilih, kembalikan ke nilai default pertama
            SelectedWeatherTypes = { WeatherList[1] }
        end
        if AutoWeatherState then
            -- Jika sedang aktif, restart loop dengan weather baru
            RunAutoBuyWeatherLoop(SelectedWeatherTypes)
        end
    end
}))

local ToggleAutoBuy = Reg("shopweath",weathershop:Toggle({
    Title = "Enable Auto Buy Weather",
    Value = false,
    Callback = function(state)
        AutoWeatherState = state
        if state then
            if #SelectedWeatherTypes == 0 then
                -- NOTIFIKASI ERROR: Belum memilih Weather
                WindUI:Notify({ Title = "Error", Content = "Pilih minimal satu jenis Weather terlebih dahulu.", Duration = 3, Icon = "x" })
                AutoWeatherState = false
                return false
            end
            RunAutoBuyWeatherLoop(SelectedWeatherTypes)
            
        else
            if AutoWeatherThread then task.cancel(AutoWeatherThread) end
            -- NOTIFIKASI WARNING: Auto Buy Dimatikan
            WindUI:Notify({ Title = "Auto Weather", Content = "Auto Buy dimatikan.", Duration = 3, Icon = "x" })
        end
    end
}))

-- ==================================== automation Tab ===========================
do
    local teleport = Window:Tab({
        Title = "Teleport",
        Icon = "map-pin",
        Locked = false,
    })

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


    -- =================================================================
    -- A. TELEPORT KE PEMAIN (Button)
    -- =================================================================
    local teleplay = teleport:Section({
        Title = "Teleport to Player",
        TextSize = 20,
    })

    local PlayerDropdown = teleplay:Dropdown({
        Title = "Select Target Player",
        Values = GetPlayerListOptions(),
        AllowNone = true,
        Callback = function(name)
            selectedTargetPlayer = name
        end
    })

    local listplaytel = teleplay:Button({
        Title = "Refresh Player List",
        Icon = "refresh-ccw",
        Callback = function()
            local newOptions = GetPlayerListOptions()
            pcall(function() PlayerDropdown:Refresh(newOptions) end)
            task.wait(0.1)
            pcall(function() PlayerDropdown:Set(false) end)
            selectedTargetPlayer = nil
            WindUI:Notify({ Title = "List Diperbarui", Content = string.format("%d pemain ditemukan.", #newOptions), Duration = 2, Icon = "check" })
        end
    })

    local teletoplay = teleplay:Button({
        Title = "Teleport to Player (One-Time)",
        Content = "Teleport satu kali ke lokasi pemain yang dipilih.",
        Icon = "corner-down-right",
        Callback = function()
            local hrp = GetHRP()
            local targetHRP = GetTargetHRP(selectedTargetPlayer)
            
            if not selectedTargetPlayer then
                WindUI:Notify({ Title = "Error", Content = "Pilih pemain target terlebih dahulu.", Duration = 3, Icon = "alert-triangle" })
                return
            end

            if hrp and targetHRP then
                -- Teleport 5 unit di atas target
                local targetPos = targetHRP.Position + Vector3.new(0, 5, 0)
                local lookVector = (targetHRP.Position - hrp.Position).Unit 
                
                hrp.CFrame = CFrame.new(targetPos, targetPos + lookVector)
                
                WindUI:Notify({ Title = "Teleport Sukses", Content = "Teleported ke " .. selectedTargetPlayer, Duration = 3, Icon = "user-check" })
            else
                 WindUI:Notify({ Title = "Error", Content = "Gagal menemukan target atau karakter Anda.", Duration = 3, Icon = "x" })
            end
        end
    })

    -- =================================================================
    -- B. TELEPORT KE AREA (Button)
    -- =================================================================
    
    local telearea = teleport:Section({
        Title = "Teleport to Fishing Area",
        TextSize = 20,
    })

    local AreaDropdown = telearea:Dropdown({
        Title = "Select Target Area",
        Values = AreaNames, -- Menggunakan variabel AreaNames dari Fishing Tab
        AllowNone = true,
        Callback = function(name)
            selectedTargetArea = name
        end
    })

    local butelearea = telearea:Button({
        Title = "Teleport to Area (One-Time)",
        Content = "Teleport satu kali ke area yang dipilih.",
        Icon = "corner-down-right",
        Callback = function()
            if not selectedTargetArea or not FishingAreas[selectedTargetArea] then
                WindUI:Notify({ Title = "Error", Content = "Pilih area target terlebih dahulu.", Duration = 3, Icon = "alert-triangle" })
                return
            end
            
            local areaData = FishingAreas[selectedTargetArea]
            pos_saved = areaData.cframe look_saved = areaData.lookup
            
            TeleportToLookAt()
        end
    })
end

-- ==================================== Webhook Tab ===========================
do
    local webhook = Window:Tab({
        Title = "Webhook",
        Icon = "send",
        Locked = false,
    })

    -- Variabel lokal untuk menyimpan data
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
                local title_private = string.format("<:TEXTURENOBG:1438662703722790992> BloxFishHub | Webhook\n\n<a:ChipiChapa:1438661193857503304> New Fish Caught! (%s)", fishName)
                
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
                
                local title_global = string.format("<:TEXTURENOBG:1438662703722790992> BloxFishHub | Global Tracker\n\n<a:globe:1438758633151266818> GLOBAL CATCH! %s", fishName)

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
                        text = string.format("BloxFishHub Community| Player: %s | %s", censoredPlayerName, os.date("%Y-%m-%d %H:%M:%S"))
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
    

    -- =================================================================
    -- UI IMPLEMENTATION (LANJUTAN)
    -- =================================================================

   local inputweb = Reg("inptweb",webhook:Input({
        Title = "Discord Webhook URL",
        Desc = "URL tempat notifikasi akan dikirim.",
        Value = "",
        Placeholder = "https://discord.com/api/webhooks/...",
        Icon = "link",
        Type = "Input",
        Callback = function(input)
            WEBHOOK_URL = input
        end
    }))

    webhook:Divider()
    
   local ToggleNotif = Reg("tweb",webhook:Toggle({
        Title = "Enable Fish Notifications",
        Desc = "Aktifkan/nonaktifkan pengiriman notifikasi ikan.",
        Value = false,
        Icon = "cloud-upload",
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
    }))

    local dwebname = Reg("drweb", webhook:Dropdown({
        Title = "Filter by Specific Name",
        Desc = "Notifikasi khusus untuk nama ikan tertentu",
        Values = getWebhookItemOptions(),
        Value = SelectedWebhookItemNames,
        Multi = true,
        AllowNone = true,
        Callback = function(names)
            SelectedWebhookItemNames = names or {} 
        end
    }))

    local dwebrar = Reg("rarwebd", webhook:Dropdown({
        Title = "Rarity to Notify",
        Desc = "Hanya notifikasi ikan rarity yang dipilih.",
        Values = RarityList, -- Menggunakan list yang sudah distandarisasi
        Value = SelectedRarityCategories,
        Multi = true,
        AllowNone = true,
        Callback = function(categories)
            SelectedRarityCategories = {}
            for _, cat in ipairs(categories or {}) do
                table.insert(SelectedRarityCategories, cat:upper()) 
            end
        end
    }))

    WebhookStatusParagraph = webhook:Paragraph({
        Title = "Webhook Status",
        Content = "Aktifkan 'Enable Fish Notifications' untuk mulai mendengarkan tangkapan ikan.",
        Icon = "info",
    })
    

    local teswebbut = webhook:Button({
        Title = "Test Webhook ",
        Icon = "send",
        Desc = "Mengirim Webhook Test",
        Callback = function()
            if WEBHOOK_URL == "" then
                WindUI:Notify({ Title = "Error", Content = "Masukkan URL Webhook terlebih dahulu.", Duration = 3, Icon = "alert-triangle" })
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
                 WindUI:Notify({ Title = "Test Sukses!", Content = "Cek channel Discord Anda. " .. message, Duration = 4, Icon = "check" })
            else
                 WindUI:Notify({ Title = "Test Gagal!", Content = "Cek console (Output) untuk error. " .. message, Duration = 5, Icon = "x" })
            end
        end
    })
end

-- ==================================== Setting Tab ===========================
do
    local SettingsTab = Window:Section({
        Title = "Configuration",
        Icon = "settings",
        Locked = false,
    })
    
    local isBoostActive = false
    local originalLightingValues = {}
    
    local function ToggleFPSBoost(enabled)
        isBoostActive = enabled
        local Lighting = game:GetService("Lighting")
        local Terrain = workspace:FindFirstChildOfClass("Terrain")
    
        if enabled then
            -- Simpan nilai asli sekali saja
            if not next(originalLightingValues) then
                originalLightingValues.GlobalShadows = Lighting.GlobalShadows
                originalLightingValues.FogEnd = Lighting.FogEnd
                originalLightingValues.Brightness = Lighting.Brightness
                originalLightingValues.ClockTime = Lighting.ClockTime
                originalLightingValues.Ambient = Lighting.Ambient
                originalLightingValues.OutdoorAmbient = Lighting.OutdoorAmbient
            end
            
            -- 1. VISUAL & EFEK (Hanya mematikan)
            pcall(function()
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Explosion") then
                        v.Enabled = false
                    elseif v:IsA("Beam") or v:IsA("Light") then
                        v.Enabled = false
                    elseif v:IsA("Decal") or v:IsA("Texture") then
                        v.Transparency = 1 
                    end
                end
            end)
            
            -- 2. LIGHTING & ENVIRONMENT (Pengaturan Minimalis)
            pcall(function()
                for _, effect in pairs(Lighting:GetChildren()) do
                    if effect:IsA("PostEffect") then effect.Enabled = false end
                end
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 9e9
                Lighting.Brightness = 0 -- Lebih gelap/kontras untuk efisiensi
                Lighting.ClockTime = 14 -- Siang tanpa bayangan
                Lighting.Ambient = Color3.new(0, 0, 0)
                Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
            end)
            
            -- 3. TERRAIN & WATER
            if Terrain then
                pcall(function()
                    Terrain.WaterWaveSize = 0
                    Terrain.WaterWaveSpeed = 0
                    Terrain.WaterReflectance = 0
                    Terrain.WaterTransparency = 1
                    Terrain.Decoration = false
                end)
            end
            
            -- 4. QUALITY & EXPLOIT TRICKS
            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
                settings().Rendering.TextureQuality = Enum.TextureQuality.Low
            end)
    
            if type(setfpscap) == "function" then pcall(function() setfpscap(100) end) end 
            if type(collectgarbage) == "function" then collectgarbage("collect") end
        else
            -- RESET
            pcall(function()
                if originalLightingValues.GlobalShadows ~= nil then
                    Lighting.GlobalShadows = originalLightingValues.GlobalShadows
                    Lighting.FogEnd = originalLightingValues.FogEnd
                    Lighting.Brightness = originalLightingValues.Brightness
                    Lighting.ClockTime = originalLightingValues.ClockTime
                    Lighting.Ambient = originalLightingValues.Ambient
                    Lighting.OutdoorAmbient = originalLightingValues.OutdoorAmbient
                end
                settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
                
                for _, effect in pairs(Lighting:GetChildren()) do
                    if effect:IsA("PostEffect") then effect.Enabled = true end
                end
            end)
            
            if type(setfpscap) == "function" then pcall(function() setfpscap(60) end) end
        end
    end
    
    -- Tambahkan di bagian atas blok 'utility'
    local VFXControllerModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Controllers").VFXController)
    local originalVFXHandle = VFXControllerModule.Handle
    local originalPlayVFX = VFXControllerModule.PlayVFX.Fire -- Asumsi PlayVFX adalah Signal/Event yang memiliki Fire
    
    -- Variabel global untuk status VFX
    local isVFXDisabled = false
    
    local CutsceneController = nil
    local OldPlayCutscene = nil
    local isNoCutsceneActive = false
    
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
    
    local miscSelection = SettingsTab:Tab({
        Title = "MISC",
        TextSize = 20,
    })
    
    local miscS = miscSelection:Section({
        Title = "MISC",
        TextSize = 20,
    })
    
    local tskin = Reg("toggleskin", miscS:Toggle({
        Title = "Remove Skin Effect",
        Value = false,
        Icon = "slash",
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
    }))
    
    local tcutscen = Reg("tnocut",miscS:Toggle({
        Title = "No Cutscene",
        Value = false,
        Icon = "film", -- Icon film strip
        Callback = function(state)
            isNoCutsceneActive = state
            
            if not CutsceneController then
                WindUI:Notify({ Title = "Gagal Hook", Content = "Module CutsceneController tidak ditemukan.", Duration = 3, Icon = "x" })
                return
            end
        end
    }))
    
    local tfps = Reg("togfps",miscS:Toggle({
        Title = "FPS Ultra Boost",
        Value = false,
        Callback = function(state)
            ToggleFPSBoost(state)
        end
    }))
    
    local t3d = Reg("t3drend",miscS:Toggle({
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
    }))
    
    local utilitySection = miscSelection:Section({
        Title = "Utility",
        TextSize = 20,
    })
    
    local RF_UnequipOxygenTank = GetRemote("RF/UnequipOxygenTank")
    local RF_EquipOxygenTank = GetRemote("RF/EquipOxygenTank")
    local RF_UpdateFishingRadar = GetRemote("RF/UpdateFishingRadar")
    
    local defaultMaxZoom = LocalPlayer.CameraMaxZoomDistance or 128
    local zoomLoopConnection = nil
    
    local equipRadar = Reg("EqRadar", utilitySection:Toggle({
        Title = "Bypass Radar",
        Value = false,
        Callback = function(state)
            RF_UpdateFishingRadar:InvokeServer(state)
        end
    }))
    
    local equipOxygen = Reg("EqOxygen", utilitySection:Toggle({
        Title = "Bypass Oksigen",
        Value = false,
        Callback = function(state)
            if state then
                RF_EquipOxygenTank:InvokeServer(105)
            else
                RF_UnequipOxygenTank:InvokeServer()
            end
        end
    }))
    
    local tzoom = Reg("infzoom", utilitySection:Toggle({
        Title = "Infinite Zoom Out",
        Value = false,
        Icon = "maximize",
        Callback = function(state)
            if state then
                -- 1. Simpan nilai asli dulu buat jaga-jaga
                defaultMaxZoom = LocalPlayer.CameraMaxZoomDistance
                
                -- 2. Paksa nilai zoom jadi besar
                LocalPlayer.CameraMaxZoomDistance = 100000
                
                -- 3. Pasang loop (RenderStepped) untuk memaksa nilai tetap besar
                -- Ini berguna kalau game mencoba mengembalikan zoom ke normal
                if zoomLoopConnection then zoomLoopConnection:Disconnect() end
                zoomLoopConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    LocalPlayer.CameraMaxZoomDistance = 100000
                end)
            else
                -- 1. Matikan loop pemaksa
                if zoomLoopConnection then 
                    zoomLoopConnection:Disconnect() 
                    zoomLoopConnection = nil
                end
                
                -- 2. Kembalikan ke nilai asli
                LocalPlayer.CameraMaxZoomDistance = defaultMaxZoom
            end
        end
    }))
    
    -- =================================================================
    -- 🎥 CINEMATIC / CONTENT TOOLS (V11 - CLEAN MODE FIX)
    -- =================================================================
    local cinematic = miscSelection:Section({ Title = "Cinematic / Content Tools", TextSize = 20})
    
    -- Services
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local StarterGui = game:GetService("StarterGui")
    local Workspace = game:GetService("Workspace")
    
    -- Modules
    local LocalPlayer = Players.LocalPlayer
    
    -- Settings & State
    local freeCamSpeed = 1.5
    local freeCamFov = 70
    local isFreeCamActive = false
    
    local camera = Workspace.CurrentCamera
    local camPos = camera.CFrame.Position
    local camRot = Vector2.new(0,0)
    
    -- Manual Mouse Vars
    local lastMousePos = Vector2.new(0,0)
    local renderConn = nil
    local touchConn = nil
    local touchDelta = Vector2.new(0, 0)
    
    -- Restore
    local oldWalkSpeed = 16
    local oldJumpPower = 50
    
    -- 1. SLIDER CAMERA SPEED
    local cameras = cinematic:Slider({
        Title = "Camera Speed",
        Step = 0.1,
        Value = { Min = 0.1, Max = 10.0, Default = 1.5 },
        Callback = function(val) 
            freeCamSpeed = tonumber(val) 
        end
    })
    
    -- 2. SLIDER FOV
    local fovcam = cinematic:Slider({
        Title = "Field of View (FOV)",
        Desc = "Zoom In/Out Lens.",
        Step = 1,
        Value = { Min = 10, Max = 120, Default = 70 },
        Callback = function(val) 
            freeCamFov = tonumber(val)
            if isFreeCamActive then 
                camera.FieldOfView = freeCamFov 
            end
        end
    })
    
    -- 3. TOGGLE CLEAN MODE (FIXED LOGIC)
    local hideuiall = cinematic:Toggle({
        Title = "Hide All UI (Clean Mode)",
        Value = false,
        Icon = "eye-off",
        Callback = function(state)
            local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
            
            if state then
                -- [LOGIKA FIX]: Simpan state asli sebelum dimatikan
                for _, gui in ipairs(PlayerGui:GetChildren()) do
                    if gui:IsA("ScreenGui") and gui.Name ~= "WindUI" and gui.Name ~= "CustomFloatingIcon_BloxFishHub" then
                        -- Simpan status 'Enabled' saat ini ke Attribute
                        gui:SetAttribute("OriginalState", gui.Enabled)
                        gui.Enabled = false
                    end
                end
                -- Matikan CoreGui (Chat, Leaderboard)
                pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
            else
                -- [LOGIKA FIX]: Restore sesuai state asli
                for _, gui in ipairs(PlayerGui:GetChildren()) do
                    if gui:IsA("ScreenGui") then
                        local originalState = gui:GetAttribute("OriginalState")
                        if originalState ~= nil then
                            gui.Enabled = originalState
                            gui:SetAttribute("OriginalState", nil) -- Bersihkan attribute
                        end
                    end
                end
                -- Nyalakan CoreGui
                pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
            end
        end
    })
    
    -- 4. FREE CAM (MANUAL TRACKING - YANG UDAH WORK)
    local enablecam = cinematic:Toggle({
        Title = "Enable Free Cam",
        Value = false,
        Icon = "video",
        Callback = function(state)
            isFreeCamActive = state
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
            if state then
                -- INIT
                camera.CameraType = Enum.CameraType.Scriptable
                camPos = camera.CFrame.Position
                local rx, ry, _ = camera.CFrame:ToEulerAnglesYXZ()
                camRot = Vector2.new(rx, ry)
                
                -- INITIAL MOUSE POS
                lastMousePos = UserInputService:GetMouseLocation()
    
                -- FREEZE CHARACTER
                if hum then
                    oldWalkSpeed = hum.WalkSpeed
                    oldJumpPower = hum.JumpPower
                    hum.WalkSpeed = 0
                    hum.JumpPower = 0
                    hum.PlatformStand = true
                end
                if hrp then hrp.Anchored = true end
    
                -- TOUCH LISTENER (MOBILE)
                if touchConn then touchConn:Disconnect() end
                touchConn = UserInputService.TouchMoved:Connect(function(input, processed)
                    if not processed then touchDelta = input.Delta end
                end)
    
                -- [UPDATE] FREECAM RENDER LOOP (MOBILE SUPPORT)
                local ControlModule = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
    
                if renderConn then renderConn:Disconnect() end
                renderConn = RunService.RenderStepped:Connect(function()
                    if not isFreeCamActive then return end
    
                    -- A. ROTASI KAMERA (Touch/Mouse)
                    local currentMousePos = UserInputService:GetMouseLocation()
                    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                        local deltaX = currentMousePos.X - lastMousePos.X
                        local deltaY = currentMousePos.Y - lastMousePos.Y
                        local sens = 0.003
                        
                        camRot = camRot - Vector2.new(deltaY * sens, deltaX * sens)
                        camRot = Vector2.new(math.clamp(camRot.X, -1.55, 1.55), camRot.Y)
                    end
                    
                    -- Mobile Touch Drag
                    if UserInputService.TouchEnabled then
                        camRot = camRot - Vector2.new(touchDelta.Y * 0.005 * 2.0, touchDelta.X * 0.005 * 2.0)
                        camRot = Vector2.new(math.clamp(camRot.X, -1.55, 1.55), camRot.Y)
                        touchDelta = Vector2.new(0, 0)
                    end
                    
                    lastMousePos = currentMousePos
    
                    -- B. PERGERAKAN (KEYBOARD + ANALOG MOBILE)
                    local rotCFrame = CFrame.fromEulerAnglesYXZ(camRot.X, camRot.Y, 0)
                    local moveVector = Vector3.zero
    
                    -- 1. Ambil Input dari Control Module (Support WASD & Mobile Analog sekaligus)
                    local rawMoveVector = ControlModule:GetMoveVector()
                    
                    -- 2. Input Keyboard Manual (untuk vertical E/Q)
                    local verticalInput = 0
                    if UserInputService:IsKeyDown(Enum.KeyCode.E) then verticalInput = 1 end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then verticalInput = -1 end
    
                    -- 3. Kalkulasi Arah (World Space)
                    -- rawMoveVector.X adalah Kanan/Kiri (Relative Camera)
                    -- rawMoveVector.Z adalah Maju/Mundur (Relative Camera)
                    
                    -- Konversi ke arah kamera saat ini
                    if rawMoveVector.Magnitude > 0 then
                        moveVector = (rotCFrame.RightVector * rawMoveVector.X) + (rotCFrame.LookVector * rawMoveVector.Z * -1)
                    end
                    
                    -- Tambah gerakan Vertikal
                    moveVector = moveVector + Vector3.new(0, verticalInput, 0)
    
                    -- 4. Kecepatan (Shift untuk ngebut)
                    local speedMultiplier = (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 4 or 1)
                    local finalSpeed = freeCamSpeed * speedMultiplier
                    
                    -- 5. Terapkan Posisi
                    if moveVector.Magnitude > 0 then
                        camPos = camPos + (moveVector * finalSpeed)
                    end
    
                    -- C. UPDATE KAMERA
                    camera.CFrame = CFrame.new(tcamPos) * rotCFrame
                    camera.FieldOfView = freeCamFov 
                end)
    
            else
                -- MATIKAN
                if renderConn then renderConn:Disconnect() renderConn = nil end
                if touchConn then touchConn:Disconnect() touchConn = nil end
                
                camera.CameraType = Enum.CameraType.Custom
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                camera.FieldOfView = 70 
    
                if hum then
                    hum.WalkSpeed = oldWalkSpeed
                    hum.JumpPower = oldJumpPower
                    hum.PlatformStand = false
                end
                if hrp then hrp.Anchored = false end
            end
        end
    })
    
    local ConfigSection = SettingsTab:Tab({
        Title = "Config Manager",
        TextSize = 20,
    })
    
    -- Variabel Lokal
    local ConfigManager = Window.ConfigManager
    
    
    -- Helper: Update Dropdown
    local function RefreshConfigList(dropdown)
        local list = ConfigManager:AllConfigs()
        if #list == 0 then list = {"None"} end
        pcall(function() dropdown:Refresh(list) end)
    end
    
    local ConfigNameInput = ConfigSection:Input({
        Title = "Config Name",
        Desc = "Nama config baru/yang akan disimpan.",
        Value = "AutoFish",
        Placeholder = "e.g. LegitFarming",
        Icon = "file-pen",
        Callback = function(text)
            SelectedConfigName = text
        end
    })
    
    local ConfigDropdown = ConfigSection:Dropdown({
        Title = "Available Configs",
        Desc = "Pilih file config yang ada.",
        Values = ConfigManager:AllConfigs() or {"None"},
        Value = "AutoFish",
        AllowNone = true,
        Callback = function(val)
            if val and val ~= "None" then
                SelectedConfigName = val
                ConfigNameInput:Set(val)
            end
        end
    })
    
    ConfigSection:Button({
        Title = "Refresh List",
        Icon = "refresh-ccw",
        Callback = function() RefreshConfigList(ConfigDropdown) end
    })
    
    ConfigSection:Divider()
    
    -- [FIXED] SAVE BUTTON
    ConfigSection:Button({
        Title = "Save Config",
        Desc = "Simpan settingan saat ini.",
        Icon = "save",
        Color = Color3.fromRGB(0, 255, 127),
        Callback = function()
            if RockHubConfig:Save() then
                WindUI:Notify({ Title = "Saved!", Content = "Config: " .. SelectedConfigName, Duration = 2, Icon = "check" })
            end
            RefreshConfigList(ConfigDropdown)
        end
    })
    
    -- [FIXED SMART LOAD] LOAD BUTTON
    ConfigSection:Button({
        Title = "Load Config",
        Icon = "download",
        Callback = function()
            if RockHubConfig:Load() then
                WindUI:Notify({ Title = "Load!", Content = "Config: " .. SelectedConfigName, Duration = 2, Icon = "check" })
            end
        end
    })
    
    -- DELETE BUTTON
    ConfigSection:Button({
        Title = "Delete Config",
        Icon = "trash-2",
        Color = Color3.fromRGB(255, 80, 80),
        Callback = function()
            Window.CurrentConfig = ConfigManager:Config(SelectedConfigName)
            if Window.CurrentConfig:Delete() then
                WindUI:Notify({ Title = "Deleted", Content = SelectedConfigName .. " dihapus.", Duration = 2, Icon = "trash" })
            else
                WindUI:Notify({ Title = "Error", Content = "File tidak ditemukan.", Duration = 3, Icon = "x" })
            end
            RefreshConfigList(ConfigDropdown)
        end
    })
end

local panelNetwork = Window:Tab({
    Title = "Network",
    Icon = "network",
})

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
    
    WindUI:Notify({
        Title = "Monitor Enabled",
        Content = "Performance monitor is now active.",
        Duration = 2,
        Icon = "activity"
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
    
    WindUI:Notify({
        Title = "Monitor Disabled",
        Content = "Performance monitor has been disabled.",
        Duration = 2,
        Icon = "activity"
    })
end

panelNetwork:Toggle({
    Title = "Show Performance Monitor",
    Icon = "activity",
    Value = false,
    Callback = function(state)
        if state then
            EnableMonitor()
        else
            DisableMonitor()
        end
    end
})


-- Auto Reload Icon saat Respawn
game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
    OnCharacterAdded(char)
end)
