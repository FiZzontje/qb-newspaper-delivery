local QBCore = exports['qb-core']:GetCoreObject()
local onDuty = false
local currentArea = nil
local papersLeft = 0
local currentDeliveryIndex = 1  -- 🆕 TRACK HUIDIGE DEUR
local npcBlip = nil
local deliveryBlips = {}

-- NPC Spawn & Blip (ongewijzigd)
Citizen.CreateThread(function()
    local npcHash = `u_m_m_aldinapoli`
    RequestModel(npcHash); while not HasModelLoaded(npcHash) do Wait(1) end
    
    local npc = CreatePed(4, npcHash, Config.JobLocation.x, Config.JobLocation.y, Config.JobLocation.z-1.0, Config.JobLocation.w, false, true)
    FreezeEntityPosition(npc, true); SetEntityInvincible(npc, true); SetBlockingOfNonTemporaryEvents(npc, true)
    
    npcBlip = AddBlipForCoord(Config.NPCBlip.coords.x, Config.NPCBlip.coords.y, Config.NPCBlip.coords.z)
    SetBlipSprite(npcBlip, Config.NPCBlip.sprite); SetBlipColour(npcBlip, Config.NPCBlip.color)
    SetBlipScale(npcBlip, Config.NPCBlip.scale); SetBlipAsShortRange(npcBlip, true)
    BeginTextCommandSetBlipName("STRING"); AddTextComponentString(Config.NPCBlip.label); EndTextCommandSetBlipName(npcBlip)
    
    exports['qb-target']:AddTargetEntity(npc, {
        options = {
            {type="client", event="qb-newspaper:client:startJob", icon="fas fa-newspaper", label="📰 Start Job", 
             job=nil, canInteract=function() return not onDuty end},
            {type="client", event="qb-newspaper:client:claimReward", icon="fas fa-dollar-sign", label="💰 Claim Reward", 
             canInteract=function() return onDuty and papersLeft==0 end},
            {type="client", event="qb-newspaper:client:quitJob", icon="fas fa-stop", label="⏹️ Stop Job", 
             canInteract=function() return onDuty end}
        }, distance=2.5
    })
end)

RegisterNetEvent('qb-newspaper:client:startJob', function()
    QBCore.Functions.TriggerCallback('qb-newspaper:server:canStart', function(can) 
        if can then TriggerServerEvent('qb-newspaper:server:startDuty') end
    end)
end)

RegisterNetEvent('qb-newspaper:client:startDutySuccess', function(areaIndex)
    onDuty = true
    currentArea = Config.Areas[areaIndex or 1]
    papersLeft = #currentArea.locations
    currentDeliveryIndex = 1  -- 🆕 RESET NAAR EERSTE DEUR
    TriggerServerEvent('qb-newspaper:server:givePapers', papersLeft)
    QBCore.Functions.Notify('📰 '..papersLeft..' Doors: #'..currentDeliveryIndex, 'success')
    SetNewWaypoint(currentArea.locations[1].x, currentArea.locations[1].y)
end)

-- 🆕 MAIN LOOP - ALLEEN HUIDIGE DEUR ACTIEF
Citizen.CreateThread(function()
    while true do
        local PlayerPed = PlayerPedId()
        Wait(0)
        if onDuty and currentArea and papersLeft > 0 and currentDeliveryIndex <= #currentArea.locations then
            local loc = currentArea.locations[currentDeliveryIndex]  -- 🆕 ALLEEN HUIDIGE DEUR!
            local blipId = 'delivery_'..currentDeliveryIndex
            
            -- Blip voor huidige deur
            if not deliveryBlips[blipId] then
                deliveryBlips[blipId] = AddBlipForCoord(loc.x, loc.y, loc.z)
                SetBlipSprite(deliveryBlips[blipId], Config.DeliveryBlip.sprite)
                SetBlipColour(deliveryBlips[blipId], Config.DeliveryBlip.color)
                SetBlipScale(deliveryBlips[blipId], Config.DeliveryBlip.scale)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("📰 Door "..currentDeliveryIndex.."/"..papersLeft)
                EndTextCommandSetBlipName(deliveryBlips[blipId])
            end
            
            -- 🆕 MARKER & TEXT ALLEEN BIJ HUIDIGE DEUR
            DrawMarker(1, loc.x, loc.y, loc.z-1, 0,0,0,0,0,0, 2.5,2.5,1.5, 0,255,0,200,false,true,2)
            if #(GetEntityCoords(PlayerPed)-loc) < 3.0 then
                QBCore.Functions.DrawText3D(loc.x, loc.y, loc.z, "[E] 📰 Door "..currentDeliveryIndex.." ("..papersLeft.." total)")
                
                if IsControlJustReleased(0,38) then
                    -- Animatie
                    local ped = PlayerPedId()
                    TaskTurnPedToFaceCoord(ped, loc.x, loc.y, loc.z, 1000); Wait(1000)
                    
                    -- Neerbuigen
                    RequestAnimDict("mini@repair")
                    while not HasAnimDictLoaded("mini@repair") do Wait(5) end
                    TaskPlayAnim(ped, "mini@repair", "fixing_a_player", 8.0, -8.0, 2500, 1, 0, false, false, false)
                    Wait(2500)
                    
                    TriggerServerEvent('qb-newspaper:server:usePaper')
                    
                    -- Opstaan
                    RequestAnimDict("anim@mp_player_intmenu@key_fob@")
                    while not HasAnimDictLoaded("anim@mp_player_intmenu@key_fob@") do Wait(5) end
                    TaskPlayAnim(ped, "anim@mp_player_intmenu@key_fob@", "fob_click_fp", 8.0, -8.0, 1500, 1, 0, false, false, false)
                    Wait(1500); ClearPedTasks(ped)
                    
                    -- 🆕 PROGRESSIE UPDATE
                    papersLeft = papersLeft - 1
                    currentDeliveryIndex = currentDeliveryIndex + 1  -- VOLGENDE DEUR!
                    TriggerServerEvent('qb-newspaper:server:deliverPaper')
                    RemoveBlip(deliveryBlips[blipId]); deliveryBlips[blipId] = nil
                    
                    QBCore.Functions.Notify('✅ Door '..(currentDeliveryIndex-1)..'Done! → #'..currentDeliveryIndex..' (€50-120)', 'success')
                    
                    if papersLeft > 0 then
                        -- Waypoint naar VOLGENDE deur
                        local nextLoc = currentArea.locations[currentDeliveryIndex]
                        SetNewWaypoint(nextLoc.x, nextLoc.y)
                    else
                        -- Klaar!
                        QBCore.Functions.Notify('🎉 all '..(#currentArea.locations)..' doors done! → Go back to the newspaper stand for the BONUS!', 'success')
                        SetNewWaypoint(Config.JobLocation.x, Config.JobLocation.y)
                        SetBlipFlashes(npcBlip, true)
                        Citizen.SetTimeout(5000, function() SetBlipFlashes(npcBlip, false) end)
                    end
                end
            end
        end
    end
end)

-- Events
RegisterNetEvent('qb-newspaper:client:claimReward', function() TriggerServerEvent('qb-newspaper:server:claimReward') end)
RegisterNetEvent('qb-newspaper:client:quitJob', function() TriggerServerEvent('qb-newspaper:server:quitDuty') end)
RegisterNetEvent('qb-newspaper:client:endDuty', function()
    onDuty = false; currentArea = nil; papersLeft = 0; currentDeliveryIndex = 1
    for k,v in pairs(deliveryBlips) do RemoveBlip(v); deliveryBlips[k] = nil end
    QBCore.Functions.Notify('Dienst gestopt', 'primary')
end)
