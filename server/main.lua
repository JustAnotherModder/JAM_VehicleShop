JAM_VehicleShop = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)	

ESX.RegisterServerCallback('JAM_VehicleShop:GetVehiclesAndCategories', function(source, cb)
	local vehicles = {}
	local categories = {}
	local data = MySQL.Sync.fetchAll("SELECT * FROM vehicles")

	for k,v in pairs(data) do
		local canAdd = true

		for _k,_v in pairs(categories) do
			if(v.category == _v.category) then
				canAdd = false
			end
		end

		if canAdd then
			table.insert(categories,{category = v.category})
		end

		table.insert(vehicles,{name = v.name, model = v.model, price = v.price, category = v.category})
	end
	cb(vehicles, categories)
end)

ESX.RegisterServerCallback('JAM_VehicleShop:HasEnoughMoney', function(source, cb, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
	if not xPlayer then return; end

	local hasEnough = false
	local playerId = xPlayer.getIdentifier()	

	if xPlayer.getMoney() >= amount then
		xPlayer.removeMoney(amount)
		hasEnough = true
	end
	cb(hasEnough)
end)

RegisterServerEvent('JAM_VehicleShop:SetVehicleOwnership')
AddEventHandler('JAM_VehicleShop:SetVehicleOwnership', function(vehicleProps)
	local xPlayer = ESX.GetPlayerFromId(source)
	if not xPlayer then return; end

	MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, stored, jamstate) VALUES (@owner, @plate, @vehicle, @stored, @state)',
	{
		['@owner']   = xPlayer.identifier,
		['@plate']   = vehicleProps.plate,
		['@vehicle'] = json.encode(vehicleProps),
		['@stored']	 = 0,
		['@state']	 = 0,
	})
end)