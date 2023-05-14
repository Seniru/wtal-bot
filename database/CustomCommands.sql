-- MySQL dump 10.13  Distrib 8.0.33, for Linux (x86_64)
--
-- Host: sql9.freesqldatabase.com    Database: sql9617855
-- ------------------------------------------------------
-- Server version	5.5.62-0ubuntu0.14.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `CustomCommands`
--

DROP TABLE IF EXISTS `CustomCommands`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE IF NOT EXISTS `CustomCommands` (
  `name` varchar(15) NOT NULL,
  `runner` varchar(20) NOT NULL,
  `source` varchar(40) NOT NULL,
  `author` bigint(20),
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `CustomCommands`
--

LOCK TABLES `CustomCommands` WRITE;
/*!40000 ALTER TABLE `CustomCommands` DISABLE KEYS */;
INSERT INTO `CustomCommands` VALUES ('8ball','cpython-3.8.9','https://pastebin.com/raw/ExMLuAgv','544776631672242176'),('coinflip','cpython-3.8.9','https://pastebin.com/raw/f8v5EGQF','544776631672242176'),('death','cpython-3.8.9','https://pastebin.com/raw/nLtRfDhs','544776631672242176'),('dice','cpython-3.8.9','https://pastebin.com/raw/LmxRAKE1','544776631672242176'),('dog','cpython-3.8.9','https://pastebin.com/raw/bijXTmat','544776631672242176'),('embed','cpython-3.8.9','https://pastebin.com/raw/AbPX16PA','522972601488900097'),('frog','cpython-3.8.9','https://pastebin.com/raw/bwpCSAvi','544776631672242176'),('graph','cpython-3.8.9','https://pastebin.com/raw/YH0YyPAk','522972601488900097'),('howto','cpython-3.8.9','https://pastebin.com/raw/amMuvd1B','522972601488900097'),('no','cpython-3.8.9','https://pastebin.com/raw/tvprgEqC','522972601488900097'),('order','cpython-3.8.9','https://pastebin.com/raw/B38n572h','544776631672242176'),('percentage','cpython-3.8.9','https://pastebin.com/raw/QghKi731','544776631672242176'),('raw','cpython-3.8.9','https://pastebin.com/raw/Mqq8TkXT','522972601488900097'),('ricardo','cpython-3.8.9','https://pastebin.com/raw/3LRJ8Q6A','522972601488900097'),('tex','cpython-3.8.9','https://pastebin.com/raw/hE2W5YKs','522972601488900097'),('worldclock','cpython-3.8.9','https://pastebin.com/raw/yBueDaSJ','522972601488900097'),('yes','cpython-3.8.9','https://pastebin.com/raw/UguBK6yg','544776631672242176');
/*!40000 ALTER TABLE `CustomCommands` ENABLE KEYS */;
UNLOCK TABLES;
