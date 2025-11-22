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

        -- Handle workbenchType being either a string or table
        local primaryType = workbench.workbenchType
        if type(primaryType) == 'table' then
            primaryType = primaryType[1] -- Use first type for config lookup
        end

        local workbenchConfig = Config.WorkbenchTypes[primaryType]

        if not workbenchConfig then
            print('[dost_crafting] Warning: No config found for workbench type: ' .. tostring(primaryType))
            goto continue
        end

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

        ::continue::
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
        -- If workbenchType is a table (multiple types), use multi-workbench event
        if type(workbenchType) == 'table' then
            TriggerServerEvent("dost_crafting:getMultiWorkbenchRecipes", workbenchType)
        else
            TriggerServerEvent("dost_crafting:getWorkbenchRecipes", workbenchType)
        end
    else
        QBCore.Functions.Notify(Config.Text['wrong_job'], 'error')
    end
end)

-- Check access by workbench type (handles both string and table types)
function CanAccessWorkbenchByType(workbenchType)
    for _, workbench in ipairs(Config.Workbenches) do
        local wbType = workbench.workbenchType

        -- Check if types match (handle both string and table comparisons)
        local matches = false
        if type(wbType) == 'table' and type(workbenchType) == 'table' then
            -- Both are tables, check if they have same first element
            matches = (wbType[1] == workbenchType[1])
        elseif type(wbType) == 'string' and type(workbenchType) == 'string' then
            matches = (wbType == workbenchType)
        elseif type(wbType) == 'table' and type(workbenchType) == 'string' then
            -- Check if string is in the table
            for _, t in ipairs(wbType) do
                if t == workbenchType then
                    matches = true
                    break
                end
            end
        end

        if matches then
            return CanAccessWorkbench(workbench)
        end
    end
    return true -- Default allow if no matching workbench config found
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

-- ============================================
-- EXPORTS FOR EXTERNAL SCRIPTS (Housing, etc.)
-- ============================================

-- Open crafting menu with specific categories
-- Usage: exports['dost_crafting']:OpenCraftingMenu('weapons') -- single type
-- Usage: exports['dost_crafting']:OpenCraftingMenu({'weapons', 'survival'}) -- multiple types
-- Usage: exports['dost_crafting']:OpenCraftingMenu('all') -- all categories
function OpenCraftingMenu(workbenchTypes)
    if type(workbenchTypes) == 'string' then
        if workbenchTypes == 'all' then
            -- Convert to table with all types
            workbenchTypes = {'weapons', 'survival', 'medical'}
        else
            -- Single type passed as string
            workbenchTypes = {workbenchTypes}
        end
    end

    TriggerServerEvent("dost_crafting:getMultiWorkbenchRecipes", workbenchTypes)
end

exports('OpenCraftingMenu', OpenCraftingMenu)

-- Event handler for external scripts
RegisterNetEvent('dost_crafting:openCraftingMenu')
AddEventHandler('dost_crafting:openCraftingMenu', function(workbenchTypes)
    OpenCraftingMenu(workbenchTypes)
end)

-- Event to receive multi-workbench recipes
RegisterNetEvent("dost_crafting:receiveMultiWorkbenchRecipes")
AddEventHandler("dost_crafting:receiveMultiWorkbenchRecipes", function(recipes, workbenchTypes)
    local displayName = "Crafting Station"

    if #workbenchTypes == 1 then
        local config = Config.WorkbenchTypes[workbenchTypes[1]]
        if config then
            displayName = config.name
        end
    else
        displayName = "Universal Crafting"
    end

    openWorkbenchMulti({recipes = recipes}, workbenchTypes, displayName)
end)

-- Open workbench UI for multiple types
function openWorkbenchMulti(val, workbenchTypes, displayName)
    local inv = {}
    local recipes = val.recipes or {}
    currentWorkbenchType = workbenchTypes

    SetNuiFocus(true, true)
    TriggerScreenblurFadeIn(500)
    local player = QBCore.Functions.GetPlayerData()

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
        workbenchType = type(workbenchTypes) == 'table' and workbenchTypes[1] or workbenchTypes,
        workbenchName = displayName
    })
end

-- ============================================
-- TEST COMMANDS
-- ============================================

-- Test command: /testcraft [type]
-- Usage: /testcraft all | /testcraft weapons | /testcraft survival | /testcraft medical
RegisterCommand('testcraft', function(source, args)
    local craftType = args[1] or 'all'

    if craftType == 'all' then
        OpenCraftingMenu('all')
    elseif craftType == 'weapons' or craftType == 'survival' or craftType == 'medical' then
        OpenCraftingMenu(craftType)
    else
        QBCore.Functions.Notify('Usage: /testcraft [all|weapons|survival|medical]', 'error')
    end
end, false)

-- Test command for multiple types: /testcraftmulti weapons,survival
RegisterCommand('testcraftmulti', function(source, args)
    if not args[1] then
        QBCore.Functions.Notify('Usage: /testcraftmulti weapons,survival,medical', 'error')
        return
    end

    local types = {}
    for type in string.gmatch(args[1], '([^,]+)') do
        table.insert(types, type)
    end

    if #types > 0 then
        OpenCraftingMenu(types)
    else
        QBCore.Functions.Notify('No valid types provided', 'error')
    end
end, false)

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