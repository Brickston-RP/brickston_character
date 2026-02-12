-- ════════════════════════════════════════════════════════════
-- BRICKSTON CHARACTER - ALTER TABLE `users`
-- Ajoute les colonnes du character creator à la table users
-- ════════════════════════════════════════════════════════════

ALTER TABLE `users`
    ADD COLUMN IF NOT EXISTS `sexe` VARCHAR(10) NOT NULL DEFAULT 'male',
    ADD COLUMN IF NOT EXISTS `firstname` VARCHAR(50) NULL,
    ADD COLUMN IF NOT EXISTS `lastname` VARCHAR(50) NULL,
    ADD COLUMN IF NOT EXISTS `nationality` VARCHAR(50) NOT NULL DEFAULT 'Français',
    ADD COLUMN IF NOT EXISTS `height` INT NOT NULL DEFAULT 175,
    ADD COLUMN IF NOT EXISTS `birthdate` VARCHAR(20) NOT NULL DEFAULT '01/01/2000',
    ADD COLUMN IF NOT EXISTS `skin` LONGTEXT NULL,
    ADD COLUMN IF NOT EXISTS `position` TEXT NULL,
    ADD COLUMN IF NOT EXISTS `last_played` TIMESTAMP NULL,
    ADD COLUMN IF NOT EXISTS `is_created` TINYINT(1) NOT NULL DEFAULT 0;
