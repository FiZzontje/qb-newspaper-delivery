local QBCore = exports['qb-core']:GetCoreObject()
local PlayersOnDuty = {}
local PlayerBorg = {}

-- Item gebruik (krant consumeren)
QBCore.Functions.CreateUseableItem(Config.NewspaperItem, function(source)
    local src = source
    if PlayersOnDuty[src] then
        local Player = QBCore.Functions.GetPlayer(src)
        Player.Functions.RemoveItem(Config.NewspaperItem, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.NewspaperItem], "remove", 1)
    end
end)

QBCore.Functions.CreateCallback('qb-newspaper:server:canStart', function(source, cb)
    cb(not PlayersOnDuty[source])
end)

RegisterNetEvent('qb-newspaper:server:startDuty', function()
    local src = source; local Player = QBCore.Functions.GetPlayer(src)
    if not PlayersOnDuty[src] and Player.Functions.RemoveMoney('cash', Config.BorgAmount) then
        PlayerBorg[src] = Config.BorgAmount; PlayersOnDuty[src] = true
        local areaIndex = math.random(1, #Config.Areas)
        TriggerClientEvent('qb-newspaper:client:startDutySuccess', src, areaIndex)
    else
        TriggerClientEvent('QBCore:Notify', src, '❌ Geen borg (€'..Config.BorgAmount..') of al bezig!', 'error')
    end
end)

RegisterNetEvent('qb-newspaper:server:givePapers', function(amount)
    local src = source; local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.AddItem(Config.NewspaperItem, amount)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.NewspaperItem], "add", amount)
end)

RegisterNetEvent('qb-newspaper:server:usePaper', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if PlayersOnDuty[src] and Player.Functions.RemoveItem(Config.NewspaperItem, 1) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.NewspaperItem], "remove", 1)
    end
end)

RegisterNetEvent('qb-newspaper:server:deliverPaper', function()
    local src = source; if PlayersOnDuty[src] then
        local Player = QBCore.Functions.GetPlayer(src)
        local reward = math.random(50, 120)
        Player.Functions.AddMoney('cash', reward)
        TriggerClientEvent('QBCore:Notify', src, '+$'..reward..' verdiend!', 'success')
    end
end)

RegisterNetEvent('qb-newspaper:server:claimReward', function()
    local src = source; if PlayersOnDuty[src] then
        local Player = QBCore.Functions.GetPlayer(src)
        local bonus = math.random(300, 600) -- bonus the
        Player.Functions.AddMoney('cash', bonus)
        TriggerClientEvent('QBCore:Notify', src, '🎉 BONUS €'..bonus..'! Perfect!', 'success')
        TriggerClientEvent('qb-newspaper:client:endDuty', src)
        PlayersOnDuty[src] = nil; PlayerBorg[src] = nil
    end
end)

RegisterNetEvent('qb-newspaper:server:quitDuty', function()
    local src = source; if PlayersOnDuty[src] then
        local Player = QBCore.Functions.GetPlayer(src)
        if PlayerBorg[src] then Player.Functions.AddMoney('cash', PlayerBorg[src]) end
        TriggerClientEvent('qb-newspaper:client:endDuty', src)
        PlayersOnDuty[src] = nil; PlayerBorg[src] = nil
    end
end)

AddEventHandler('playerDropped', function() 
    local src = source; PlayersOnDuty[src] = nil; PlayerBorg[src] = nil
end)
