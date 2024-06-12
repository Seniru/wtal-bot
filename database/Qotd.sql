CREATE TABLE IF NOT EXISTS `QOTD` (
    `id` int NOT NULL,
    `question` VARCHAR(200) NOT NULL,
    PRIMARY KEY (`id`) 
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `QOTData` (
    `kind` CHAR(6) NOT NULL,
    `value` VARCHAR(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `QOTData` 
VALUES('latest', '$current_time'); 

INSERT INTO `QOTData` 
VALUES('index', '0');
