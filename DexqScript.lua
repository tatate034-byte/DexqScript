local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Dexq",
    Author = "Anime Card Farm",
    Folder = "DexqUI",
    Size = UDim2.fromOffset(480, 310),
    Transparent = true,
    Theme = "Dark", 
    HideSearchBar = true,
    OpenButton = {
        Title = "Open Dexq",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        Scale = 0.8,
        Color = ColorSequence.new(
            Color3.fromHex("#8c3cff"),
            Color3.fromHex("#5523a8")
        )
    }
})

local MainTab = Window:Tab({
    Title = "Main",
    Icon = "solar:home-bold",
})

local FilterConfig = {
    EnableRarityFilter = false,
    EnableMutationFilter = false,
    BuyRarities = {},
    BuyMutations = {}
}

local function getSpawnPackClickDetector()
    local player = game:GetService("Players").LocalPlayer
    local plotNum = player:FindFirstChild("PlotNumber") and player.PlotNumber.Value or 0
    if plotNum ~= 0 then
        local plotFolder = workspace:FindFirstChild("MAP") 
            and workspace.MAP:FindFirstChild("Plots") 
            and workspace.MAP.Plots:FindFirstChild(tostring(plotNum))
        
        if plotFolder and plotFolder:FindFirstChild("Plot_N0") then
            for _, v in ipairs(plotFolder.Plot_N0:GetDescendants()) do
                if v:IsA("ClickDetector") and v.Parent.Name == "ButtonPart" then
                    return v
                end
            end
        end
    end
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("ClickDetector") and desc.Parent and desc.Parent.Name == "ButtonPart" and desc.Parent.Parent and desc.Parent.Parent.Name == "Plot_N0" then
            return desc
        end
    end
    return nil
end

getgenv().AutoSpawnPack = false
local AutoSpawnToggle = MainTab:Toggle({
    Title = "Auto Spawn Pack",
    Callback = function(state)
        getgenv().AutoSpawnPack = state
        if state then
            task.spawn(function()
                local cd = getSpawnPackClickDetector()
                if not cd then
                    WindUI:Notify({ Title = "Error", Content = "Spawn Pack button not found!", Duration = 3 })
                    getgenv().AutoSpawnPack = false
                    return
                end
                
                while getgenv().AutoSpawnPack do
                    local activeCards = 0
                    if getgenv().CardFolder then
                        for _, model in ipairs(getgenv().CardFolder:GetChildren()) do
                            if model:IsA("Model") and model:GetAttribute("IgnoreTutoBeam") ~= nil and model:FindFirstChildWhichIsA("ProximityPrompt", true) then
                                if getgenv().AutoBuyCards and model:GetAttribute("Rejected") then
                                    continue
                                end
                                activeCards = activeCards + 1
                            end
                        end
                    end
                    
                    if getgenv().AutoBuyCards then
                        if activeCards == 0 then
                            pcall(fireclickdetector, cd)
                            task.wait(0.3) 
                        else
                            task.wait(0.05) 
                        end
                    else
                        pcall(fireclickdetector, cd)
                        if activeCards >= 3 then
                            task.wait(0.2)
                        else
                            task.wait(0.01)
                        end
                    end
                end
            end)
        end
    end
})

local RaritiesList = {
    "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Divine",
    "Transcendent", "Shadow", "Emperor", "Demon", "Manga", "Celestial", "Heavenly",
    "Corrupted", "Striker", "Sacred", "Paradox", "Founder", "Evolved", "Magic", "Oni",
    "Chaos", "Ruin", "Reborn", "Beast", "Nordic", "Hunter", "Soul", "Swordsman",
    "Gamer", "Revenge", "Chainsaw", "Eternity", "Academy", "Dynasty", "Grail",
    "Mystery", "VIP", "Event", "Limited", "Conquest", "Blaze", "Devour"
}

getgenv().SelectedRarities = {}

local RarityDropdown = MainTab:Dropdown({
    Title = "Select Rarities to Buy",
    Multi = true,
    Values = RaritiesList,
    Value = {},
    Callback = function(value)
        getgenv().SelectedRarities = {}
        if type(value) == "table" then
            for k, v in pairs(value) do
                if type(k) == "number" then
                    getgenv().SelectedRarities[string.lower(tostring(v))] = true
                else
                    getgenv().SelectedRarities[string.lower(tostring(k))] = v
                end
            end
        elseif type(value) == "string" then
            getgenv().SelectedRarities[string.lower(value)] = true
        end
    end
})

local MutationsList = {
    "Normal", "Golden", "Diamond", "Venomous", "Rainbow", "Sakura", "Candy",
    "Blessed", "Radioactive", "Glitch", "Starfallen", "Admin", "Unknow"
}

getgenv().SelectedMutations = {}

local MutationDropdown = MainTab:Dropdown({
    Title = "Select Mutations to Buy",
    Multi = true,
    Values = MutationsList,
    Value = {},
    Callback = function(value)
        getgenv().SelectedMutations = {}
        if type(value) == "table" then
            for k, v in pairs(value) do
                if type(k) == "number" then
                    getgenv().SelectedMutations[string.lower(tostring(v))] = true
                else
                    getgenv().SelectedMutations[string.lower(tostring(k))] = v
                end
            end
        elseif type(value) == "string" then
            getgenv().SelectedMutations[string.lower(value)] = true
        end
    end
})

getgenv().CardFolder = getgenv().CardFolder or nil
getgenv().PromptCooldowns = getgenv().PromptCooldowns or {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local function findCardFolder()
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            local model = desc:FindFirstAncestorOfClass("Model")
            if model and model:GetAttribute("IgnoreTutoBeam") ~= nil then
                getgenv().CardFolder = model.Parent
                return true
            end
        end
    end
    return false
end

local function GetAllInventorySummary()
    local player = Players.LocalPlayer
    local inventory = {}
    
    local function scanFolder(folder)
        if not folder then return end
        for _, item in ipairs(folder:GetChildren()) do
            if item:IsA("Tool") then
                local rarityAttr = item:GetAttribute("Rarity")
                local cardNameAttr = item:GetAttribute("CardName")
                local groupKey = rarityAttr or cardNameAttr or item.Name
                
                if not item:GetAttribute("Rarity") and item:FindFirstChild("Rarity") and item.Rarity:IsA("StringValue") then
                    groupKey = item.Rarity.Value
                end
                
                local mutation = item:GetAttribute("Mutation") or "Normal"
                if not item:GetAttribute("Mutation") and item:FindFirstChild("Mutation") and item.Mutation:IsA("StringValue") then
                    mutation = item.Mutation.Value
                end
                
                if not string.find(string.lower(item.Name), "box") and groupKey ~= "Box" then
                    if not inventory[groupKey] then
                        inventory[groupKey] = {}
                    end
                    if not inventory[groupKey][mutation] then
                        inventory[groupKey][mutation] = 0
                    end
                    inventory[groupKey][mutation] = inventory[groupKey][mutation] + 1
                end
            end
        end
    end
    
    pcall(function()
        scanFolder(player:FindFirstChild("Backpack"))
        if player.Character then
            scanFolder(player.Character)
        end
    end)
    
    local resultLines = {}
    for key, mutations in pairs(inventory) do
        local mutStrings = {}
        for mut, count in pairs(mutations) do
            table.insert(mutStrings, mut .. " x" .. tostring(count))
        end
        table.insert(resultLines, tostring(key) .. ": " .. table.concat(mutStrings, " | "))
    end
    
    if #resultLines > 0 then
        local fullText = table.concat(resultLines, "\n")
        if string.len(fullText) > 1000 then
            return string.sub(fullText, 1, 1000) .. "..."
        end
        return fullText
    else
        return "None"
    end
end

local function SendWebhook(url, rarity, mutation)
    local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not req then return end
    
    local inventoryText = "Unknown"
    pcall(function()
        inventoryText = GetAllInventorySummary()
    end)
    
    local data = {
        ["content"] = "",
        ["embeds"] = {
            {
                ["title"] = "🎉 Card Bought!",
                ["description"] = "Successfully bought a card matching your criteria.",
                ["type"] = "rich",
                ["color"] = 5579688,
                ["fields"] = {
                    {
                        ["name"] = "Rarity",
                        ["value"] = tostring(rarity),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Mutation",
                        ["value"] = tostring(mutation),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Full Inventory",
                        ["value"] = inventoryText,
                        ["inline"] = false
                    }
                },
                ["timestamp"] = DateTime.now():ToIsoDate()
            }
        }
    }
    
    pcall(function()
        req({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = game:GetService("HttpService"):JSONEncode(data)
        })
    end)
end

local function instantBuyLoop()
    if not getgenv().AutoBuyCards then return end
    
    if not getgenv().CardFolder then
        findCardFolder()
    end
    if not getgenv().CardFolder then return end

    for _, model in ipairs(getgenv().CardFolder:GetChildren()) do
        if not model:IsA("Model") or model:GetAttribute("IgnoreTutoBeam") == nil then continue end
        
        local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
        if not prompt then continue end

        local rarityLabel = model:FindFirstChild("Rarity", true)
        local mutationLabel = model:FindFirstChild("Mutation", true)
        
        if rarityLabel then
            local cleanRarityText = string.gsub(rarityLabel.Text, "<[^>]+>", "")
            local cardRarity = string.match(cleanRarityText, "^%s*(.-)%s*$") or ""
            if cardRarity ~= "" and cardRarity ~= "Label" then
                
                local cardMutation = "Normal"
                if mutationLabel then
                    local cleanMutationText = string.gsub(mutationLabel.Text, "<[^>]+>", "")
                    local mText = string.match(cleanMutationText, "^%s*(.-)%s*$") or ""
                    if mText ~= "" and mText ~= "Label" then
                        cardMutation = mText
                    end
                end
                
                local matchRarity = true
                if next(getgenv().SelectedRarities) ~= nil then
                    matchRarity = (getgenv().SelectedRarities[string.lower(cardRarity)] == true)
                end
                
                local matchMutation = true
                if next(getgenv().SelectedMutations) ~= nil then
                    matchMutation = (getgenv().SelectedMutations[string.lower(cardMutation)] == true)
                end
                
                if matchRarity and matchMutation then
                    local now = tick()
                    if not getgenv().PromptCooldowns[prompt] or now - getgenv().PromptCooldowns[prompt] > 0.05 then
                        getgenv().PromptCooldowns[prompt] = now
                        
                        pcall(function()
                            prompt.RequiresLineOfSight = false
                            prompt.MaxActivationDistance = 99999
                            fireproximityprompt(prompt)
                        end)
                        
                        if getgenv().DiscordWebhook and getgenv().DiscordWebhook ~= "" then
                            if not getgenv().NotifiedCards then getgenv().NotifiedCards = {} end
                            if not getgenv().NotifiedCards[prompt] then
                                getgenv().NotifiedCards[prompt] = true
                                task.spawn(function()
                                    SendWebhook(getgenv().DiscordWebhook, cardRarity, cardMutation)
                                end)
                            end
                        end
                    end
                else
                    model:SetAttribute("Rejected", true)
                end
            end
        end
    end
end

if getgenv().BruteForceLoop then getgenv().BruteForceLoop:Disconnect() end
getgenv().BruteForceLoop = RunService.Heartbeat:Connect(instantBuyLoop)

getgenv().AutoBuyCards = false
local AutoBuyToggle = MainTab:Toggle({
    Title = "Buy Selected Now",
    Callback = function(state)
        getgenv().AutoBuyCards = state
    end
})

getgenv().AutoCarry = false
getgenv().AutoCarryDelay = 5

local AutoCarryToggle = MainTab:Toggle({
    Title = "Auto Carry (Collect Money)",
    Callback = function(state)
        getgenv().AutoCarry = state
        if state then
            task.spawn(function()
                while getgenv().AutoCarry do
                    local player = Players.LocalPlayer
                    local character = player.Character
                    local hrp = character and character:FindFirstChild("HumanoidRootPart")
                    
                    local searchArea = workspace
                    local plotNum = player:FindFirstChild("PlotNumber") and player.PlotNumber.Value or 0
                    if plotNum ~= 0 then
                        local plotFolder = workspace:FindFirstChild("MAP") 
                            and workspace.MAP:FindFirstChild("Plots") 
                            and workspace.MAP.Plots:FindFirstChild(tostring(plotNum))
                        if plotFolder then searchArea = plotFolder end
                    end
                    
                    for _, prompt in ipairs(searchArea:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") then
                            local txt = (prompt.ActionText .. " " .. prompt.ObjectText .. " " .. prompt.Name):lower()
                            if txt:find("carry") then
                                pcall(function()
                                    local targetPos
                                    if prompt.Parent:IsA("BasePart") then targetPos = prompt.Parent.Position
                                    elseif prompt.Parent:IsA("Attachment") then targetPos = prompt.Parent.WorldPosition
                                    elseif prompt.Parent:IsA("Model") and prompt.Parent.PrimaryPart then targetPos = prompt.Parent.PrimaryPart.Position end
                                    
                                    local originalCFrame
                                    if hrp and targetPos then
                                        originalCFrame = hrp.CFrame
                                        hrp.CFrame = CFrame.new(targetPos) + Vector3.new(0, 3, 0)
                                        task.wait(0.2)
                                    end
                                    
                                    prompt.RequiresLineOfSight = false
                                    prompt.MaxActivationDistance = 99999
                                    fireproximityprompt(prompt)
                                    task.wait(0.1)
                                    
                                    if originalCFrame then hrp.CFrame = originalCFrame end
                                end)
                            end
                        end
                    end
                    
                    local delayTime = tonumber(getgenv().AutoCarryDelay) or 5
                    if delayTime < 1 then delayTime = 1 end
                    
                    local elapsed = 0
                    while getgenv().AutoCarry and elapsed < (delayTime * 60) do
                        task.wait(1)
                        elapsed = elapsed + 1
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

getgenv().AutoSellBox = false
local AutoSellBoxToggle = MainTab:Toggle({
    Title = "Auto Sell Box",
    Callback = function(state)
        getgenv().AutoSellBox = state
        if state then
            task.spawn(function()
                while getgenv().AutoSellBox do
                    local player = Players.LocalPlayer
                    local character = player.Character
                    local hrp = character and character:FindFirstChild("HumanoidRootPart")
                    
                    local backpack = player:FindFirstChild("Backpack")
                    local boxTool = nil
                    
                    if backpack then
                        for _, tool in ipairs(backpack:GetChildren()) do
                            if tool:IsA("Tool") and (tool:GetAttribute("BoxValue") ~= nil or tool.Name:find("Box")) then
                                boxTool = tool
                                break
                            end
                        end
                    end
                    
                    if boxTool and character and character:FindFirstChild("Humanoid") then
                        character.Humanoid:EquipTool(boxTool)
                        task.wait(0.2)
                    end
                    
                    local isEquipped = false
                    if character then
                        for _, tool in ipairs(character:GetChildren()) do
                            if tool:IsA("Tool") and (tool:GetAttribute("BoxValue") ~= nil or tool.Name:find("Box")) then
                                isEquipped = true
                                break
                            end
                        end
                    end
                    
                    if isEquipped and hrp then
                        local plotNum = player:FindFirstChild("PlotNumber") and player.PlotNumber.Value or 0
                        if plotNum ~= 0 then
                            local plotFolder = workspace:FindFirstChild("MAP") 
                                and workspace.MAP:FindFirstChild("Plots") 
                                and workspace.MAP.Plots:FindFirstChild(tostring(plotNum))
                            
                            if plotFolder and plotFolder:FindFirstChild("Plot_N0") and plotFolder.Plot_N0:FindFirstChild("SellPart") then
                                local sellPart = plotFolder.Plot_N0.SellPart
                                local prompt = sellPart:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if prompt then
                                    pcall(function()
                                        local originalCFrame = hrp.CFrame
                                        hrp.CFrame = sellPart.CFrame + Vector3.new(0, 3, 0)
                                        task.wait(0.15)
                                        
                                        prompt.RequiresLineOfSight = false
                                        prompt.MaxActivationDistance = 99999
                                        fireproximityprompt(prompt)
                                        task.wait(0.1)
                                        
                                        hrp.CFrame = originalCFrame
                                    end)
                                end
                            end
                        end
                    end
                    
                    task.wait(1)
                end
            end)
        end
    end
})

-- ==============================================================
-- 🚀 AUTO GIFT SYSTEM (Fast Warp/Equip + Dynamic Wait on Accept)
-- ==============================================================

getgenv().GiftTargetPlayer = ""
getgenv().MaxGiftLimit = "0"
getgenv().CurrentGiftedCount = 0

local function GetServerPlayersList()
    local list = {}
    local localPlayer = Players.LocalPlayer
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer then
            table.insert(list, p.Name)
        end
    end
    if #list == 0 then
        table.insert(list, "No other players")
    end
    return list
end

local GiftPlayerDropdown
GiftPlayerDropdown = MainTab:Dropdown({
    Title = "Select Target Player to Gift",
    Multi = false,
    Values = GetServerPlayersList(),
    Value = "",
    Callback = function(value)
        if type(value) == "table" then
            for k, v in pairs(value) do
                if type(k) == "number" then
                    getgenv().GiftTargetPlayer = tostring(v)
                else
                    getgenv().GiftTargetPlayer = tostring(k)
                end
            end
        else
            getgenv().GiftTargetPlayer = tostring(value)
        end
    end
})

MainTab:Button({
    Title = "Refresh Player List",
    Callback = function()
        pcall(function()
            if GiftPlayerDropdown and GiftPlayerDropdown.Refresh then
                GiftPlayerDropdown:Refresh(GetServerPlayersList(), "")
            end
        end)
        WindUI:Notify({ Title = "Success", Content = "Player list refreshed!", Duration = 2 })
    end
})

local GiftLimitInput
GiftLimitInput = MainTab:Input({
    Title = "Max Gift Limit (0 or Blank = Unlimited)",
    Default = "0",
    PlaceholderText = "e.g. 5 or 0 for unlimited",
    ClearTextOnFocus = false,
    Callback = function(text)
        getgenv().MaxGiftLimit = text
    end
})

getgenv().GiftSelectedRarities = {}
local GiftRarityDropdown = MainTab:Dropdown({
    Title = "Select Rarities to Gift",
    Multi = true,
    Values = RaritiesList,
    Value = {},
    Callback = function(value)
        getgenv().GiftSelectedRarities = {}
        if type(value) == "table" then
            for k, v in pairs(value) do
                if type(k) == "number" then
                    getgenv().GiftSelectedRarities[string.lower(tostring(v))] = true
                else
                    getgenv().GiftSelectedRarities[string.lower(tostring(k))] = v
                end
            end
        elseif type(value) == "string" then
            getgenv().GiftSelectedRarities[string.lower(value)] = true
        end
    end
})

getgenv().GiftSelectedMutations = {}
local GiftMutationDropdown = MainTab:Dropdown({
    Title = "Select Mutations to Gift",
    Multi = true,
    Values = MutationsList,
    Value = {},
    Callback = function(value)
        getgenv().GiftSelectedMutations = {}
        if type(value) == "table" then
            for k, v in pairs(value) do
                if type(k) == "number" then
                    getgenv().GiftSelectedMutations[string.lower(tostring(v))] = true
                else
                    getgenv().GiftSelectedMutations[string.lower(tostring(k))] = v
                end
            end
        elseif type(value) == "string" then
            getgenv().GiftSelectedMutations[string.lower(value)] = true
        end
    end
})

getgenv().AutoGiftCards = false
local AutoGiftToggle = MainTab:Toggle({
    Title = "Auto Gift from Backpack & Warp",
    Callback = function(state)
        getgenv().AutoGiftCards = state
        if state then
            getgenv().CurrentGiftedCount = 0
            task.spawn(function()
                while getgenv().AutoGiftCards do
                    local targetName = getgenv().GiftTargetPlayer
                    
                    local maxLimitText = tostring(getgenv().MaxGiftLimit or "0"):gsub("%s+", "")
                    local maxLimit = tonumber(maxLimitText)
                    if maxLimit == nil then maxLimit = 0 end
                    
                    if maxLimit > 0 and getgenv().CurrentGiftedCount >= maxLimit then
                        WindUI:Notify({ Title = "Auto Gift", Content = "Reached max gift limit (" .. maxLimit .. "). Stopping...", Duration = 3 })
                        getgenv().AutoGiftCards = false
                        AutoGiftToggle:SetValue(false)
                        break
                    end
                    
                    if targetName ~= "" and targetName ~= "No other players" then
                        pcall(function()
                            local player = Players.LocalPlayer
                            local character = player.Character
                            local hrp = character and character:FindFirstChild("HumanoidRootPart")
                            local backpack = player:FindFirstChild("Backpack")
                            
                            if targetName == player.Name then return end
                            
                            local targetPlayer = Players:FindFirstChild(targetName)
                            if not targetPlayer or targetPlayer == player then return end
                            
                            local targetChar = targetPlayer.Character
                            local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                            
                            if hrp and targetHrp and backpack then
                                for _, tool in ipairs(backpack:GetChildren()) do
                                    if not getgenv().AutoGiftCards then break end
                                    if not tool:IsA("Tool") then continue end
                                    
                                    local cardRarity = string.lower(tool:GetAttribute("Rarity") or "")
                                    local cardMutation = string.lower(tool:GetAttribute("Mutation") or "normal")
                                    
                                    if cardRarity == "" and tool:FindFirstChild("Rarity") and tool.Rarity:IsA("StringValue") then
                                        cardRarity = string.lower(tool.Rarity.Value)
                                    end
                                    if cardMutation == "normal" and tool:FindFirstChild("Mutation") and tool.Mutation:IsA("StringValue") then
                                        cardMutation = string.lower(tool.Mutation.Value)
                                    end
                                    
                                    if string.find(string.lower(tool.Name), "box") or cardRarity == "box" then continue end
                                    
                                    local matchRarity = (next(getgenv().GiftSelectedRarities) == nil) or getgenv().GiftSelectedRarities[cardRarity]
                                    local matchMutation = (next(getgenv().GiftSelectedMutations) == nil) or getgenv().GiftSelectedMutations[cardMutation]
                                    
                                    if matchRarity and matchMutation then
                                        hrp.CFrame = targetHrp.CFrame + Vector3.new(0, 0, 2)
                                        task.wait(0.1) 
                                        
                                        if character and character:FindFirstChild("Humanoid") then
                                            character.Humanoid:EquipTool(tool)
                                            task.wait(0.15) 
                                        end
                                        
                                        local fired = false
                                        local function triggerPrompt(prompt)
                                            if prompt and prompt:IsA("ProximityPrompt") then
                                                pcall(function()
                                                    prompt.RequiresLineOfSight = false
                                                    prompt.MaxActivationDistance = 99999
                                                    prompt.HoldDuration = 0
                                                    
                                                    if fireproximityprompt then
                                                        fireproximityprompt(prompt)
                                                    else
                                                        prompt:InputHoldBegin()
                                                        prompt:InputHoldEnd()
                                                    end
                                                end)
                                                fired = true
                                            end
                                        end

                                        if targetChar then
                                            for _, desc in ipairs(targetChar:GetDescendants()) do
                                                if desc:IsA("ProximityPrompt") then
                                                    triggerPrompt(desc)
                                                    task.wait(0.05)
                                                end
                                            end
                                        end

                                        if not fired then
                                            for _, desc in ipairs(tool:GetDescendants()) do
                                                if desc:IsA("ProximityPrompt") then
                                                    triggerPrompt(desc)
                                                    task.wait(0.05)
                                                end
                                            end
                                        end
                                        
                                        getgenv().CurrentGiftedCount = getgenv().CurrentGiftedCount + 1
                                        
                                        local maxWait = 2.5
                                        local elapsedWait = 0
                                        while getgenv().AutoGiftCards and elapsedWait < maxWait do
                                            task.wait(0.1)
                                            elapsedWait = elapsedWait + 0.1
                                            
                                            local stillExists = false
                                            if tool.Parent == backpack or (character and tool.Parent == character) then
                                                stillExists = true
                                            end
                                            if not stillExists then
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
})
