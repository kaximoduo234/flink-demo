-- ====================================================================
-- StarRocks 数据仓库表建表脚本
-- 用途：创建 DWS/ADS 层聚合宽表，供 OLAP 分析
-- 执行：docker exec -it starrocks mysql -uroot -h127.0.0.1 -P9030
-- ====================================================================

-- 创建分析数据库
CREATE DATABASE IF NOT EXISTS analytics;
USE analytics;

-- DWS 层：用户维度统计表
CREATE TABLE dws_user_stats (
    date_key DATE COMMENT '日期',
    gender VARCHAR(20) COMMENT '性别',
    age_group VARCHAR(20) COMMENT '年龄段：18-25/26-35/36-45/46+',
    city VARCHAR(100) COMMENT '城市',
    user_count BIGINT SUM DEFAULT '0' COMMENT '用户数量',
    new_user_count BIGINT SUM DEFAULT '0' COMMENT '新增用户数',
    active_user_count BIGINT SUM DEFAULT '0' COMMENT '活跃用户数',
    latest_ts DATETIME MAX COMMENT '最新更新时间'
) ENGINE=OLAP
AGGREGATE KEY (date_key, gender, age_group, city)
DISTRIBUTED BY HASH(date_key, gender) BUCKETS 8
PROPERTIES (
    "replication_num" = "1",
    "storage_format" = "DEFAULT",
    "compression" = "LZ4"
);

-- DWS 层：商品维度统计表
CREATE TABLE dws_product_stats (
    date_key DATE COMMENT '日期',
    category VARCHAR(100) COMMENT '商品类别',
    brand VARCHAR(100) COMMENT '品牌',
    view_count BIGINT SUM DEFAULT '0' COMMENT '浏览次数',
    click_count BIGINT SUM DEFAULT '0' COMMENT '点击次数',
    purchase_count BIGINT SUM DEFAULT '0' COMMENT '购买次数',
    favorite_count BIGINT SUM DEFAULT '0' COMMENT '收藏次数',
    total_sales_amount DECIMAL(18,2) SUM DEFAULT '0.00' COMMENT '销售总额',
    avg_price DECIMAL(10,2) REPLACE COMMENT '平均价格',
    latest_ts DATETIME MAX COMMENT '最新更新时间'
) ENGINE=OLAP
AGGREGATE KEY (date_key, category, brand)
DISTRIBUTED BY HASH(date_key, category) BUCKETS 8
PROPERTIES (
    "replication_num" = "1",
    "storage_format" = "DEFAULT",
    "compression" = "LZ4"
);

-- DWS 层：订单维度统计表
CREATE TABLE dws_order_stats (
    date_key DATE COMMENT '日期',
    hour_key INT COMMENT '小时',
    payment_method VARCHAR(50) COMMENT '支付方式',
    order_status VARCHAR(20) COMMENT '订单状态',
    order_count BIGINT SUM DEFAULT '0' COMMENT '订单数量',
    total_amount DECIMAL(18,2) SUM DEFAULT '0.00' COMMENT '订单总金额',
    avg_amount DECIMAL(12,2) REPLACE COMMENT '平均订单金额',
    max_amount DECIMAL(12,2) MAX COMMENT '最大订单金额',
    min_amount DECIMAL(12,2) MIN COMMENT '最小订单金额',
    latest_ts DATETIME MAX COMMENT '最新更新时间'
) ENGINE=OLAP
AGGREGATE KEY (date_key, hour_key, payment_method, order_status)
DISTRIBUTED BY HASH(date_key, hour_key) BUCKETS 8
PROPERTIES (
    "replication_num" = "1",
    "storage_format" = "DEFAULT",
    "compression" = "LZ4"
);

-- DWS 层：用户行为统计表
CREATE TABLE dws_user_behavior_stats (
    date_key DATE COMMENT '日期',
    hour_key INT COMMENT '小时',
    user_id BIGINT COMMENT '用户ID',
    behavior_type VARCHAR(50) COMMENT '行为类型',
    item_category VARCHAR(100) COMMENT '商品类别',
    behavior_count BIGINT SUM DEFAULT '0' COMMENT '行为次数',
    session_count BIGINT SUM DEFAULT '0' COMMENT '会话数',
    latest_behavior_time DATETIME MAX COMMENT '最新行为时间',
    latest_ts DATETIME MAX COMMENT '最新更新时间'
) ENGINE=OLAP
AGGREGATE KEY (date_key, hour_key, user_id, behavior_type, item_category)
DISTRIBUTED BY HASH(user_id, date_key) BUCKETS 8
PROPERTIES (
    "replication_num" = "1",
    "storage_format" = "DEFAULT",
    "compression" = "LZ4"
);

-- ADS 层：实时大屏指标表
CREATE TABLE ads_realtime_metrics (
    metric_key VARCHAR(100) COMMENT '指标键',
    metric_name VARCHAR(200) COMMENT '指标名称',
    metric_value DECIMAL(18,2) REPLACE COMMENT '指标值',
    metric_unit VARCHAR(50) COMMENT '指标单位',
    category VARCHAR(100) COMMENT '指标分类',
    update_time DATETIME REPLACE COMMENT '更新时间'
) ENGINE=OLAP
PRIMARY KEY (metric_key)
DISTRIBUTED BY HASH(metric_key) BUCKETS 4
PROPERTIES (
    "replication_num" = "1",
    "storage_format" = "DEFAULT"
);

-- ADS 层：每日汇总报表
CREATE TABLE ads_daily_summary (
    date_key DATE COMMENT '日期',
    total_users BIGINT REPLACE COMMENT '总用户数',
    new_users BIGINT REPLACE COMMENT '新增用户数',
    active_users BIGINT REPLACE COMMENT '活跃用户数',
    total_orders BIGINT REPLACE COMMENT '总订单数',
    total_sales_amount DECIMAL(18,2) REPLACE COMMENT '总销售额',
    avg_order_amount DECIMAL(12,2) REPLACE COMMENT '平均订单金额',
    total_page_views BIGINT REPLACE COMMENT '总页面浏览量',
    total_clicks BIGINT REPLACE COMMENT '总点击数',
    conversion_rate DECIMAL(5,4) REPLACE COMMENT '转化率',
    update_time DATETIME REPLACE COMMENT '更新时间'
) ENGINE=OLAP
PRIMARY KEY (date_key)
DISTRIBUTED BY HASH(date_key) BUCKETS 4
PROPERTIES (
    "replication_num" = "1",
    "storage_format" = "DEFAULT"
);

-- 创建维度表：用户维度表
CREATE TABLE dim_user (
    user_id BIGINT COMMENT '用户ID',
    name VARCHAR(255) COMMENT '用户姓名',
    gender VARCHAR(20) COMMENT '性别',
    age INT COMMENT '年龄',
    age_group VARCHAR(20) COMMENT '年龄段',
    email VARCHAR(255) COMMENT '邮箱',
    phone VARCHAR(20) COMMENT '手机号',
    city VARCHAR(100) COMMENT '城市',
    register_time DATETIME COMMENT '注册时间',
    is_active BOOLEAN COMMENT '是否活跃',
    last_login_time DATETIME COMMENT '最后登录时间',
    update_time DATETIME REPLACE COMMENT '更新时间'
) ENGINE=OLAP
PRIMARY KEY (user_id)
DISTRIBUTED BY HASH(user_id) BUCKETS 8
PROPERTIES (
    "replication_num" = "1",
    "storage_format" = "DEFAULT"
);

-- 创建维度表：商品维度表
CREATE TABLE dim_product (
    product_id BIGINT COMMENT '商品ID',
    product_name VARCHAR(255) COMMENT '商品名称',
    category VARCHAR(100) COMMENT '商品类别',
    brand VARCHAR(100) COMMENT '品牌',
    price DECIMAL(10,2) COMMENT '价格',
    status VARCHAR(20) COMMENT '状态',
    create_time DATETIME COMMENT '创建时间',
    update_time DATETIME REPLACE COMMENT '更新时间'
) ENGINE=OLAP
PRIMARY KEY (product_id)
DISTRIBUTED BY HASH(product_id) BUCKETS 8
PROPERTIES (
    "replication_num" = "1",
    "storage_format" = "DEFAULT"
);

-- 插入初始化数据到实时指标表
INSERT INTO ads_realtime_metrics VALUES
('total_users', '总用户数', 0, '人', 'user', NOW()),
('new_users_today', '今日新增用户', 0, '人', 'user', NOW()),
('total_orders', '总订单数', 0, '单', 'order', NOW()),
('total_sales', '总销售额', 0, '元', 'sales', NOW()),
('avg_order_amount', '平均订单金额', 0, '元', 'sales', NOW()),
('conversion_rate', '转化率', 0, '%', 'conversion', NOW());

-- 显示创建的表
SHOW TABLES;

-- 显示表结构示例
DESCRIBE dws_user_stats;
DESCRIBE ads_realtime_metrics; 