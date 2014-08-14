DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` INTEGER NOT NULL auto_increment PRIMARY KEY,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  UNIQUE KEY `username_uniq_idx` (`username`),
  PRIMARY KEY (`id`)
) CHARACTER SET utf8 ENGINE=InnoDB;

DROP TABLE IF EXISTS `posts`;
CREATE TABLE `posts` (
  `id`      INTEGER NOT NULL auto_increment PRIMARY KEY,
  `user_id` INTEGER NOT NULL,
  `content` TEXT,
  `created_at` TIMESTAMP NOT NULL,
  INDEX `post_created_at` (`created_at`)
) CHARACTER SET utf8 ENGINE=InnoDB;

DROP TABLE IF EXISTS `stars`;
CREATE TABLE `stars` (
  `id`      INTEGER NOT NULL auto_increment PRIMARY KEY,
  `user_id` INTEGER NOT NULL,
  `post_id` INTEGER NOT NULL,
  PRIMARY KEY (`user_id`, `post_id`)
) CHARACTER SET utf8 ENGINE=InnoDB;
