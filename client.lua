local lastTriggered = {}

local function IsEmergencyVehicle(vehicle)
    local vehicleClass = GetVehicleClass(vehicle)
    return vehicleClass == 18
end

Citizen.CreateThread(function()
    if not Config.UseBlips then return end
    local propModel = GetHashKey('prop_cctv_pole_01a')
    RequestModel(propModel)
    while not HasModelLoaded(propModel) do Wait(0) end

    for i, camera in ipairs(Config.Cameras) do
        local blip = AddBlipForCoord(camera.coords.x, camera.coords.y, camera.coords.z)
        SetBlipSprite(blip, 184)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.4)
        SetBlipColour(blip, 46)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Speed Camera")
        EndTextCommandSetBlipName(blip)

        local prop = CreateObject(propModel, camera.coords.x, camera.coords.y, camera.coords.z, false, false, false)
        SetEntityHeading(prop, camera.coords.w)
        FreezeEntityPosition(prop, true)

        if Config.Debug then
            print("Camera Spawned - Speed Limit: " .. camera.speedLimit .. ", Location: " .. tostring(camera.coords))
        end
    end
    SetModelAsNoLongerNeeded(propModel)
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if not IsEmergencyVehicle(vehicle) then
                local speed = GetEntitySpeed(vehicle) * 3.6
                if Config.MPH then speed = speed * 0.621371 end

                for i, camera in ipairs(Config.Cameras) do
                    local dist = #(GetEntityCoords(vehicle) - vector3(camera.coords.x, camera.coords.y, camera.coords.z))
                    if dist < 60.0 then
                        sleep = 0
                        local limit = camera.speedLimit + Config.GracePeriod
                        if speed > limit and (not lastTriggered[i] or (GetGameTimer() - lastTriggered[i]) > Config.Cooldown * 1000) then
                            local driverPed = GetPedInVehicleSeat(vehicle, -1)
                            if playerPed == driverPed then
                                local vehModel = GetEntityModel(vehicle)
                                local vehName = GetLabelText(GetDisplayNameFromVehicleModel(vehModel)) or "Unknown Vehicle"
                                local plate = GetVehicleNumberPlateText(vehicle):gsub("%s+", "")
                                if Config.Debug then
                                    print("[DEBUG] Triggering server:checkFine - Speed: " .. math.floor(speed) .. ", Limit: " .. limit .. ", Camera: " .. i)
                                end
                                TriggerServerEvent('cx-speedcameras:server:checkFine', speed, camera.speedLimit, i, vehName, plate)
                            end
                            lastTriggered[i] = GetGameTimer()
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('cx-speedcameras:client:receiveFine')
AddEventHandler('cx-speedcameras:client:receiveFine', function(speed, limit, fine, cameraIndex)

    if Config.Debug then
        print("[DEBUG] Received fine event - Speed: " .. speed .. ", Limit: " .. limit .. ", Fine: " .. fine .. ", Camera: " .. cameraIndex)
    end

    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local vehName = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))) or "Unknown Vehicle"

    local message = ("You were caught going %d %s in a %s | Speed Limit: %d | Fine: $%d"):format(math.floor(speed), Config.MPH and "MPH" or "KM/H", vehName, limit, fine)

    if Config.Debug then print("[DEBUG] Sending email: " .. message) end

    TriggerServerEvent('qb-phone:server:sendNewMail', {sender = "LSPD", subject = "Speeding Fine Issued", message = message})

    if Config.UseFlashEffect then
        SetFlash(0, 0, 200, 150, 200)
    end

    if Config.UseCameraSound then
        PlaySoundFrontend(-1, "Camera_Shoot", "Phone_SoundSet_Default", true)
    end

    if Config.Dispatch.useDispatch then
        SendSpeedCameraDispatch(playerPed, vehicle, vehName)
    end
end)

function SendSpeedCameraDispatch(playerPed, vehicle, vehName)
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    local plate = GetVehicleNumberPlateText(vehicle)

    if Config.Dispatch.system == "ps-dispatch" then
        local dispatchData = {
            message = "Speeding Vehicle Detected",
            dispatchCode = "2",
            code = "10-11",
            icon = "fas fa-car",
            priority = "2",
            coords = coords,
            heading = heading,
            vehicle = vehName,
            plate = plate,
            jobs = Config.Dispatch.jobs,
            alert = {
                radius = 50,
                sprite = 1,
                color = 1,
                scale = 0.7,
                length = 5,
                sound = "Lose_1st",
                sound2 = "GTAO_FM_Events_Soundset",
                offset = false,
                flash = true
            }
        }
        TriggerServerEvent('ps-dispatch:server:notify', dispatchData)
    elseif Config.Dispatch.system == "cd_dispatch" then
        TriggerServerEvent('cd_dispatch:AddNotification', {
            job_table = Config.Dispatch.jobs,
            coords = coords,
            title = "10-11 | Speed Camera",
            message = "Speeding vehicle detected",
            flash = 0,
            unique_id = tostring(math.random(0000000,9999999)),
            blip = {
                sprite = 1,
                scale = 0.7,
                colour = 1,
                flashes = true,
                text = "Speed Camera",
                time = (5*60*1000),
                radius = 0,
            }
        })
    elseif Config.Dispatch.system == "lb-tablet" then
        local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street = GetStreetNameFromHashKey(streetHash)

        exports["lb-tablet"]:AddDispatch({
            priority = "low",
            code = "10-11",
            title = "Speeding Vehicle",
            description = "Speeding Vehicle Detected - " .. plate,
            location = {
                label = street,
                coords = coords
            },
            time = 20,
            job = "police",
        })
    elseif Config.Dispatch.system == "custom" then
        --- INSERT CUSTOM CODE HERE
    end
    if Config.Debug then
        print("[DEBUG] Dispatch sent via: " .. Config.Dispatch.system)
    end
end

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if Config.Debug then
            print("[DEBUG] Starting Cxspers Speed Cameras")
        end
    end
end)