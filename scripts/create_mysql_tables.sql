-- ====================================================================
-- MySQL 数据源表建表脚本
-- 用途：创建业务数据源表，供 Flink CDC 抽取
-- 执行：docker exec -it mysql mysql -uroot -proot123
-- ====================================================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS ods CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ods;

-- 用户基础信息表
CREATE TABLE user (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL COMMENT '用户姓名',
    gender VARCHAR(20) NOT NULL COMMENT '性别：M/F',
    age INT NOT NULL COMMENT '年龄',
    email VARCHAR(255) COMMENT '邮箱',
    phone VARCHAR(20) COMMENT '手机号',
    city VARCHAR(100) COMMENT '城市',
    register_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
    ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_gender (gender),
    INDEX idx_city (city),
    INDEX idx_register_time (register_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户基础信息表';

-- 用户行为表
CREATE TABLE user_behavior (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    behavior_type VARCHAR(50) NOT NULL COMMENT '行为类型：view/click/purchase/favorite',
    item_id BIGINT COMMENT '商品ID',
    item_category VARCHAR(100) COMMENT '商品类别',
    behavior_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '行为时间',
    session_id VARCHAR(100) COMMENT '会话ID',
    ip_address VARCHAR(45) COMMENT 'IP地址',
    user_agent TEXT COMMENT '用户代理',
    ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_user_id (user_id),
    INDEX idx_behavior_type (behavior_type),
    INDEX idx_behavior_time (behavior_time),
    INDEX idx_item_id (item_id),
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户行为表';

-- 商品信息表
CREATE TABLE product (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(255) NOT NULL COMMENT '商品名称',
    category VARCHAR(100) NOT NULL COMMENT '商品类别',
    brand VARCHAR(100) COMMENT '品牌',
    price DECIMAL(10,2) NOT NULL COMMENT '价格',
    stock_quantity INT DEFAULT 0 COMMENT '库存数量',
    status VARCHAR(20) DEFAULT 'ACTIVE' COMMENT '状态：ACTIVE/INACTIVE',
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_category (category),
    INDEX idx_brand (brand),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品信息表';

-- 订单表
CREATE TABLE orders (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    order_no VARCHAR(50) UNIQUE NOT NULL COMMENT '订单号',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    total_amount DECIMAL(12,2) NOT NULL COMMENT '订单总金额',
    order_status VARCHAR(20) DEFAULT 'PENDING' COMMENT '订单状态：PENDING/PAID/SHIPPED/COMPLETED/CANCELLED',
    payment_method VARCHAR(50) COMMENT '支付方式',
    shipping_address TEXT COMMENT '收货地址',
    order_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '下单时间',
    payment_time TIMESTAMP NULL COMMENT '支付时间',
    ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_user_id (user_id),
    INDEX idx_order_status (order_status),
    INDEX idx_order_time (order_time),
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单表';

-- 订单明细表
CREATE TABLE order_detail (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    order_id BIGINT NOT NULL COMMENT '订单ID',
    product_id BIGINT NOT NULL COMMENT '商品ID',
    product_name VARCHAR(255) NOT NULL COMMENT '商品名称',
    quantity INT NOT NULL COMMENT '购买数量',
    unit_price DECIMAL(10,2) NOT NULL COMMENT '单价',
    total_price DECIMAL(12,2) NOT NULL COMMENT '小计金额',
    ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_order_id (order_id),
    INDEX idx_product_id (product_id),
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单明细表';

-- 插入测试数据
INSERT INTO user (name, gender, age, email, phone, city) VALUES
('张三', 'M', 25, 'zhangsan@example.com', '13800138001', '北京'),
('李四', 'F', 30, 'lisi@example.com', '13800138002', '上海'),
('王五', 'M', 28, 'wangwu@example.com', '13800138003', '广州'),
('赵六', 'F', 26, 'zhaoliu@example.com', '13800138004', '深圳'),
('钱七', 'M', 32, 'qianqi@example.com', '13800138005', '杭州');

INSERT INTO product (product_name, category, brand, price, stock_quantity) VALUES
('iPhone 15', '手机', 'Apple', 7999.00, 100),
('MacBook Pro', '笔记本', 'Apple', 15999.00, 50),
('小米13', '手机', '小米', 3999.00, 200),
('华为MateBook', '笔记本', '华为', 6999.00, 80),
('AirPods Pro', '耳机', 'Apple', 1999.00, 150);

INSERT INTO user_behavior (user_id, behavior_type, item_id, item_category, session_id) VALUES
(1, 'view', 1, '手机', 'session_001'),
(1, 'click', 1, '手机', 'session_001'),
(2, 'view', 2, '笔记本', 'session_002'),
(3, 'purchase', 3, '手机', 'session_003'),
(4, 'favorite', 4, '笔记本', 'session_004'),
(5, 'view', 5, '耳机', 'session_005');

INSERT INTO orders (order_no, user_id, total_amount, order_status, payment_method) VALUES
('ORD20250619001', 1, 7999.00, 'PAID', 'ALIPAY'),
('ORD20250619002', 3, 3999.00, 'COMPLETED', 'WECHAT'),
('ORD20250619003', 2, 15999.00, 'PENDING', 'BANK_CARD');

INSERT INTO order_detail (order_id, product_id, product_name, quantity, unit_price, total_price) VALUES
(1, 1, 'iPhone 15', 1, 7999.00, 7999.00),
(2, 3, '小米13', 1, 3999.00, 3999.00),
(3, 2, 'MacBook Pro', 1, 15999.00, 15999.00);

-- 显示表结构和数据
SHOW TABLES;
SELECT COUNT(*) as user_count FROM user;
SELECT COUNT(*) as behavior_count FROM user_behavior;
SELECT COUNT(*) as product_count FROM product;
SELECT COUNT(*) as order_count FROM orders;
SELECT COUNT(*) as order_detail_count FROM order_detail; 