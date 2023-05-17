
CREATE TABLE IF NOT EXISTS `CustomCommands` (
  `name` varchar(15) NOT NULL,
  `runner` varchar(20) NOT NULL,
  `source` varchar(40) NOT NULL,
  `author` bigint(20),
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
