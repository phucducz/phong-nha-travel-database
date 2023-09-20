-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Máy chủ: 127.0.0.1:3306
-- Thời gian đã tạo: Th8 07, 2023 lúc 03:25 AM
-- Phiên bản máy phục vụ: 8.0.31
-- Phiên bản PHP: 8.0.26

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Cơ sở dữ liệu: `travel_management`
--

DELIMITER $$
--
-- Thủ tục
--
DROP PROCEDURE IF EXISTS `deleteBookedDetails`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteBookedDetails` (IN `idBookDetails` INT)   BEGIN
	DELETE FROM booke_details WHERE id = idBookDetails;
END$$

DROP PROCEDURE IF EXISTS `sp_delete_image`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_delete_image` (`ID` INT)   BEGIN
	DELETE FROM images WHERE tour_id = ID;
END$$

DROP PROCEDURE IF EXISTS `sp_delete_tour`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_delete_tour` (IN `tourId` INT)   BEGIN
	DELETE FROM tours WHERE id = tourId;
END$$

DROP PROCEDURE IF EXISTS `sp_delete_tours_categories`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_delete_tours_categories` (`tourId` INT)   BEGIN
    DELETE
FROM
    tours_categories
WHERE
    tours_id = tourId ; 
END$$

DROP PROCEDURE IF EXISTS `sp_delete_tours_topics`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_delete_tours_topics` (`tourId` INT)   BEGIN
	DELETE FROM tours_topics WHERE tours_id = tourId ;
END$$

DROP PROCEDURE IF EXISTS `sp_handle_delete_tour`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_handle_delete_tour` (`tourId` INT)   BEGIN
	CALL sp_delete_image(tourId);
	CALL sp_delete_tours_topics(tourId);
    CALL sp_delete_tours_categories(tourId);
    CALL sp_delete_tour(tourId);
END$$

DROP PROCEDURE IF EXISTS `sp_handle_insert_tour`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_handle_insert_tour` (IN `name` VARCHAR(100), IN `description` VARCHAR(1000), IN `price` DECIMAL(20,0), IN `image` VARCHAR(1000), IN `lengthTopics` INT, IN `topics` VARCHAR(50), IN `lengthCategories` INT, IN `categories` VARCHAR(50))   BEGIN
	DECLARE count int default 0;
    DECLARE pos int default 1;
    CALL sp_insert_tour(name, description, price, @tour_id);
    
    SET @tour_id_in := @tour_id ;
    
    CALL sp_insert_image(image, @tour_id_in) ;
    
	WHILE count < lengthTopics DO
        CALL sp_insert_tours_topics(@tour_id_in, SUBSTRING(topics, pos, 1));
        set pos = pos + 2;
        set count = count + 1;
	END WHILE;
    
    set count = 0;
    set pos = 1;
    
    WHILE count < lengthCategories DO
        CALL sp_insert_tours_categories(@tour_id_in, SUBSTRING(categories, pos, 1));
        set pos = pos + 2;
        set count = count + 1;
	END WHILE;
END$$

DROP PROCEDURE IF EXISTS `sp_handle_update_tour`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_handle_update_tour` (`tourId` INT, `name` VARCHAR(100), `description` VARCHAR(1000), `price` DECIMAL(20,0), `priceChildren` DECIMAL(20,0), `image` VARCHAR(100), `lengthCategories` INT, `categories` VARCHAR(50), `lengthTopics` INT, `topics` VARCHAR(50))   BEGIN
	UPDATE tours SET name = name, description = description, priceAdult = price, priceChildren = priceChildren WHERE id = tourId;
    
    UPDATE images SET image = image WHERE tour_id = tourId AND isMain = 1;
    
	CALL sp_update_tours_categories(tourId, lengthCategories, categories);
    CALL sp_update_tours_topics(tourId, lengthTopics, topics);
END$$

DROP PROCEDURE IF EXISTS `sp_inserta_tours_topics`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_inserta_tours_topics` (`topicsId` INT)   BEGIN
	DECLARE toursId INT;
    
    SELECT id INTO toursId FROM tours 
        ORDER BY id DESC LIMIT 1;
        
    INSERT INTO tours_topics(tours_id, topics_id)
		VALUES(toursId, topicsId);
END$$

DROP PROCEDURE IF EXISTS `sp_insertBookDetails`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insertBookDetails` (`name_company` VARCHAR(50), `country` VARCHAR(50), `zip_code` VARCHAR(50), `city` VARCHAR(50), `note` VARCHAR(1000), `payment_method_id` INT, `NAME` VARCHAR(50), `surname` VARCHAR(50), `address` VARCHAR(50), `apartment` VARCHAR(50), `number_phone` VARCHAR(20), `email_address` VARCHAR(50), `quantity` INT, `couponId` INT)   BEGIN
    DECLARE
        booked_tour_id_current INT ;
    SELECT
        id
    INTO booked_tour_id_current
FROM
    booked_tours
ORDER BY
    id
DESC
LIMIT 1 ;
INSERT INTO `booke_details`(
    `booked_tour_id`,
    `name_company`,
    `country`,
    `zip_code`,
    `city`,
    `note`,
    `payment_method_id`,
    `name`,
    `surname`,
    `address`,
    `apartment`,
    `number_phone`,
    `email_address`,
    `quantity`,
    `couponId`
)
VALUES(
    booked_tour_id_current,
    name_company,
    country,
    zip_code,
    city,
    note,
    payment_method_id,
    NAME,
    surname,
    address,
    apartment,
    number_phone,
    email_address,
    quantity,
    couponId
) ;
END$$

DROP PROCEDURE IF EXISTS `sp_insertBookedTours`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insertBookedTours` (IN `tour_id` INT, IN `booked_date` DATETIME, IN `user_id` INT)   BEGIN
	INSERT INTO booked_tours(tour_id, booked_date, user_id) VALUES (tour_id, DATE_FORMAT(booked_date, '%Y/%m/%d'), user_id);
END$$

DROP PROCEDURE IF EXISTS `sp_insertTour`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insertTour` (IN `name` VARCHAR(50), IN `description` VARCHAR(50), IN `topic_id` INT, IN `priceAdult` DECIMAL(20,0))   BEGIN
	DECLARE priceChildren FLOAT;
    SET priceChildren = priceAdult - (priceAdult * 10 / 100);
    
	INSERT INTO tours(`name`, `description`, `priceAdult`, `priceChildren`) 
    VALUES(name, description, priceAdult, priceChildren);
END$$

DROP PROCEDURE IF EXISTS `sp_insert_image`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_image` (IN `image` VARCHAR(50), IN `tour_id` INT)   BEGIN
	INSERT INTO images(`image`, `tour_id`, isMain) VALUES(image, tour_id, 1);
END$$

DROP PROCEDURE IF EXISTS `sp_insert_tour`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_tour` (IN `NAME` VARCHAR(100), IN `description` VARCHAR(1000), IN `price` DECIMAL(20,0), OUT `tour_id` INT)   BEGIN
    DECLARE
        priceChildren decimal(20, 0);
    SET
        priceChildren = price-(price * 10 / 100) ;
    INSERT INTO tours(
        `name`,
        `description`,
        `priceAdult`,
        `priceChildren`
    )
VALUES(
    NAME,
    description,
    price,
    priceChildren
) ;
SET
    tour_id = LAST_INSERT_ID() ;
    END$$

DROP PROCEDURE IF EXISTS `sp_insert_tours_categories`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_tours_categories` (IN `toursId` INT, IN `categoriesId` INT)   BEGIN
    INSERT INTO `tours_categories`(`tours_id`, `categories_id`)
VALUES(toursId, categoriesId) ;
END$$

DROP PROCEDURE IF EXISTS `sp_insert_tours_topics`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_tours_topics` (`toursId` INT, `topicsId` INT)   BEGIN
	insert into tours_topics(tours_id, topics_id) values(toursId, topicsId);
END$$

DROP PROCEDURE IF EXISTS `sp_search_tours`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_search_tours` (IN `tourName` VARCHAR(100))   BEGIN
	SELECT
        t.id, t.name, t.description, t.priceAdult AS price, t.priceChildren, i.image AS image
    FROM
        images AS i, tours AS t
    WHERE
        i.tour_id = t.id AND i.isMain = 1 AND t.name LIKE CONCAT('%', tourName, '%') 
    ORDER BY t.id ASC;
END$$

DROP PROCEDURE IF EXISTS `sp_selectTourBooked`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_selectTourBooked` (IN `userId` INT)   BEGIN
    SELECT
    T.id,
    T.name,
    T.priceAdult as price,
    DATE_FORMAT(BT.booked_date, '%d/%m/%Y') AS 'bookDate',
    I.image,
    bd.id AS bookDetailId,
    bd.quantity
FROM
    booke_details AS bd,
    booked_tours AS bt,
    tours AS t,
    images AS I,
    users AS u
WHERE
    BD.booked_tour_id = BT.id AND I.tour_id = T.id AND BT.tour_id = T.id AND BT.user_id = U.id AND I.tour_id = T.id AND U.id = userId
;END$$

DROP PROCEDURE IF EXISTS `sp_select_tours`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_select_tours` ()   BEGIN
	SELECT
    t.id,
    t.name,
    t.description,
    t.priceAdult AS price,
    t.priceChildren,
    i.image AS image
FROM
    images AS i,
    tours AS t
WHERE
    i.tour_id = t.id AND i.isMain = 1
ORDER BY
    t.id ASC;
END$$

DROP PROCEDURE IF EXISTS `sp_select_tours_topics`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_select_tours_topics` ()   BEGIN
   SELECT
    t.id,
    t.name,
    t.description,
    t.priceAdult AS price,
    t.priceChildren,
    tt.topics_id AS topicId,
    i.image AS image
FROM
    images AS i,
    tours AS t,
    tours_topics as tt
WHERE
    i.tour_id = t.id AND i.isMain = 1 AND t.id = tt.tours_id
ORDER BY
    t.id ASC;
END$$

DROP PROCEDURE IF EXISTS `sp_select_tours_topics_id`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_select_tours_topics_id` (IN `id` INT)   BEGIN
   SELECT
    t.id,
    t.title
FROM
    tours_topics AS tt,
    topics AS t
WHERE
    tt.tours_id = id AND tt.topics_id = t.id;
        END$$

DROP PROCEDURE IF EXISTS `sp_select_tour_id`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_select_tour_id` (IN `tourId` INT)   BEGIN
     SELECT
        tr.id,
        tr.name,
        tr.description,
        tr.priceAdult as price,
        tr.priceChildren,
        i.image AS image
    FROM
        images AS i,
        tours AS tr
    WHERE tr.id = tourId AND i.tour_id = tr.id ;
END$$

DROP PROCEDURE IF EXISTS `sp_tours`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_tours` ()   BEGIN
SET FOREIGN_KEY_CHECKS = ON;
	CALL sp_tours_order_most;
    CALL sp_tours_hot;
END$$

DROP PROCEDURE IF EXISTS `sp_tours_hot`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_tours_hot` ()   BEGIN
	SELECT t.id, t.description, t.name, i.image, t.priceAdult AS price, 'hot' AS type
FROM tours AS t, images AS i
WHERE t.id = i.tour_id AND (t.id = 3 OR t.id = 2 OR t.id = 4);
END$$

DROP PROCEDURE IF EXISTS `sp_tours_hot_order_most`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_tours_hot_order_most` ()   BEGIN
	SELECT * FROM
(
    SELECT t.id, t.description, t.name, t.priceAdult AS price, i.image, COUNT(i.id) as quantity, 'hot' AS type, tc.id as topicId
    FROM tours AS t, images AS i, tours_topics as tt, topics as tc
    WHERE t.id = i.tour_id AND tt.tours_id = t.id AND tt.topics_id = tc.id AND (t.id = 45 OR t.id = 2 OR t.id = 4 OR t.id = 43)
    GROUP BY t.id, tc.id
) AS f
UNION ALL
(
	SELECT t.id, t.description, t.name, t.priceAdult as price, i.image, COUNT(bt.tour_id) as quantity, 'ordermost' AS type, tc.id as topicId
	FROM tours AS t, booked_tours AS bt, images AS i, tours_topics as tt, topics as tc
    WHERE t.id = bt.tour_id AND i.tour_id = t.id  AND tt.tours_id = t.id AND tt.topics_id = tc.id
    GROUP BY t.id, tc.id
    HAVING quantity BETWEEN 3 - 2 AND (
    	SELECT MAX(quantity) FROM (
    		SELECT COUNT(bt.tour_id) AS quantity FROM booked_tours AS bt GROUP BY bt.tour_id) AS C
    )
)
ORDER BY id ASC;
END$$

DROP PROCEDURE IF EXISTS `sp_tours_order_most`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_tours_order_most` ()   BEGIN
	DECLARE maxBookNumber INT DEFAULT 0;
    
	SELECT COUNT(tour_id) AS bookeNumber INTO maxBookNumber
    FROM booked_tours
    GROUP BY tour_id 
    HAVING COUNT(tour_id) = (
    SELECT MAX(bookeNumber) FROM (
    SELECT ID, tour_id, COUNT(tour_id) bookeNumber 
    FROM booked_tours
    GROUP BY tour_id
    ) AS S);
    
    SELECT t.id, t.description, t.name, t.priceAdult as price, COUNT(bt.tour_id) as bookeNumber, i.image, 'ordermost' AS type
FROM tours AS t, booked_tours AS bt, images AS i
    WHERE t.id = bt.tour_id AND i.tour_id = t.id
    GROUP BY t.id
    HAVING bookeNumber BETWEEN 3 - 2 AND 3
    ORDER BY bookeNumber DESC LIMIT 3;
END$$

DROP PROCEDURE IF EXISTS `sp_update_tours_categories`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_tours_categories` (`tourId` INT, `length` INT, `categories` VARCHAR(50))   BEGIN
	DECLARE count INT DEFAULT 0;
	DECLARE pos INT DEFAULT 1;
    
    CALL sp_delete_tours_categories(tourId);
    
	WHILE count < length DO
        CALL sp_insert_tours_categories(tourId, SUBSTRING(categories, pos, 1));
        SET pos = pos + 2;
        SET count = count + 1;
	END WHILE;
END$$

DROP PROCEDURE IF EXISTS `sp_update_tours_topics`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_tours_topics` (`tourId` INT, `length` INT, `topics` VARCHAR(50))   BEGIN
	DECLARE count INT DEFAULT 0;
	DECLARE pos INT DEFAULT 1;
    
    CALL sp_delete_tours_topics(tourId);
    
	WHILE count < length DO
        CALL sp_insert_tours_topics(tourId, SUBSTRING(topics, pos, 1));
        set pos = pos + 2;
        set count = count + 1;
	END WHILE;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `booked_tours`
--

DROP TABLE IF EXISTS `booked_tours`;
CREATE TABLE IF NOT EXISTS `booked_tours` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tour_id` int NOT NULL,
  `booked_date` date NOT NULL,
  `user_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_booked_users` (`user_id`),
  KEY `fk_booked_tours` (`tour_id`)
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `booked_tours`
--

INSERT INTO `booked_tours` (`id`, `tour_id`, `booked_date`, `user_id`) VALUES
(13, 1, '2023-11-30', 1),
(14, 3, '2023-11-30', 1),
(15, 5, '2023-11-30', 1),
(16, 42, '2023-11-30', 1),
(17, 46, '2023-11-30', 1),
(18, 1, '2023-11-30', 1),
(19, 3, '2023-11-30', 1),
(20, 5, '2023-11-30', 1),
(21, 42, '2023-11-30', 1),
(22, 46, '2023-11-30', 1),
(23, 1, '2023-11-30', 1),
(24, 42, '2023-11-30', 1),
(25, 46, '2023-11-30', 1),
(26, 5, '2023-11-30', 1),
(27, 5, '2023-11-30', 1),
(28, 1, '2023-11-30', 1),
(29, 45, '2023-11-30', 1),
(30, 45, '2023-11-30', 1),
(31, 45, '2023-11-30', 1),
(32, 45, '2023-11-30', 1),
(33, 37, '2023-11-30', 1),
(34, 37, '2023-11-30', 1),
(35, 37, '2023-11-30', 1),
(40, 45, '2023-11-30', 1),
(41, 45, '2023-11-30', 1),
(42, 45, '2023-11-30', 1),
(43, 45, '2023-11-30', 1),
(44, 45, '2023-11-30', 1),
(45, 43, '2023-11-30', 1),
(46, 37, '2023-12-31', 1),
(47, 43, '2023-12-31', 1);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `booke_details`
--

DROP TABLE IF EXISTS `booke_details`;
CREATE TABLE IF NOT EXISTS `booke_details` (
  `id` int NOT NULL AUTO_INCREMENT,
  `booked_tour_id` int NOT NULL,
  `name_company` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `country` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `zip_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `city` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `note` varchar(1000) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payment_method_id` int NOT NULL,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `surname` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `address` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `apartment` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `number_phone` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email_address` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity` int NOT NULL,
  `couponId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_bookeDetails_BookedTour` (`booked_tour_id`),
  KEY `FK_coupon_bookedDetails` (`couponId`),
  KEY `fk_bookeDetails_paymentMethods` (`payment_method_id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `booke_details`
--

INSERT INTO `booke_details` (`id`, `booked_tour_id`, `name_company`, `country`, `zip_code`, `city`, `note`, `payment_method_id`, `name`, `surname`, `address`, `apartment`, `number_phone`, `email_address`, `quantity`, `couponId`) VALUES
(1, 35, 'F8 Ofical', 'Vietnam', 'dsadas', 'Đồng Tháp', 'ghichu', 1, 'Phúc Đức', 'Dương Vĩnh', 'lý thường kiệt, khóm 4, phường 1, tp sa đéc', '192/5, Khóm 4, Phường 1, TP. Sa Đéc', '0763700336', 'admin1005@gmail.com', 12, 1),
(2, 40, 'F8 Ofical', 'Vietnam', 'dsadas', 'Đồng Tháp', 'ghichu', 2, 'Phúc Đức', 'Dương Vĩnh', 'lý thường kiệt, khóm 4, phường 1, tp sa đéc', '192/5, Khóm 4, Phường 1, TP. Sa Đéc', '0763700336', 'admin1005@gmail.com', 12, 1),
(3, 41, 'F8 Ofical', 'Vietnam', 'dsadas', 'Đồng Tháp', 'ghichu', 2, 'Phúc Đức', 'Dương Vĩnh', 'lý thường kiệt, khóm 4, phường 1, tp sa đéc', '192/5, Khóm 4, Phường 1, TP. Sa Đéc', '0763700336', 'admin1005@gmail.com', 12, 1),
(4, 42, 'F8 Ofical', 'Vietnam', 'dsadas', 'Đồng Tháp', '', 2, 'Phúc Đức', 'Dương Vĩnh', 'lý thường kiệt, khóm 4, phường 1, tp sa đéc', '192/5, Khóm 4, Phường 1, TP. Sa Đéc', '0763700336', 'admin1005@gmail.com', 12, 1),
(5, 43, 'F8 Ofical', 'Vietnam', 'dsadas', 'Đồng Tháp', '', 1, 'Phúc Đức', 'Dương Vĩnh', 'lý thường kiệt, khóm 4, phường 1, tp sa đéc', '192/5, Khóm 4, Phường 1, TP. Sa Đéc', '0763700336', 'admin1005@gmail.com', 12, 1),
(6, 45, 'F8 Ofical', 'Vietnam', 'dsadas', 'Đồng Tháp', 'test date format', 2, 'Phúc Đứcc', 'Dương Vĩnh', 'lý thường kiệt, khóm 4, phường 1, tp sa đéc', '192/5, Khóm 4, Phường 1, TP. Sa Đéc', '0763700336', 'admin1005@gmail.com', 4, 1),
(7, 46, 'F8 Ofical', 'Vietnam', 'dsadas', 'Đồng Tháp', '', 1, 'Phúc Đức', 'Dương Vĩnh', 'lý thường kiệt, khóm 4, phường 1, tp sa đéc', '192/5, Khóm 4, Phường 1, TP. Sa Đéc', '0763700336', 'admin1005@gmail.com', 5, 1),
(8, 47, 'F8 Ofical', 'Vietnam', 'dsadas', 'Đồng Tháp', 'ghichu /.....', 2, 'Phúc Đức', 'Dương Vĩnh', 'lý thường kiệt, khóm 4, phường 1, tp sa đéc', '192/5, Khóm 4, Phường 1, TP. Sa Đéc', '0763700336', 'admin1005@gmail.com', 6, 1);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `categories`
--

DROP TABLE IF EXISTS `categories`;
CREATE TABLE IF NOT EXISTS `categories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `categories`
--

INSERT INTO `categories` (`id`, `title`) VALUES
(1, 'Tour Miền Trung'),
(2, 'Tour Quảng Bình Trọn Gói'),
(3, 'Tour Mạo Hiểm'),
(4, 'Tour Hằng Ngày'),
(5, 'Tour Phong Nha Trọn Gói'),
(6, 'Tour Nổi Bật'),
(7, 'Tour Deal');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `coupon`
--

DROP TABLE IF EXISTS `coupon`;
CREATE TABLE IF NOT EXISTS `coupon` (
  `id` int NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` int NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `coupon`
--

INSERT INTO `coupon` (`id`, `code`, `value`) VALUES
(1, 'pntcl1005', 25);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `images`
--

DROP TABLE IF EXISTS `images`;
CREATE TABLE IF NOT EXISTS `images` (
  `id` int NOT NULL AUTO_INCREMENT,
  `image` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tour_id` int NOT NULL,
  `isMain` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_images_tours` (`tour_id`)
) ENGINE=InnoDB AUTO_INCREMENT=102 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `images`
--

INSERT INTO `images` (`id`, `image`, `tour_id`, `isMain`) VALUES
(58, '../images/anh-cau-hien-luong-014.jpg', 4, 1),
(59, '../images/phong-nha-ke-bang-park-252x212.jpg', 1, 1),
(60, '../images/hoian-720x606.jpg', 2, 1),
(61, '../images/suoi-mooc-quang-binh-4-720x606.jpg', 3, 1),
(63, '../images/20190502_195313-2-531x354.jpg', 5, 1),
(71, '../images/khu_du_lich_wvzh (1).jpg', 37, 1),
(76, '../images/congvienquangbinh-1-531x354.jpg', 42, 1),
(77, '../images/zipline-sông-Chày-hang-Tối-360x240.jpg', 43, 1),
(78, '../images/Ngắm-hoàng-hôn-trên-những-mỏm-đá-833x474-531x354.jpg', 44, 1),
(79, '../images/donthienduong3.jpg', 45, 1),
(80, '../images/ximang_quangbinh-531x354.jpg', 46, 1);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `payment_methods`
--

DROP TABLE IF EXISTS `payment_methods`;
CREATE TABLE IF NOT EXISTS `payment_methods` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `payment_methods`
--

INSERT INTO `payment_methods` (`id`, `name`) VALUES
(1, 'Thanh toán trực tuyến'),
(2, 'Thanh toán trực tiếp');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `topics`
--

DROP TABLE IF EXISTS `topics`;
CREATE TABLE IF NOT EXISTS `topics` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(1000) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `topics`
--

INSERT INTO `topics` (`id`, `title`) VALUES
(1, 'Tour Quảng Bình nổi bật'),
(2, 'Tour hằng ngày'),
(3, 'Tour đang ưu đãi');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `tours`
--

DROP TABLE IF EXISTS `tours`;
CREATE TABLE IF NOT EXISTS `tours` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(1000) COLLATE utf8mb4_unicode_ci NOT NULL,
  `priceAdult` decimal(20,0) NOT NULL,
  `priceChildren` float NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=67 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `tours`
--

INSERT INTO `tours` (`id`, `name`, `description`, `priceAdult`, `priceChildren`) VALUES
(1, 'TOUR ĐỘNG PHONG NHA – ĐỘNG THIÊN ĐƯỜNG', 'TOUR ĐỘNG PHONG NHA – ĐỘNG THIÊN ĐƯỜNG là chương trình tham quan Vườn quốc gia Phong Nha Kẻ Bàng của Quảng Bình nổi tiếng với những hang động tuyệt đẹp và hệ động thực vật đa dạng phong phú, bạn hãy đặt tour du lịch TOUR ĐỘNG PHONG NHA – ĐỘNG THIÊN ĐƯỜNG  để tận mắt ngắm nhìn tuyệt tác của thiên nhiên này vì “trăm nghe không bằng một thấy”. TOUR ĐỘNG PHONG NHA – ĐỘNG THIÊN ĐƯỜNG 1 Ngày cùng Phong Nha Travel sẽ đem đến cho quý khách những giây phút thư giản thoải mái hòa mình vào thiên nhiên cùng núi rừng Phong nha – Kẽ bàng. Với hơn 300 hang động lớn nhỏ Phong Nha – Kẻ Bàng được ví như một bảo tàng địa chất khổng lồ, chứa đựng lịch sử hơn 400 triệu năm trước của trái đất. Đặc điểm nổi bật ở đây là hệ thống sông ngầm trong hang động trong lòng núi đá vôi.Phong Nha với vẻ đẹp hoang sơ nhưng vô cùng kỳ vỹ làm say đắm lòng người.', '730000', 657000),
(2, 'Tour Đà Nẵng Hội An-Hội AN-Huế-Quảng Bình 5 ngày 4 đêm', 'Tour Đà Nẵng Hội An-Hội AN-Huế-Quảng Bình 5 ngày 4 đêm. là chương trình Chọn lọc tham quan các điểm đến hấp dẫn trong 4 tỉnh Miền Trung: Đà Nẵng – Hội An – Huế – Quảng Bình. Miền trung không chỉ sỡ hữu nhiều điểm đến hấp dẫn là những di sản văn hóa thế giới cùng các bãi tắm, vịnh biển đẹp là những điều kiện làm nên chuỗi sản phẩm du lịch Miền Trung thu hút du khách từ khắp mọi nơi.Tour Đà Nẵng Hội An-Hội AN-Huế-Quảng Bình 5 ngày 4 đêm. mở đầu với Quảng Bình được mệnh danh là “Vương Quốc Hang Động” khám phá Động Thiên Đường và Động Phong Nha, tham quan Vĩ Tuyến 17 “nhân chứng lịch sử” chia cắt đất Việt suốt 21 năm, đến Cố đô Huế với các điểm đến chọn lọc cùng thưởng thức những làn điệu Ca Huế trên dòng sông Hương thơ mộng, thăm Vịnh Lăng Cô, chinh phục đỉnh Bà Nà – Núi Chúa, khám phá triền núi Đông Nam Bán Đảo Sơn Trà. Chương trình được chúng tôi chọn lọc kỹ lưỡng cùng các dịch vụ tốt nhất chắc chắn sẽ làm bạn hài lòng.', '720000', 648000),
(3, 'Tour Động Động Thiên Đường Suối Nước Moọc', 'Để khám phá thiên nhiên hoang sơ hùng vĩ của Vườn quốc gia Phong Nha Kẻ Bàng một trong những vùng đá vôi nhiệt đới cổ đại nhất, rộng lớn nhất thế giới quý khách hãy đặt Tour du lịch Quảng Bình 1 ngày tham quan Động Thiên Đường Suối Nước Moọc vô cùng hấp dẫn.Tham gia tour Phong Nha Kẻ Bàng tham quan Động Thiên Đường Suối Nước Moọc 1 ngày khởi hành hàng ngày sẽ đưa du khách tìm hiểu sự đa dạng và quý hiếm của động thực vật, nhìn tận mắt những loại động vật thuộc danh mục sách đỏ của Việt Nam và thế giới hay chiêm nhưỡng kệt tác thạch nhủ trong động Thiên Đường, tận hưởng những giây phút thư giản thoải mái khi đắm mình trong dòng nước mát tại Suối Nước Moọc.', '1250000', 1125000),
(4, 'TOUR ĐỒNG HỚI – NTLS TRƯỜNG SƠN – THÀNH CỔ – CẦU H', 'Tour thăm lại chiến trường xưa ở Quảng Trị. Một trong những địa danh ác liệt nhất trong chiến tranh Việt Nam. Những di tích lịch sử Quốc Gia đặc biệt trong khu vực phi quân sự DMZ.Hãy đặt TOUR ĐỒNG HỚI – NTLS TRƯỜNG SƠN – THÀNH CỔ – CẦU HIỀN LƯƠNG ngay hôm nay. Để hưởng dịch vụ tốt nhất.', '2200000', 1980000),
(5, 'Tour Công viên OZo – bãi biển đá nhãy 1 ngày 1 đêm', 'Tour Công viên OZo – bãi biển đá nhãy 1 ngày. Là chương trình du lịch Quảng Bình khởi hành hàng ngày, du khách sẽ có dịp trải nghiệm cuộc sống của cư dân bản địa, thưởng ngoạn bức tranh sơn thủy hữu tình của Vườn quốc gia Phong Nha Kẻ Bàng.Được ngâm mình trong làn suối trong mát, trãi nghiệm trò chơi trên dây, Đám mình trong làn nước mát của bãi tắm đá nhảy.Du khách bỏ ra chí phí thấp được hưởng dịch vụ tốt nhất Bên cạnh đó sẽ có những người bạn cùng sở thích đồng hành cùng quý khách.hãy đặt Tour Công viên OZo – bãi biển đá nhãy 1 ngày ngay hôm nay.', '1150000', 1035000),
(37, 'Tour Vũng chùa Đảo Yến Đèo Ngang Làng Bích Họa bãi Đá Nhảy Cồn cát', 'Tour Vũng chùa Đảo Yến Đèo Ngang Làng Bích Họa bãi Đá Nhảy Cồn cát 1 ngày kết nối thắng cảnh Vũng Chùa Đảo Yến viếng mộ Đại Tướng, dừng chân ngắm phong cảnh thơ mộng của đèo Ngang, cầu an tại đền thờ Liễu Hạnh Công Chúa, trải nghiệm cuộc sống ngư dân của làng Bích Họa Cảnh Dương, tham quan Đá Nhảy và vui chơi tại Cồn Cát Quang Phú tạo thành một tuyến du lịch tâm linh kết hợp tham quan đầy sức thu hút, không chỉ phong cảnh đẹp mà còn rất thiêng liêng.\n\nĐặt Tour Vũng chùa Đảo Yến Đèo Ngang Làng Bích Họa bãi Đá Nhảy Cồn cát ngay hôm nay để khám phá những cảnh đẹp bắc Quảng Bình', '123432543', 111089000),
(42, 'Tour Động Phong Nha – Công viên ozo 1 ngày', 'Tour Động Phong Nha – Công viên ozo 1 ngày. Là Chương trình du lịch tham quan hang động kết hợp với nghĩ dưỡng tắm suối OZo có thêm trải nghiện Zipline trên cây vô cùng thú vị mà Cty chúng tôi đã chọn lọc kỹ lưỡng giúp du khách có những giây phút thoải mái.\nHãy đặt Tour Động Phong Nha – Công viên ozo 1 ngày  cùng Phong Nha Travel để được trải nghiệm theo cách trọn vẹn nhất.', '12312321', 11081100),
(43, 'Tour Động Phong Nha – Sông Chày Hang Tối', 'Tour Động Phong Nha – Sông Chày Hang Tối. Là chương trình du lịch Phong Nha 1 ngày khởi hành hàng ngày, du khách sẽ có dịp trải nghiệm cuộc sống của cư dân bản địa, thưởng ngoạn bức tranh sơn thủy hữu tình của Vườn quốc gia Phong Nha Kẻ Bàng.\n\nTour Động Phong Nha – Sông Chày Hang Tối du khách được vui chơi các trò chơi mạo hiểm như đu dây tắm sông Chày, đu dây vào Hang Tối, chèo thuyền Kayak … , tắm bùn tự nhiên. Chiêm ngưỡng Động Phong Nha được mệnh danh là “Đệ Nhất Kỳ Quan Động” ẩn chứa bao điều kỳ diệu khiến du khách như lạc vào thế giới thần tiên. Hãy Đặt Tour Động Phong Nha – Sông Chày – Hang Tối của PHONG NHA TRAVEL để được ưu đãi', '1350000', 1215000),
(44, 'TOUR DU LỊCH QUẢNG BÌNH 2 NGÀY 1 ĐÊM', 'TOUR DU LỊCH QUẢNG BÌNH 2 NGÀY 1 ĐÊM. dành cho những vị khách yêu du lịch nhưng hạn chế về mặt thời gian.Hành trình sẽ đưa quý khách tham quan một số danh thắng nổi bật của mảnh đất Quảng Bình như động Thiên Đường – Hoàng cung trong lòng đất, động Phong Nha – Kỳ quan đệ nhất động, Vũng chùa – Đảo Yến – nới an nghỉ cuối cùng của đại tướng Võ Nguyên Giáp.\n\nBên cạnh đó quý khách sẽ được dừng chân tại bãi biển Đá nhảy, môt trong những bãi biển đẹp của Quảng Bình với bãi đá nhấp nhô trải dài cho quý khách tha hồ ngắm cảnh và chụp ảnh lưu niệm. Đồi cát Quang Phú cũng là địa điểm vui chơi thú vị không thể thiếu trong chương trình này. Cùng nhau trượt cát trên đồi cát bao la cạnh bãi biển xanh biếc vô cùng thú vị…Hãy đặt TOUR DU LỊCH QUẢNG BÌNH 2 NGÀY 1 ĐÊM cùng Phong Nha Travel để được trải nghiệm theo cách trọn vẹn nhất.', '1890000', 1701000),
(45, 'Tour Phong Nha ghép đoàn hàng ngày', 'Tour Phong Nha ghép đoàn hàng ngày. Du khách có thể tham quan những cảnh đẹp nổi tiếng ở Quảng Bình với những hang động tuyệt đẹp và hệ động thực vật đa dạng phong phú, bạn hãy đặt tour du lịch Động Thiên Đường – Động Phong Nha để tận mắt ngắm nhìn tuyệt tác của thiên nhiên này vì “trăm nghe không bằng một thấy”.\n\n\nTour Phong Nha ghép đoàn hàng ngày. cùng Phong Nha Travel sẽ đem đến cho quý khách những giây phút thư giản thoải mái hòa mình vào thiên nhiên cùng núi rừng Phong nha – Kẽ bàng.\n\nHãy book Tour Động Thiên đường – Động Phong nha ghép đoàn hàng ngày của Phong Nha Travel', '1150000', 1035000),
(46, 'Tour Du lịch Quảng Bình 4 Ngày 3 Đêm', 'Tour Du lịch Quảng Bình 4 Ngày 3 Đêm. Là chường trình du lịch trọn gói hấp dẫn. du kháchTrải nghiệm những khoảng khắc đáng nhớ khi khám phá những danh lam thắng cảnh nổi tiếng nơi đây như vườn quốc gia Phong Nha Kẻ Bàng, biển Nhật Lệ, Vũng Chùa Đảo Yến, Đá Nhảy…\n\nNhững ai yêu thích thám hiểm, khám phá thiên nhiên hoang sơ hãy đặt tour du lịch quảng Bình 4 ngày 3 đêm để chiêm ngưỡng một bức tranh hoành tráng, có rừng, có biển với những di sản thiên nhiên quý báu mà tạo hóa đã ban tặng cho Quảng Bình, mảnh đất nằm ở miền Trung là tỉnh có chiều ngang hẹp nhất đất nước song chứa đựng bao điều kỳ thú và trải nghiệm cuộc sống cùng cư dân bản địa.', '3650000', 3285000);

--
-- Bẫy `tours`
--
DROP TRIGGER IF EXISTS `tg_deleteImage`;
DELIMITER $$
CREATE TRIGGER `tg_deleteImage` AFTER DELETE ON `tours` FOR EACH ROW BEGIN
	DELETE from images where tour_id = OLD.id; 
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `tours_categories`
--

DROP TABLE IF EXISTS `tours_categories`;
CREATE TABLE IF NOT EXISTS `tours_categories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tours_id` int NOT NULL,
  `categories_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_tours_categories_tours` (`tours_id`),
  KEY `fk_tours_categories_categories` (`categories_id`)
) ENGINE=InnoDB AUTO_INCREMENT=78 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `tours_categories`
--

INSERT INTO `tours_categories` (`id`, `tours_id`, `categories_id`) VALUES
(4, 2, 1),
(5, 2, 6),
(6, 2, 2),
(9, 4, 1),
(10, 4, 4),
(11, 5, 3),
(12, 5, 6),
(15, 42, 1),
(16, 42, 7),
(17, 42, 6),
(19, 45, 1),
(20, 45, 3),
(21, 45, 5),
(22, 3, 4),
(23, 3, 6),
(24, 3, 7),
(25, 3, 5),
(29, 43, 5),
(30, 43, 4),
(31, 43, 6),
(32, 46, 4),
(33, 46, 2),
(34, 46, 7),
(35, 44, 2),
(36, 44, 6),
(37, 44, 4),
(38, 37, 1),
(39, 37, 7),
(66, 1, 7),
(67, 1, 4),
(68, 1, 6);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `tours_topics`
--

DROP TABLE IF EXISTS `tours_topics`;
CREATE TABLE IF NOT EXISTS `tours_topics` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tours_id` int NOT NULL,
  `topics_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_tours_topics_tours` (`tours_id`),
  KEY `fk_tours_topics_topics` (`topics_id`)
) ENGINE=InnoDB AUTO_INCREMENT=85 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `tours_topics`
--

INSERT INTO `tours_topics` (`id`, `tours_id`, `topics_id`) VALUES
(3, 2, 2),
(4, 2, 3),
(5, 3, 3),
(6, 4, 2),
(7, 5, 2),
(8, 5, 3),
(9, 37, 2),
(10, 37, 3),
(11, 42, 1),
(12, 42, 2),
(13, 42, 3),
(14, 43, 1),
(15, 43, 3),
(16, 44, 3),
(17, 44, 2),
(18, 46, 1),
(19, 46, 2),
(20, 46, 3),
(78, 45, 1),
(79, 45, 2);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE IF NOT EXISTS `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone_number` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `isAdmin` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `email`, `phone_number`, `isAdmin`) VALUES
(1, 'admin', '1005', 'admin1005@gmail.com', '0763700336', 1),
(2, 'admin', '2003', 'admin2003@gmail.com', '0763700336', 1),
(3, 'tringuyen', '2003', 'tringuyen1103@gmail.com', '0986578763', 0);

-- --------------------------------------------------------

--
-- Cấu trúc đóng vai cho view `v_tours_hot_order_most`
-- (See below for the actual view)
--
DROP VIEW IF EXISTS `v_tours_hot_order_most`;
CREATE TABLE IF NOT EXISTS `v_tours_hot_order_most` (
`id` int
,`description` text
,`name` varchar(200)
,`price` decimal(20,0)
,`priceChildren` float
,`image` text
,`quantity` bigint
,`type` varchar(9)
,`topicId` int
);

-- --------------------------------------------------------

--
-- Cấu trúc cho view `v_tours_hot_order_most`
--
DROP TABLE IF EXISTS `v_tours_hot_order_most`;

DROP VIEW IF EXISTS `v_tours_hot_order_most`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_tours_hot_order_most`  AS SELECT `f`.`id` AS `id`, `f`.`description` AS `description`, `f`.`name` AS `name`, `f`.`price` AS `price`, `f`.`priceChildren` AS `priceChildren`, `f`.`image` AS `image`, `f`.`quantity` AS `quantity`, `f`.`type` AS `type`, `f`.`topicId` AS `topicId` FROM (select `t`.`id` AS `id`,`t`.`description` AS `description`,`t`.`name` AS `name`,`t`.`priceAdult` AS `price`,`t`.`priceChildren` AS `priceChildren`,`i`.`image` AS `image`,count(`i`.`id`) AS `quantity`,'hot' AS `type`,`tc`.`id` AS `topicId` from (((`tours` `t` join `images` `i`) join `tours_topics` `tt`) join `topics` `tc`) where ((`t`.`id` = `i`.`tour_id`) and (`tt`.`tours_id` = `t`.`id`) and (`tt`.`topics_id` = `tc`.`id`) and ((`t`.`id` = 45) or (`t`.`id` = 2) or (`t`.`id` = 4) or (`t`.`id` = 43))) group by `t`.`id`,`tc`.`id`) AS `f` union all select `t`.`id` AS `id`,`t`.`description` AS `description`,`t`.`name` AS `name`,`t`.`priceAdult` AS `price`,`t`.`priceChildren` AS `priceChildren`,`i`.`image` AS `image`,count(`bt`.`tour_id`) AS `quantity`,'ordermost' AS `type`,`tc`.`id` AS `topicId` from ((((`tours` `t` join `booked_tours` `bt`) join `images` `i`) join `tours_topics` `tt`) join `topics` `tc`) where ((`t`.`id` = `bt`.`tour_id`) and (`i`.`tour_id` = `t`.`id`) and (`tt`.`tours_id` = `t`.`id`) and (`tt`.`topics_id` = `tc`.`id`)) group by `t`.`id`,`tc`.`id` having (`quantity` between (3 - 2) and 3) order by `id`  ;

--
-- Các ràng buộc cho các bảng đã đổ
--

--
-- Các ràng buộc cho bảng `booked_tours`
--
ALTER TABLE `booked_tours`
  ADD CONSTRAINT `fk_booked_tours` FOREIGN KEY (`tour_id`) REFERENCES `tours` (`id`),
  ADD CONSTRAINT `fk_booked_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Các ràng buộc cho bảng `booke_details`
--
ALTER TABLE `booke_details`
  ADD CONSTRAINT `fk_bookeDetails_BookedTour` FOREIGN KEY (`booked_tour_id`) REFERENCES `booked_tours` (`id`),
  ADD CONSTRAINT `fk_bookeDetails_paymentMethods` FOREIGN KEY (`payment_method_id`) REFERENCES `payment_methods` (`id`),
  ADD CONSTRAINT `FK_coupon_bookedDetails` FOREIGN KEY (`couponId`) REFERENCES `coupon` (`id`);

--
-- Các ràng buộc cho bảng `images`
--
ALTER TABLE `images`
  ADD CONSTRAINT `fk_images_tours` FOREIGN KEY (`tour_id`) REFERENCES `tours` (`id`);

--
-- Các ràng buộc cho bảng `tours_categories`
--
ALTER TABLE `tours_categories`
  ADD CONSTRAINT `fk_tours_categories_categories` FOREIGN KEY (`categories_id`) REFERENCES `categories` (`id`),
  ADD CONSTRAINT `fk_tours_categories_tours` FOREIGN KEY (`tours_id`) REFERENCES `tours` (`id`);

--
-- Các ràng buộc cho bảng `tours_topics`
--
ALTER TABLE `tours_topics`
  ADD CONSTRAINT `fk_tours_topics_topics` FOREIGN KEY (`topics_id`) REFERENCES `topics` (`id`),
  ADD CONSTRAINT `fk_tours_topics_tours` FOREIGN KEY (`tours_id`) REFERENCES `tours` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
