function ChannelContent:Dropdown(flag, config)
    local DropFunc = {}
    local selected = {}
    if flag then
        DiscordLib.Flags[flag] = {
            SetValue = function(self, val) end,
            Clear = function(self) end,
            Add = function(self, val) end,
            Refresh = function(self, list) end
        }
    end

    if config.Value then
        if config.Multi then
            selected = type(config.Value) == "table" and config.Value or {config.Value}
        else
            selected = type(config.Value) == "table" and config.Value or {config.Value}
        end
    end

    local itemcount = 0
    local framesize = 0
    local DropTog = false

    -- ✅ MAIN DROPDOWN CONTAINER (tidak berubah size)
    local Dropdown = Instance.new("Frame")
    local DropdownTitle = Instance.new("TextLabel")
    local DropdownFrameOutline = Instance.new("Frame")
    local DropdownFrameOutlineCorner = Instance.new("UICorner")
    local DropdownFrame = Instance.new("Frame")
    local DropdownFrameCorner = Instance.new("UICorner")
    local CurrentSelectedText = Instance.new("TextLabel")
    local ArrowImg = Instance.new("ImageLabel")
    local DropdownFrameBtn = Instance.new("TextButton")

    Dropdown.Name = "Dropdown"
    Dropdown.Parent = ChannelHolder
    Dropdown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Dropdown.BackgroundTransparency = 1.000
    Dropdown.Position = UDim2.new(0.0796874985, 0, 0.445175439, 0)
    Dropdown.Size = UDim2.new(0, 403, 0, 73) -- ✅ SIZE TETAP!

    DropdownTitle.Name = "DropdownTitle"
    DropdownTitle.Parent = Dropdown
    DropdownTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    DropdownTitle.BackgroundTransparency = 1.000
    DropdownTitle.Position = UDim2.new(0, 5, 0, 0)
    DropdownTitle.Size = UDim2.new(0, 200, 0, 29)
    DropdownTitle.Font = Enum.Font.Gotham
    DropdownTitle.Text = config.Title
    DropdownTitle.TextColor3 = Color3.fromRGB(127, 131, 137)
    DropdownTitle.TextSize = 14.000
    DropdownTitle.TextXAlignment = Enum.TextXAlignment.Left

    DropdownFrameOutline.Name = "DropdownFrameOutline"
    DropdownFrameOutline.Parent = DropdownTitle
    DropdownFrameOutline.AnchorPoint = Vector2.new(0.5, 0.5)
    DropdownFrameOutline.BackgroundColor3 = Color3.fromRGB(37, 40, 43)
    DropdownFrameOutline.Position = UDim2.new(0.988442957, 0, 1.6197437, 0)
    DropdownFrameOutline.Size = UDim2.new(0, 396, 0, 36)

    DropdownFrameOutlineCorner.CornerRadius = UDim.new(0, 3)
    DropdownFrameOutlineCorner.Name = "DropdownFrameOutlineCorner"
    DropdownFrameOutlineCorner.Parent = DropdownFrameOutline

    DropdownFrame.Name = "DropdownFrame"
    DropdownFrame.Parent = DropdownTitle
    DropdownFrame.BackgroundColor3 = Color3.fromRGB(48, 51, 57)
    DropdownFrame.ClipsDescendants = true
    DropdownFrame.Position = UDim2.new(0.00999999978, 0, 1.06638527, 0)
    DropdownFrame.Selectable = true
    DropdownFrame.Size = UDim2.new(0, 392, 0, 32)

    DropdownFrameCorner.CornerRadius = UDim.new(0, 3)
    DropdownFrameCorner.Name = "DropdownFrameCorner"
    DropdownFrameCorner.Parent = DropdownFrame

    CurrentSelectedText.Name = "CurrentSelectedText"
    CurrentSelectedText.Parent = DropdownFrame
    CurrentSelectedText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    CurrentSelectedText.BackgroundTransparency = 1.000
    CurrentSelectedText.Position = UDim2.new(0.0178571437, 0, 0, 0)
    CurrentSelectedText.Size = UDim2.new(0, 340, 0, 32)
    CurrentSelectedText.Font = Enum.Font.Gotham
    CurrentSelectedText.Text = "..."
    CurrentSelectedText.TextColor3 = Color3.fromRGB(212, 212, 212)
    CurrentSelectedText.TextSize = 14.000
    CurrentSelectedText.TextXAlignment = Enum.TextXAlignment.Left
    CurrentSelectedText.TextTruncate = Enum.TextTruncate.AtEnd

    ArrowImg.Name = "ArrowImg"
    ArrowImg.Parent = DropdownFrame
    ArrowImg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ArrowImg.BackgroundTransparency = 1.000
    ArrowImg.Position = UDim2.new(0.92, 0, 0.15, 0)
    ArrowImg.Size = UDim2.new(0, 22, 0, 22)
    ArrowImg.Image = "http://www.roblox.com/asset/?id=6034818372"
    ArrowImg.ImageColor3 = Color3.fromRGB(212, 212, 212)

    DropdownFrameBtn.Name = "DropdownFrameBtn"
    DropdownFrameBtn.Parent = DropdownFrame
    DropdownFrameBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    DropdownFrameBtn.BackgroundTransparency = 1.000
    DropdownFrameBtn.Size = UDim2.new(0, 392, 0, 32)
    DropdownFrameBtn.Font = Enum.Font.SourceSans
    DropdownFrameBtn.Text = ""
    DropdownFrameBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    DropdownFrameBtn.TextSize = 14.000

    -- ✅ FLOATING DROPDOWN MENU (parent ke MainFrame agar overlay)
    local DropdownFloatingContainer = Instance.new("Frame")
    local DropdownFrameMainOutline = Instance.new("Frame")
    local DropdownFrameMainOutlineCorner = Instance.new("UICorner")
    local DropdownFrameMain = Instance.new("Frame")
    local DropdownFrameMainCorner = Instance.new("UICorner")
    local DropItemHolderLabel = Instance.new("TextLabel")
    local DropItemHolder = Instance.new("ScrollingFrame")
    local DropItemHolderLayout = Instance.new("UIListLayout")
    local DropShadow = Instance.new("ImageLabel")

    -- ✅ Container untuk block clicks
    DropdownFloatingContainer.Name = "DropdownFloatingContainer"
    DropdownFloatingContainer.Parent = MainFrame -- ✅ Parent ke MainFrame!
    DropdownFloatingContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    DropdownFloatingContainer.BackgroundTransparency = 0.5 -- Semi-transparent overlay
    DropdownFloatingContainer.BorderSizePixel = 0
    DropdownFloatingContainer.Size = UDim2.new(1, 0, 1, 0)
    DropdownFloatingContainer.ZIndex = 999
    DropdownFloatingContainer.Visible = false

    -- ✅ Shadow/Glow effect
    DropShadow.Name = "DropShadow"
    DropShadow.Parent = DropdownFloatingContainer
    DropShadow.BackgroundTransparency = 1
    DropShadow.Position = UDim2.new(0, -15, 0, -15)
    DropShadow.Size = UDim2.new(1, 30, 1, 30)
    DropShadow.ZIndex = 998
    DropShadow.Image = "rbxassetid://4996891970"
    DropShadow.ImageColor3 = Color3.fromRGB(15, 15, 15)
    DropShadow.ScaleType = Enum.ScaleType.Slice
    DropShadow.SliceCenter = Rect.new(20, 20, 280, 280)

    DropdownFrameMainOutline.Name = "DropdownFrameMainOutline"
    DropdownFrameMainOutline.Parent = DropdownFloatingContainer
    DropdownFrameMainOutline.BackgroundColor3 = Color3.fromRGB(37, 40, 43)
    DropdownFrameMainOutline.Position = UDim2.new(0.5, -198, 0.5, -40) -- ✅ Center position
    DropdownFrameMainOutline.Size = UDim2.new(0, 396, 0, 81)
    DropdownFrameMainOutline.ZIndex = 1000

    DropdownFrameMainOutlineCorner.CornerRadius = UDim.new(0, 3)
    DropdownFrameMainOutlineCorner.Name = "DropdownFrameMainOutlineCorner"
    DropdownFrameMainOutlineCorner.Parent = DropdownFrameMainOutline

    DropdownFrameMain.Name = "DropdownFrameMain"
    DropdownFrameMain.Parent = DropdownFrameMainOutline
    DropdownFrameMain.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
    DropdownFrameMain.ClipsDescendants = true
    DropdownFrameMain.Position = UDim2.new(0, 2, 0, 2)
    DropdownFrameMain.Size = UDim2.new(0, 392, 0, 77)
    DropdownFrameMain.ZIndex = 1001

    DropdownFrameMainCorner.CornerRadius = UDim.new(0, 3)
    DropdownFrameMainCorner.Name = "DropdownFrameMainCorner"
    DropdownFrameMainCorner.Parent = DropdownFrameMain

    DropItemHolderLabel.Name = "ItemHolderLabel"
    DropItemHolderLabel.Parent = DropdownFrameMain
    DropItemHolderLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    DropItemHolderLabel.BackgroundTransparency = 1.000
    DropItemHolderLabel.Position = UDim2.new(0.0178571437, 0, 0, 0)
    DropItemHolderLabel.Size = UDim2.new(0, 193, 0, 13)
    DropItemHolderLabel.Font = Enum.Font.Gotham
    DropItemHolderLabel.Text = ""
    DropItemHolderLabel.TextColor3 = Color3.fromRGB(212, 212, 212)
    DropItemHolderLabel.TextSize = 14.000
    DropItemHolderLabel.TextXAlignment = Enum.TextXAlignment.Left
    DropItemHolderLabel.ZIndex = 1002

    DropItemHolder.Name = "ItemHolder"
    DropItemHolder.Parent = DropItemHolderLabel
    DropItemHolder.Active = true
    DropItemHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    DropItemHolder.BackgroundTransparency = 1.000
    DropItemHolder.Position = UDim2.new(0, 0, 0.215384638, 0)
    DropItemHolder.Size = UDim2.new(0, 385, 0, 0)
    DropItemHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
    DropItemHolder.ScrollBarThickness = 6
    DropItemHolder.BorderSizePixel = 0
    DropItemHolder.ScrollBarImageColor3 = Color3.fromRGB(28, 29, 32)
    DropItemHolder.ZIndex = 1003

    DropItemHolderLayout.Name = "ItemHolderLayout"
    DropItemHolderLayout.Parent = DropItemHolder
    DropItemHolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
    DropItemHolderLayout.Padding = UDim.new(0, 0)
    
    local function UpdateDisplay()
        if #selected > 0 then
            CurrentSelectedText.Text = table.concat(selected, ", ")
        else
            CurrentSelectedText.Text = "..."
        end
        
        if flag then
            local value = config.Multi and selected or (selected[1] or "")
            DiscordLib.ConfigSystem:SetFlag(flag, value)
        end
        
        pcall(config.Callback, config.Multi and selected or (selected[1] or ""))
    end
    
    -- ✅ TOGGLE DROPDOWN
    DropdownFrameBtn.MouseButton1Click:Connect(function()
        DropTog = not DropTog
        
        if DropTog then
            -- Show floating dropdown
            DropdownFloatingContainer.Visible = true
            
            -- Animate arrow rotation
            TweenService:Create(
                ArrowImg,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                {Rotation = 180}
            ):Play()
        else
            -- Hide floating dropdown
            DropdownFloatingContainer.Visible = false
            
            -- Reset arrow
            TweenService:Create(
                ArrowImg,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                {Rotation = 0}
            ):Play()
        end
    end)
    
    -- ✅ CLICK OUTSIDE TO CLOSE
    DropdownFloatingContainer.MouseButton1Click:Connect(function()
        DropTog = false
        DropdownFloatingContainer.Visible = false
        TweenService:Create(
            ArrowImg,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {Rotation = 0}
        ):Play()
    end)
    
    -- ✅ PREVENT CLICKS FROM CLOSING WHEN CLICKING ITEMS
    DropdownFrameMain.MouseButton1Click:Connect(function()
        -- Do nothing, just stop propagation
    end)
    
    local function CreateItem(v)
        local Item = Instance.new("TextButton")
        local ItemCorner = Instance.new("UICorner")
        local ItemText = Instance.new("TextLabel")
        local CheckMark = Instance.new("TextLabel")

        Item.Name = "Item"
        Item.Parent = DropItemHolder
        Item.BackgroundColor3 = Color3.fromRGB(42, 44, 48)
        Item.Size = UDim2.new(0, 379, 0, 29)
        Item.AutoButtonColor = false
        Item.Font = Enum.Font.SourceSans
        Item.Text = ""
        Item.TextColor3 = Color3.fromRGB(0, 0, 0)
        Item.TextSize = 14.000
        Item.BackgroundTransparency = 1
        Item.ZIndex = 1004

        ItemCorner.CornerRadius = UDim.new(0, 4)
        ItemCorner.Name = "ItemCorner"
        ItemCorner.Parent = Item

        ItemText.Name = "ItemText"
        ItemText.Parent = Item
        ItemText.BackgroundColor3 = Color3.fromRGB(42, 44, 48)
        ItemText.BackgroundTransparency = 1.000
        ItemText.Position = UDim2.new(0.0211081803, 0, 0, 0)
        ItemText.Size = UDim2.new(0, 330, 0, 29)
        ItemText.Font = Enum.Font.Gotham
        ItemText.TextColor3 = Color3.fromRGB(212, 212, 212)
        ItemText.TextSize = 14.000
        ItemText.TextXAlignment = Enum.TextXAlignment.Left
        ItemText.Text = v
        ItemText.ZIndex = 1005
        
        CheckMark.Name = "CheckMark"
        CheckMark.Parent = Item
        CheckMark.BackgroundTransparency = 1.000
        CheckMark.Position = UDim2.new(0.9, 0, 0, 0)
        CheckMark.Size = UDim2.new(0, 29, 0, 29)
        CheckMark.Font = Enum.Font.GothamBold
        CheckMark.Text = ""
        CheckMark.TextColor3 = Color3.fromRGB(114, 137, 228)
        CheckMark.TextSize = 18.000
        CheckMark.ZIndex = 1005

        for _, sel in pairs(selected) do
            if sel == v then
                CheckMark.Text = "✓"
                break
            end
        end

        Item.MouseEnter:Connect(function()
            ItemText.TextColor3 = Color3.fromRGB(255,255,255)
            Item.BackgroundTransparency = 0
        end)

        Item.MouseLeave:Connect(function()
            ItemText.TextColor3 = Color3.fromRGB(212, 212, 212)
            Item.BackgroundTransparency = 1
        end)

        Item.MouseButton1Click:Connect(function()
            if config.Multi then
                local found = false
                for idx, sel in pairs(selected) do
                    if sel == v then
                        table.remove(selected, idx)
                        CheckMark.Text = ""
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(selected, v)
                    CheckMark.Text = "✓"
                end
                UpdateDisplay()
            else
                selected = {v}
                for _, child in pairs(DropItemHolder:GetChildren()) do
                    if child:IsA("TextButton") and child:FindFirstChild("CheckMark") then
                        child.CheckMark.Text = ""
                    end
                end
                CheckMark.Text = "✓"
                UpdateDisplay()
                
                -- Auto close
                DropdownFloatingContainer.Visible = false
                DropTog = false
                TweenService:Create(
                    ArrowImg,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                    {Rotation = 0}
                ):Play()
            end
        end)
    end
    
    for i,v in pairs(config.List) do
        itemcount = itemcount + 1
        
        if itemcount == 1 then
            framesize = 29
        elseif itemcount == 2 then
            framesize = 58
        elseif itemcount >= 3 then
            framesize = 87
        end
        
        CreateItem(v)
        
        DropItemHolder.CanvasSize = UDim2.new(0,0,0,DropItemHolderLayout.AbsoluteContentSize.Y)
        DropItemHolder.Size = UDim2.new(0, 385, 0, framesize)
        DropdownFrameMain.Size = UDim2.new(0, 392, 0, framesize + 6)
        DropdownFrameMainOutline.Size = UDim2.new(0, 396, 0, framesize + 10)
    end
    
    function DropFunc:SetValue(val)
        if config.Multi then
            if type(val) == "table" then
                selected = val
            else
                selected = {val}
            end
        else
            selected = type(val) == "table" and val or {val}
        end
        
        for _, child in pairs(DropItemHolder:GetChildren()) do
            if child:IsA("TextButton") and child:FindFirstChild("CheckMark") then
                local itemText = child.ItemText.Text
                local isSelected = false
                for _, sel in pairs(selected) do
                    if sel == itemText then
                        isSelected = true
                        break
                    end
                end
                child.CheckMark.Text = isSelected and "✓" or ""
            end
        end
        
        UpdateDisplay()
    end
    
    function DropFunc:Clear()
        for i,v in pairs(DropItemHolder:GetChildren()) do
            if v.Name == "Item" then
                v:Destroy()
            end
        end
        selected = {}
        CurrentSelectedText.Text = "..."
        itemcount = 0
        framesize = 0
    end
    
    function DropFunc:Add(textadd)
        itemcount = itemcount + 1
        if itemcount == 1 then framesize = 29
        elseif itemcount == 2 then framesize = 58
        elseif itemcount >= 3 then framesize = 87 end
        
        CreateItem(textadd)
        
        DropItemHolder.CanvasSize = UDim2.new(0,0,0,DropItemHolderLayout.AbsoluteContentSize.Y)
        DropItemHolder.Size = UDim2.new(0, 385, 0, framesize)
        DropdownFrameMain.Size = UDim2.new(0, 392, 0, framesize + 6)
        DropdownFrameMainOutline.Size = UDim2.new(0, 396, 0, framesize + 10)
    end
    
    function DropFunc:Refresh(newlist)
        DropFunc:Clear()
        for _, v in pairs(newlist) do
            DropFunc:Add(v)
        end
    end
    
    if flag then
        DiscordLib.Flags[flag] = DropFunc
        DiscordLib.ConfigSystem:SetFlag(flag, config.Multi and selected or (selected[1] or ""))
    end
    
    UpdateDisplay()
    ChannelHolder.CanvasSize = UDim2.new(0,0,0,ChannelHolderLayout.AbsoluteContentSize.Y)
    
    return DropFunc
end
