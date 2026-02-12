local function GenerateCitizenId()
    local charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local id = 'BRK'
    for _ = 1, 5 do
        local rand = math.random(1, #charset)
        id = id .. charset:sub(rand, rand)
    end
    -- Vérifier l'unicité
    local exists = MySQL.scalar.await('SELECT COUNT(*) FROM brickston_characters WHERE citizenid = ?', { id })
    if exists and exists > 0 then
        return GenerateCitizenId()
    end
    return id
end

local function GetPlayerLicense(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in ipairs(identifiers) do
        if string.find(id, 'license:') then
            return id
        end
    end
    return nil
end

-- Récupérer les personnages d'un joueur
lib.callback.register('brickston_character:getCharacters', function(source)
    local license = GetPlayerLicense(source)
    if not license then
        return {}
    end

    local characters = MySQL.query.await(
        'SELECT * FROM brickston_characters WHERE license = ? ORDER BY last_played DESC',
        { license }
    )

    return characters or {}
end)

-- Vérifier si le joueur peut créer un nouveau personnage
lib.callback.register('brickston_character:canCreateCharacter', function(source)
    local license = GetPlayerLicense(source)
    if not license then
        return false
    end

    local count = MySQL.scalar.await(
        'SELECT COUNT(*) FROM brickston_characters WHERE license = ?',
        { license }
    )

    return (count or 0) < Config.MaxCharacters
end)

-- Créer un personnage
RegisterNetEvent('brickston_character:createCharacter', function(data)
    local source = source
    local license = GetPlayerLicense(source)

    if not license then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Erreur',
            description = 'Impossible de récupérer votre licence.',
            type = 'error',
        })
        return
    end

    -- Vérifier le nombre de personnages
    local count = MySQL.scalar.await(
        'SELECT COUNT(*) FROM brickston_characters WHERE license = ?',
        { license }
    )

    if (count or 0) >= Config.MaxCharacters then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Erreur',
            description = 'Nombre maximum de personnages atteint.',
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

    local citizenid = GenerateCitizenId()

    -- Position par défaut en JSON
    local defaultPos = json.encode({
        x = Config.DefaultSpawn.x,
        y = Config.DefaultSpawn.y,
        z = Config.DefaultSpawn.z,
        w = Config.DefaultSpawn.w,
    })

    MySQL.insert.await(
        'INSERT INTO brickston_characters (citizenid, license, gender, firstname, lastname, nationality, height, birthdate, position, last_played) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())',
        { citizenid, license, data.gender, firstName, lastName, data.nationality, height, data.birthDate, defaultPos }
    )

    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Brickston RP',
        description = ('Personnage %s %s créé avec succès !'):format(firstName, lastName),
        type = 'success',
    })

    -- Notifier le client que la création est terminée
    TriggerClientEvent('brickston_character:characterCreated', source, {
        citizenid = citizenid,
        gender = data.gender,
        firstName = firstName,
        lastName = lastName,
        nationality = data.nationality,
        height = height,
        birthDate = data.birthDate,
    })

    print(('[brickston_character] Personnage créé: %s %s (CID: %s) par %s'):format(firstName, lastName, citizenid, GetPlayerName(source)))
end)

-- Sélectionner un personnage
RegisterNetEvent('brickston_character:selectCharacter', function(citizenid)
    local source = source
    local license = GetPlayerLicense(source)

    if not license then return end

    local character = MySQL.single.await(
        'SELECT * FROM brickston_characters WHERE citizenid = ? AND license = ?',
        { citizenid, license }
    )

    if not character then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Erreur',
            description = 'Personnage introuvable.',
            type = 'error',
        })
        return
    end

    -- Mettre à jour la date de dernière connexion
    MySQL.update.await(
        'UPDATE brickston_characters SET last_played = NOW() WHERE citizenid = ?',
        { citizenid }
    )

    -- Envoyer les données au client pour le spawn
    TriggerClientEvent('brickston_character:spawnCharacter', source, character)

    print(('[brickston_character] %s a sélectionné le personnage %s %s (CID: %s)'):format(
        GetPlayerName(source), character.firstname, character.lastname, citizenid
    ))
end)

-- Supprimer un personnage
RegisterNetEvent('brickston_character:deleteCharacter', function(citizenid)
    local source = source
    local license = GetPlayerLicense(source)

    if not license then return end

    local affected = MySQL.update.await(
        'DELETE FROM brickston_characters WHERE citizenid = ? AND license = ?',
        { citizenid, license }
    )

    if affected and affected > 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Brickston RP',
            description = 'Personnage supprimé.',
            type = 'success',
        })

        -- Renvoyer la liste mise à jour
        local characters = MySQL.query.await(
            'SELECT * FROM brickston_characters WHERE license = ? ORDER BY last_played DESC',
            { license }
        )
        TriggerClientEvent('brickston_character:refreshCharacters', source, characters or {})
    end
end)

-- Sauvegarder la position du joueur
RegisterNetEvent('brickston_character:savePosition', function(citizenid, coords)
    local source = source
    if not citizenid or not coords then return end

    local pos = json.encode({
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = coords.w or 0.0,
    })

    MySQL.update('UPDATE brickston_characters SET position = ? WHERE citizenid = ?', { pos, citizenid })
end)

-- Sauvegarde automatique de la position à la déconnexion
AddEventHandler('playerDropped', function()
    local source = source
    -- La sauvegarde de position est gérée côté client avant la déconnexion
end)

print('[brickston_character] Resource démarrée avec succès')
