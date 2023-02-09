DROP DATABASE IF EXISTS bounties;

-- Dumping structure for table characters.bounties
CREATE TABLE IF NOT EXISTS `bounties` (
  `id` int NOT NULL AUTO_INCREMENT,
  `placedBy` int NOT NULL,
  `placedOn` int NOT NULL,
  `goldAmount` double DEFAULT NULL,
  `itemAmount` float DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=109 DEFAULT CHARSET=latin1;

