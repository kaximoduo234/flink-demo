package com.flinkdemo.cdcdemo;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

/**
 * description:
 *
 * @author: jj.Sun
 * date: 2025/6/12.
 */
public class InsertIntoMysql {
    // HikariCP连接池配置
    private static HikariDataSource dataSource;
    static {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:mysql://localhost:3306/ods?serverTimezone=Asia/Shanghai&useUnicode=true&characterEncoding=UTF-8&rewriteBatchedStatements=true");
        config.setUsername("root");
        config.setPassword("root123");
        config.setMaximumPoolSize(10); // 最大连接数
        config.setMinimumIdle(5);      // 最小空闲连接
        config.addDataSourceProperty("cachePrepStmts", "true");
        config.addDataSourceProperty("prepStmtCacheSize", "250");
        config.addDataSourceProperty("prepStmtCacheSqlLimit", "2048");
        dataSource = new HikariDataSource(config);
    }

    public static void main(String[] args) {
        final int BATCH_SIZE = 10; // 每批次插入量
        final long SLEEP_INTERVAL = 10000; // 批次间隔(毫秒)

        try (Connection conn = dataSource.getConnection()) {
            // 创建预编译语句
            String sql = "INSERT INTO users (username,email,birthdate,is_active) VALUES (?, ?, ?, ?)";
            PreparedStatement pstmt = conn.prepareStatement(sql);

            // 关闭自动提交以启用事务
            conn.setAutoCommit(false);

            int totalCount = 0;
            while (true) { // 持续插入循环
                List<DataRecord> batchData = generateData(BATCH_SIZE); // 模拟数据生成

                // 批量参数设置
                for (DataRecord record : batchData) {
                    pstmt.setString(1, record.getUsername());
                    pstmt.setString(2, record.getEmail());
                    pstmt.setDate(3, new java.sql.Date(record.getBirthdate().getTime()));
                    pstmt.setInt(4, record.getIsActive());
                    pstmt.addBatch(); // 添加到批处理
                }

                // 执行批处理
                int[] results = pstmt.executeBatch();
                conn.commit(); // 提交事务

                totalCount += batchData.size();
                System.out.printf("已插入 %d 条数据，当前批次: %d 条%n",
                        totalCount, batchData.size());

                // 清空批处理缓存
                pstmt.clearBatch();

                Thread.sleep(SLEEP_INTERVAL); // 控制插入频率
            }
        } catch (SQLException | InterruptedException e) {
            e.printStackTrace();
        }
    }

    // 模拟数据生成方法
    private static List<DataRecord> generateData(int count) {
        List<DataRecord> data = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            data.add(new DataRecord("user_" + System.currentTimeMillis(),
                    "user_" + System.currentTimeMillis() + "@qq.com",
                    new Date(),
                    (int)(Math.random() * 50 + 18)));
        }
        return data;
    }

    // 数据记录实体类
    static class DataRecord {
        private String username;
        private String email;

        private Date birthdate;
        private int isActive;

        public DataRecord(String username, String email, Date birthdate, int isActive) {
            this.username = username;
            this.email = email;
            this.birthdate = birthdate;
            this.isActive = isActive;
        }

        // Getter方法
        public String getUsername() { return username; }

        public Date getBirthdate() { return birthdate; }

        public int getIsActive() { return isActive; }
        public String getEmail() { return email; }
    }
}
