Config = {}

-- Nombre maximum de personnages par joueur
Config.MaxCharacters = 5

-- Coordonnées de spawn pour la création de personnage (caméra)
Config.CreatorCoords = vector4(-75.53, -818.98, 326.18, 225.59)

-- Coordonnées du ped pendant la création
Config.PedCoords = vector4(-75.53, -818.98, 326.18, 225.59)

-- Coordonnées de spawn par défaut après création
Config.DefaultSpawn = vector4(-269.44, -955.34, 31.22, 205.71)

-- Modèles de ped
Config.MaleModel = `mp_m_freemode_01`
Config.FemaleModel = `mp_f_freemode_01`

-- Nom de la ressource (pour le NUI)
Config.ResourceName = 'brickston_character'

-- Durée du fondu (ms)
Config.FadeDuration = 500

-- Caméra
Config.Camera = {
    offset = vector3(0.0, 1.8, 0.3),  -- Offset par rapport au ped
    fov = 40.0,                         -- Champ de vision
}
