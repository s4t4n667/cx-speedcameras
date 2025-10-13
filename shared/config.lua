Config = {}
Config.Debug = false -- Enable verbose debug logging for the resource
Config.MPH = true -- true = MPH, false = KM/H
Config.UseBlips = true -- Show blips on the map
Config.UseFlashEffect = true -- Flash camera effect
Config.UseCameraSound = true -- Play shutter sound when triggered
Config.FinePlayers = true -- Actually deduct fines
Config.GracePeriod = 5 -- Grace MPH/KM before fine triggers
Config.Cooldown = 60 -- Cooldown between triggers per camera

-- Dispatch Integration (PS-dispatch only)
Config.UseDispatch = true -- Enable PS-dispatch alerts for speeding
Config.DispatchCode = 'speeding' -- Code name in alerts.lua for PS-dispatch
Config.DispatchPriority = 2 -- PS-dispatch priority
Config.DispatchJobs = { 'leo' } -- Jobs that receive the alert

Config.Cameras = {
    {coords = vector4(129.4788, -978.7402, 28.3572, 20.5138), speedLimit = 60},
    {coords = vector4(215.5583, -1012.4580, 28.2797, 70.3095), speedLimit = 60},
    {coords = vector4(263.2112, -881.4597, 28.1290, 220.4618), speedLimit = 60},
    {coords = vector4(182.9164, -847.2209, 30.0537, 240.2815), speedLimit = 60},
    {coords = vector4(237.5170, -600.8360, 41.5681, 200.9582), speedLimit = 60},
}

Config.Fines = {
    {minSpeed = 35, fine = 150},
    {minSpeed = 40, fine = 300},
    {minSpeed = 50, fine = 500},
    {minSpeed = 60, fine = 750},
    {minSpeed = 75, fine = 900},
    {minSpeed = 100, fine = 1250},
    {minSpeed = 125, fine = 2000},
    {minSpeed = 150, fine = 2500},
    {minSpeed = 175, fine = 3000},
    {minSpeed = 200, fine = 3500},
    {minSpeed = 210, fine = 4500},
    {minSpeed = 220, fine = 5000},
    
}

Config.SpeedingNotification = 'You were caught speeding by a camera! Fine issued.'
