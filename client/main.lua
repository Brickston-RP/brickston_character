local isCreatorOpen = false
local creatorCam = nil
local creatorPed = nil
local characterLoaded = false

-- ════════════════════════════════════════════
-- UTILS
-- ════════════════════════════════════════════

local function LoadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
end

local function DeleteCreatorPed()
    if creatorPed and DoesEntityExist(creatorPed) then
        DeleteEntity(creatorPed)
        creatorPed = nil
    end
end

local function DestroyCreatorCam()
    if creatorCam then
        RenderScriptCams(false, true, Config.FadeDuration, true, true)
        DestroyCam(creatorCam, false)
        creatorCam = nil
    end
end

-- ════════════════════════════════════════════
-- CAMERA
-- ════════════════════════════════════════════

local function SetupCreatorCamera()
    local pedCoords = Config.PedCoords
    local offset = Config.Camera.offset

    creatorCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)

    local camX = pedCoords.x + offset.x
    local camY = pedCoords.y + offset.y
    local camZ = pedCoords.z + offset.z

    SetCamCoord(creatorCam, camX, camY, camZ)
    PointCamAtCoord(creatorCam, pedCoords.x, pedCoords.y, pedCoords.z + 0.3)
    SetCamFov(creatorCam, Config.Camera.fov)
    SetCamActive(creatorCam, true)
    RenderScriptCams(true, true, Config.FadeDuration, true, true)
end

-- ════════════════════════════════════════════
-- PED CREATION
-- ════════════════════════════════════════════

local function CreateCreatorPed(gender)
    DeleteCreatorPed()

    local model = gender == 'female' and Config.FemaleModel or Config.MaleModel
    LoadModel(model)

    local coords = Config.PedCoords
    creatorPed = CreatePed(26, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)

    SetEntityInvincible(creatorPed, true)
    FreezeEntityPosition(creatorPed, true)
    SetBlockingOfNonTemporaryEvents(creatorPed, true)
    SetEntityVisible(creatorPed, true, false)
    TaskStandStill(creatorPed, -1)

    SetModelAsNoLongerNeeded(model)
end

-- ════════════════════════════════════════════
-- NUI CALLBACKS
-- ════════════════════════════════════════════

RegisterNUICallback('createCharacter', function(data, cb)
    if not data.gender or not data.firstName or not data.lastName then
        cb({ ok = false })
        return
    end

    TriggerServerEvent('brickston_character:createCharacter', {
        gender = data.gender,
        firstName = data.firstName,
        lastName = data.lastName,
        nationality = data.nationality or 'Français',
        height = tonumber(data.height) or 175,
        birthDate = data.birthDate or '01/01/2000',
    })

    cb({ ok = true })
end)

RegisterNUICallback('cancelCreation', function(_, cb)
    CloseCreator()
    cb({ ok = true })
end)

RegisterNUICallback('selectGender', function(data, cb)
    if data.gender then
        CreateCreatorPed(data.gender)
    end
    cb({ ok = true })
end)

-- ════════════════════════════════════════════
-- OPEN / CLOSE CREATOR
-- ════════════════════════════════════════════

function OpenCreator()
    if isCreatorOpen then return end
    isCreatorOpen = true

    -- Masquer le HUD
    DisplayRadar(false)
    DisplayHud(false)

    -- Configurer l'environnement
    local coords = Config.CreatorCoords
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(PlayerPedId(), coords.w)
    FreezeEntityPosition(PlayerPedId(), true)
    SetEntityVisible(PlayerPedId(), false, false)

    Wait(500)

    -- Créer le ped par défaut (homme)
    CreateCreatorPed('male')

    -- Configurer la caméra
    SetupCreatorCamera()

    -- Ouvrir le NUI
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openCreator',
    })
end

function CloseCreator()
    if not isCreatorOpen then return end
    isCreatorOpen = false

    -- Fermer le NUI
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeCreator',
    })

    -- Nettoyer
    DestroyCreatorCam()
    DeleteCreatorPed()

    -- Restaurer le joueur
    FreezeEntityPosition(PlayerPedId(), false)
    SetEntityVisible(PlayerPedId(), true, false)
    DisplayRadar(true)
    DisplayHud(true)
end

-- ════════════════════════════════════════════
-- EVENTS (serveur → client)
-- ════════════════════════════════════════════

-- Le serveur a détecté que le joueur n'a pas de personnage
RegisterNetEvent('brickston_character:openCreator', function()
    characterLoaded = false
    OpenCreator()
end)

-- Appelé quand le personnage est créé avec succès
RegisterNetEvent('brickston_character:characterCreated', function(data)
    CloseCreator()

    -- Spawn le joueur aux coordonnées par défaut
    local coords = Config.DefaultSpawn
    local model = data.gender == 'female' and Config.FemaleModel or Config.MaleModel

    LoadModel(model)
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)

    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(ped, coords.w)

    characterLoaded = true

    DoScreenFadeIn(Config.FadeDuration)

    TriggerEvent('brickston_character:onCharacterLoaded', data)
end)

-- Spawn un personnage existant (envoyé par le serveur via checkIdentity)
RegisterNetEvent('brickston_character:spawnCharacter', function(character)
    CloseCreator()

    DoScreenFadeOut(Config.FadeDuration)
    Wait(Config.FadeDuration)

    local model = character.sex == 'female' and Config.FemaleModel or Config.MaleModel
    LoadModel(model)
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)

    local ped = PlayerPedId()

    -- Position
    local pos = character.position and json.decode(character.position) or nil
    if pos then
        SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, true)
        SetEntityHeading(ped, pos.w or 0.0)
    else
        local coords = Config.DefaultSpawn
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
        SetEntityHeading(ped, coords.w)
    end

    -- Skin
    if character.skin then
        local skin = json.decode(character.skin)
        if skin then
            -- Appliquer l'apparence si les données existent
            -- Compatible avec ox_appearance ou fivem-appearance
        end
    end

    characterLoaded = true

    DoScreenFadeIn(Config.FadeDuration)
    DisplayRadar(true)
    DisplayHud(true)

    TriggerEvent('brickston_character:onCharacterLoaded', {
        sex = character.sex,
        firstName = character.firstname,
        lastName = character.lastname,
        birthDate = character.dateofbirth,
    })
end)

-- ════════════════════════════════════════════
-- ESX PLAYER LOADED (écran noir en attendant le serveur)
-- ════════════════════════════════════════════

-- Quand ESX charge le joueur, on fade out et on attend
-- que le serveur envoie spawnCharacter ou openCreator
RegisterNetEvent('esx:playerLoaded', function()
    characterLoaded = false
    DoScreenFadeOut(0)
end)

-- ════════════════════════════════════════════
-- COMMANDES (DEV)
-- ════════════════════════════════════════════

RegisterCommand('charcreator', function()
    OpenCreator()
end, false)

RegisterCommand('logout', function()
    characterLoaded = false
    DoScreenFadeOut(Config.FadeDuration)
    Wait(Config.FadeDuration)
    OpenCreator()
end, false)

-- ════════════════════════════════════════════
-- SAUVEGARDE POSITION
-- ════════════════════════════════════════════

-- Sauvegarde automatique toutes les 5 minutes
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        if characterLoaded then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            TriggerServerEvent('brickston_character:savePosition', {
                x = coords.x,
                y = coords.y,
                z = coords.z,
                w = heading,
            })
        end
    end
end)

-- Sauvegarde à l'arrêt de la resource
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if characterLoaded then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            TriggerServerEvent('brickston_character:savePosition', {
                x = coords.x,
                y = coords.y,
                z = coords.z,
                w = heading,
            })
        end
        CloseCreator()
    end
end)

-- Export pour d'autres resources
exports('IsCharacterLoaded', function()
    return characterLoaded
end)

exports('OpenCharacterCreator', function()
    OpenCreator()
end)
