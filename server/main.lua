-- ════════════════════════════════════════════════════════════
-- BRICKSTON CHARACTER - SERVER
-- Update dans la table `users` (gérée par ESX)
-- ESX crée déjà la ligne dans users à la connexion,
-- on ne fait que lire/modifier les colonnes character creator.
-- ════════════════════════════════════════════════════════════

ESX = exports['es_extended']:getSharedObject()

-- Récupère l'identifier ESX du joueur (sans préfixe license:)
local function GetESXIdentifier(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        return xPlayer.identifier
    end
    return nil
end

-- ════════════════════════════════════════════
-- CALLBACKS
-- ════════════════════════════════════════════

-- Vérifier si le joueur a déjà créé un personnage
lib.callback.register('brickston_character:hasCharacter', function(source)
    local identifier = GetESXIdentifier(source)
    if not identifier then return false end

    local isCreated = MySQL.scalar.await(
        'SELECT is_created FROM users WHERE identifier = ?',
        { identifier }
    )

    return isCreated == 1
end)

-- Récupérer les données du personnage
lib.callback.register('brickston_character:getCharacter', function(source)
    local identifier = GetESXIdentifier(source)
    if not identifier then return nil end

    local character = MySQL.single.await(
        'SELECT sex, firstname, lastname, nationality, height, dateofbirth, skin, position, last_played FROM users WHERE identifier = ? AND is_created = 1',
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

    -- Vérifier si le personnage existe déjà
    local isCreated = MySQL.scalar.await(
        'SELECT is_created FROM users WHERE identifier = ?',
        { identifier }
    )

    if isCreated == 1 then
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

    -- Position par défaut en JSON
    local defaultPos = json.encode({
        x = Config.DefaultSpawn.x,
        y = Config.DefaultSpawn.y,
        z = Config.DefaultSpawn.z,
        w = Config.DefaultSpawn.w,
    })

    -- UPDATE la ligne existante dans users (créée par ESX)
    MySQL.update.await(
        'UPDATE users SET sex = ?, firstname = ?, lastname = ?, nationality = ?, height = ?, dateofbirth = ?, position = ?, last_played = NOW(), is_created = 1 WHERE identifier = ?',
        { data.gender, firstName, lastName, data.nationality, height, data.birthDate, defaultPos, identifier }
    )

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
-- CHARGEMENT DU PERSONNAGE
-- ════════════════════════════════════════════

RegisterNetEvent('brickston_character:loadCharacter', function()
    local source = source
    local identifier = GetESXIdentifier(source)

    if not identifier then return end

    local character = MySQL.single.await(
        'SELECT sex, firstname, lastname, nationality, height, dateofbirth, skin, position, last_played FROM users WHERE identifier = ? AND is_created = 1',
        { identifier }
    )

    if not character then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Erreur',
            description = 'Aucun personnage trouvé. Veuillez en créer un.',
            type = 'error',
        })
        return
    end

    -- Mettre à jour la date de dernière connexion
    MySQL.update.await(
        'UPDATE users SET last_played = NOW() WHERE identifier = ?',
        { identifier }
    )

    -- Envoyer les données au client pour le spawn
    TriggerClientEvent('brickston_character:spawnCharacter', source, character)

    print(('[brickston_character] %s a chargé le personnage %s %s'):format(
        GetPlayerName(source), character.firstname, character.lastname
    ))
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
    -- La sauvegarde de position est gérée côté client avant la déconnexion
end)

print('[brickston_character] Resource démarrée avec succès')
