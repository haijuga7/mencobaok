-- Gunakan dengan risiko sendiri

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Load WindUI Library dengan error handling
local WindUI
local LoadSuccess, LoadError = pcall(function()
    WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()
end)

if not LoadSuccess or not WindUI then
    warn("❌ WindUI gagal dimuat: " .. tostring(LoadError))
    warn("🔄 Mencoba URL alternatif...")
    
    -- Coba URL alternatif
    local success2, error2 = pcall(function()
        WindUI = loadstring(game:HttpGet("https://pastebin.com/raw/s5ybragX"))()
    end)
    
    if not success2 or not WindUI then
        error("❌ Tidak dapat memuat WindUI library. Error: " .. tostring(error2))
        return
    end
end

-- ================= ANIMATION CONTROL (NO RESPAWN NEEDED) ====================
local disableAnimations = false
local originalAnimateScript = nil
local animationConnections = {}

-- Fungsi untuk menyimpan script Animate original
local function saveOriginalAnimate(character)
    local animateScript = character:FindFirstChild("Animate")
    if animateScript and not originalAnimateScript then
        originalAnimateScript = animateScript:Clone()
    end
end

-- Fungsi untuk menghentikan semua animasi
local function stopAllAnimations(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                track:Stop()
                track:Destroy()
            end
        end
        
        local animateScript = character:FindFirstChild("Animate")
        if animateScript then
            animateScript.Disabled = true
            task.wait(0.1)
            animateScript:Destroy()
        end
    end
end

-- Fungsi untuk mengembalikan animasi (TANPA RESPAWN)
local function restoreAnimations(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Hapus Animate script yang rusak jika ada
    local oldAnimate = character:FindFirstChild("Animate")
    if oldAnimate then
        oldAnimate:Destroy()
    end
    
    -- Clone dan pasang kembali script Animate original
    if originalAnimateScript then
        local newAnimate = originalAnimateScript:Clone()
        newAnimate.Parent = character
        newAnimate.Disabled = false
        
        -- Tunggu script active
        task.wait(0.2)
        
        -- Force reload animator
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            -- Trigger animasi idle untuk "restart" animator
            humanoid:ChangeState(Enum.HumanoidStateType.Landed)
        end
    end
end

-- Fungsi untuk setup disable animasi pada character
local function setupCharacter(character)
    -- Simpan original animate script pertama kali
    saveOriginalAnimate(character)
    
    if not disableAnimations then return end
    
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    
    task.wait(0.1)
    stopAllAnimations(character)
    
    -- Monitor dan block animasi baru
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        local connection = animator.AnimationPlayed:Connect(function(track)
            if disableAnimations then
                track:Stop()
                track:Destroy()
            end
        end)
        table.insert(animationConnections, connection)
    end
end

-- Fungsi untuk disconnect semua connection
local function cleanupConnections()
    for _, conn in pairs(animationConnections) do
        if conn then conn:Disconnect() end
    end
    animationConnections = {}
end

-- Fungsi utama untuk toggle animasi (NO RESPAWN)
local function toggleAnimations(state)
    disableAnimations = not state
    
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    
    if character then
        if disableAnimations then
            -- Disable animasi
            stopAllAnimations(character)
            setupCharacter(character)
        else
            -- Enable animasi (TANPA RESPAWN!)
            cleanupConnections()
            restoreAnimations(character)
        end
    end
end

-- Setup character
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Simpan original animate dari character pertama
if player.Character then
    saveOriginalAnimate(player.Character)
    setupCharacter(player.Character)
end

-- Cache remote paths untuk performa lebih baik
local NET_PATH = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
local CANCEL_FISHING = NET_PATH["RF/CancelFishingInputs"]
local CHARGE_ROD = NET_PATH["RF/ChargeFishingRod"]
local REQUEST_MINIGAME = NET_PATH["RF/RequestFishingMinigameStarted"]
local FISHING_COMPLETED = NET_PATH["RE/FishingCompleted"]
local UPDOK = NET_PATH["RF/UpdateAutoFishingState"]

local CAUGHT_FISH_VISUAL = NET_PATH["RE/CaughtFishVisual"]
local FISH_CAUGHT = NET_PATH["RE/FishCaught"]
local FISH_NOTIF = NET_PATH["RE/ObtainedNewFishNotification"]
local DSM = NET_PATH["RE/DisplaySystemMessage"]

-- Variabel delay
local minigameDelay = 1.3
local cycleDelay = 0.1
local recass = 0.3

-- Variabel kontrol
local active = false
local autoFishThread = nil
local weather = nil
local charge = false
local aRod = false
local fishMode = "Instant"
local CurrentTrack = nil
local savedLoc = nil

local originalFireServer = nil
local originalConnect = nil

local testFish = nil
local respawnloop = false

-- ========
local FDY = nil
local CDY = nil
local RDY = nil

local numWalk = 16
local infjumpstate = false
local infjumpconn = nil

-- Fungsi Auto Fish
local function autoFish()
    local success, err = pcall(function()
        CHARGE_ROD:InvokeServer(1, 0.999)
        if charge then
            task.wait(0.25)
        end
        REQUEST_MINIGAME:InvokeServer(1, 0.999)
        task.wait(minigameDelay)
        FISHING_COMPLETED:FireServer()
        task.wait(recass)
        CANCEL_FISHING:InvokeServer()
    end)
    
    if not success then
        warn("⚠️ Auto Fish Error: " .. tostring(err))
    end
end

local function blatantFishv1()
    local success, err = pcall(function()
        task.spawn(function()
            CHARGE_ROD:InvokeServer(1, 0.999)
            if charge then
                task.wait(0.25)
            end
            REQUEST_MINIGAME:InvokeServer(1, 0.999)
            task.wait(minigameDelay)
            FISHING_COMPLETED:FireServer()
            task.wait(recass)
            CANCEL_FISHING:InvokeServer()
        end)
    end)
    
    if not success then
        warn("⚠️ Auto Fish Error: " .. tostring(err))
    end
end

local function blatantFishv2()
    local success, err = pcall(function()
        task.spawn(function()
            CHARGE_ROD:InvokeServer(1, 0.999)
            if charge then
                task.wait(0.25)
            end
            REQUEST_MINIGAME:InvokeServer(1, 0.999)
        end)
        task.spawn(function()
            task.wait(minigameDelay)
            FISHING_COMPLETED:FireServer()
            task.wait(recass)
            CANCEL_FISHING:InvokeServer()
        end)
    end)
    
    if not success then
        warn("⚠️ Auto Fish Error: " .. tostring(err))
    end
end

-- Fungsi untuk memulai auto fish (FIXED)
-- Fungsi untuk memulai auto fish (DIPERBAIKI)
local function startAutoFish()
    if autoFishThread then 
        warn("⚠️ Auto Fish sudah berjalan!")
        return 
    end
    
    game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipToolFromHotbar"]:FireServer(1)
    
    local CHAR = player.Character or player.CharacterAdded:Wait()
    local HUMAN = CHAR:WaitForChild("Humanoid", 10)
    
    -- Hentikan animasi lama jika ada
    if CurrentTrack then
        CurrentTrack:Stop()
        CurrentTrack:Destroy()
    end
    
    -- Muat animasi baru
    local ANIMATION = Instance.new("Animation")
    ANIMATION.AnimationId = "rbxassetid://114959536562596"
    
    CurrentTrack = HUMAN:LoadAnimation(ANIMATION)
    CurrentTrack.Looped = true
    CurrentTrack:Play()
    
    autoFishThread = task.spawn(function()
        print("✅ Auto Fish Thread Started")
        UPDOK:InvokeServer(false)
        
        while active do
            if fishMode == "Instant" then
                autoFish()
            elseif fishMode == "Blatant v1" then
                blatantFishv1()
            else
                blatantFishv2()
            end
            
            task.wait(cycleDelay)
        end
        
        print("⏹️ Auto Fish Thread Stopped")
        autoFishThread = nil
    end)
end

-- Fungsi untuk menghentikan auto fish (DIPERBAIKI)
local function stopAutoFish()
    active = false
    
    -- Hentikan animasi
    if CurrentTrack then
        CurrentTrack:Stop()
        CurrentTrack:Destroy()
        CurrentTrack = nil
    end
    
    -- Tunggu thread selesai
    if autoFishThread then
        task.wait(0.5)
        autoFishThread = nil
    end
end

-- Fungsi validasi input number
local function validateNumber(value, min, max, default)
    local num = tonumber(value)
    if not num then return default end
    if min and num < min then return min end
    if max and num > max then return max end
    return num
end

local function savedLocFunc()
    game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/SellAllItems"]:InvokeServer()
    task.wait(1)
    player.Character.HumanoidRootPart.CFrame = savedLoc
    WindUI:Notify({
        Title = "Save Location",
        Content = "Success to Teleport Save Location",
        Duration = 1
    })
    if respawnloop then
        task.wait(5)
        CANCEL_FISHING:InvokeServer()
        testFish:Set(true)
    end
end

-- Create WindUI Window
local Window = WindUI:CreateWindow({
    Title = "Auto Fish - Fish It",
    Icon = "tent",
    Author = "Made with ❤️",
    Folder = "AutoFishConfig",
    MinSize = Vector2.new(560, 350),
    Transparent = true
})

-- Notifikasi awal
WindUI:Notify({
    Title = "🎣 Auto Fish Loaded!",
    Content = "Ready to catch some fish!",
    Duration = 1
})

-- ==================== MAIN TAB ====================
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "fish"
})

MainTab:Select()

local MainSection = MainTab:Section({
    Title = "Auto Fishing Controls",
    Opened = true
})

MainSection:Dropdown({
    Title = "Select Mode",
    Desc = "Change Mode to Fishing",
    Values = { "Instant", "Blatant v1", "Blatant v2" },
    Value = "Instant",
    Callback = function(option)
        fishMode = option
        if option == "Instant" then
            FDY:Set(0.1)
            CDY:Set(1.3)
        elseif option == "Blatant v1" then
            FDY:Set(1.9765)
            CDY:Set(1.0)
        else
            FDY:Set(2.02)
            CDY:Set(3.50)
            RDY:Set(0.3)
        end
        WindUI:Notify({
            Title = "Change Method Fishing",
            Content = "Success Change Method to" .. option,
            Duration = 2
        })
    end
})

MainSection:Dropdown({
    Title = "Select Mode",
    Desc = "Select Mode to Charge",
    Values = { "Fast", "Random" },
    Value = "Fast",
    Callback = function(option) 
        if option == "Fast" then
            charge = false
            print("📌 Mode: Fast (No Charge)")
        else
            charge = true
            print("📌 Mode: Random (With Charge)")
        end
        WindUI:Notify({
            Title = "Change Mode Charge",
            Content = "Success Change Mode Charge to" .. option,
            Duration = 2
        })
    end
})

-- Cycle Delay (FIXED WITH VALIDATION)
FDY = MainSection:Input({
    Title = "Fishing Delay",
    Value = tostring(cycleDelay),
    Type = "Input",
    Placeholder = "Default: 0.87",
    Callback = function(value)
        cycleDelay = value
    end
})

-- Minigame Delay (FIXED WITH VALIDATION)
CDY = MainSection:Input({
    Title = "Caught Delay",
    Value = tostring(minigameDelay),
    Type = "Input",
    Placeholder = "Default: 1",
    Callback = function(value)
        minigameDelay = value
        if fishMode == 'Blatant v2' then
            local iil = ((value + 0.3) / 2) + 0.1
            FDY:Set(iil)
        end
    end
})

-- Recast Delay (FIXED - sekarang update variabel yang benar!)
RDY = MainSection:Input({
    Title = "Cancel Delay",
    Value = tostring(recass),
    Type = "Input",
    Placeholder = "Default: 0.1",
    Callback = function(value)
        recass = value -- FIX: Sebelumnya salah update minigameDelay
    end
})

MainSection:Button({
    Title = "Reset Fishing",
    Icon = "repeat-2",
    Callback = function()
        CANCEL_FISHING:InvokeServer(1, 0.999)
        WindUI:Notify({
            Title = "✅ Reset Fishing",
            Content = "Reset Fishing Success",
            Duration = 1
        })
    end
})

-- Toggle Auto Fish (FIXED)
testFish = MainSection:Toggle({
    Title = "Enable Auto Fish",
    Description = "Start/Stop automatic fishing",
    Value = false,
    Callback = function(state)
        active = state
        
        if active then
            WindUI:Notify({
                Title = "✅ Auto Fish Started",
                Content = string.format("Cycle: %.2fs | Caught: %.2fs | Recast: %.2fs", cycleDelay, minigameDelay, recass),
                Duration = 1
            })
            startAutoFish()
        else
            WindUI:Notify({
                Title = "⏸️ Auto Fish Stopped",
                Content = "Fishing disabled",
                Duration = 1
            })
            stopAutoFish()
        end
    end
})

-- Auto Equip Rod (FIXED)
MainSection:Toggle({
    Title = "Enable Auto Equip Fishing Rod",
    Value = false,
    Callback = function(state)
        aRod = state
        
        if aRod then
            task.spawn(function()
                while aRod do
                    pcall(function()
                        game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipToolFromHotbar"]:FireServer(1)
                    end)
                    task.wait(1)
                end
            end)
        end
    end
})

MainSection:Toggle({
    Title = "Disable Character Animations",
    Description = "Turn on/off all character animations (instant, no respawn needed)",
    Value = false,
    Callback = function(state)
        state = not state
        toggleAnimations(state)
        
        if state then
            WindUI:Notify({
                Title = "🚫 Animations Disabled",
                Content = "All animations removed instantly",
                Duration = 1
            })
        else
            WindUI:Notify({
                Title = "✅ Animations Restored",
                Content = "Animations enabled without respawn",
                Duration = 1
            })
        end
    end
})

MainSection:Space()

MainSection:Button({
    Title = "Respawn",
    Icon = "repeat-2",
    Callback = function()
        if active then
            respawnloop = true
            testFish:Set(false)
        else
            respawnloop = false
        end
        task.wait(0.1)
        player.Character:BreakJoints()
    end
})

local sellTab = Window:Tab({
    Title = "Sell Fish",
    Icon = "shopping-cart"
})

sellTab:Button({
    Title = "Sell Fish",
    Desc = "Sell All Fish Except Favorite",
    Callback = function()
        local success = pcall(function()
            game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/SellAllItems"]:InvokeServer()
        end)
        
        if success then
            WindUI:Notify({
                Title = "✅ Sell Fish",
                Content = "Sell All Fish Success",
                Duration = 1
            })
        else
            WindUI:Notify({
                Title = "❌ Sell Failed",
                Content = "Could not sell fish",
                Duration = 1
            })
        end
    end
})

local function walkspeed()
    hum = player.Character:FindFirstChildOfClass("Humanoid")
    hum.WalkSpeed = numWalk
end

local playerTab = Window:Tab({
    Title = "Player",
    Icon = "user-pen"
})

local slideWalk = playerTab:Slider({
    Title = "Walkspeed",
    Desc = "Change Walkspeed",
    Step = 1,
    Value = {
        Min = 16,
        Max = 200,
        Default = 16
    },
    Callback = function(value)
        numWalk = value
        walkspeed()
    end
})

playerTab:Toggle({
    Title = "Inf Jump",
    Value = false,
    Callback = function(state)
        infjumpstate = state
        if infjumpstate then
            infjumpconn = UserInputService.JumpRequest:Connect(function()
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            if infjumpconn then infjumpconn:Disconnect() end
        end
    end
})

playerTab:Toggle({
    Title = "Bypass Oksigen",
    Value = false,
    Callback = function(state)
        if state then
            game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/EquipOxygenTank"]:InvokeServer(105)
        else
            game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/UnequipOxygenTank"]:InvokeServer()
        end
    end
})

playerTab:Toggle({
    Title = "Bypass radar",
    Value = false,
    Callback = function(state)
        game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/UpdateFishingRadar"]:InvokeServer(state)
    end
})
-- ==================== Weather TAB ====================
local weatherTab = Window:Tab({
    Title = "Weather",
    Icon = "cloudy"
})


local cuaca = { "Cloudy", "Wind", "Snow", "Storm", "Radiant", "Shark Hunt" }

weatherTab:Dropdown({
    Title = "Buy Weather",
    Desc = "Select Weather to Buy",
    Values = cuaca,
    Value = { "Cloudy", "Wind", "Storm" },
    Multi = true,
    AllowNone = true,
    Callback = function(option) 
        weather = option
        print("🌤️ Selected weather:", table.concat(option, ", "))
    end
})

weatherTab:Toggle({
    Title = "Enable Auto Buy Weather",
    Description = "Buy Weather Every 10 Minutes",
    Value = false,
    Callback = function(state)
        active = state
        
        if active then
            task.spawn(function()
                while active do
                    for _, i in pairs(weather) do
                        local success = pcall(function()
                            game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/PurchaseWeatherEvent"]:InvokeServer(i)
                        end)
                        if success then
                            print("✅ Bought weather:", i)
                        end
                    end
                    WindUI:Notify({
                        Title = "✅ Buy Weather",
                        Content = "Purchasing " .. #weather .. " weather(s)",
                        Duration = 1
                    })
                    task.wait(120)
                end
            end)
        else
            WindUI:Notify({
                Title = "⏸️ Auto Buy Weather",
                Content = "Stopped",
                Duration = 1
            })
        end
    end
})

local weatherSection = weatherTab:Section({
    Title = "Buy Weather One Click",
    Opened = true
})

for _, i in cuaca do
    weatherSection:Button({
        Title = i,
        Callback = function()
            game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/PurchaseWeatherEvent"]:InvokeServer(i)
            WindUI:Notify({
                Title = "✅ Buy Weather",
                Content = "Purchasing " .. i .. " weather(s)",
                Duration = 1
            })
        end
    })
end

-- ==================== AUTOMATION TAB ====================
local AutoTab = Window:Tab({
    Title = "Automation",
    Icon = "tv-minimal-play"
})

local buySection = AutoTab:Section({
    Title = "Buy Section",
    Opened = true
})

-- Data untuk buy system
local buyTableTotem = {
    { name = "Lucky Totem", opsi = 5 },
    { name = "Shining Totem", opsi = 7 },
    { name = "Mutation Totem", opsi = 8 }
}

local buyTableRod = {
    { name = "Ares Rod (3M)", opsi = 126 }
}

local buyTableBobber = {
    { name = "Corrupt Bait (1.3M)", opsi = 15 },
    { name = "Floral Bait (4M)", opsi = 20 }
}

-- Remote paths
local buyTotem = NET_PATH["RF/PurchaseMarketItem"]
local buyRod = NET_PATH["RF/PurchaseFishingRod"]
local buyBobber = NET_PATH['RF/PurchaseBait']

-- Variabel untuk menyimpan pilihan
local selectedTotem = nil
local selectedRod = nil
local selectedBobber = nil

-- Fungsi helper untuk mendapatkan nama items
local function getNames(pp)
    local names = {}
    for _, item in ipairs(pp) do
        table.insert(names, item.name)
    end
    return names
end

-- Fungsi helper untuk mendapatkan opsi berdasarkan nama
local function getTotemOption(pp, name)
    for _, item in ipairs(pp) do
        if item.name == name then
            return item.opsi
        end
    end
    return nil
end

-- Dropdown 1: Totem
buySection:Dropdown({
    Title = "Select Market Item",
    Values = getNames(buyTableTotem),
    Value = "Not Selected",
    Callback = function(value)
        selectedTotem = value
        print("🎯 Selected Totem:", selectedTotem)
    end
})
buySection:Button({
    Title = "Buy Totem",
    Callback = function()
        if selectedTotem and selectedTotem ~= "Not Selected" then
            local totemOption = getOption(buyTableTotem, selectedTotem)
            local success = pcall(function()
                buyTotem:InvokeServer(totemOption)
            end)
            if success then
                print("✅ Berhasil beli:", selectedTotem)
            else
                warn("❌ Gagal beli:", selectedTotem)
            end
        end
    end
})
buySection:Space()

-- Dropdown 2: Fishing Rod
buySection:Dropdown({
    Title = "Select Rod",
    Values = getNames(buyTableRod),
    Value = "Not Selected",
    Callback = function(value)
        selectedRod = value
        print("🎯 Selected Totem:", selectedRod)
    end
})
buySection:Button({
    Title = "Buy Rod",
    Callback = function()
        if selectedRod and selectedRod ~= "Not Selected" then
            local rodOption = getOption(buyTableRod, selectedRod)
            local success = pcall(function()
                buyRod:InvokeServer(rodOption)
            end)
            if success then
                print("✅ Berhasil beli:", selectedRod)
            else
                warn("❌ Gagal beli:", selectedRod)
            end
        end
    end
})
buySection:Space()

-- Dropdown 3: Bobber/Bait
buySection:Dropdown({
    Title = "Select Bobber",
    Values = getNames(buyTableBobber),
    Value = "Not Selected",
    Callback = function(value)
        selectedBobber = value
        print("🎯 Selected Totem:", selectedBobber)
    end
})
buySection:Button({
    Title = "Buy Rod",
    Callback = function()
        if selectedBobber and selectedBobber ~= "Not Selected" then
            local bobberOption = getOption(buyTableBobber, selectedBobber)
            local success = pcall(function()
                buyBobber:InvokeServer(bobberOption)
            end)
            if success then
                print("✅ Berhasil beli:", selectedBobber)
            else
                warn("❌ Gagal beli:", selectedBobber)
            end
        end
    end
})

local autoSaveSection = AutoTab:Section({
    Title = "Auto Save Location"
})

local autoSaveStatus = autoSaveSection:Paragraph({
    Title = "Auto Saved Status",
    Desc = "❌ Not Active"
})

local autoSaveParagraph = autoSaveSection:Paragraph({
    Title = "Auto Save Location",
    Desc = [[
If you press the auto save location button, you will be immediately teleported to the saved location. This will sell all the fish in your inventory. Click Delete Posisition to deactivate it.
    ]]
})

autoSaveSection:Button({
    Title = "Save Posisition",
    Icon = "save",
    Callback = function()
        if savedLoc ~= nil then
            savedLoc = player.Character.HumanoidRootPart.CFrame
            autoSaveStatus:SetDesc("✅ Active New Location")
        else
            savedLoc = player.Character.HumanoidRootPart.CFrame
            autoSaveStatus:SetDesc("✅ Active")
        end
        WindUI:Notify({
            Title = "SUCCESS",
            Content = "Success Save Location",
            Duration = 1
        })
    end
})

autoSaveSection:Button({
    Title = "Delete Posisition",
    Icon = "delete",
    Callback = function()
        savedLoc = nil
        autoSaveStatus:SetDesc("❌ Not Active")
        WindUI:Notify({
            Title = "SUCCESS",
            Content = "Success Deleted Save Location",
            Duration = 1
        })
    end
})

-- ==================== TELEPORT TAB ====================
local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "users"
})

local TeleportSection = TeleportTab:Section({
    Title = "Player Teleport",
    Opened = true
})

-- Variabel untuk menyimpan data player
local playerList = {}
local selectedPlayer = nil
local TPPlayer = nil

-- Fungsi untuk mendapatkan list player di map yang sama
local function getPlayersInSameMap()
    local currentPlayers = {}
    local localPlayer = Players.LocalPlayer
    
    if not localPlayer.Character then
        return currentPlayers
    end
    
    local localRoot = localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then
        return currentPlayers
    end
    
    -- Cek semua player
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= localPlayer and otherPlayer.Character then
            local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            table.insert(currentPlayers, otherPlayer.Name)
        end
    end
    
    return currentPlayers
end

-- Fungsi refresh player list
local function refreshPlayerList()
    playerList = getPlayersInSameMap()
    
    if #playerList == 0 then
        WindUI:Notify({
            Title = "⚠️ No Players Found",
            Content = "Tidak ada player lain di map ini",
            Duration = 2
        })
        playerList = {"No players available"}
    else
        WindUI:Notify({
            Title = "✅ Player List Updated",
            Content = "Found " .. #playerList .. " player(s)",
            Duration = 2
        })
    end
    
    if TPPlayer ~= nil then
        TPPlayer:Refresh(playerList)
    end
    
    return playerList
end

-- Dropdown untuk memilih player
TPPlayer = TeleportSection:Dropdown({
    Title = "Select Player",
    Desc = "Pilih player untuk teleport",
    Values = playerList,
    Value = playerList[1] or "No players available",
    Callback = function(value)
        if value ~= "No players available" then
            selectedPlayer = value
            print("📍 Selected player:", selectedPlayer)
        else
            selectedPlayer = nil
        end
    end
})

-- Button untuk refresh player list
TeleportSection:Button({
    Title = "🔄 Refresh Player List",
    Desc = "Update daftar player di map yang sama",
    Callback = function()
        refreshPlayerList()
    end
})

-- Button untuk teleport ke player
TeleportSection:Button({
    Title = "🚀 Teleport to Player",
    Desc = "Teleport ke player yang dipilih",
    Callback = function()
        if not selectedPlayer or selectedPlayer == "No players available" then
            WindUI:Notify({
                Title = "❌ No Player Selected",
                Content = "Pilih player terlebih dahulu!",
                Duration = 3
            })
            return
        end
        
        local targetPlayer = Players:FindFirstChild(selectedPlayer)
        
        if not targetPlayer then
            WindUI:Notify({
                Title = "❌ Player Not Found",
                Content = selectedPlayer .. " sudah tidak ada di game",
                Duration = 3
            })
            refreshPlayerList()
            return
        end
        
        if not targetPlayer.Character then
            WindUI:Notify({
                Title = "❌ Character Not Found",
                Content = selectedPlayer .. " belum spawn",
                Duration = 3
            })
            return
        end
        
        local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        local localRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        
        if not targetRoot or not localRoot then
            WindUI:Notify({
                Title = "❌ Teleport Failed",
                Content = "Character tidak valid",
                Duration = 3
            })
            return
        end
        
        -- Teleport dengan offset sedikit agar tidak stuck
        local success = pcall(function()
            localRoot.CFrame = targetRoot.CFrame * CFrame.new(3, 0, 3)
        end)
        
        if success then
            WindUI:Notify({
                Title = "✅ Teleported!",
                Content = "Berhasil teleport ke " .. selectedPlayer,
                Duration = 2
            })
        else
            WindUI:Notify({
                Title = "❌ Teleport Failed",
                Content = "Gagal teleport, coba lagi",
                Duration = 3
            })
        end
    end
})

-- ==================== LOCATION TELEPORT ====================
local LocationTPSection = TeleportTab:Section({
    Title = "Location Teleport",
    Opened = true
})

-- Data lokasi teleport (FIXED SYNTAX)
local TPdata = {
    {name = "Ancient Jungle", cframe = CFrame.new(1896.9, 8.4, -577.5), cf = {1.97, 3.5}},
    {name = "Ancient Ruin", cframe = CFrame.new(6090.0, -585.9, 4634.0), cf = {1.978, 3.5}},
    {name = "Classic Event", cframe = CFrame.new(1439.0,46.0,2779.0), cf = {1.97, 3.5}},
    {name = "Creator Island", cframe = CFrame.new(979.0, 47.6, 5086.0), cf = {1.965, 3.4}},
    {name = "Esoteric Depth", cframe = CFrame.new(3189.7, -1302.9, 1406.9), cf = {1.9, 3.3}},
    {name = "Iron Cafe", cframe = CFrame.new(-8642.0, -547.5, 162.0)},
    {name = "Iron Cavern", cframe = CFrame.new(-8792.0,-585.0,223.0)},
    {name = "Sacred Ruin", cframe = CFrame.new(1526.1, 4.9, -637.4)},
    {name = "Tropical Grove", cframe = CFrame.new(-2139.0, 53.5, 3624.0)}
}

-- Generate buttons untuk setiap lokasi (FIXED LOOP)
for _, location in ipairs(TPdata) do
    LocationTPSection:Button({
        Title = "📍 " .. location.name,
        Callback = function()
            local character = player.Character
            if not character then
                WindUI:Notify({
                    Title = "❌ Error",
                    Content = "Character tidak ditemukan!",
                    Duration = 2
                })
                return
            end
            
            local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
            if not humanoidRoot then
                WindUI:Notify({
                    Title = "❌ Error",
                    Content = "HumanoidRootPart tidak ditemukan!",
                    Duration = 2
                })
                return
            end
            
            -- Teleport dengan pcall untuk error handling
            local success = pcall(function()
                humanoidRoot.CFrame = location.cframe
            end)
            
            if success then
                WindUI:Notify({
                    Title = "✅ Teleported!",
                    Content = "Berhasil teleport ke " .. location.name,
                    Duration = 2
                })
            else
                WindUI:Notify({
                    Title = "❌ Teleport Failed",
                    Content = "Gagal teleport ke " .. location.name,
                    Duration = 2
                })
            end
        end
    })
end

-- ==================== Setting TAB ====================
local SettingTab = Window:Tab({
    Title = "Setting",
    Icon = "settings"
})

local PerformanceSection = SettingTab:Section({
    Title = "Performance Settings",
    Opened = true
})

-- Variabel untuk tracking FPS boost status
local fpsBoostEnabled = false
local render3DDisabled = false

-- Fungsi untuk boost FPS
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

-- Fungsi untuk disable 3D render
local function toggleRender3D(state)
    render3DDisabled = not state
    
    local RunService = game:GetService("RunService")
    
    if not state then
        -- DISABLE 3D RENDERING
        pcall(function()
            RunService:Set3dRenderingEnabled(false)
        end)
        
        print("✅ 3D Rendering Disabled")
    else
        -- ENABLE 3D RENDERING
        pcall(function()
            RunService:Set3dRenderingEnabled(true)
        end)
        
        print("✅ 3D Rendering Enabled")
    end
end

-- Toggle FPS Boost
PerformanceSection:Toggle({
    Title = "🚀 FPS Boost Mode",
    Description = "Ultra low graphics untuk performa maksimal (cocok untuk AFK)",
    Value = false,
    Callback = function(state)
        toggleFPSBoost(state)
        
        WindUI:Notify({
            Title = state and "✅ FPS Boost ON" or "⚙️ FPS Boost OFF",
            Content = state and "Graphics set to ultra low" or "Graphics restored to normal",
            Duration = 2
        })
    end
})

-- Toggle 3D Render
PerformanceSection:Toggle({
    Title = "👁️ Enable 3D Rendering",
    Description = "Disable untuk FPS tertinggi (layar hitam tapi game tetap jalan)",
    Value = true,
    Callback = function(state)
        toggleRender3D(state)
        
        WindUI:Notify({
            Title = state and "✅ 3D Render ON" or "🚫 3D Render OFF",
            Content = state and "Rendering enabled" or "Rendering disabled - screen will be black",
            Duration = 3
        })
    end
})

local function DisableOk(siap, opsi)
    for _, connection in ipairs(getconnections(siap.OnClientEvent)) do
        if opsi then
            connection:Enable()
        else
            connection:Disable()
        end
    end
end

SettingTab:Toggle({
    Title = "Disable Fish Caught",
    Value = false,
    Callback = function(state)
        state = not state
        DisableOk(FISH_CAUGHT, state)
    end
})

SettingTab:Toggle({
    Title = "Disable Visual Fish Caught",
    Value = false,
    Callback = function(state)
        state = not state
        DisableOk(CAUGHT_FISH_VISUAL, state)
    end
})


SettingTab:Toggle({
    Title = "Disable Fish Notif",
    Value = false,
    Callback = function(state)
        state = not state
        DisableOk(FISH_NOTIF, state)
    end
})

SettingTab:Toggle({
    Title = "Disable Display System Message",
    Value = false,
    Callback = function(state)
        state = not state
        DisableOk(DSM, state)
    end
})

-- ==================== INFO TAB ====================
local InfoTab = Window:Tab({
    Title = "Info",
    Icon = "info"
})

local InfoSection = InfoTab:Section({
    Title = "📖 Information",
    Opened = true
})

InfoSection:Paragraph({
    Title = "🎣 Auto Fish",
    Desc = [[
Settingan Rod Ares

• Sisyphus Statue
  -> 1.35 - 1.54


Settingan Rod Ghosfin

• Ancient Jungle + Sacred Ruin
  -> 1.25 - 1.40 
• Escetonic Depth
  -> 0.9 + 1.1
• 
    ]]
})

InfoSection:Paragraph({
    Title = "⚙️ How to Use",
    Desc = [[
1. Go to Main tab
2. Adjust delays (optional)
3. Click "Enable Auto Fish"
4. Enjoy fishing!

Tips:
• Lower delays = faster but riskier
• Keep Cycle Delay above 4s
• Enable Auto Equip Rod if needed
    ]]
})

-- Cleanup on teleport
game:GetService("Players").LocalPlayer.OnTeleport:Connect(function()
    stopAutoFish()
    cleanupConnections()
end)

print("🎣 Auto Fish GUI loaded successfully! (Version 1.0.1 - FIXED)")
print("📌 Delays - Cycle:", cycleDelay, "| Caught:", minigameDelay, "| Recast:", recass)

if player.Character then
    saveOriginalAnimate(player.Character)
    setupCharacter(player.Character)
    walkspeed()
end

player.CharacterAdded:Connect(function(character)
    -- Reset originalAnimateScript untuk character baru
    originalAnimateScript = nil
    cleanupConnections()
    
    saveOriginalAnimate(character)
    setupCharacter(character)
    walkspeed()
    if savedLoc ~= nil then
        savedLocFunc()
    end
    
end)

-- Anti AFK
local VirtualUser = game:GetService("VirtualUser")
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    print("Anti AFK triggered")
end)
