CREATE DATABASE  IF NOT EXISTS `final_ecommerce_project` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `final_ecommerce_project`;
-- MySQL dump 10.13  Distrib 8.0.44, for Win64 (x86_64)
--
-- Host: localhost    Database: final_ecommerce_project
-- ------------------------------------------------------
-- Server version	8.0.44

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `products`
--

DROP TABLE IF EXISTS `products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `products` (
  `ProductID` int NOT NULL,
  `ProductName` varchar(100) DEFAULT NULL,
  `Category` varchar(100) DEFAULT NULL,
  `Price` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`ProductID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `products`
--

LOCK TABLES `products` WRITE;
/*!40000 ALTER TABLE `products` DISABLE KEYS */;
INSERT INTO `products` VALUES (1,'Laptop B','Clothing',739.49),(2,'Laptop C','Electronics',520.15),(3,'Smartphone D','Accessories',107.03),(4,'Shoes E','Electronics',467.31),(5,'Shirt F','Electronics',90.60),(6,'Smartphone G','Electronics',729.92),(7,'Bag H','Accessories',534.44),(8,'Bag I','Home',674.20),(9,'Watch J','Beauty',277.91),(10,'Bag K','Electronics',46.30),(11,'Shoes L','Clothing',403.36),(12,'Shoes M','Footwear',208.93),(13,'Watch N','Home',743.34),(14,'Shoes O','Home',27.32),(15,'Bag P','Clothing',993.52),(16,'Shirt Q','Electronics',142.49),(17,'Shirt R','Clothing',40.47),(18,'Bag S','Footwear',487.92),(19,'Bag T','Accessories',336.76),(20,'Watch U','Electronics',676.79),(21,'Watch V','Beauty',93.71),(22,'Laptop W','Beauty',345.58),(23,'Laptop X','Electronics',568.48),(24,'Watch Y','Footwear',528.68),(25,'Smartphone Z','Beauty',527.04),(26,'Watch A','Footwear',230.74),(27,'Watch B','Beauty',703.73),(28,'Watch C','Electronics',235.84),(29,'Shirt D','Home',891.21),(30,'Watch E','Beauty',172.54),(31,'Watch F','Electronics',256.94),(32,'Shirt G','Accessories',250.09),(33,'Shoes H','Home',706.78),(34,'Smartphone I','Footwear',207.24),(35,'Shoes J','Clothing',770.29),(36,'Shoes K','Footwear',114.49),(37,'Shirt L','Electronics',707.91),(38,'Watch M','Beauty',979.92),(39,'Watch N','Electronics',501.21),(40,'Smartphone O','Electronics',219.23),(41,'Watch P','Clothing',285.01),(42,'Watch Q','Electronics',63.41),(43,'Shoes R','Footwear',770.25),(44,'Laptop S','Clothing',68.27),(45,'Bag T','Electronics',256.97),(46,'Shirt U','Footwear',660.98),(47,'Watch V','Beauty',343.84),(48,'Watch W','Home',285.27),(49,'Shoes X','Accessories',117.17),(50,'Bag Y','Home',834.71),(51,'Shirt Z','Home',854.04),(52,'Shirt A','Footwear',420.58),(53,'Watch B','Beauty',390.71),(54,'Shirt C','Beauty',645.47),(55,'Shoes D','Home',858.32),(56,'Bag E','Footwear',912.75),(57,'Bag F','Electronics',734.91),(58,'Shirt G','Electronics',464.42),(59,'Shoes H','Electronics',333.56),(60,'Shirt I','Accessories',619.71),(61,'Laptop J','Electronics',870.61),(62,'Shirt K','Accessories',86.39),(63,'Shoes L','Clothing',369.50),(64,'Smartphone M','Clothing',938.56),(65,'Shoes N','Home',407.69),(66,'Shirt O','Footwear',363.09),(67,'Smartphone P','Accessories',784.97),(68,'Bag Q','Beauty',810.60),(69,'Shirt R','Accessories',587.01),(70,'Shirt S','Home',821.35),(71,'Bag T','Accessories',615.95),(72,'Smartphone U','Footwear',642.34),(73,'Laptop V','Footwear',101.30),(74,'Laptop W','Electronics',316.69),(75,'Shoes X','Accessories',123.14),(76,'Laptop Y','Accessories',651.21),(77,'Shirt Z','Home',177.34),(78,'Smartphone A','Accessories',334.61),(79,'Watch B','Beauty',165.15),(80,'Shoes C','Clothing',141.88),(81,'Shirt D','Home',637.06),(82,'Shoes E','Beauty',77.75),(83,'Watch F','Electronics',805.81),(84,'Watch G','Electronics',690.67),(85,'Shirt H','Electronics',422.95),(86,'Smartphone I','Accessories',627.72),(87,'Bag J','Footwear',368.89),(88,'Smartphone K','Electronics',627.73),(89,'Shirt L','Footwear',396.44),(90,'Watch M','Home',54.22),(91,'Smartphone N','Footwear',640.31),(92,'Smartphone O','Home',217.88),(93,'Bag P','Accessories',632.27),(94,'Shirt Q','Beauty',400.46),(95,'Bag R','Beauty',61.28),(96,'Laptop S','Beauty',204.37),(97,'Shirt T','Accessories',516.07),(98,'Watch U','Clothing',760.93),(99,'Laptop V','Home',209.60),(100,'Shirt W','Clothing',470.00);
/*!40000 ALTER TABLE `products` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-12-30 15:19:21
