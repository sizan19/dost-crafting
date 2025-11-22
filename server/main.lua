QBCore = exports['qb-core']:GetCoreObject()

-- Function to check if player has required skill (devhub_skillTree)
function HasRequiredSkill(source, item)
    local recipe = Config.Recipes[item]
    if not recipe or not recipe.SkillRequirement then
        return true -- No skill requirement
    end
    
    local skillCategory = recipe.SkillRequirement.category
    local skillId = recipe.SkillRequirement.skill
    
    -- Handle different skill formats
    local hasSkill = false
    
    if type(skillId) == "table" then
        -- Multiple skills required (array format) - ANY of these unlocked
        for _, singleSkill in ipairs(skillId) do
            if exports['devhub_skillTree']:hasUnlockedSkill(skillCategory, singleSkill, source) then
                hasSkill = true
                break
            end
        end
    elseif type(skillId) == "string" then
        -- Single skill required
        hasSkill = exports['devhub_skillTree']:hasUnlockedSkill(skillCategory, skillId, source)
    end
    
    return hasSkill
end

-- Function to check crafting requirements
function CanCraftItem(source, item)
    local hasSkill = HasRequiredSkill(source, item)
    
    return {
        canCraft = hasSkill,
        hasSkill = hasSkill,
        skillLocked = not hasSkill
    }
end

-- Main Craft Event
RegisterServerEvent("dost_crafting:craft")
AddEventHandler("dost_crafting:craft", function(item, retrying)
    local src = source
    local recipe = Config.Recipes[item]
    
    if not recipe then
        TriggerClientEvent('QBCore:Notify', src, "Recipe not found!", "error")
        return
    end
    
    -- Check skill requirements
    local craftCheck = CanCraftItem(src, item)
    
    if not craftCheck.canCraft then
        local errorMsg = ""
        
        if craftCheck.skillLocked then
            local skillName = "Unknown Skill"
            if recipe.SkillRequirement then
                if type(recipe.SkillRequirement.skill) == "table" then
                    skillName = table.concat(recipe.SkillRequirement.skill, " or ")
                else
                    skillName = recipe.SkillRequirement.skill
                end
            end
            errorMsg = string.format("You need the skill: %s to craft this item", skillName)
        end
        
        TriggerClientEvent('QBCore:Notify', src, errorMsg, 'error')
        return
    end
    
    craft(src, item, retrying)
end)

-- Event to get available recipes for a single workbench type
RegisterServerEvent("dost_crafting:getWorkbenchRecipes")
AddEventHandler("dost_crafting:getWorkbenchRecipes", function(workbenchType)
    local src = source
    local availableRecipes = {}

    -- Get all recipes for this workbench type
    for itemName, recipe in pairs(Config.Recipes) do
        if recipe.WorkbenchType == workbenchType then
            -- Create a copy of the recipe
            local recipeData = {}
            for k, v in pairs(recipe) do
                recipeData[k] = v
            end

            -- Check skill requirements
            local craftCheck = CanCraftItem(src, itemName)

            -- Set locking flags
            recipeData.SkillLocked = craftCheck.skillLocked
            recipeData.CanCraft = craftCheck.canCraft

            availableRecipes[itemName] = recipeData
        end
    end

    TriggerClientEvent("dost_crafting:receiveWorkbenchRecipes", src, availableRecipes, workbenchType)
end)

-- Event to get recipes for multiple workbench types (for external scripts like housing)
RegisterServerEvent("dost_crafting:getMultiWorkbenchRecipes")
AddEventHandler("dost_crafting:getMultiWorkbenchRecipes", function(workbenchTypes)
    local src = source
    local availableRecipes = {}

    -- Ensure workbenchTypes is a table
    if type(workbenchTypes) ~= 'table' then
        workbenchTypes = {workbenchTypes}
    end

    -- Create a lookup table for faster checking
    local typeMap = {}
    for _, wType in ipairs(workbenchTypes) do
        typeMap[wType] = true
    end

    -- Get all recipes matching any of the workbench types
    for itemName, recipe in pairs(Config.Recipes) do
        if typeMap[recipe.WorkbenchType] then
            -- Create a copy of the recipe
            local recipeData = {}
            for k, v in pairs(recipe) do
                recipeData[k] = v
            end

            -- Check skill requirements
            local craftCheck = CanCraftItem(src, itemName)

            -- Set locking flags
            recipeData.SkillLocked = craftCheck.skillLocked
            recipeData.CanCraft = craftCheck.canCraft

            availableRecipes[itemName] = recipeData
        end
    end

    TriggerClientEvent("dost_crafting:receiveMultiWorkbenchRecipes", src, availableRecipes, workbenchTypes)
end)

-- -- XP Books for skill system
-- QBCore.Functions.CreateUseableItem("bookranger", function(source, item)
--     local Player = QBCore.Functions.GetPlayer(source)
--     if not Player then return end

--     Player.Functions.RemoveItem("bookranger", 1, item.slot)
--     TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["bookranger"], "remove")

--     -- Add XP to devhub_skillTree system
--     exports['devhub_skillTree']:addXp('personal', 100, source)
    
--     TriggerClientEvent("QBCore:Notify", source, "You study the Ranger techniques and gain XP!", "success")
-- end)

-- QBCore.Functions.CreateUseableItem("bookclothing", function(source, item)
--     local Player = QBCore.Functions.GetPlayer(source)
--     if not Player then return end

--     Player.Functions.RemoveItem("bookclothing", 1, item.slot)
--     TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["bookclothing"], "remove")

--     -- Add XP to devhub_skillTree system
--     exports['devhub_skillTree']:addXp('personal', 50, source)

--     TriggerClientEvent("QBCore:Notify", source, "You study the Clothing manual and gain XP!", "success")
-- end)

-- QBCore.Functions.CreateUseableItem("bookelectronics", function(source, item)
--     local Player = QBCore.Functions.GetPlayer(source)
--     if not Player then return end

--     Player.Functions.RemoveItem("bookelectronics", 1, item.slot)
--     TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["bookelectronics"], "remove")

--     -- Add XP to devhub_skillTree system
--     exports['devhub_skillTree']:addXp('personal', 75, source)

--     TriggerClientEvent("QBCore:Notify", source, "You study the Electronics manual and gain XP!", "success")
-- end)

-- Item crafted event
RegisterServerEvent("dost_crafting:itemCrafted")
AddEventHandler("dost_crafting:itemCrafted", function(item, count)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local recipe = Config.Recipes[item]
    
    if not recipe then return end
    
    -- local xpAmount = recipe.XPReward or 10

    if recipe.SuccessRate >= math.random(0, 100) then
        -- Add the crafted item
        Player.Functions.AddItem(item, recipe.Amount)
        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[item], "add")
        TriggerClientEvent('QBCore:Notify', src, Config.Text['item_crafted'], 'success')
        
        -- Add XP to devhub_skillTree
        -- exports['devhub_skillTree']:addXp('personal', xpAmount, src)
    else
        TriggerClientEvent('QBCore:Notify', src, Config.Text['crafting_failed'], 'error')
    end
end)

-- Main crafting function
function craft(src, item)
    local xPlayer = QBCore.Functions.GetPlayer(src)
    local recipe = Config.Recipes[item]
    
    if not recipe then
        TriggerClientEvent('QBCore:Notify', src, "Recipe not found!", "error")
        return
    end
    
    local cancraft = false
    local total = 0
    local count = 0
    local reward = recipe.Amount

    -- Check if player has all required ingredients
    for ingredientName, requiredAmount in pairs(recipe.Ingredients) do
        total = total + 1
        local playerItem = xPlayer.Functions.GetItemByName(ingredientName)
        if playerItem ~= nil and playerItem.amount >= requiredAmount then
            count = count + 1
        end
    end
    
    if total == count then
        cancraft = true
    else
        TriggerClientEvent('QBCore:Notify', src, Config.Text['not_enough_ingredients'], "error")
        return
    end

    if cancraft then
        -- Remove ingredients (except permanent items)
        for ingredientName, requiredAmount in pairs(recipe.Ingredients) do
            if not Config.PermanentItems[ingredientName] then
                xPlayer.Functions.RemoveItem(ingredientName, requiredAmount)
                TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[ingredientName], "remove")
            end
        end
        
        -- Start crafting process
        TriggerClientEvent("dost_crafting:craftStart", src, item, reward)
    end
end