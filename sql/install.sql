CREATE TABLE IF NOT EXISTS `brickston_characters` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `license` VARCHAR(100) NOT NULL,
    `gender` VARCHAR(10) NOT NULL DEFAULT 'male',
    `firstname` VARCHAR(50) NOT NULL,
    `lastname` VARCHAR(50) NOT NULL,
    `nationality` VARCHAR(50) NOT NULL DEFAULT 'Français',
    `height` INT NOT NULL DEFAULT 175,
    `birthdate` VARCHAR(20) NOT NULL DEFAULT '01/01/2000',
    `skin` LONGTEXT NULL,
    `position` TEXT NULL,
    `last_played` TIMESTAMP NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_citizenid` (`citizenid`),
    KEY `idx_license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
