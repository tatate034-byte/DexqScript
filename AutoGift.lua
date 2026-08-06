-- ==========================================
-- AUTO GIFT MAIN SCRIPT (Optimized & Stable)
-- ==========================================

_G.AutoGiftConfig = _G.AutoGiftConfig or {
    TargetPlayer = "DefaultTarget",
    MaxLimit = 0,
    SendCards = true,
    Cards = {
        ["secret"] = true,
        ["divine"] = true,
    },
    CardMutations = {
        ["rainbow"] = true,
        ["golden"] = true
    },
    SendPacks = true,
    Packs = {
        ["Sand Pack"] = true,
    }
}

local Config = _G.AutoGiftConfig
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

getgenv().CurrentGiftedCount = 0
getgenv().AutoGiftRunning = true

task.spawn(function()
    while getgenv().AutoGiftRunning do
        local targetName = Config.TargetPlayer
        local maxLimit = tonumber(Config.MaxLimit) or 0
        
        if maxLimit > 0 and getgenv().CurrentGiftedCount >= maxLimit then
            warn("[AutoGift] ส่งครบตามจำนวนจำกัดแล้ว ระบบหยุดทำงาน")
            getgenv().AutoGiftRunning = false
            break
        end
        
        if targetName and targetName ~= "" and targetName ~= LocalPlayer.Name then
            pcall(function()
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                
                local targetPlayer = Players:FindFirstChild(targetName)
                local targetChar = targetPlayer and targetPlayer.Character
                local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                
                if hrp and targetHrp and backpack then
                    -- ตารางเก็บรายการที่พยายามส่งไปแล้วในรอบนี้ เพื่อป้องกันการวนซ้ำชิ้นเดิมถ้ามีปัญหา
                    local attemptedTools = {}
                    
                    for _, tool in ipairs(backpack:GetChildren()) do
                        if not getgenv().AutoGiftRunning then break end
                        if not tool:IsA("Tool") then continue end
                        if attemptedTools[tool] then continue end -- ข้ามชิ้นที่เคยลองแล้วในรอบนี้
                        
                        local toolName = tool.Name
                        local toolNameLower = string.lower(toolName)
                        local rAttrLower = string.lower(tool:GetAttribute("Rarity") or "")
                        local mutationAttr = string.lower(tool:GetAttribute("Mutation") or "normal")
                        
                        local shouldSend = false
                        
                        -- เงื่อนไขเช็ค "การ์ด"
                        if Config.SendCards and (Config.Cards[toolName] or Config.Cards[rAttrLower]) then
                            local matchMutation = (next(Config.CardMutations) == nil) or Config.CardMutations[mutationAttr] or string.find(toolNameLower, mutationAttr)
                            if matchMutation then
                                shouldSend = true
                            end
                        end
                        
                        -- เงื่อนไขเช็ค "แพ็ค"
                        if Config.SendPacks and Config.Packs[toolName] then
                            shouldSend = true
                        end
                        
                        if shouldSend then
                            attemptedTools[tool] = true -- ทำเครื่องหมายว่าชิ้นนี้กำลังดำเนินการ
                            
                            -- เทเลพอร์ตไปใกล้เป้าหมาย
                            hrp.CFrame = targetHrp.CFrame + Vector3.new(0, 0, 2)
                            task.wait(0.15)
                            
                            -- ถือไอเทม
                            if character:FindFirstChild("Humanoid") then
                                local humanoid = character.Humanoid
                                pcall(function()
                                    humanoid:EquipTool(tool)
                                end)
                                task.wait(0.2)
                            end
                            
                            -- กด ProximityPrompt ของเป้าหมาย
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
                            
                            -- รอเวลาคูลดาวน์ระบบเกม (ปรับยืดหยุ่นให้เสถียรขึ้น)
                            task.wait(5.0)
                            
                            -- ตรวจสอบว่าไอเทมถูกส่งออกไปจริงไหม (เช็คว่าหลุดจาก Backpack หรือถูกทำลาย)
                            if not tool.Parent or tool.Parent ~= backpack then
                                getgenv().CurrentGiftedCount = getgenv().CurrentGiftedCount + 1
                                task.wait(0.5) -- พักเล็กน้อยหลังส่งสำเร็จ
                                break -- หลุดลูปย่อยเพื่ออัปเดตสถานะกระเป๋าใหม่
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)
