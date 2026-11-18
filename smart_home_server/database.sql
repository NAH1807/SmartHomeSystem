CREATE DATABASE IF NOT EXISTS smart_home
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE smart_home;

-- ============================================================
-- DEVICES
-- ============================================================

CREATE TABLE IF NOT EXISTS devices (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    name VARCHAR(100) NOT NULL,

    device_type ENUM(
        'relay',
        'fan',
        'camera'
    ) NOT NULL,

    icon VARCHAR(100) DEFAULT 'devices',

    mqtt_topic VARCHAR(255) DEFAULT NULL,

    is_online TINYINT(1) NOT NULL DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
);


-- ============================================================
-- DEVICE STATES
-- ============================================================

CREATE TABLE IF NOT EXISTS device_states (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    device_id INT UNSIGNED NOT NULL,

    is_on TINYINT(1) NOT NULL DEFAULT 0,

    intensity DECIMAL(5,2) NOT NULL DEFAULT 0,

    temperature DECIMAL(5,2) DEFAULT NULL,

    humidity DECIMAL(5,2) DEFAULT NULL,

    target_temperature DECIMAL(5,2) DEFAULT NULL,

    ac_mode ENUM(
        'cool',
        'fan',
        'dry',
        'auto'
    ) DEFAULT NULL,

    fan_speed INT DEFAULT NULL,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_device_states_device
        FOREIGN KEY (device_id)
        REFERENCES devices(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    UNIQUE KEY unique_device_state (device_id)
);

DROP TABLE automations 

-- ============================================================
-- AUTOMATIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS automations (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,  
    device_id INT UNSIGNED NOT NULL,
    enabled TINYINT(1) NOT NULL DEFAULT 0,
    time_on TIME DEFAULT NULL,
    time_off TIME DEFAULT NULL,
    day_on_week VARCHAR(20) NOT NULL DEFAULT '1,2,3,4,5,6,7',
    default_level INT DEFAULT NULL,
    auto_mode VARCHAR(20) DEFAULT NULL,
    temperature_on DECIMAL(4,1) DEFAULT 0,
    temperature_off DECIMAL(4,1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,
	
	CONSTRAINT fk_automations_device
			FOREIGN KEY (device_id)
			REFERENCES devices(id)
);


USE smart_home;

ALTER TABLE devices
ADD COLUMN device_uid VARCHAR(100) NULL,
ADD COLUMN device_ip VARCHAR(45) NULL,
ADD COLUMN config_topic VARCHAR(255) NULL,
ADD COLUMN control_topic VARCHAR(255) NULL,
ADD COLUMN security_topic VARCHAR(255) NULL,
ADD COLUMN profile_version INT NOT NULL DEFAULT 0,
ADD COLUMN device_version INT NOT NULL DEFAULT 0,
ADD COLUMN security_state VARCHAR(30) NOT NULL DEFAULT 'NORMAL';

CREATE UNIQUE INDEX idx_devices_device_uid
ON devices(device_uid);

ALTER TABLE devices
ADD UNIQUE KEY uq_devices_device_uid (device_uid);

SHOW COLUMNS FROM devices LIKE 'device_type';


CREATE TABLE IF NOT EXISTS motion_configs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    device_id INT UNSIGNED NOT NULL,
    motion_enabled TINYINT(1) NOT NULL DEFAULT 1,
    hold_seconds INT UNSIGNED NOT NULL DEFAULT 30,
    cooldown_seconds INT UNSIGNED NOT NULL DEFAULT 30,
    CONSTRAINT fk_motion_configs_device
        FOREIGN KEY (device_id)
        REFERENCES devices(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    UNIQUE KEY uq_motion_configs_device (device_id)
);