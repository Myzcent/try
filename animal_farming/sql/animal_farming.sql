-- Animal Farming Database Schema

-- Table for farmlot ownership
CREATE TABLE IF NOT EXISTS `animal_farmlots` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `lot_id` varchar(50) NOT NULL,
    `lot_type` varchar(50) NOT NULL DEFAULT 'mixed',
    `coordinates` longtext NOT NULL,
    `purchase_date` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_lot` (`lot_id`),
    KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table for animal livestock
CREATE TABLE IF NOT EXISTS `animal_livestock` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `lot_id` varchar(50) NOT NULL,
    `animal_id` varchar(50) NOT NULL,
    `animal_type` varchar(50) NOT NULL,
    `gender` varchar(10) NOT NULL DEFAULT 'Male',
    `health` int(11) DEFAULT 100,
    `hunger` int(11) DEFAULT 100,
    `thirst` int(11) DEFAULT 100,
    `experience` int(11) DEFAULT 0,
    `level` int(11) DEFAULT 1,
    `coordinates` longtext NOT NULL,
    `last_fed` timestamp NULL DEFAULT NULL,
    `last_watered` timestamp NULL DEFAULT NULL,
    `last_production` timestamp NULL DEFAULT NULL,
    `is_dead` tinyint(1) DEFAULT 0,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_animal` (`animal_id`),
    KEY `citizenid` (`citizenid`),
    KEY `lot_id` (`lot_id`),
    FOREIGN KEY (`lot_id`) REFERENCES `animal_farmlots`(`lot_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table for water troughs
CREATE TABLE IF NOT EXISTS `animal_water_troughs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `lot_id` varchar(50) NOT NULL,
    `coordinates` longtext NOT NULL,
    `water_level` int(11) DEFAULT 100,
    `last_refilled` timestamp NULL DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `lot_id` (`lot_id`),
    FOREIGN KEY (`lot_id`) REFERENCES `animal_farmlots`(`lot_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert sample farmlot locations (can be customized)
INSERT IGNORE INTO `animal_farmlots` (`citizenid`, `lot_id`, `lot_type`, `coordinates`) VALUES
('sample', 'lot_1', 'mixed', '{"x": 2447.3, "y": 4968.5, "z": 51.7}'),
('sample', 'lot_2', 'cow', '{"x": 2435.1, "y": 4980.2, "z": 51.8}'),
('sample', 'lot_3', 'pig', '{"x": 2460.7, "y": 4955.3, "z": 51.6}');