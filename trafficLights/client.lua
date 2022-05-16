---------------
-- Variables --
---------------

-- World related variables

local ped 
local pos
local vehicle

-- Data variables 

local trafficLights = {
	'prop_traffic_01a',
	'prop_traffic_01b',
	'prop_traffic_01d',
	'prop_traffic_02a',
	'prop_traffic_02b',
	'prop_traffic_03a',
	'prop_traffic_lightset_01',
}
local pool = {
	__gc = function(enum)
	  	if enum.destructor and enum.handle then
			enum.destructor(enum.handle)
	  	end
	  	enum.destructor = nil
	  	enum.handle = nil
	end
}
local keyValues, handles, tempTables = {}, {}, {}
local threshold = 100
local last

-- State variables

local newCheck = true 

--------------------
-- Main functions --
--------------------

-- Main thread : 

Citizen.CreateThread(function()
	for i, v in pairs(trafficLights) do
		keyValues[GetHashKey(v)] = i
	end

	while true do
		ped = PlayerPedId()
		pos = GetEntityCoords(ped)

		if IsPedInAnyVehicle(ped, false) then 
			vehicle = GetVehiclePedIsIn(ped, false)

			if GetVehicleClass(vehicle) == 18 and IsVehicleSirenOn(vehicle) then 
				threshold = 1
				if newCheck then
					for obj in Pools(FindFirstObject, FindNextObject, EndFindObject) do
						IsTrafficObject(obj)
					end
					newCheck = false 
					Citizen.SetTimeout(1300, function()
						newCheck = true
					end)
				end

				if handles ~= nil then
					for i, v in pairs(handles) do 
						local offset = GetOffsetFromEntityInWorldCoords(vehicle, 5.0, 50.0, 0.0)
						local coords = GetEntityCoords(v)
						local dist = #(coords - offset)

						if dist < 20.0 then 
							local trafficHeading = GetEntityHeading(v)
							local head = GetEntityHeading(ped)

							if math.abs(head - trafficHeading) < 15.0 and math.abs(head - trafficHeading) > -15.0 and v ~= last then 
								last = v
								local temp = {}
								for k, w in pairs(handles) do
									local coords2 = GetEntityCoords(w)
									if #(coords2 - coords) < 75.0 then 
										if temp[w] == nil then
											temp[w] = {coords2, GetEntityModel(w)}
										end
									end
								end
								table.insert(tempTables, temp)

								TriggerServerEvent('trafficLight:server:sync', temp, 1)

								local temp2 = {}
								for veh in Pools(FindFirstVehicle, FindNextVehicle, EndFindVehicle) do
									if #(GetEntityCoords(veh) - pos) < 50.0 and veh ~= GetVehiclePedIsIn(ped, false) and not IsPedAPlayer(GetPedInVehicleSeat(x)) then 
										BringVehicleToHalt(veh, 8.0, 1500, false)
										table.insert(temp2, veh)
									end
								end
							
								Citizen.SetTimeout(6000, function()
									TriggerServerEvent('trafficLight:server:sync', tempTables[1], 3)
									table.remove(tempTables, 1)
									for i, v in pairs(temp2) do 
										StopBringVehicleToHalt(v)
									end
								end)
							end
						elseif dist > 200.0 or not DoesEntityExist(v) then 
							table.remove(handles, i)
						end
					end
				end

				local offset = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 12.0, 0.0)
		
				local vehR = GetClosestVehicle(offset.x + 3.0 , offset.y , offset.z, 3.0, 0, 70)
				local vehL = GetClosestVehicle(offset.x - 2.0, offset.y , offset.z, 2.0, 0, 70)
		
				if vehR ~= 0 then
					local headDiff = math.abs(GetEntityHeading(ped) - GetEntityHeading(vehR))
					if headDiff < 15.0 and headDiff > -15.0 then
						local dvPed = GetPedInVehicleSeat(vehR, -1)    
						TaskVehicleDriveToCoord(dvPed, vehR, GetOffsetFromEntityInWorldCoords(vehR, 2.5, 6.0, 0.0), 50, 0, GetEntityModel(vehR), 786603 , 50, true)
					end
				end
		
				if vehL ~= 0 then
					local headDiff = math.abs(GetEntityHeading(ped) - GetEntityHeading(vehL))
					if headDiff < 15.0 and headDiff > -15.0 then
						local dvPed = GetPedInVehicleSeat(vehL, -1)
						TaskVehicleDriveToCoord(dvPed, vehL, GetOffsetFromEntityInWorldCoords(vehL, -2.5, 6.0, 0.0), 50, 0, GetEntityModel(vehL), 786603 , 50, true)
					end
				end
			else 
				for i, v in pairs(sirens) do 
					local localHandle = NetToVeh(v)
					if #(GetEntityCoords(localHandle) - pos) < 120.0 then
						if GetEntitySpeed(localHandle) > 10.0 then
							playWarning()
						end
					end
				end
			end
		else 
			threshold = 1500
		end
		Citizen.Wait(threshold)
	end
end)

---------------
-- Functions --
---------------

function Pools(initFunc, moveFunc, disposeFunc)
	return coroutine.wrap(function()
	  	local iter, id = initFunc()
	  	if not id or id == 0 then
			disposeFunc(iter)
			return
	  	end

	  	local enum = {handle = iter, destructor = disposeFunc}
	  	setmetatable(enum, pool)
	  
	  	local next = true
	  	repeat
			coroutine.yield(id)
			next, id = moveFunc(iter)
	  	until not next
	  
	  	enum.destructor, enum.handle = nil, nil
	  	disposeFunc(iter)
	end)
end

function IsTrafficObject(handle)
	local model = GetEntityModel(handle)
	if keyValues[model] ~= nil then
		table.insert(handles, handle)
		return true
	end
	return false
end

function playWarning()
	------------------- TODO : WRITE THIS FUNCTION ------------------------
end

------------
-- Events --
------------

RegisterNetEvent("trafficLight:client:sync")
AddEventHandler("trafficLight:client:sync",function(table, color)
    for i,v in pairs(table) do 
		local kv = trafficLights[keyValues[v[2]]]
		if kv ~= nil then 
			local result = GetClosestObjectOfType(v[1].x, v[1].y, v[1].z, 2.0, kv, false, false, false)
			SetEntityTrafficlightOverride(result, color)
		end
	end
end)