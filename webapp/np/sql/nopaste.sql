DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` INTEGER NOT NULL auto_increment PRIMARY KEY,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  UNIQUE KEY `username_uniq_idx` (`username`)
) CHARACTER SET utf8 ENGINE=InnoDB;

DROP TABLE IF EXISTS `posts`;
CREATE TABLE `posts` (
  `id`      INTEGER NOT NULL auto_increment PRIMARY KEY,
  `user_id` INTEGER NOT NULL,
  `content` TEXT,
  `created_at` TIMESTAMP NOT NULL
) CHARACTER SET utf8 ENGINE=InnoDB;

DROP TABLE IF EXISTS `stars`;
CREATE TABLE `stars` (
  `id`      INTEGER NOT NULL auto_increment PRIMARY KEY,
  `user_id` INTEGER NOT NULL,
  `post_id` INTEGER NOT NULL
) CHARACTER SET utf8 ENGINE=InnoDB;

