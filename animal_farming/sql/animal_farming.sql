-- Animal Farming System Database Tables

-- Table for farmlot ownership
CREATE TABLE IF NOT EXISTS `animal_farmlots` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `farmlot_id` int(11) NOT NULL,
    `animal_type` varchar(50) NOT NULL,
    `purchase_date` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_farmlot` (`farmlot_id`),
    KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table for animal livestock
CREATE TABLE IF NOT EXISTS `animal_livestock` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `farmlot_id` int(11) NOT NULL,
    `animal_type` varchar(50) NOT NULL,
    `animal_id` varchar(100) NOT NULL,
    `gender` enum('male','female') NOT NULL,
    `health` int(11) DEFAULT 100,
    `hunger` int(11) DEFAULT 100,
    `thirst` int(11) DEFAULT 100,
    `last_fed` timestamp NULL DEFAULT NULL,
    `last_watered` timestamp NULL DEFAULT NULL,
    `last_production` timestamp NULL DEFAULT NULL,
    `is_alive` tinyint(1) DEFAULT 1,
    `coords_x` float DEFAULT NULL,
    `coords_y` float DEFAULT NULL,
    `coords_z` float DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_animal` (`animal_id`),
    KEY `citizenid` (`citizenid`),
    KEY `farmlot_id` (`farmlot_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table for water troughs
CREATE TABLE IF NOT EXISTS `animal_water_troughs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `farmlot_id` int(11) NOT NULL,
    `coords_x` float NOT NULL,
    `coords_y` float NOT NULL,
    `coords_z` float NOT NULL,
    `heading` float DEFAULT 0.0,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `farmlot_id` (`farmlot_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes for better performance
CREATE INDEX `idx_animal_farmlot_citizen` ON `animal_farmlots` (`citizenid`, `farmlot_id`);
CREATE INDEX `idx_livestock_farmlot_alive` ON `animal_livestock` (`farmlot_id`, `is_alive`);
CREATE INDEX `idx_livestock_production` ON `animal_livestock` (`last_production`, `is_alive`, `gender`);