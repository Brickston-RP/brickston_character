-- ════════════════════════════════════════════════════════════
-- BRICKSTON CHARACTER - SERVER
-- Inspiré du pattern esx_identity :
-- Le serveur contrôle tout (check DB → envoie event au client)
-- ════════════════════════════════════════════════════════════

ESX = exports['es_extended']:getSharedObject()

local alreadyRegistered = {}

-- ════════════════════════════════════════════
-- UTILS
-- ════════════════════════════════════════════

local function GetESXIdentifier(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        return xPlayer.identifier
    end
    return nil
end

-- ════════════════════════════════════════════
-- CHECK IDENTITY (pattern esx_identity)
-- ════════════════════════════════════════════

-- Vérifie dans la BDD si le joueur a un personnage,
-- puis envoie le bon event au client
local function checkIdentity(xPlayer)
    local result = MySQL.single.await(
        'SELECT sex, firstname, lastname, nationality, height, dateofbirth, skin, position FROM users WHERE identifier = ?',
        { xPlayer.identifier }
    )

    -- Pas de ligne ou firstname vide → pas de personnage
    if not result or not result.firstname or result.firstname == '' then
        alreadyRegistered[xPlayer.identifier] = false
        TriggerClientEvent('brickston_character:openCreator', xPlayer.source)
        return
    end

    -- Le personnage existe
    alreadyRegistered[xPlayer.identifier] = true

    -- Mettre à jour les données ESX (comme esx_identity)
    xPlayer.setName(('%s %s'):format(result.firstname, result.lastname))
    xPlayer.set('firstName', result.firstname)
    xPlayer.set('lastName', result.lastname)
    xPlayer.set('dateofbirth', result.dateofbirth)
    xPlayer.set('sex', result.sex)
    xPlayer.set('height', result.height)
    xPlayer.set('nationality', result.nationality)

    -- Envoyer au client pour le spawn
    TriggerClientEvent('brickston_character:spawnCharacter', xPlayer.source, result)

    print(('[brickston_character] %s a chargé le personnage %s %s'):format(
        GetPlayerName(xPlayer.source), result.firstname, result.lastname
    ))
end

-- ════════════════════════════════════════════
-- EVENTS ESX (connexion + restart resource)
-- ════════════════════════════════════════════

-- Quand ESX charge un joueur (connexion / reconnexion)
RegisterNetEvent('esx:playerLoaded', function(playerId, xPlayer)
    checkIdentity(xPlayer)
end)

-- Quand la resource restart en cours de jeu
-- (re-vérifie tous les joueurs connectés, comme esx_identity)
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    Wait(500)

    local xPlayers = ESX.GetExtendedPlayers()
    for i = 1, #xPlayers do
        if xPlayers[i] then
            checkIdentity(xPlayers[i])
        end
    end
end)

-- ════════════════════════════════════════════
-- CALLBACKS (compatibilité)
-- ════════════════════════════════════════════

lib.callback.register('brickston_character:hasCharacter', function(source)
    local identifier = GetESXIdentifier(source)
    if not identifier then return false end

    return alreadyRegistered[identifier] == true
end)

lib.callback.register('brickston_character:getCharacter', function(source)
    local identifier = GetESXIdentifier(source)
    if not identifier then return nil end

    local character = MySQL.single.await(
        'SELECT sex, firstname, lastname, nationality, height, dateofbirth, skin, position FROM users WHERE identifier = ? AND firstname IS NOT NULL AND firstname != \'\'',
        { identifier }
    )

    return character
end)

-- ════════════════════════════════════════════
-- CREATION DE PERSONNAGE
-- ════════════════════════════════════════════

RegisterNetEvent('brickston_character:createCharacter', function(data)
    local source = source
    local identifier = GetESXIdentifier(source)

    if not identifier then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Erreur',
            description = 'Impossible de récupérer votre identifiant.',
            type = 'error',
        })
        return
    end

    -- Vérifier si le personnage existe déjà (mémoire + BDD)
    if alreadyRegistered[identifier] then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Erreur',
            description = 'Vous avez déjà créé un personnage.',
            type = 'error',
        })
        return
    end

    -- Validation des données
    if not data.gender or not data.firstName or not data.lastName or not data.nationality or not data.height or not data.birthDate then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Erreur',
            description = 'Données invalides.',
            type = 'error',
        })
        return
    end

    -- Nettoyage des données
    local firstName = data.firstName:gsub('[^%a%s%-ÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝàáâãäåèéêëìíîïòóôõöùúûüý]', '')
    local lastName = data.lastName:gsub('[^%a%s%-ÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝàáâãäåèéêëìíîïòóôõöùúûüý]', '')

    if #firstName < 2 or #firstName > 20 or #lastName < 2 or #lastName > 20 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Erreur',
            description = 'Prénom et nom doivent faire entre 2 et 20 caractères.',
            type = 'error',
        })
        return
    end

    local height = tonumber(data.height)
    if not height or height < 140 or height > 220 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Erreur',
            description = 'Taille invalide.',
            type = 'error',
        })
        return
    end

    -- UPDATE la ligne existante dans users (créée par ESX)
    MySQL.update.await(
        'UPDATE users SET sex = ?, firstname = ?, lastname = ?, nationality = ?, height = ?, dateofbirth = ? WHERE identifier = ?',
        { data.gender, firstName, lastName, data.nationality, height, data.birthDate, identifier }
    )

    -- Marquer comme enregistré
    alreadyRegistered[identifier] = true

    -- Mettre à jour les données ESX
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        xPlayer.setName(('%s %s'):format(firstName, lastName))
        xPlayer.set('firstName', firstName)
        xPlayer.set('lastName', lastName)
        xPlayer.set('dateofbirth', data.birthDate)
        xPlayer.set('sex', data.gender)
        xPlayer.set('height', height)
        xPlayer.set('nationality', data.nationality)
    end

    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Brickston RP',
        description = ('Personnage %s %s créé avec succès !'):format(firstName, lastName),
        type = 'success',
    })

    -- Notifier le client que la création est terminée
    TriggerClientEvent('brickston_character:characterCreated', source, {
        identifier = identifier,
        gender = data.gender,
        firstName = firstName,
        lastName = lastName,
        nationality = data.nationality,
        height = height,
        birthDate = data.birthDate,
    })

    print(('[brickston_character] Personnage créé: %s %s par %s'):format(firstName, lastName, GetPlayerName(source)))
end)

-- ════════════════════════════════════════════
-- CHARGEMENT DU PERSONNAGE (fallback)
-- ════════════════════════════════════════════

RegisterNetEvent('brickston_character:loadCharacter', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    checkIdentity(xPlayer)
end)

-- ════════════════════════════════════════════
-- SAUVEGARDE POSITION
-- ════════════════════════════════════════════

RegisterNetEvent('brickston_character:savePosition', function(coords)
    local source = source
    local identifier = GetESXIdentifier(source)
    if not identifier or not coords then return end

    local pos = json.encode({
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = coords.w or 0.0,
    })

    MySQL.update('UPDATE users SET position = ? WHERE identifier = ?', { pos, identifier })
end)

-- ════════════════════════════════════════════
-- SAUVEGARDE SKIN
-- ════════════════════════════════════════════

RegisterNetEvent('brickston_character:saveSkin', function(skinData)
    local source = source
    local identifier = GetESXIdentifier(source)
    if not identifier or not skinData then return end

    local skin = json.encode(skinData)
    MySQL.update('UPDATE users SET skin = ? WHERE identifier = ?', { skin, identifier })
end)

-- ════════════════════════════════════════════
-- DECONNEXION
-- ════════════════════════════════════════════

AddEventHandler('playerDropped', function()
    local source = source
    local identifier = GetESXIdentifier(source)
    if identifier then
        alreadyRegistered[identifier] = nil
    end
end)

print('[brickston_character] Resource démarrée avec succès')
