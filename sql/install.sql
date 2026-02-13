-- ════════════════════════════════════════════════════════════
-- BRICKSTON CHARACTER - ALTER TABLE `users`
-- Ajoute les colonnes du character creator à la table users
-- La table users utilise `identifier` comme clé joueur (ESX)
-- Colonnes ESX standard : sex, dateofbirth, firstname, lastname, height
-- ════════════════════════════════════════════════════════════

-- Renommer les colonnes existantes pour correspondre à ESX
ALTER TABLE `users` CHANGE COLUMN IF EXISTS `sexe` `sex` VARCHAR(10) NOT NULL DEFAULT 'male';
ALTER TABLE `users` CHANGE COLUMN IF EXISTS `birthdate` `dateofbirth` VARCHAR(20) NOT NULL DEFAULT '01/01/2000';

-- Ajouter les colonnes si elles n'existent pas encore
ALTER TABLE `users`
    ADD COLUMN IF NOT EXISTS `sex` VARCHAR(10) NOT NULL DEFAULT 'male',
    ADD COLUMN IF NOT EXISTS `firstname` VARCHAR(50) NULL,
    ADD COLUMN IF NOT EXISTS `lastname` VARCHAR(50) NULL,
    ADD COLUMN IF NOT EXISTS `nationality` VARCHAR(50) NOT NULL DEFAULT 'Français',
    ADD COLUMN IF NOT EXISTS `height` INT NOT NULL DEFAULT 175,
    ADD COLUMN IF NOT EXISTS `dateofbirth` VARCHAR(20) NOT NULL DEFAULT '01/01/2000',
    ADD COLUMN IF NOT EXISTS `skin` LONGTEXT NULL,
    ADD COLUMN IF NOT EXISTS `last_played` TIMESTAMP NULL,
    ADD COLUMN IF NOT EXISTS `is_created` TINYINT(1) NOT NULL DEFAULT 0;
