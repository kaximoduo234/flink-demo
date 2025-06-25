package com.flinkdemo.cdcdemo;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.flinkdemo.entity.User;   
import com.flinkdemo.utils.ParseDataUtils;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.streaming.api.datastream.DataStreamSource;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;
import org.apache.flink.streaming.connectors.redis.RedisSink;
import org.apache.flink.streaming.connectors.redis.common.config.FlinkJedisPoolConfig;
import org.apache.flink.streaming.connectors.redis.common.mapper.RedisCommand;
import org.apache.flink.streaming.connectors.redis.common.mapper.RedisCommandDescription;
import org.apache.flink.streaming.connectors.redis.common.mapper.RedisMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Map;

/**
 * Enhanced Kafka consumer for Flink with comprehensive logging and error handling.
 * 
 * <p>Architecture Design:
 * - Implements proper logging for monitoring and debugging
 * - Uses modern Flink Kafka Source API
 * - Includes comprehensive error handling and validation
 * - Provides clear separation of concerns
 * - Uses updated entity classes with proper naming conventions
 * 
 * <p>Data Flow:
 * Kafka → Flink → Redis (HSET operations for user data storage)
 * 
 * @author Flink Demo Team
 * @version 1.1.0
 * @since 1.0.0
 */
public class FlinkReadKafka {

    private static final Logger LOG = LoggerFactory.getLogger(FlinkReadKafka.class);

    // ==================== Configuration Constants ====================
    
    private static final String KAFKA_BOOTSTRAP_SERVERS = "kafka:9092";
    private static final String KAFKA_TOPIC = "Login-User";
    private static final String KAFKA_GROUP_ID = "flink-group";
    private static final String REDIS_HOST = "redis";
    private static final int REDIS_PORT = 6379;
    private static final String REDIS_HASH_KEY = "ods_users";
    
    // Checkpoint configuration
    private static final long CHECKPOINT_INTERVAL = 5000L; // 5 seconds
    private static final long CHECKPOINT_TIMEOUT = 60000L; // 60 seconds
    private static final int MAX_CONCURRENT_CHECKPOINTS = 1;
    private static final long MIN_PAUSE_BETWEEN_CHECKPOINTS = 500L; // 500ms

    // ==================== Main Method ====================

    public static void main(String[] args) throws Exception {
        LOG.info("🚀 Starting Flink Kafka Consumer Job...");
        
        try {
            // Initialize execution environment
            StreamExecutionEnvironment env = createExecutionEnvironment();
            
            // Create Kafka source
            KafkaSource<String> kafkaSource = createKafkaSource();
            
            // Create data stream
            DataStreamSource<String> dataStream = env.fromSource(
                    kafkaSource,
                    WatermarkStrategy.noWatermarks(),
                    "Kafka Source"
            );
            
            LOG.info("📊 Created Kafka data stream from topic: {}", KAFKA_TOPIC);
            
            // Configure Redis sink
            FlinkJedisPoolConfig redisConfig = createRedisConfig();
            RedisSink<String> redisSink = new RedisSink<>(redisConfig, new UserRedisMapper());
            
            // Add sink to data stream
            dataStream.addSink(redisSink);
            
            LOG.info("💾 Configured Redis sink to: {}:{}", REDIS_HOST, REDIS_PORT);
            
            // Execute the job
            LOG.info("▶️ Executing Flink job...");
            env.execute("Kafka-to-Redis Consumer Job");
            
            LOG.info("✅ Flink job completed successfully");
            
        } catch (Exception e) {
            LOG.error("❌ Failed to execute Flink job", e);
            throw e;
        }
    }

    // ==================== Private Helper Methods ====================

    /**
     * Creates and configures the Flink execution environment
     */
    private static StreamExecutionEnvironment createExecutionEnvironment() {
        LOG.info("🔧 Configuring Flink execution environment...");
        
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        
        // Set parallelism
        env.setParallelism(1);
        LOG.debug("Set parallelism to: 1");
        
        // Configure checkpointing
        env.enableCheckpointing(CHECKPOINT_INTERVAL);
        env.getCheckpointConfig().setCheckpointTimeout(CHECKPOINT_TIMEOUT);
        env.getCheckpointConfig().setMaxConcurrentCheckpoints(MAX_CONCURRENT_CHECKPOINTS);
        env.getCheckpointConfig().setMinPauseBetweenCheckpoints(MIN_PAUSE_BETWEEN_CHECKPOINTS);
        
        LOG.info("✓ Configured checkpointing: interval={}ms, timeout={}ms", 
                CHECKPOINT_INTERVAL, CHECKPOINT_TIMEOUT);
        
        // Note: Checkpoint storage configuration can be added here if needed
        // env.getCheckpointConfig().setCheckpointStorage(new FileSystemCheckpointStorage("file:///opt/flink/checkpoints"));
        
        return env;
    }

    /**
     * Creates and configures the Kafka source
     */
    private static KafkaSource<String> createKafkaSource() {
        LOG.info("📡 Configuring Kafka source...");
        
        KafkaSource<String> kafkaSource = KafkaSource.<String>builder()
                .setBootstrapServers(KAFKA_BOOTSTRAP_SERVERS)
                .setTopics(KAFKA_TOPIC)
                .setGroupId(KAFKA_GROUP_ID)
                .setStartingOffsets(OffsetsInitializer.earliest())
                .setValueOnlyDeserializer(new SimpleStringSchema())
                .build();
        
        LOG.info("✓ Kafka source configured: servers={}, topic={}, group={}", 
                KAFKA_BOOTSTRAP_SERVERS, KAFKA_TOPIC, KAFKA_GROUP_ID);
        
        return kafkaSource;
    }

    /**
     * Creates and configures the Redis connection
     */
    private static FlinkJedisPoolConfig createRedisConfig() {
        LOG.info("🔗 Configuring Redis connection...");
        
        FlinkJedisPoolConfig config = new FlinkJedisPoolConfig.Builder()
                .setHost(REDIS_HOST)
                .setPort(REDIS_PORT)
                .build();
        
        LOG.info("✓ Redis config created: {}:{}", REDIS_HOST, REDIS_PORT);
        
        return config;
    }

    // ==================== Redis Mapper Implementation ====================

    /**
     * Enhanced Redis mapper with comprehensive error handling and logging
     */
    public static class UserRedisMapper implements RedisMapper<String> {
        
        private static final Logger MAPPER_LOG = LoggerFactory.getLogger(UserRedisMapper.class);
        private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

        @Override
        public RedisCommandDescription getCommandDescription() {
            return new RedisCommandDescription(RedisCommand.HSET, REDIS_HASH_KEY);
        }

        @Override
        public String getKeyFromData(String data) {
            try {
                JsonNode jsonNode = OBJECT_MAPPER.readTree(data);
                JsonNode idNode = jsonNode.get("id");
                
                if (idNode == null || idNode.isNull()) {
                    MAPPER_LOG.warn("⚠️ Missing 'id' field in data: {}", data);
                    return "user_unknown_" + System.currentTimeMillis();
                }
                
                String userId = idNode.asText();
                String key = "user_" + userId;
                
                MAPPER_LOG.debug("🔑 Generated Redis key: {} for user ID: {}", key, userId);
                return key;
                
            } catch (Exception e) {
                MAPPER_LOG.error("❌ Failed to extract key from data: {}", data, e);
                // Return a fallback key to prevent job failure
                return "user_error_" + System.currentTimeMillis();
            }
        }

        @Override
        public String getValueFromData(String data) {
            try {
                // Validate JSON format
                JsonNode jsonNode = OBJECT_MAPPER.readTree(data);
                
                // Log operation type if available
                JsonNode opNode = jsonNode.get("op");
                if (opNode != null) {
                    String operation = opNode.asText();
                    MAPPER_LOG.debug("📝 Processing CDC operation: {} for data: {}", operation, data);
                }
                
                return data;
                
            } catch (Exception e) {
                MAPPER_LOG.error("❌ Invalid JSON data received: {}", data, e);
                
                // Create error record
                try {
                    return OBJECT_MAPPER.writeValueAsString(Map.of(
                        "error", true,
                        "original_data", data,
                        "error_message", e.getMessage(),
                        "timestamp", System.currentTimeMillis()
                    ));
                } catch (Exception ex) {
                    MAPPER_LOG.error("❌ Failed to create error record", ex);
                    return "{\"error\":true,\"message\":\"Failed to process data\"}";
                }
            }
        }
    }
}
