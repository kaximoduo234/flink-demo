-- 创建数据库
CREATE DATABASE IF NOT EXISTS ods CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 使用数据库
USE ods;

-- 创建users表
CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    birthdate DATE,
    is_active TINYINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 插入测试数据
INSERT INTO users (username, email, birthdate, is_active) VALUES
('test_user1', 'test1@example.com', '1990-01-01', 1),
('test_user2', 'test2@example.com', '1995-05-15', 1),
('test_user3', 'test3@example.com', '1988-12-25', 0);

-- 显示表结构
DESCRIBE users; 