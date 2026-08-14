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
        local map = workspace:FindFirstChild("MAP")
        local plots = map and map:FindFirstChild("Plots")
        local plotFolder = plots and plots:FindFirstChild(tostring(plotNum))
        
        if plotFolder and plotFolder:FindFirstChild("Plot_N0") then
            for _, v in ipairs(plotFolder.Plot_N0:GetDescendants()) do
                if v:IsA("ClickDetector") and v.Parent and v.Parent.Name == "ButtonPart" then
                    return v
                end
            end
        end
    end

    for _, desc in ipairs(workspace:GetChildren()) do
        if desc.Name == "MAP" or desc.Name == "Plots" then
            for _, v in ipairs(desc:GetDescendants()) do
                if v:IsA("ClickDetector") and v.Parent and v.Parent.Name == "ButtonPart" then
                    return v
                end
            end
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
                    WindUI:Notify({ Title = "Error", Content = "Spawn Pack button not found! (Try resetting or wait for load)", Duration = 3 })
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
    "Conquest", "Blaze", "Devour", "Common", "Uncommon", "Rare", "Epic", "Legendary", 
    "Mythic", "Secret", "Divine", "Transcendent", "Shadow", "Emperor", "Demon", 
    "Manga", "Celestial", "Heavenly", "Corrupted", "Striker", "Sacred", "Paradox", 
    "Founder", "Evolved", "Magic", "Oni", "Chaos", "Ruin", "Reborn", "Beast", 
    "Nordic", "Hunter", "Soul", "Swordsman", "Gamer", "Revenge", "Chainsaw", 
    "Eternity", "Academy", "Dynasty", "Grail", "Mystery", "VIP", "Event", "Limited", "Raven", "Arcane", "Nightfall"
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
    "Blessed", "Radioactive", "Glitch", "Starfallen", "Admin", "Unknow", "Evolution"
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
                local toolName = item.Name
                local rarityAttr = item:GetAttribute("Rarity") or ""
                local mutationAttr = item:GetAttribute("Mutation") or ""
                
                local groupKey = rarityAttr
                if groupKey == "" then
                    for _, rName in ipairs(RaritiesList) do
                        if string.find(string.lower(toolName), string.lower(rName)) then
                            groupKey = rName
                            break
                        end
                    end
                end
                if groupKey == "" then groupKey = toolName
                end
                
                local mutation = mutationAttr
                if mutation == "" or mutation == "Normal" then
                    for _, mName in ipairs(MutationsList) do
                        if string.find(string.lower(toolName), string.lower(mName)) then
                            mutation = mName
                            break
                        end
                    end
                end
                
                if mutation == "" or mutation == "Normal" then
                    for _, desc in ipairs(item:GetDescendants()) do
                        if desc:IsA("TextLabel") then
                            local tLower = string.lower(desc.Text)
                            for _, mName in ipairs(MutationsList) do
                                if string.find(tLower, string.lower(mName)) then
                                    mutation = mName
                                    break
                                end
                            end
                        end
                    end
                end
                
                if mutation == "" then mutation = "Normal" end
                
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

MainTab:Paragraph({ Title = "--- Card Gifting Settings ---", Content = "Configure specific card rarity and mutation to gift." })

getgenv().GiftSelectedRarities = {}
local GiftRarityDropdown = MainTab:Dropdown({
    Title = "Select Card Rarities to Gift",
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
    Title = "Select Card Mutations to Gift",
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

-- ==========================================
-- Auto Gift Cards Only (แก้ไขปัญหาติดค้างใบสุดท้าย + คูลดาวน์ 5 วินาที)
-- ==========================================
getgenv().AutoGiftCardsState = false
local AutoGiftCardsToggle = MainTab:Toggle({
    Title = "Auto Gift Cards Only",
    Callback = function(state)
        getgenv().AutoGiftCardsState = state
        if state then
            getgenv().CurrentGiftedCount = 0
            task.spawn(function()
                while getgenv().AutoGiftCardsState do
                    local targetName = getgenv().GiftTargetPlayer
                    
                    local maxLimitText = tostring(getgenv().MaxGiftLimit or "0"):gsub("%s+", "")
                    local maxLimit = tonumber(maxLimitText)
                    if maxLimit == nil then maxLimit = 0 end
                    
                    if maxLimit > 0 and getgenv().CurrentGiftedCount >= maxLimit then
                        WindUI:Notify({ Title = "Auto Gift Cards", Content = "Reached max gift limit (" .. maxLimit .. "). Stopping...", Duration = 3 })
                        getgenv().AutoGiftCardsState = false
                        AutoGiftCardsToggle:SetValue(false)
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
                                    if not getgenv().AutoGiftCardsState then break end
                                    if not tool:IsA("Tool") then continue end
                                    
                                    local toolNameLower = string.lower(tool.Name)
                                    local rAttrLower = string.lower(tool:GetAttribute("Rarity") or "")
                                    local isBoxOrPack = string.find(toolNameLower, "box") or string.find(toolNameLower, "pack") or rAttrLower == "box" or rAttrLower == "pack" or tool:GetAttribute("BoxValue") ~= nil
                                    if isBoxOrPack then continue end
                                    
                                    local isEvolutionCard = string.find(toolNameLower, "evolution") or string.find(toolNameLower, "evolved")
                                    local combinedTextForCheck = toolNameLower .. " " .. rAttrLower
                                    for _, desc in ipairs(tool:GetDescendants()) do
                                        if desc:IsA("TextLabel") then
                                            local tText = string.lower(desc.Text)
                                            combinedTextForCheck = combinedTextForCheck .. " " .. tText
                                            if string.find(tText, "evolution") or string.find(tText, "evolved") then
                                                isEvolutionCard = true
                                            end
                                        end
                                    end
                                    
                                    local evoSelected = getgenv().GiftSelectedRarities["evolution"] or getgenv().GiftSelectedRarities["evolved"]
                                    if isEvolutionCard and not evoSelected then
                                        continue 
                                    end
                                    
                                    local cardRarity = ""
                                    for _, rName in ipairs(RaritiesList) do
                                        if rName ~= "Evolved" and rName ~= "Evolution" then
                                            if string.find(combinedTextForCheck, string.lower(rName)) then
                                                cardRarity = string.lower(rName)
                                                break
                                            end
                                        end
                                    end
                                    
                                    local cardMutation = "normal"
                                    for _, mName in ipairs(MutationsList) do
                                        if string.find(combinedTextForCheck, string.lower(mName)) then
                                            cardMutation = string.lower(mName)
                                            break
                                        end
                                    end
                                    
                                    local matchRarity = (next(getgenv().GiftSelectedRarities) == nil) or getgenv().GiftSelectedRarities[cardRarity]
                                    if not matchRarity and next(getgenv().GiftSelectedRarities) ~= nil then
                                        for rKey, _ in pairs(getgenv().GiftSelectedRarities) do
                                            if string.find(combinedTextForCheck, rKey) then
                                                matchRarity = true
                                                break
                                            end
                                        end
                                    end
                                    
                                    local matchMutation = (next(getgenv().GiftSelectedMutations) == nil) or getgenv().GiftSelectedMutations[cardMutation]
                                    if not matchMutation and next(getgenv().GiftSelectedMutations) ~= nil then
                                        for mKey, _ in pairs(getgenv().GiftSelectedMutations) do
                                            if string.find(combinedTextForCheck, mKey) then
                                                matchMutation = true
                                                break
                                            end
                                        end
                                    end
                                    
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
                                        
                                        -- หน่วงเวลารอคูลดาวน์เกม 5.2 วินาที
                                        task.wait(5.2)
                                        
                                        -- เช็คซ้ำว่าการ์ดออกไปหรือยัง ถ้ายังอยู่ให้ข้าม/ลองลูปใหม่ใบเดิมโดยไม่เพิ่มโควตาค้าง
                                        if tool.Parent == backpack then
                                            break
                                        else
                                            getgenv().CurrentGiftedCount = getgenv().CurrentGiftedCount + 1
                                            break
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

MainTab:Paragraph({ Title = "--- Pack Gifting Settings ---", Content = "Configure specific pack rarities and mutations to gift (Packs only)." })

getgenv().GiftSelectedPacks = {}
local GiftPackRarityDropdown = MainTab:Dropdown({
    Title = "Select Pack Rarities to Gift",
    Multi = true,
    Values = RaritiesList,
    Value = {},
    Callback = function(value)
        getgenv().GiftSelectedPacks = {}
        if type(value) == "table" then
            for k, v in pairs(value) do
                if type(k) == "number" then
                    getgenv().GiftSelectedPacks[string.lower(tostring(v))] = true
                else
                    getgenv().GiftSelectedPacks[string.lower(tostring(k))] = v
                end
            end
        elseif type(value) == "string" then
            getgenv().GiftSelectedPacks[string.lower(value)] = true
        end
    end
})

getgenv().GiftSelectedPackMutations = {}
local GiftPackMutationDropdown = MainTab:Dropdown({
    Title = "Select Pack Mutations to Gift",
    Multi = true,
    Values = MutationsList,
    Value = {},
    Callback = function(value)
        getgenv().GiftSelectedPackMutations = {}
        if type(value) == "table" then
            for k, v in pairs(value) do
                if type(k) == "number" then
                    getgenv().GiftSelectedPackMutations[string.lower(tostring(v))] = true
                else
                    getgenv().GiftSelectedPackMutations[string.lower(tostring(k))] = v
                end
            end
        elseif type(value) == "string" then
            getgenv().GiftSelectedPackMutations[string.lower(value)] = true
        end
    end
})

-- ==========================================
-- Auto Gift Packs Only (แก้ไขปัญหาติดค้างใบสุดท้าย + คูลดาวน์ 5 วินาที)
-- ==========================================
getgenv().AutoGiftPacksState = false
local AutoGiftPacksToggle = MainTab:Toggle({
    Title = "Auto Gift Packs Only",
    Callback = function(state)
        getgenv().AutoGiftPacksState = state
        if state then
            getgenv().CurrentGiftedCount = 0
            task.spawn(function()
                while getgenv().AutoGiftPacksState do
                    local targetName = getgenv().GiftTargetPlayer
                    
                    local maxLimitText = tostring(getgenv().MaxGiftLimit or "0"):gsub("%s+", "")
                    local maxLimit = tonumber(maxLimitText)
                    if maxLimit == nil then maxLimit = 0 end
                    
                    if maxLimit > 0 and getgenv().CurrentGiftedCount >= maxLimit then
                        WindUI:Notify({ Title = "Auto Gift Packs", Content = "Reached max gift limit (" .. maxLimit .. "). Stopping...", Duration = 3 })
                        getgenv().AutoGiftPacksState = false
                        AutoGiftPacksToggle:SetValue(false)
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
                                    if not getgenv().AutoGiftPacksState then break end
                                    if not tool:IsA("Tool") then continue end
                                    
                                    local toolNameLower = string.lower(tool.Name)
                                    local rAttrLower = string.lower(tool:GetAttribute("Rarity") or "")
                                    local mutationAttr = string.lower(tool:GetAttribute("Mutation") or "")
                                    
                                    local isPack = string.find(toolNameLower, "pack") or rAttrLower == "pack"
                                    if not isPack then continue end
                                    
                                    local packRarity = rAttrLower
                                    if packRarity == "" then
                                        for _, rName in ipairs(RaritiesList) do
                                            if string.find(toolNameLower, string.lower(rName)) then
                                                packRarity = string.lower(rName)
                                                break
                                            end
                                        end
                                    end
                                    
                                    local packMutation = mutationAttr
                                    if packMutation == "" or packMutation == "normal" then
                                        for _, mName in ipairs(MutationsList) do
                                            if string.find(toolNameLower, string.lower(mName)) then
                                                packMutation = string.lower(mName)
                                                break
                                            end
                                        end
                                    end
                                    if packMutation == "" then packMutation = "normal" end
                                    
                                    local matchPackRarity = (next(getgenv().GiftSelectedPacks) == nil) or getgenv().GiftSelectedPacks[packRarity]
                                    local matchPackMutation = (next(getgenv().GiftSelectedPackMutations) == nil) or getgenv().GiftSelectedPackMutations[packMutation]
                                    
                                    if matchPackRarity and matchPackMutation then
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
                                        
                                        -- หน่วงเวลารอคูลดาวน์เกม 5.2 วินาที
                                        task.wait(5.2)
                                        
                                        -- เช็คซ้ำว่าแพ็กออกไปหรือยัง ถ้ายังอยู่ให้ลูปส่งใหม่ใบเดิม
                                        if tool.Parent == backpack then
                                            break
                                        else
                                            getgenv().CurrentGiftedCount = getgenv().CurrentGiftedCount + 1
                                            break
                                        end
                                    end
                                end
                            end
                        end)
                    end
                    task.wait(0.2)
                end
            end)
        end
    end
})

getgenv().AutoAcceptGift = false
local AutoAcceptToggle = MainTab:Toggle({
    Title = "Auto Accept Gift",
    Callback = function(state)
        getgenv().AutoAcceptGift = state
        if state then
            task.spawn(function()
                while getgenv().AutoAcceptGift do
                    pcall(function()
                        local player = Players.LocalPlayer
                        local playerGui = player:FindFirstChild("PlayerGui")
                        if playerGui then
                            for _, gui in ipairs(playerGui:GetDescendants()) do
                                if (gui:IsA("TextButton") or gui:IsA("ImageButton")) then
                                    local txt = ""
                                    for _, sub in ipairs(gui:GetDescendants()) do
                                        if sub:IsA("TextLabel") or sub:IsA("TextButton") then
                                            txt = txt .. " " .. sub.Text
                                        end
                                    end
                                    if gui:IsA("TextButton") then
                                        txt = txt .. " " .. gui.Text
                                    end
                                    
                                    txt = string.lower(txt)
                                    if string.find(txt, "accept") then
                                        if gui.AbsoluteSize.X > 0 and gui.Visible then
                                            if firesignal then
                                                pcall(function() firesignal(gui.MouseButton1Click) end)
                                                pcall(function() firesignal(gui.Activated) end)
                                            end
                                            
                                            if getconnections then
                                                for _, conn in ipairs(getconnections(gui.MouseButton1Click)) do
                                                    pcall(function() conn:Fire() end)
                                                end
                                            end
                                            
                                            task.wait(0.2)
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.2)
                end
            end)
        end
    end
})

local InventoryTab = Window:Tab({
    Title = "Inventory",
    Icon = "solar:box-bold",
})

local InventoryParagraph = InventoryTab:Paragraph({
    Title = "Current Inventory Summary",
    Content = "Click the button below to scan and update your backpack contents."
})

InventoryTab:Button({
    Title = "Refresh Inventory Status",
    Callback = function()
        pcall(function()
            local summary = GetAllInventorySummary()
            InventoryParagraph:SetDesc(summary)
            WindUI:Notify({ Title = "Inventory", Content = "Refreshed backpack items!", Duration = 2 })
        end)
    end
})

local AutoCarrySlider = MainTab:Slider({
    Title = "Auto Carry Delay (Minutes)",
    Step = 1,
    Value = {
        Min = 1,
        Max = 30,
        Default = getgenv().AutoCarryDelay or 5
    },
    Callback = function(value)
        getgenv().AutoCarryDelay = value
    end
})

local VirtualUser = game:GetService("VirtualUser")
local antiAfkConnection

getgenv().AntiAfkState = false
local AntiAfkToggle = MainTab:Toggle({
    Title = "Anti AFK",
    Callback = function(state)
        getgenv().AntiAfkState = state
        if state then
            antiAfkConnection = Players.LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        else
            if antiAfkConnection then
                antiAfkConnection:Disconnect()
                antiAfkConnection = nil
            end
        end
    end
})

local function isLuckBoostActive()
    local PlayerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not PlayerGui then return true end 
    local InfoGui = PlayerGui:FindFirstChild("InfoGui")
    if not InfoGui then return true end
    local Boost = InfoGui:FindFirstChild("Boost")
    if not Boost then return true end
    local PotionLuck = Boost:FindFirstChild("PotionLuck")
    if not PotionLuck then return false end 
    
    if not PotionLuck.Visible then return false end
    
    for _, v in ipairs(PotionLuck:GetDescendants()) do
        if v:IsA("TextLabel") then
            if v.Text == "00:00:00" or v.Text == "00:00" then
                return false
            end
        end
    end
    return true
end

local function getPotionAmount(potionId)
    local PlayerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not PlayerGui then return 0 end
    local GuiMid = PlayerGui:FindFirstChild("GuiMid")
    if not GuiMid then return 0 end
    local Items = GuiMid:FindFirstChild("Items")
    if not Items then return 0 end
    local ItemsFrame = Items:FindFirstChild("ItemsFrame")
    if not ItemsFrame then return 0 end
    local ScrollingFrameItems = ItemsFrame:FindFirstChild("ScrollingFrameItems")
    if not ScrollingFrameItems then return 0 end
    
    local ObjectFrame = ScrollingFrameItems:FindFirstChild("ObjectFrame_" .. potionId)
    if not ObjectFrame then return 0 end
    
    if not ObjectFrame.Visible then return 0 end
    
    local ObjectButton = ObjectFrame:FindFirstChild("ObjectButton")
    if not ObjectButton then return 0 end
    
    local Quantity = ObjectButton:FindFirstChild("Quantity")
    if not Quantity or not Quantity:IsA("TextLabel") then return 0 end
    
    local amountStr = Quantity.Text:gsub("x", "")
    return tonumber(amountStr) or 0
end

getgenv().AutoUseLuck = false
local AutoUseLuckToggle = MainTab:Toggle({
    Title = "Auto Use Luck Potion",
    Value = getgenv().AutoUseLuck,
    Callback = function(state)
        getgenv().AutoUseLuck = state
        if state then
            task.spawn(function()
                local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)
                local ItemsRE = Remotes and Remotes:WaitForChild("ItemsRE", 5)
                if not ItemsRE then return end
                
                while getgenv().AutoUseLuck do
                    if not isLuckBoostActive() then
                        local amt1 = getPotionAmount("LuckPotion1")
                        local amt2 = getPotionAmount("LuckPotion2")
                        local amt3 = getPotionAmount("LuckPotion3")
                        
                        if WindUI and WindUI.Notify then
                            WindUI:Notify({
                                Title = "Luck Inventory Check",
                                Content = string.format("Remaining - III: %d | II: %d | I: %d", amt3, amt2, amt1),
                                Duration = 3
                            })
                        end
                        
                        if amt3 > 0 then
                            ItemsRE:FireServer("UseItem", {ItemId = "LuckPotion3", Amount = math.min(5, amt3)})
                        elseif amt2 > 0 then
                            ItemsRE:FireServer("UseItem", {ItemId = "LuckPotion2", Amount = math.min(5, amt2)})
                        elseif amt1 > 0 then
                            ItemsRE:FireServer("UseItem", {ItemId = "LuckPotion1", Amount = math.min(5, amt1)})
                        end
                    end
                    task.wait(2)
                end
            end)
        end
    end
})

local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "solar:settings-bold",
})

local HttpService = game:GetService("HttpService")
local ConfigFolder = "Dexq_AnimeCardFarm"

if not isfolder(ConfigFolder) then
    pcall(makefolder, ConfigFolder)
end

local function GetConfigs()
    local configs = {}
    if isfolder(ConfigFolder) then
        for _, file in ipairs(listfiles(ConfigFolder)) do
            if file:sub(-5) == ".json" and not file:find("_MainConfig.json") then
                local name = file:match("([^/\\]+)%.json$")
                if name then table.insert(configs, name) end
            end
        end
    end
    return configs
end

local ConfigData = {
    Autoload = "",
}

local function SaveMainConfig()
    if writefile then
        pcall(function()
            writefile(ConfigFolder .. "/_MainConfig.json", HttpService:JSONEncode(ConfigData))
        end)
    end
end

local function LoadMainConfig()
    if isfile and isfile(ConfigFolder .. "/_MainConfig.json") then
        local s, r = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigFolder .. "/_MainConfig.json"))
        end)
        if s and type(r) == "table" then
            ConfigData = r
        end
    end
end
LoadMainConfig()

getgenv().DiscordWebhook = ""
local WebhookInput = MiscTab:Input({
    Title = "Discord Webhook URL",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    Callback = function(text)
        getgenv().DiscordWebhook = text
    end
})

MiscTab:Keybind({
    Title = "Toggle UI Key",
    Key = "RightControl",
    Callback = function()
        pcall(function()
            local toggled = false
            if Window and type(Window.Toggle) == "function" then
                Window:Toggle()
                toggled = true
            end
            if not toggled then
                for _, v in ipairs(game:GetService("CoreGui"):GetChildren()) do
                    if v:IsA("ScreenGui") and v:FindFirstChild("Main") and v.Main:IsA("Frame") then
                        local titleLabel = v.Main:FindFirstChild("Topbar", true)
                        if titleLabel or v.Name == "WindUI" or v.Name == "DexqUI" then
                            v.Enabled = not v.Enabled
                        end
                    end
                end
            end
        end)
    end
})

local function SaveConfig(name)
    local data = {
        Rarities = getgenv().SelectedRarities or {},
        Mutations = getgenv().SelectedMutations or {},
        AutoSpawn = getgenv().AutoSpawnPack or false,
        AutoBuy = getgenv().AutoBuyCards or false,
        AutoCarry = getgenv().AutoCarry or false,
        AutoSellBox = getgenv().AutoSellBox or false,
        AutoCarryDelay = getgenv().AutoCarryDelay or 5,
        AntiAfk = getgenv().AntiAfkState or false,
        AutoUseLuck = getgenv().AutoUseLuck or false,
        Webhook = getgenv().DiscordWebhook or "",
        GiftTarget = getgenv().GiftTargetPlayer or {},
        GiftRarities = getgenv().GiftSelectedRarities or {},
        GiftMutations = getgenv().GiftSelectedMutations or {},
        GiftPacks = getgenv().GiftSelectedPacks or {},
        GiftPackMutations = getgenv().GiftSelectedPackMutations or {},
        AutoGiftCards = getgenv().AutoGiftCardsState or false,
        AutoGiftPacks = getgenv().AutoGiftPacksState or false,
        AutoAccept = getgenv().AutoAcceptGift or false,
        MaxGiftLimit = getgenv().MaxGiftLimit or "0"
    }
    if writefile then
        pcall(function()
            writefile(ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
            WindUI:Notify({ Title = "Config", Content = "Saved config: " .. name, Duration = 3 })
        end)
    end
end

local function LoadConfig(name)
    if isfile and isfile(ConfigFolder .. "/" .. name .. ".json") then
        local s, data = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigFolder .. "/" .. name .. ".json"))
        end)
        if s and type(data) == "table" then
            getgenv().SelectedRarities = data.Rarities or {}
            getgenv().SelectedMutations = data.Mutations or {}
            
            getgenv().GiftTargetPlayer = data.GiftTarget or ""
            getgenv().GiftSelectedRarities = data.GiftRarities or {}
            getgenv().GiftSelectedMutations = data.GiftMutations or {}
            getgenv().GiftSelectedPacks = data.GiftPacks or {}
            getgenv().GiftSelectedPackMutations = data.GiftPackMutations or {}
            getgenv().MaxGiftLimit = data.MaxGiftLimit or "0"
            
            pcall(function()
                if GiftPlayerDropdown and GiftPlayerDropdown.SetValue then
                    GiftPlayerDropdown:SetValue(getgenv().GiftTargetPlayer)
                end
                if GiftLimitInput and GiftLimitInput.SetValue then
                    GiftLimitInput:SetValue(tostring(getgenv().MaxGiftLimit))
                end
            end)
            
            local function safeToggleSet(toggleObj, val)
                if not toggleObj then return end
                pcall(function() toggleObj:SetValue(val) end)
                pcall(function() toggleObj:Set(val) end)
                pcall(function() toggleObj.Value = val end)
            end
            
            safeToggleSet(AutoSpawnToggle, data.AutoSpawn or false)
            safeToggleSet(AutoBuyToggle, data.AutoBuy or false)
            safeToggleSet(AutoCarryToggle, data.AutoCarry or false)
            safeToggleSet(AutoSellBoxToggle, data.AutoSellBox or false)
            safeToggleSet(AutoGiftCardsToggle, data.AutoGiftCards or false)
            safeToggleSet(AutoGiftPacksToggle, data.AutoGiftPacks or false)
            safeToggleSet(AutoAcceptToggle, data.AutoAccept or false)
            
            if data.AutoCarryDelay then
                getgenv().AutoCarryDelay = data.AutoCarryDelay
                pcall(function() AutoCarrySlider:SetValue(data.AutoCarryDelay) end)
                pcall(function() AutoCarrySlider:Set(data.AutoCarryDelay) end)
            end
            safeToggleSet(AntiAfkToggle, data.AntiAfk or false)
            safeToggleSet(AutoUseLuckToggle, data.AutoUseLuck or false)
            
            getgenv().DiscordWebhook = data.Webhook or ""
            pcall(function() WebhookInput:SetValue(getgenv().DiscordWebhook) end)
            
            if RarityDropdown then
                local dictR = {}
                for _, v in ipairs(RaritiesList) do
                    if getgenv().SelectedRarities[string.lower(v)] then
                        dictR[v] = true
                    end
                end
                pcall(function() RarityDropdown:SetValue(dictR) end)
            end
            
            if MutationDropdown then
                local dictM = {}
                for _, v in ipairs(MutationsList) do
                    if getgenv().SelectedMutations[string.lower(v)] then
                        dictM[v] = true
                    end
                end
                pcall(function() MutationDropdown:SetValue(dictM) end)
            end
            
            if GiftRarityDropdown then
                local gArrR = {}
                for _, v in ipairs(RaritiesList) do
                    if getgenv().GiftSelectedRarities[string.lower(v)] then
                        table.insert(gArrR, v)
                    end
                end
                pcall(function() GiftRarityDropdown:SetValue(gArrR) end)
            end

            if GiftMutationDropdown then
                local gArrM = {}
                for _, v in ipairs(MutationsList) do
                    if getgenv().GiftSelectedMutations[string.lower(v)] then
                        table.insert(gArrM, v)
                    end
                end
                pcall(function() GiftMutationDropdown:SetValue(gArrM) end)
            end

            if GiftPackRarityDropdown then
                local gArrP = {}
                for _, v in ipairs(RaritiesList) do
                    if getgenv().GiftSelectedPacks[string.lower(v)] then
                        table.insert(gArrP, v)
                    end
                end
                pcall(function() GiftPackRarityDropdown:SetValue(gArrP) end)
            end

            if GiftPackMutationDropdown then
                local gArrPM = {}
                for _, v in ipairs(MutationsList) do
                    if getgenv().GiftSelectedPackMutations[string.lower(v)] then
                        table.insert(gArrPM, v)
                    end
                end
                pcall(function() GiftPackMutationDropdown:SetValue(gArrPM) end)
            end
            
            WindUI:Notify({ Title = "Config", Content = "Loaded config: " .. name, Duration = 3 })
        else
            WindUI:Notify({ Title = "Config", Content = "Failed to load config: " .. name, Duration = 3 })
        end
    end
end

local ConfigNameInput = ""
MiscTab:Input({
    Title = "Config Name",
    PlaceholderText = "Config name...",
    Callback = function(text)
        ConfigNameInput = text
    end
})

local ConfigDropdown

MiscTab:Button({
    Title = "Save Config",
    Callback = function()
        if ConfigNameInput ~= "" then
            SaveConfig(ConfigNameInput)
            if ConfigDropdown and ConfigDropdown.Refresh then
                pcall(function() ConfigDropdown:Refresh(GetConfigs()) end)
            end
        else
            WindUI:Notify({ Title = "Config", Content = "Please enter a config name", Duration = 3 })
        end
    end
})

local ConfigList = GetConfigs()
local SelectedConfig = ConfigData.Autoload

ConfigDropdown = MiscTab:Dropdown({
    Title = "Saved Configs",
    Values = ConfigList,
    Value = ConfigData.Autoload,
    Callback = function(value)
        if type(value) == "table" then
            for k, v in pairs(value) do
                if type(k) == "number" then
                    SelectedConfig = v
                else
                    SelectedConfig = k
                end
            end
        else
            SelectedConfig = value
        end
    end
})

MiscTab:Button({
    Title = "Refresh Config Library",
    Callback = function()
        if ConfigDropdown and ConfigDropdown.Refresh then
            pcall(function() ConfigDropdown:Refresh(GetConfigs()) end)
        end
        WindUI:Notify({ Title = "Config", Content = "Config list refreshed", Duration = 3 })
    end
})

MiscTab:Button({
    Title = "Load Selected Config",
    Callback = function()
        if SelectedConfig and SelectedConfig ~= "" then
            LoadConfig(SelectedConfig)
        end
    end
})

MiscTab:Button({
    Title = "Delete Selected Config",
    Callback = function()
        if SelectedConfig and SelectedConfig ~= "" then
            if isfile and isfile(ConfigFolder .. "/" .. SelectedConfig .. ".json") then
                pcall(delfile, ConfigFolder .. "/" .. SelectedConfig .. ".json")
                if ConfigData.Autoload == SelectedConfig then
                    ConfigData.Autoload = ""
                    SaveMainConfig()
                end
                if ConfigDropdown and ConfigDropdown.Refresh then
                    pcall(function() ConfigDropdown:Refresh(GetConfigs()) end)
                end
                WindUI:Notify({ Title = "Config", Content = "Deleted config", Duration = 3 })
                SelectedConfig = ""
            else
                WindUI:Notify({ Title = "Config", Content = "Config not found!", Duration = 3 })
            end
        end
    end
})

MiscTab:Toggle({
    Title = "Auto Load Selected Config",
    Value = (ConfigData.Autoload ~= ""),
    Callback = function(state)
        if state then
            ConfigData.Autoload = SelectedConfig
        else
            ConfigData.Autoload = ""
        end
        SaveMainConfig()
    end
})

if ConfigData.Autoload ~= "" then
    task.spawn(function()
        task.wait(1)
        LoadConfig(ConfigData.Autoload)
    end)
end

WindUI:Notify({
    Title = "Dexq Loaded",
    Content = "loaded successfully",
    Duration = 5,
})
