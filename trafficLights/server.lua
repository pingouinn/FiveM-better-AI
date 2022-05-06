-------------------
-- Synced Events --
-------------------

-- Documentation : 
    -- Event "trafficLight:server:sync" : Send a synced table over the clients

RegisterNetEvent("trafficLight:server:sync")
AddEventHandler("trafficLight:server:sync",function(table, state)
    TriggerClientEvent("trafficLight:client:sync", -1, table, state)
end)