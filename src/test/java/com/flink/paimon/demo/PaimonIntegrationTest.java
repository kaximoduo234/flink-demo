package com.flink.paimon.demo;

import org.apache.flink.configuration.Configuration;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.table.api.TableResult;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;
import org.apache.flink.types.Row;
import org.apache.flink.util.CloseableIterator;
import org.junit.jupiter.api.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testcontainers.containers.KafkaContainer;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 🔥 Paimon集成测试套件
 * 
 * 测试覆盖:
 * - Paimon表创建和管理
 * - 数据插入和流式查询
 * - 批处理查询模式
 * - Schema演进
 * - 性能基准测试
 */
@Testcontainers
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@DisplayName("🔥 Paimon Integration Test Suite")
public class PaimonIntegrationTest {

    private static final Logger LOG = LoggerFactory.getLogger(PaimonIntegrationTest.class);
    
    private StreamExecutionEnvironment env;
    private StreamTableEnvironment tableEnv;

    @Container
    static KafkaContainer kafka = new KafkaContainer(DockerImageName.parse("confluentinc/cp-kafka:7.4.0"))
            .withEmbeddedZookeeper()
            .withEnv("KAFKA_AUTO_CREATE_TOPICS_ENABLE", "true");

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0")
            .withDatabaseName("test_db")
            .withUsername("test")
            .withPassword("test");

    @BeforeEach
    void setUp() {
        LOG.info("🚀 Setting up Flink environment...");
        
        Configuration config = new Configuration();
        config.setString("execution.checkpointing.interval", "10s");
        config.setString("execution.checkpointing.mode", "EXACTLY_ONCE");
        config.setString("state.backend", "rocksdb");
        config.setString("state.checkpoints.dir", "file:///tmp/checkpoints");
        
        env = StreamExecutionEnvironment.getExecutionEnvironment(config);
        env.setParallelism(1);
        
        tableEnv = StreamTableEnvironment.create(env);
        
        // 配置Paimon Catalog
        tableEnv.executeSql("CREATE CATALOG paimon_catalog WITH (" +
                "'type' = 'paimon'," +
                "'warehouse' = 'file:///tmp/paimon-warehouse'" +
                ")");
        
        tableEnv.executeSql("USE CATALOG paimon_catalog");
        
        LOG.info("✅ Flink environment initialized successfully");
    }
    
    @AfterEach
    void tearDown() {
        LOG.info("🧹 Cleaning up test resources...");
        // 清理测试数据
        try {
            tableEnv.executeSql("DROP TABLE IF EXISTS test_table");
        } catch (Exception e) {
            LOG.warn("Failed to drop test table: {}", e.getMessage());
        }
    }

    @Test
    @Order(1)
    @DisplayName("🔥 Test Paimon Table Creation")
    void testPaimonTableCreation() {
        LOG.info("🧪 Testing Paimon table creation...");
        
        // 创建Paimon表
        TableResult result = tableEnv.executeSql("CREATE TABLE test_table (" +
                "id BIGINT," +
                "name STRING," +
                "age INT," +
                "score DOUBLE," +
                "create_time TIMESTAMP(3)," +
                "PRIMARY KEY (id) NOT ENFORCED" +
                ") WITH (" +
                "'bucket' = '2'," +
                "'changelog-producer' = 'input'" +
                ")");
        
        assertNotNull(result, "Table creation should return non-null result");
        LOG.info("✅ Paimon table created successfully");
    }

    @Test
    @Order(2)
    @DisplayName("🔥 Test Data Insertion and Streaming Query")
    void testDataInsertionAndQuery() throws Exception {
        LOG.info("🧪 Testing data insertion and streaming query...");
        
        // 创建测试表
        tableEnv.executeSql("CREATE TABLE test_table (" +
                "id BIGINT," +
                "name STRING," +
                "age INT," +
                "score DOUBLE," +
                "create_time TIMESTAMP(3)," +
                "PRIMARY KEY (id) NOT ENFORCED" +
                ") WITH (" +
                "'bucket' = '2'," +
                "'changelog-producer' = 'input'" +
                ")");
        
        // 插入测试数据
        tableEnv.executeSql("INSERT INTO test_table VALUES " +
                "(1, 'Alice', 25, 95.5, TIMESTAMP '2024-01-01 10:00:00')," +
                "(2, 'Bob', 30, 88.0, TIMESTAMP '2024-01-01 11:00:00')," +
                "(3, 'Charlie', 35, 92.5, TIMESTAMP '2024-01-01 12:00:00')");
        
        // 验证数据插入
        TableResult queryResult = tableEnv.executeSql("SELECT COUNT(*) as cnt FROM test_table");
        
        try (CloseableIterator<Row> iterator = queryResult.collect()) {
            assertTrue(iterator.hasNext(), "Query should return results");
            Row row = iterator.next();
            long count = row.getFieldAs(0);
            assertEquals(3L, count, "Should have 3 records");
            LOG.info("✅ Data insertion verified: {} records", count);
        }
    }

    @Test
    @Order(3)
    @DisplayName("🔥 Test Batch Query Mode")
    void testBatchQueryMode() throws Exception {
        LOG.info("🧪 Testing batch query mode...");
        
        // 创建新的批处理模式环境（不能动态切换）
        Configuration batchConfig = new Configuration();
        batchConfig.setString("execution.runtime-mode", "BATCH");
        StreamExecutionEnvironment batchEnv = StreamExecutionEnvironment.getExecutionEnvironment(batchConfig);
        StreamTableEnvironment batchTableEnv = StreamTableEnvironment.create(batchEnv);
        
        // 配置 Paimon Catalog
        batchTableEnv.executeSql("CREATE CATALOG paimon_catalog WITH (" +
                "'type' = 'paimon'," +
                "'warehouse' = 'file:///tmp/paimon-warehouse'" +
                ")");
        batchTableEnv.useCatalog("paimon_catalog");
        
        // 创建测试表
        batchTableEnv.executeSql("CREATE TABLE batch_test_table (" +
                "id BIGINT," +
                "name STRING," +
                "amount DECIMAL(10,2)," +
                "PRIMARY KEY (id) NOT ENFORCED" +
                ") WITH (" +
                "'bucket' = '1'" +
                ")");
        
        // 插入批量数据
        batchTableEnv.executeSql("INSERT INTO batch_test_table VALUES " +
                "(1, 'Product A', 100.50)," +
                "(2, 'Product B', 200.75)," +
                "(3, 'Product C', 150.25)," +
                "(4, 'Product D', 300.00)");
        
        // 执行聚合查询
        TableResult result = batchTableEnv.executeSql("SELECT " +
                "COUNT(*) as total_products," +
                "SUM(amount) as total_amount," +
                "AVG(amount) as avg_amount," +
                "MAX(amount) as max_amount " +
                "FROM batch_test_table");
        
        try (CloseableIterator<Row> iterator = result.collect()) {
            assertTrue(iterator.hasNext(), "Batch query should return results");
            Row row = iterator.next();
            
            assertEquals(Long.valueOf(4), row.getFieldAs(0), "Should have 4 products");
            assertEquals(751.50, ((Number) row.getFieldAs(1)).doubleValue(), 0.01, "Total amount should be 751.50");
            assertEquals(187.875, ((Number) row.getFieldAs(2)).doubleValue(), 0.001, "Average amount should be 187.875");
            assertEquals(300.00, ((Number) row.getFieldAs(3)).doubleValue(), 0.01, "Max amount should be 300.00");
            
            LOG.info("✅ Batch query validation passed");
        }
    }

    @Test
    @Order(4)
    @DisplayName("🔥 Test Schema Evolution")
    void testSchemaEvolution() throws Exception {
        LOG.info("🧪 Testing schema evolution...");
        
        // 创建初始表
        tableEnv.executeSql("CREATE TABLE evolution_table (" +
                "id BIGINT," +
                "name STRING," +
                "PRIMARY KEY (id) NOT ENFORCED" +
                ")");
        
        // 插入初始数据
        tableEnv.executeSql("INSERT INTO evolution_table VALUES (1, 'Initial')");
        
        // 添加新列（模拟schema evolution）
        tableEnv.executeSql("ALTER TABLE evolution_table ADD age INT");
        
        // 插入包含新列的数据
        tableEnv.executeSql("INSERT INTO evolution_table VALUES (2, 'Updated', 25)");
        
        // 验证schema evolution
        TableResult result = tableEnv.executeSql("SELECT * FROM evolution_table ORDER BY id");
        
        List<Row> rows = new ArrayList<>();
        try (CloseableIterator<Row> iterator = result.collect()) {
            while (iterator.hasNext()) {
                rows.add(iterator.next());
            }
        }
        
        assertEquals(2, rows.size(), "Should have 2 records");
        assertEquals("Initial", rows.get(0).getFieldAs("name"));
        assertEquals("Updated", rows.get(1).getFieldAs("name"));
        assertEquals(Integer.valueOf(25), rows.get(1).getFieldAs("age"));
        
        LOG.info("✅ Schema evolution test passed");
    }

    @Test
    @Order(5)
    @DisplayName("🔥 Test Performance Benchmark")
    void testPerformanceBenchmark() throws Exception {
        LOG.info("🧪 Running performance benchmark...");
        
        // 创建性能测试表
        tableEnv.executeSql("CREATE TABLE perf_table (" +
                "id BIGINT," +
                "data STRING," +
                "timestamp_col TIMESTAMP(3)," +
                "PRIMARY KEY (id) NOT ENFORCED" +
                ") WITH (" +
                "'bucket' = '4'," +
                "'compaction.min.file-num' = '5'," +
                "'compaction.max.file-num' = '10'" +
                ")");
        
        // 性能测试：批量插入
        long startTime = System.currentTimeMillis();
        
        StringBuilder insertSql = new StringBuilder("INSERT INTO perf_table VALUES ");
        for (int i = 1; i <= 1000; i++) {
            if (i > 1) insertSql.append(",");
            insertSql.append("(").append(i).append(", 'data_").append(i).append("', TIMESTAMP '2024-01-01 10:00:00')");
        }
        
        tableEnv.executeSql(insertSql.toString());
        
        long insertTime = System.currentTimeMillis() - startTime;
        LOG.info("📊 Batch insert time: {} ms for 1000 records", insertTime);
        
        // 性能测试：查询
        startTime = System.currentTimeMillis();
        TableResult queryResult = tableEnv.executeSql("SELECT COUNT(*) FROM perf_table WHERE id > 500");
        
        try (CloseableIterator<Row> iterator = queryResult.collect()) {
            assertTrue(iterator.hasNext(), "Performance query should return results");
            Row row = iterator.next();
            long count = row.getFieldAs(0);
            assertEquals(500L, count, "Should have 500 records with id > 500");
        }
        
        long queryTime = System.currentTimeMillis() - startTime;
        LOG.info("📊 Query time: {} ms for filtering 1000 records", queryTime);
        
        // 性能断言：确保操作在合理时间内完成
        assertTrue(insertTime < 30000, "Batch insert should complete within 30 seconds");
        assertTrue(queryTime < 10000, "Query should complete within 10 seconds");
        
        LOG.info("✅ Performance benchmark passed");
    }
} 