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
local keyValues = {}
local handles = {}
local threshold = 100
local tempTables = {}

-- State variables

local newCheck = true 

--------------------
-- Main functions --
--------------------

----------- TODO : EVENTS TO DECORS -------------
----------- TODO : REWORK OF THE LOOPS ------------

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

				for i,v in pairs(handles) do 
					local offset = GetOffsetFromEntityInWorldCoords(vehicle, 5.0, 50.0, 0.0)
					local coords = GetEntityCoords(v)
					local dist = #(coords - offset)

					if dist < 20.0 then 
						local trafficHeading = GetEntityHeading(v)
						local head = GetEntityHeading(ped)

						if math.abs(head - trafficHeading) < 15.0 and math.abs(head - trafficHeading) > -15.0 then 
							local temp = {}
							for k, w in pairs(handles) do
								local coords2 = GetEntityCoords(w)
								if #(coords2 - coords) < 75.0 then 
									if temp[w] == nil then
										temp[w] = coords2
									end
								end
							end
							table.append(tempTables, temp)

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

--------------------- TODO : REWORK OF THE CODE AFTER THIS ------------

				local vehfaceD = GetOffsetFromEntityInWorldCoords(vehicle, 3.0, 12.0, 0.0)
				local vehfaceG = GetOffsetFromEntityInWorldCoords(vehicle, -2.0, 12.0, 0.0)
		
				local vehDecalD = GetClosestVehicle(vehfaceD, 3.0, 0, 70)
				local vehDecalG = GetClosestVehicle(vehfaceG, 2.0, 0, 70)
		
				if vehDecalD ~= nil then
					local drivePedD = GetPedInVehicleSeat(vehDecalD, -1)    
					TaskVehicleDriveToCoord(drivePedD, vehDecalD, vehfaceD.x , vehfaceD.y , vehfaceD.z , 50, 0, GetEntityModel(vehDecalD), 786603 , 50, true)
				end
		
				if vehDecalG ~= nil then
					local drivePedG = GetPedInVehicleSeat(vehDecalG, -1)
					TaskVehicleDriveToCoord(drivePedG, vehDecalG, vehfaceG.x , vehfaceG.y , vehfaceG.z , 50, 0, GetEntityModel(vehDecalG), 786603 , 50, true)
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
	if keyValues[handle] ~= nil then
		table.insert(handles, handle)
		return true
	end
	return false
end

------------
-- Events --
------------

------------------ TODO : KeyValues management  ------------------

RegisterNetEvent("trafficLight:client:sync")
AddEventHandler("trafficLight:client:sync",function(table, color)
    for i,v in pairs(table) do 
		for j,w in pairs(trafficLights) do 
			local result = GetClosestObjectOfType(v.x, v.y, v.z, 2.0, w, false, false, false)
			SetEntityTrafficlightOverride(result, color)
		end
	end
end)
