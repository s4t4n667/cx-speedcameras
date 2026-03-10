local DISCORD_WEBHOOK = '' -- Add your webhook here
-- To disable Discord notifications, leave as empty string

if Config.Debug then print("[DEBUG] Loading cx-speedcameras server.lua") end

local function GetFine(speed)
    local unit = Config.MPH and "MPH" or "KM/H"
    for i = #Config.Fines, 1, -1 do
        local tier = Config.Fines[i]
        if speed >= tier.minSpeed then
            if Config.Debug then
                print(("[DEBUG] GetFine: Speed %d %s, Selected fine: $%d (minSpeed: %d)"):format(math.floor(speed), unit, tier.fine, tier.minSpeed))
            end
            return tier.fine
        end
    end
    if Config.Debug then
        print(("[DEBUG] GetFine: Speed %d %s, No fine applied"):format(math.floor(speed), unit))
    end
    return 0
end

RegisterNetEvent('cx-speedcameras:server:checkFine', function(speed, limit, cameraIndex, vehName, plate)
    local src = source
    if Config.Debug then print(("[DEBUG] checkFine: Triggered for source %s, Speed: %s, Limit: %s"):format(src, speed, limit)) end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then
        if Config.Debug then
            print("[DEBUG] Player not found for source: " .. tostring(src))
        end
        return
    end

    local isOwned = false
    local result = exports.oxmysql:executeSync('SELECT 1 FROM player_vehicles WHERE citizenid = :citizenid AND plate = :plate', {citizenid = player.PlayerData.citizenid,plate = plate})
    if result and #result > 0 then isOwned = true end

    if Config.Debug then
        print(("[DEBUG] Vehicle ownership check: Plate %s, Owned: %s"):format(plate or "N/A", tostring(isOwned)))
    end

    if not isOwned then
        if Config.Debug then print("[DEBUG] Vehicle not owned by player; skipping fine.") end
        TriggerClientEvent('ox_lib:notify', src, { title = 'Speed Camera', description = 'You were caught speeding, but no fine was issued as the vehicle is not registered to you.', type = 'inform', duration = 5000 })
        return
    end

    local fine = GetFine(speed)
    if fine <= 0 then
        if Config.Debug then print("[DEBUG] No fine applied (fine = 0)") end
        TriggerClientEvent('cx-speedcameras:client:receiveFine', src, speed, limit, fine, cameraIndex)
        return
    end

    if Config.FinePlayers then
        ChargeSpeedCameraFine(player, fine)
        if Config.Debug then
            print(("[DEBUG] RemoveMoney: Player %s, Fine $%d, Success: %s"):format(player.PlayerData.name, fine, tostring(success)))
        end
    end

    TriggerClientEvent('ox_lib:notify', src, { title = 'Speed Camera', description = ('%s Amount: $%d'):format('You were caught speeding by a camera! Fine issued.', fine), type = 'success', duration = 5000 })

    if DISCORD_WEBHOOK and DISCORD_WEBHOOK ~= '' then
        local embed = {
            {
                title = "🚨 Speeding Violation Caught",
                description = string.format(
                    "**Player:** %s (ID: %s)\n**Vehicle:** %s (Plate: %s)\n**Speed:** %.0f %s (Limit: %d)\n**Location:** Speed Camera #%d\n**Fine:** $%d",
                    player.PlayerData.name,
                    player.PlayerData.citizenid,
                    vehName or "Unknown Vehicle",
                    plate or "Unknown Plate",
                    speed,
                    Config.MPH and "MPH" or "KM/H",
                    limit,
                    cameraIndex,
                    fine
                ),
                color = 16711680,
                image = { url = 'https://testing.strataservers.com/cx-scripts/speedcam.png' },
                footer = { text = "LSPD Speed Enforcement System" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }

        local payload = json.encode({ username = "LSPD Speed Camera", embeds = embed })
        if Config.Debug then print("[DEBUG] Sending Discord payload (webhook configured).") end

        PerformHttpRequest(DISCORD_WEBHOOK, function(err, text, headers)
            if err == 200 or err == 204 then
                if Config.Debug then print("[DEBUG] Embed posted to Discord successfully.") end
            else
                print(("[ERROR] Discord webhook failed: %s - %s"):format(tostring(err), text or "No response"))
            end
        end, 'POST', payload, { ['Content-Type'] = 'application/json' })
    else
        if Config.Debug then print("[DEBUG] DISCORD_WEBHOOK not configured; skipping Discord post.") end
    end

    if Config.Debug then print("[DEBUG] Triggering client:receiveFine for source " .. src) end
    TriggerClientEvent('cx-speedcameras:client:receiveFine', src, speed, limit, fine, cameraIndex)
end)


function ChargeSpeedCameraFine(player, fine)
    local success = player.Functions.RemoveMoney('bank', fine, 'speed-camera-fine')

    if Config.Debug then
        print(("[DEBUG] RemoveMoney: Player %s, Fine $%d, Success: %s"):format(player.PlayerData.name, fine, tostring(success)))
    end

    return success
end