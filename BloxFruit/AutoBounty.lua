false Configs = getgenv().configs
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

task.wait(4)

local Configs = getgenv().configs or {
    ["SkipPlayerTime"] = 10,
    ["HopMode"] = true,
    ["SafeModeHP"] = 40,
    ["Team"] = "Pirate",
    ["TPMethod"] = "Tween",
    ["DistancePlayer"] = 15
}


local currentTarget = nil
local currentTween = nil
local targetAttackStartTime = 0
local isAttackingStarted = false 
local isLockedTarget = false
local isDead = false
local isSafeHealing = false
local lastAbilityTime = 15
local abilityCooldown = 15
local blacklist = {}
local isHoping = false
local targetFindCooldown = 0 
local isReadyToHunt = false

local teamSelected = Configs.Team
if teamSelected == "Pirate" then teamSelected = "Pirates" end
if teamSelected == "Marine" then teamSelected = "Marines" end

local function selectTeam()
    pcall(function()
        local commF = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
        if commF then
            commF:InvokeServer("SetTeam2", teamSelected)
        end
    end)
end

local function enablePvpAfterDeath()
    pcall(function()
        local commF = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
        if commF then
            commF:InvokeServer("EnablePvp")
        end
    end)
end

local function activateAbility()
    pcall(function()
        local commE = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommE")
        if commE then
            commE:FireServer("ActivateAbility")
        end
    end)
end

local function hopServer()
    if not Configs.HopMode or isHoping then return end
    isHoping = true
    
    pcall(function()
        local currentPlaceId = game.PlaceId
        if currentPlaceId ~= 275391518 and currentPlaceId ~= 4442272183 and currentPlaceId ~= 7449423635 then
            currentPlaceId = 7449423635 
        end
        
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. currentPlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        for _, s in ipairs(servers.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                local success = pcall(function()
                    TeleportService:TeleportToPlaceInstance(currentPlaceId, s.id, LocalPlayer)
                end)
                if success then
                    break
                end
            end
        end
    end)
    
    task.wait(3)
    isHoping = false
end

local function getBloxFruitTool()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return nil end
    
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            if tool.ToolTip and string.find(tool.ToolTip, "Blox Fruit") then
                return tool
            end
            local appearance = tool:FindFirstChild("Appearance")
            if appearance then
                local tooltip = appearance:FindFirstChild("ToolTip")
                if tooltip and type(tooltip.Value) == "string" and string.find(tooltip.Value, "Blox Fruit") then
                    return tool
                end
            end
        end
    end
    return nil
end

local function equipBloxFruit()
    pcall(function()
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        local currentTool = character:FindFirstChildOfClass("Tool")
        local isHoldingFruit = false
        if currentTool and currentTool.ToolTip and string.find(currentTool.ToolTip, "Blox Fruit") then
            isHoldingFruit = true
        end
        
        if not isHoldingFruit then
            local fruitTool = getBloxFruitTool()
            if fruitTool then
                humanoid:EquipTool(fruitTool)
            end
        end
    end)
end

local function isTransformed()
    local character = LocalPlayer.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid:GetAttribute("Transformed") then
        return true
    end
    
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and (part.Size.Magnitude > 10 or character:GetAttribute("IsTransformed")) then
            return true
        end
    end
    
    return false
end

local function checkAndTransform()
    pcall(function()
        if not isTransformed() then
            local character = LocalPlayer.Character
            if character and character:FindFirstChildOfClass("Humanoid") then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid:FindFirstChild("") then
                    humanoid[""]:InvokeServer("V")
                end
            end
        end
    end)
end

selectTeam()
task.wait(3)
equipBloxFruit()
task.wait(0.5)
checkAndTransform()
isReadyToHunt = true

local function setupCharacter(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid then
        isDead = false
        isSafeHealing = false
        isReadyToHunt = false
        
        task.delay(3, function()
            if not isDead and LocalPlayer.Character == character then
                equipBloxFruit()
                task.wait(0.5)
                checkAndTransform()
                isReadyToHunt = true
                targetFindCooldown = tick() + 1
            end
        end)

        humanoid.Died:Connect(function()
            if not isDead then
                isDead = true
                isSafeHealing = false
                isReadyToHunt = false
                if currentTween then currentTween:Cancel() currentTween = nil end
                currentTarget = nil
                isLockedTarget = false
                isAttackingStarted = false
                targetFindCooldown = tick() + 3
                
                task.delay(2, function()
                    enablePvpAfterDeath()
                end)
            end
        end)
    end
end

if LocalPlayer.Character then
    setupCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

local function isInMapSafeZone(player)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    local hrp = char.HumanoidRootPart
    
    local worldOrigin = Workspace:FindFirstChild("_WorldOrigin")
    if worldOrigin then
        local safeZones = worldOrigin:FindFirstChild("SafeZones")
        if safeZones then
            for _, zonePart in ipairs(safeZones:GetChildren()) do
                if zonePart:IsA("BasePart") then
                    local distance = (hrp.Position - zonePart.Position).Magnitude
                    local maxDim = math.max(zonePart.Size.X, zonePart.Size.Y, zonePart.Size.Z) / 2
                    if distance <= maxDim + 15 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function isValidTarget(player)
    if player == LocalPlayer then return false end
    if blacklist[player] then return false end
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
    
    local targetHum = player.Character:FindFirstChildOfClass("Humanoid")
    if not targetHum or targetHum.Health <= 0 then return false end
    
    if isInMapSafeZone(player) then
        return false
    end
    
    return true
end

local function isLocalInSafeZone()
    return isInMapSafeZone(LocalPlayer)
end

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local Event = ReplicatedStorage.Remotes.CommE
            Event:FireServer("Ken", true)
        end)
    end
end)

task.spawn(function()
    local commE = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommE")
    if commE then
        commE.OnClientEvent:Connect(function(...)
            local args = {...}
            if args[1] == "Ken" and args[2] == false then
                pcall(function()
                    commE:FireServer("Ken", true)
                end)
            end
        end)
    end
end)

RunService.Stepped:Connect(function()
    pcall(function()
        local character = LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end)

RunService.Heartbeat:Connect(function()
    pcall(function()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChildOfClass("Humanoid") then
            return
        end
        
        if not isReadyToHunt then return end
        
        local hrp = character.HumanoidRootPart
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        equipBloxFruit()
        
        if not isTransformed() then
            checkAndTransform()
        end
        
        local currentHPPercent = (humanoid.Health / humanoid.MaxHealth) * 100
        
        if currentHPPercent < Configs.SafeModeHP then
            if not isSafeHealing then
                isSafeHealing = true
                if currentTween then currentTween:Cancel() currentTween = nil end
                currentTarget = nil
                isLockedTarget = false
                isAttackingStarted = false
                targetFindCooldown = tick() + 2
                
                local escapeCFrame = hrp.CFrame * CFrame.new(0, 1500, 0)
                local escapeTween = TweenService:Create(hrp, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {CFrame = escapeCFrame})
                escapeTween:Play()
            end
        end
        
        if isSafeHealing then
            if currentHPPercent >= 50 then
                isSafeHealing = false
                targetFindCooldown = tick() + 1 
            else
                hrp.Velocity = Vector3.new(0, 0, 0)
                return
            end
        end
        
        if isLocalInSafeZone() then
            enablePvpAfterDeath()
        end
        
        if currentTarget then
            local targetChar = currentTarget.Character
            local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
            local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
            
            if not targetHRP or not targetHum or targetHum.Health <= 0 or isInMapSafeZone(currentTarget) or (isAttackingStarted and (tick() - targetAttackStartTime) > Configs.SkipPlayerTime) then
                if currentTween then currentTween:Cancel() currentTween = nil end
                blacklist[currentTarget] = true
                currentTarget = nil
                isAttackingStarted = false
                isLockedTarget = false
                targetFindCooldown = tick() + 1 
            else
                local distance = (hrp.Position - targetHRP.Position).Magnitude
                local behindTargetCFrame = targetHRP.CFrame * CFrame.new(0, 5, Configs.DistancePlayer)
                
                if Configs.TPMethod == "Tween" then
                    if distance > 25 then
                        if not currentTween or currentTween.PlaybackState ~= Enum.PlaybackState.Playing then
                            local speed = 300
                            local timeTaken = distance / speed
                            local tweenInfo = TweenInfo.new(timeTaken, Enum.EasingStyle.Linear)
                            currentTween = TweenService:Create(hrp, tweenInfo, {CFrame = behindTargetCFrame})
                            currentTween:Play()
                        end
                    else
                        if currentTween then currentTween:Cancel() currentTween = nil end
                        hrp.CFrame = behindTargetCFrame
                        
                        if not isAttackingStarted then
                            isAttackingStarted = true
                            targetAttackStartTime = tick()
                            isLockedTarget = true
                        end
                        
                        local tool = character:FindFirstChildOfClass("Tool")
                        if tool and tool:FindFirstChild("LeftClickRemote") then
                            tool.LeftClickRemote:FireServer(targetHRP.Position)
                        end
                    end
                elseif Configs.TPMethod == "TP" then
                    hrp.CFrame = behindTargetCFrame
                    
                    if not isAttackingStarted then
                        isAttackingStarted = true
                        targetAttackStartTime = tick()
                        isLockedTarget = true
                    end
                    
                    local tool = character:FindFirstChildOfClass("Tool")
                    if tool and tool:FindFirstChild("LeftClickRemote") then
                        tool.LeftClickRemote:FireServer(targetHRP.Position)
                    end
                end
            end
        end
        
        if not currentTarget and not isLockedTarget then
            isAttackingStarted = false
            
            if tick() >= targetFindCooldown then
                local shortestDistance = math.huge
                for _, player in ipairs(Players:GetPlayers()) do
                    if isValidTarget(player) then
                        local targetChar = player.Character
                        local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                        if targetHRP then
                            local distance = (hrp.Position - targetHRP.Position).Magnitude
                            if distance < shortestDistance then
                                shortestDistance = distance
                                currentTarget = player
                            end
                        end
                    end
                end
                
                if currentTarget then
                    if (tick() - lastAbilityTime) >= abilityCooldown then
                        lastAbilityTime = tick()
                        activateAbility()
                    end
                end
            end
        end
        
        if not currentTarget and not isLockedTarget and tick() >= targetFindCooldown then
            hopServer()
            task.wait(3)
            return
        end
    end)
end)
