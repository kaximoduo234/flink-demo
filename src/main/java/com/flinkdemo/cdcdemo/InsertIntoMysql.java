package com.flinkdemo.cdcdemo;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.*;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

public class InsertIntoMysql {

    private static final Logger logger = LoggerFactory.getLogger(InsertIntoMysql.class);

    // HikariCP连接池配置
    private static final HikariDataSource dataSource;

    static {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:mysql://localhost:3306/ods?serverTimezone=Asia/Shanghai&useUnicode=true&characterEncoding=UTF-8&rewriteBatchedStatements=true");
        config.setUsername("root");
        config.setPassword("root123");
        config.setMaximumPoolSize(10);
        config.setMinimumIdle(5);
        config.addDataSourceProperty("cachePrepStmts", "true");
        config.addDataSourceProperty("prepStmtCacheSize", "250");
        config.addDataSourceProperty("prepStmtCacheSqlLimit", "2048");
        dataSource = new HikariDataSource(config);
    }

    public static void main(String[] args) {
        final int BATCH_SIZE = 1; // 每批次条数
        final long SLEEP_INTERVAL = 3000L; // 每批次间隔 ms
        final int MAX_TOTAL = 50; // 最大写入总数

        int totalCount = 0;

        try (Connection conn = dataSource.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(
                     "INSERT INTO users (username, email, birthdate, is_active) VALUES (?, ?, ?, ?)")) {

            conn.setAutoCommit(false);

            while (totalCount < MAX_TOTAL) {
                List<DataRecord> batchData = generateData(BATCH_SIZE);

                for (DataRecord record : batchData) {
                    pstmt.setString(1, record.getUsername());
                    pstmt.setString(2, record.getEmail());
                    pstmt.setDate(3, new java.sql.Date(record.getBirthdate().getTime()));
                    pstmt.setInt(4, record.getIsActive()); // 修复：is_active 只应为 0/1
                    pstmt.addBatch();
                }

                try {
                    pstmt.executeBatch();
                    conn.commit();
                    logger.info("已插入 {} 条数据，当前批次: {} 条", totalCount += batchData.size(), batchData.size());
                } catch (SQLException e) {
                    conn.rollback();
                    logger.error("批次执行失败，事务回滚", e);
                }

                pstmt.clearBatch();
                Thread.sleep(SLEEP_INTERVAL);
            }

            logger.info("数据插入完成，共计插入 {} 条记录。", totalCount);
        } catch (SQLException | InterruptedException e) {
            logger.error("插入过程异常", e);
            Thread.currentThread().interrupt(); // 恢复线程中断标记
        } finally {
            dataSource.close();
        }
    }

    // 生成模拟数据
    private static List<DataRecord> generateData(int count) {
        List<DataRecord> data = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            String timestamp = String.valueOf(System.currentTimeMillis());
            data.add(new DataRecord(
                    "user_" + timestamp,
                    "user_" + timestamp + "@example.com",
                    new Date(),
                    Math.random() > 0.5 ? 1 : 0  // 合法 is_active 值
            ));
        }
        return data;
    }

    // 简单实体类
    static class DataRecord {
        private final String username;
        private final String email;
        private final Date birthdate;
        private final int isActive;

        public DataRecord(String username, String email, Date birthdate, int isActive) {
            this.username = username;
            this.email = email;
            this.birthdate = birthdate;
            this.isActive = isActive;
        }

        public String getUsername() { return username; }
        public String getEmail() { return email; }
        public Date getBirthdate() { return birthdate; }
        public int getIsActive() { return isActive; }
    }
}
