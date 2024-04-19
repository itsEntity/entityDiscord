Citizen.CreateThread(function ()
    repeat Wait(500) until NetworkIsSessionActive()
    
    TriggerServerEvent('entity::server::initPlayer')
end)