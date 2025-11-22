QBCore = exports['qb-core']:GetCoreObject()
local labels = {}
local craftingQueue = {}
local job = ""
local grade = 0
local currentWorkbenchType = nil
local spawnedWorkbenches = {}

-- Initialize system
Citizen.CreateThread(function()
    while QBCore.Functions.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

    job = QBCore.Functions.GetPlayerData().job.name
    grade = QBCore.Functions.GetPlayerData().job.grade

    -- Load item labels
    for k, v in pairs(QBCore.Shared.Items) do
        labels[k] = v.label
    end

    -- Initialize workbenches after small delay
    Citizen.Wait(1000)
    InitializeWorkbenches()
end)

-- Job update handler
RegisterNetEvent("QBCore:Client:OnJobUpdate")
AddEventHandler("QBCore:Client:OnJobUpdate", function(j)
    job = j.name
    grade = j.grade
end)

-- Initialize workbenches with props and targets
function InitializeWorkbenches()
    for i, workbench in ipairs(Config.Workbenches) do
        local coords = workbench.coords
        local workbenchConfig = Config.WorkbenchTypes[workbench.workbenchType]
        
        -- Spawn workbench prop
        if workbenchConfig.prop then
            SpawnWorkbenchProp(workbench, workbenchConfig, i)
        end
        
        -- Create blip if enabled
        if workbench.blip then
            CreateWorkbenchBlip(workbench, workbenchConfig)
        end
        
        -- Add QB-Target integration
        AddWorkbenchTarget(workbench, workbenchConfig, i)
    end
end

-- Spawn workbench prop
function SpawnWorkbenchProp(workbench, config, index)
    local coords = workbench.coords
    local model = config.prop
    
    -- Load model
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(1)
    end
    
    -- Create prop
    local prop = CreateObject(model, coords.x, coords.y, coords.z - 1.0, false, false, false)
    SetEntityHeading(prop, workbench.heading or 0.0)
    FreezeEntityPosition(prop, true)
    SetEntityInvincible(prop, true)
    
    -- Store reference
    spawnedWorkbenches[index] = {
        prop = prop,
        coords = coords,
        workbenchType = workbench.workbenchType
    }
    
    -- Cleanup model
    SetModelAsNoLongerNeeded(model)
end

-- Create workbench blip
function CreateWorkbenchBlip(workbench, config)
    local blip = AddBlipForCoord(workbench.coords)
    
    SetBlipSprite(blip, config.blipSprite or Config.BlipSprite)
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, config.blipColor or Config.BlipColor)
    SetBlipAsShortRange(blip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(config.name or Config.BlipText)
    EndTextCommandSetBlipName(blip)
end

-- Add QB-Target for workbench
function AddWorkbenchTarget(workbench, config, index)
    local targetName = "crafting_workbench_" .. index
    local coords = workbench.coords
    
    -- QB-Target zone
    exports['qb-target']:AddBoxZone(targetName, coords, 2.0, 2.0, {
        name = targetName,
        heading = workbench.heading or 0.0,
        debugPoly = Config.Debug or false,
        minZ = coords.z - 1.0,
        maxZ = coords.z + 1.5,
    }, {
        options = {
            {
                type = "client",
                event = "dost_crafting:openWorkbench",
                icon = config.targetIcon or "fas fa-hammer",
                label = config.targetLabel or ("Use " .. config.name),
                workbenchType = workbench.workbenchType,
                canInteract = function()
                    return CanAccessWorkbench(workbench)
                end
            }
        },
        distance = 2.5
    })
end

-- Check if player can access workbench
function CanAccessWorkbench(workbench)
    if #workbench.jobs == 0 then
        return true
    end
    
    for _, allowedJob in ipairs(workbench.jobs) do
        if allowedJob == job then
            return true
        end
    end
    
    return false
end

-- QB-Target event handler
RegisterNetEvent('dost_crafting:openWorkbench')
AddEventHandler('dost_crafting:openWorkbench', function(data)
    local workbenchType = data.workbenchType
    
    if CanAccessWorkbenchByType(workbenchType) then
        TriggerServerEvent("dost_crafting:getWorkbenchRecipes", workbenchType)
    else
        QBCore.Functions.Notify(Config.Text['wrong_job'], 'error')
    end
end)

-- Check access by workbench type
function CanAccessWorkbenchByType(workbenchType)
    for _, workbench in ipairs(Config.Workbenches) do
        if workbench.workbenchType == workbenchType then
            return CanAccessWorkbench(workbench)
        end
    end
    return false
end

-- Legacy function for distance checking
function isNearWorkbench()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    for _, v in ipairs(Config.Workbenches) do
        local dst = #(coords - v.coords)
        if dst < v.radius then
            return true
        end
    end
    
    return false
end

-- Crafting queue handler
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if craftingQueue[1] ~= nil then
            if not Config.CraftingStopWithDistance or (Config.CraftingStopWithDistance and isNearWorkbench()) then
                craftingQueue[1].time = craftingQueue[1].time - 1

                SendNUIMessage({
                    type = "addqueue",
                    item = craftingQueue[1].item,
                    time = craftingQueue[1].time,
                    id = craftingQueue[1].id
                })

                if craftingQueue[1].time == 0 then
                    TriggerServerEvent("dost_crafting:itemCrafted", craftingQueue[1].item, craftingQueue[1].count)
                    table.remove(craftingQueue, 1)
                end
            end
        end
    end
end)

-- Event to receive workbench-specific recipes
RegisterNetEvent("dost_crafting:receiveWorkbenchRecipes")
AddEventHandler("dost_crafting:receiveWorkbenchRecipes", function(recipes, workbenchType)
    openWorkbench({recipes = recipes}, workbenchType)
end)

-- Open workbench UI
function openWorkbench(val, workbenchType)
    local inv = {}
    local recipes = val.recipes or {}
    currentWorkbenchType = workbenchType
    
    SetNuiFocus(true, true)
    TriggerScreenblurFadeIn(500)
    local player = QBCore.Functions.GetPlayerData()
    
    -- No levels needed - skill system only
    local levels = {}
    
    for _, v in pairs(player.items) do
        inv[v.name] = v.amount
    end

    SendNUIMessage({
        type = "open",
        recipes = recipes,
        names = labels,
        level = levels,
        inventory = inv,
        job = job,
        grade = grade,
        hidecraft = Config.HideWhenCantCraft,
        categories = Config.Categories,
        workbenchType = workbenchType,
        workbenchName = Config.WorkbenchTypes[workbenchType] and Config.WorkbenchTypes[workbenchType].name or "Workbench"
    })
end

-- Legacy event for opening workbench
RegisterNetEvent("open:workbench")
AddEventHandler("open:workbench", function(workbenchType)
    workbenchType = workbenchType or Config.Workbenches[1].workbenchType
    
    if CanAccessWorkbenchByType(workbenchType) then
        TriggerServerEvent("dost_crafting:getWorkbenchRecipes", workbenchType)
    else
        QBCore.Functions.Notify(Config.Text['wrong_job'], 'error')
    end
end)

-- Craft start event
RegisterNetEvent("dost_crafting:craftStart")
AddEventHandler("dost_crafting:craftStart", function(item, count)
    local id = math.random(1000, 9999)
    local recipe = nil
    
    -- Find the recipe
    for recipeKey, recipeData in pairs(Config.Recipes) do
        if recipeKey == item then
            recipe = recipeData
            break
        end
    end
    
    if recipe then
        table.insert(craftingQueue, {time = recipe.Time, item = item, count = 1, id = id})

        SendNUIMessage({
            type = "crafting",
            item = item
        })

        SendNUIMessage({
            type = "addqueue",
            item = item,
            time = recipe.Time,
            id = id
        })
    end
end)

-- NUI Callbacks
RegisterNUICallback("close", function(data, cb)
    TriggerScreenblurFadeOut(500)
    SetNuiFocus(false, false)
    currentWorkbenchType = nil
    cb('ok')
end)

RegisterNUICallback("craft", function(data, cb)
    local item = data["item"]
    TriggerServerEvent("dost_crafting:craft", item, false)
    cb('ok')
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, workbench in pairs(spawnedWorkbenches) do
            if DoesEntityExist(workbench.prop) then
                DeleteEntity(workbench.prop)
            end
        end
        
        -- Remove QB-Target zones
        for i = 1, #Config.Workbenches do
            exports['qb-target']:RemoveZone("crafting_workbench_" .. i)
        end
    end
end)

-- Legacy text drawing (kept for compatibility)
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoord())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)
    local scale = ((1 / dist) * 2) * (1 / GetGameplayCamFov()) * 100

    if onScreen then
        SetTextColour(255, 255, 255, 255)
        SetTextScale(0.0 * scale, 0.35 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextCentre(true)
        SetTextDropshadow(1, 1, 1, 1, 255)

        BeginTextCommandWidth("STRING")
        AddTextComponentString(text)
        local height = GetTextScaleHeight(0.55 * scale, 4)
        local width = EndTextCommandGetWidth(4)

        SetTextEntry("STRING")
        AddTextComponentString(text)
        EndTextCommandDisplayText(_x, _y)
    end
end