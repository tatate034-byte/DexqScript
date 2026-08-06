local Config = loadstring(readfile("Config.lua"))() -- หรือเรียกใช้งานจาก Table โดยตรง
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

getgenv().CurrentGiftedCount = 0
getgenv().AutoGiftRunning = true

task.spawn(function()
    while getgenv().AutoGiftRunning do
        local targetName = Config.TargetPlayer
        local maxLimit = tonumber(Config.MaxGiftLimit) or 0
        
        -- ตรวจสอบโควตาการส่ง
        if maxLimit > 0 and getgenv().CurrentGiftedCount >= maxLimit then
            warn("[AutoGift] ส่งครบตามจำนวนจำกัดแล้ว ระบบหยุดทำงาน")
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
                    for _, tool in ipairs(backpack:GetChildren()) do
                        if not getgenv().AutoGiftRunning then break end
                        if not tool:IsA("Tool") then continue end
                        
                        local toolNameLower = string.lower(tool.Name)
                        local rAttrLower = string.lower(tool:GetAttribute("Rarity") or "")
                        local mutationAttr = string.lower(tool:GetAttribute("Mutation") or "normal")
                        
                        -- เช็คเงื่อนไขความหายากและ Mutation ตาม Config
                        local matchRarity = (next(Config.SelectedRarities) == nil) or Config.SelectedRarities[rAttrLower] or string.find(toolNameLower, rAttrLower)
                        local matchMutation = (next(Config.SelectedMutations) == nil) or Config.SelectedMutations[mutationAttr] or string.find(toolNameLower, mutationAttr)
                        
                        if matchRarity and matchMutation then
                            -- เทเลพอร์ตไปหาเป้าหมายและถือไอเทม
                            hrp.CFrame = targetHrp.CFrame + Vector3.new(0, 0, 2)
                            task.wait(0.1)
                            
                            if character:FindFirstChild("Humanoid") then
                                character.Humanoid:EquipTool(tool)
                                task.wait(0.15)
                            end
                            
                            -- กด ProximityPrompt เพื่อส่งกิฟต์
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
                            
                            -- หน่วงเวลารอคูลดาวน์ระบบเกม (5.2 วินาที)
                            task.wait(5.2)
                            
                            -- เช็คว่าไอเทมถูกส่งออกไปจริงไหม
                            if tool.Parent ~= backpack then
                                getgenv().CurrentGiftedCount = getgenv().CurrentGiftedCount + 1
                                break
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)
