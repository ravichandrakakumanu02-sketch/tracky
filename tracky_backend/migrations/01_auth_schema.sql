-- Migration 01: Multi-user authentication schema
-- Clear any existing dummy data
DELETE FROM `exercises`;
DELETE FROM `workout_logs`;

-- Create users table
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_users_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Add user_id column and foreign key to workout_logs
ALTER TABLE `workout_logs`
ADD COLUMN `user_id` INT NOT NULL AFTER `id`;

ALTER TABLE `workout_logs`
ADD CONSTRAINT `fk_workout_logs_user`
FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
ON DELETE CASCADE;

-- Drop single-column unique constraint on workout_date and replace with composite constraint
ALTER TABLE `workout_logs` DROP INDEX `workout_date`;
ALTER TABLE `workout_logs` ADD UNIQUE KEY `uq_user_workout_date` (`user_id`, `workout_date`);
