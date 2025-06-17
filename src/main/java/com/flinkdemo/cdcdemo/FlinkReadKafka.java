package com.flinkdemo.cdcdemo;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.flinkdemo.entity.users;
import com.flinkdemo.utils.ParseDataUtils;
import com.ververica.cdc.connectors.mysql.source.MySqlSource;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.functions.FilterFunction;
import org.apache.flink.api.common.functions.FlatMapFunction;
import org.apache.flink.api.common.serialization.SerializationSchema;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.api.common.JobExecutionResult;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.datastream.DataStreamSource;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;
import org.apache.flink.streaming.connectors.redis.RedisSink;
import org.apache.flink.streaming.connectors.redis.common.config.FlinkJedisPoolConfig;
import org.apache.flink.streaming.connectors.redis.common.mapper.RedisCommand;
import org.apache.flink.streaming.connectors.redis.common.mapper.RedisCommandDescription;
import org.apache.flink.streaming.connectors.redis.common.mapper.RedisMapper;
import org.apache.flink.util.Collector;
import org.apache.kafka.clients.producer.ProducerRecord;

import java.io.IOException;
import java.util.Properties;

/**
 * description:
 *
 * @author: jj.Sun
 * date: 2025/6/12.
 */
public class FlinkReadKafka {
    public static void main(String[] args) throws Exception {

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        env.setParallelism(1);

        // 启用检查点 (Flink 1.20.1 新API)
        env.enableCheckpointing(5000); // 每5秒触发一次检查点
        env.getCheckpointConfig().setCheckpointTimeout(60000); // 设置检查点超时时间为60秒
        env.getCheckpointConfig().setMaxConcurrentCheckpoints(1); // 设置最大并发检查点数量为1
        env.getCheckpointConfig().setMinPauseBetweenCheckpoints(500); // 设置两次检查点之间的最小间隔为500毫秒

        // 配置状态后端和检查点存储
        // env.getCheckpointConfig().setCheckpointStorage(new FileSystemCheckpointStorage("file:///opt/flink/checkpoints"));

        env.setParallelism(1);

        // 从kafka读取数据 (使用新的KafkaSource API)
        KafkaSource<String> kafkaSource = KafkaSource.<String>builder()
                .setBootstrapServers("kafka:9092")
                .setTopics("Login-User")
                .setGroupId("flink-group")
                .setStartingOffsets(OffsetsInitializer.earliest())
                .setValueOnlyDeserializer(new SimpleStringSchema())
                .build();

        // 添加 Source 到数据流
        DataStreamSource<String> dataStream = env.fromSource(
                kafkaSource,
                WatermarkStrategy.noWatermarks(),
                "Kafka Source"
        );

        // 6.redis 配置
        FlinkJedisPoolConfig config = new FlinkJedisPoolConfig.Builder()
                .setHost("redis").setPort(6379).build();
        // 7. 定义 RedisSink,  将数据写入 Redis
        dataStream.addSink(new RedisSink<>(config, new redisSink()));

        // 8. 执行任务
        env.execute();
    }

    public static class redisSink implements RedisMapper<String> {
        private static final ObjectMapper objectMapper = new ObjectMapper();

        @Override
        public RedisCommandDescription getCommandDescription() {
            return new RedisCommandDescription(RedisCommand.HSET, "ods_users");
        }

        @Override
        public String getKeyFromData(String data) {
            try {
                JsonNode jsonNode = objectMapper.readTree(data);
                return "user_" + jsonNode.get("id").asText();
            } catch (Exception e) {
                throw new RuntimeException("Failed to parse JSON data", e);
            }
        }

        @Override
        public String getValueFromData(String data) {
            return data;
        }
    }
}
