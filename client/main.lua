-------------------------------------------
--#######################################--
--##                                   ##--
--##       Get ESX shared object       ##--
--##                                   ##--
--#######################################--
-------------------------------------------

function JAM_VehicleShop:GetSharedObject(obj) self.ESX = obj; ESX = obj; end

-------------------------------------------
--#######################################--
--##                                   ##--
--##      Blip and Marker Updates      ##--
--##                                   ##--
--#######################################--
-------------------------------------------

function JAM_VehicleShop:UpdateMarkers()
    if not self or not self.Config or not self.Config.Markers then return; end

    for key,val in pairs(self.Config.Markers) do
        if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), val.Pos.x, val.Pos.y, val.Pos.z) < self.Config.MarkerDrawDistance then
            DrawMarker(val.Type, val.Pos.x, val.Pos.y, val.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, val.Scale.x, val.Scale.y, val.Scale.z, val.Color.r, val.Color.g, val.Color.b, 100, false, true, 2, false, false, false, false)
        end
    end
end

function JAM_VehicleShop:UpdateBlips()
    if not self or not self.Config or not self.Config.Blips then return; end

    for key,val in pairs(self.Config.Blips) do
        local blip = AddBlipForCoord(val.Pos.x, val.Pos.y, val.Pos.z)
        SetBlipSprite               (blip, val.Sprite)
        SetBlipDisplay              (blip, val.Display)
        SetBlipScale                (blip, val.Scale)
        SetBlipColour               (blip, val.Color)
        SetBlipAsShortRange         (blip, true)
        BeginTextCommandSetBlipName ("STRING")
        AddTextComponentString      (val.Zone)
        EndTextCommandSetBlipName   (blip)
    end
end

-------------------------------------------
--#######################################--
--##                                   ##--
--##       Check player position       ##--
--##        relevant to markers        ##--
--##                                   ##--
--#######################################--
-------------------------------------------

function JAM_VehicleShop:CheckPosition()
    if not self or not self.Config or not self.Config.Markers then return; end

    self.StandingInMarker = self.StandingInMarker or false

    local standingInMarker = false

    for key,val in pairs(self.Config.Markers) do
        if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), val.Pos.x, val.Pos.y, val.Pos.z) < val.Scale.x then
            standingInMarker = true
        end
    end

    if standingInMarker and not self.StandingInMarker then
        self.StandingInMarker = true
        self.ActionData = ActionData or {};
        self.ActionData.Action = true        
        self.ActionData.Message = 'Press ~INPUT_PICKUP~ to access the vehicle store.'
    end

    if not standingInMarker and self.StandingInMarker then
        self.StandingInMarker = false
        self.ActionData.Action = false

        if not self.seatedInVehicle then
            self.ESX.UI.Menu.CloseAll()
        end
    end
end

-------------------------------------------
--#######################################--
--##                                   ##--
--##        Check for input if         ##--
--##           inside marker           ##--
--##                                   ##--
--#######################################--
-------------------------------------------

function JAM_VehicleShop:CheckInput()
    if not self or not self.ActionData then return; end

    self.Timer = self.Timer or 0

    if self.ActionData.Action then
        SetTextComponentFormat('STRING')
        AddTextComponentString(self.ActionData.Message)
        DisplayHelpTextFromStringLabel(0, 0, 1, -1)

        if IsControlPressed(0, self.Config.Keys['E']) and (GetGameTimer() - self.Timer) > 150 then
            self:OpenShopMenu()
            self.ActionData.Action = false
            self.Timer = GetGameTimer()
        end
    end
end

-------------------------------------------
--#######################################--
--##                                   ##--
--##             Shop Menus            ##--
--##                                   ##--
--#######################################--
-------------------------------------------

function JAM_VehicleShop:OpenShopMenu()
    if not self or not self.ESX or not ESX then return; end

    self.ESX.UI.Menu.CloseAll()

    local elements = {}

    for k,v in pairs(self.categoryList) do
        table.insert(elements,{label = v.category:sub(1,1):upper() .. v.category:sub(2)})
    end

    self.ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), "Auto_Dealer",
    {
        title = "Auto Dealer",
        align = 'top-left',
        elements = elements,
    },

    function(data, menu)
        menu.close()
        for k,v in pairs(self.categoryList) do
            if data.current.label == v.category:sub(1,1):upper() .. v.category:sub(2) then
                self:OpenVehicleList(data.current.label)
            end
        end
    end,
    function(data, menu)
        menu.close()        
        if self.seatedInVehicle then
            self.ActionData.Action = false
            self:DeleteSpawnedVehicles() 
        else
            self.ActionData.Action = true
        end
    end
    )
end

function JAM_VehicleShop:OpenVehicleList(category)
    if not self or not self.ESX or not ESX then return; end
    local _category = category:sub(1,1):lower() .. category:sub(2)
    self.ESX.UI.Menu.CloseAll()

    local elements = {}

    for k,v in pairs(self.sortedList) do
        for _k,_v in pairs(v) do
            if _v.category == _category then
                table.insert(elements,{label = _v.name .. " : $" .. _v.price, value = _v})
            end
        end
    end

    self.ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), category,
    {
        title = category,
        align = 'top-left',
        elements = elements,
    },

    function(data, menu)                -- model                xpos            ypos        zpos        heading

        menu.close()
        self:DeleteSpawnedVehicles()

        local playerPed = PlayerPedId()

        ESX.Game.SpawnLocalVehicle(data.current.value.model, {x = -47.570, y = -1097.221, z = 25.422}, -20.0, function (vehicle)

            TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
            FreezeEntityPosition(vehicle, true)
            table.insert(self.spawnedVehicles, {veh = vehicle})
            self.seatedInVehicle = true
            self:OpenPurchaseMenu(data.current.value)
        end)
    end,

    function(data, menu)
        menu.close()
        self:OpenShopMenu()
    end
    )
end

function JAM_VehicleShop:OpenPurchaseMenu(vehicle)
    print("OPEN BUY MENU")
    if not self or not self.ESX or not ESX then return; end
    print(vehicle.name, vehicle.price)

    self.ESX.UI.Menu.CloseAll()

    local elements = {}
    local playerPed = PlayerPedId()

    table.insert(elements, {label = "Buy : $" .. vehicle.price, value = 'Buy'})

    self.ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), "Purhcase",
    {
        title = "Purhcase",
        align = 'top-left',
        elements = elements,
    },
    function(data, menu)

        menu.close()
        if data.current.value == 'Buy' then
            self:DeleteSpawnedVehicles()

            ESX.TriggerServerCallback('JAM_VehicleShop:HasEnoughMoney', function(valid) 
                if valid then
                    ESX.Game.SpawnVehicle(vehicle.model, {x = -47.570, y = -1097.221, z = 25.422}, -20.0, function (veh)     
                        menu.close()
            
                        TaskWarpPedIntoVehicle(playerPed, veh, -1)    
                        local vehicleProps = ESX.Game.GetVehicleProperties(veh)
                        TriggerServerEvent('JAM_VehicleShop:SetVehicleOwnership', vehicleProps)

                        TriggerEvent('esx:showNotification', "You have purchased a new vehicle.")                        
                    end)
                else
                    TriggerEvent('esx:showNotification', "You don't have enough money.")
                end
            end, vehicle.price)            
        end
    end,  

    function(data, menu)
        menu.close()
        self:OpenVehicleList(vehicle.category)
    end
    )
end

-------------------------------------------
--#######################################--
--##                                   ##--
--##     Delete Vehicles Function      ##--
--##                                   ##--
--#######################################--
-------------------------------------------
    

function JAM_VehicleShop:DeleteSpawnedVehicles()
    while #self.spawnedVehicles > 0 do
        for k,v in pairs(self.spawnedVehicles) do
            ESX.Game.DeleteVehicle(v.veh)
            table.remove(self.spawnedVehicles, 1)
        end
        Citizen.Wait(0)
    end
end

-------------------------------------------
--#######################################--
--##                                   ##--
--##         Retrieve Shop Data        ##--
--##                                   ##--
--#######################################--
-------------------------------------------


function JAM_VehicleShop:GetShopData()
    ESX.TriggerServerCallback('JAM_VehicleShop:GetVehiclesAndCategories', function(vehicles, categories)
        self.vehicleList = vehicles
        self.categoryList = categories

        self:SortVehiclesToCategory(vehicles, categories)
    end)
end

function JAM_VehicleShop:SortVehiclesToCategory(vehiclelist, categorylist)
    local sortedList = {}
    for k,v in pairs(categorylist) do
        for _k,_v in pairs(vehiclelist) do
            if _v.category == v.category then
                table.insert(sortedList, {category = v.category, vehicle = _v})
            end
        end
    end

    self.sortedList = sortedList
end

-------------------------------------------
--#######################################--
--##                                   ##--
--##     VehicleShop Update Thread     ##--
--##                                   ##--
--#######################################--
-------------------------------------------

function JAM_VehicleShop:Update()
    Citizen.Wait(1000)
    TriggerEvent('esx:getSharedObject', function(...) self:GetSharedObject(...); end);

    Citizen.Wait(1000)
    
    self.tick = 0
    self.sortedList = {}
    self.spawnedVehicles = {}
    self:GetShopData()
    self:UpdateBlips()

    while true do
        self:UpdateMarkers()
        self:CheckPosition()
        self:CheckInput()

        self.tick = self.tick + 1

        Citizen.Wait(0)
    end
end

Citizen.CreateThread(function(...) JAM_VehicleShop:Update(...); end)
