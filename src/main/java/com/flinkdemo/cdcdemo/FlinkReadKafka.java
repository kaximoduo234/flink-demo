package com.flinkdemo.cdcdemo;

import com.alibaba.fastjson.JSONObject;
import com.flinkdemo.entity.users;
import com.flinkdemo.utils.ParseDataUtils;
import com.ververica.cdc.connectors.mysql.source.MySqlSource;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.functions.FilterFunction;
import org.apache.flink.api.common.functions.FlatMapFunction;
import org.apache.flink.api.common.serialization.SerializationSchema;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.contrib.streaming.state.RocksDBStateBackend;
import org.apache.flink.runtime.state.StateBackend;
import org.apache.flink.runtime.state.filesystem.FsStateBackend;
import org.apache.flink.streaming.api.CheckpointingMode;
import org.apache.flink.streaming.api.datastream.DataStreamSink;
import org.apache.flink.streaming.api.datastream.DataStreamSource;
import org.apache.flink.streaming.api.datastream.SingleOutputStreamOperator;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer;
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaProducer;
import org.apache.flink.streaming.connectors.kafka.KafkaSerializationSchema;
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

        // 启用检查点
        env.enableCheckpointing(5000); // 每5秒触发一次检查点
        env.getCheckpointConfig().setCheckpointingMode(CheckpointingMode.EXACTLY_ONCE); // 设置检查点模式为精确一次
        env.getCheckpointConfig().setCheckpointTimeout(60000); // 设置检查点超时时间为60秒
        env.getCheckpointConfig().setMaxConcurrentCheckpoints(1); // 设置最大并发检查点数量为1
        env.getCheckpointConfig().setMinPauseBetweenCheckpoints(500); // 设置两次检查点之间的最小间隔为500毫秒


        // 配置RocksDBStateBackend   file:///path/to/checkpoints
        RocksDBStateBackend rocksDbBackend = new RocksDBStateBackend("file:///D:/checkpoint");
        env.setStateBackend(rocksDbBackend);
        // 配置状态后端和检查点存储

        env.setParallelism(1);

        //stringDataStreamSource.print();
        // 从kafka读取数据
        // 2. 配置 Kafka 消费者参数
        Properties properties = new Properties();
        properties.setProperty("bootstrap.servers", "localhost:9092"); // Kafka 集群地址
        properties.setProperty("group.id", "flink-group");       // 消费者组 ID
        properties.setProperty("auto.offset.reset", "latest");            // 从最新位点开始消费
        properties.setProperty("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        properties.setProperty("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");



        FlinkKafkaConsumer<String> loginUser = new FlinkKafkaConsumer<>(
                "Login-User",
                new SimpleStringSchema(),
                properties
        );

        loginUser.setStartFromEarliest();

        // 5. 添加 Source 到数据流
        DataStreamSource<String> dataStream = env.addSource(loginUser);

        // 6.redis 配置
        FlinkJedisPoolConfig config = new FlinkJedisPoolConfig.Builder()
                .setHost("localhost").setPort(6379).build();
        // 7. 定义 RedisSink,  将数据写入 Redis
        dataStream.addSink(new RedisSink<>(config, new redisSink()));

        // 8. 执行任务
        env.execute();
    }

    public static class redisSink implements RedisMapper<String> {
        @Override
        public RedisCommandDescription getCommandDescription() {
            return new RedisCommandDescription(RedisCommand.HSET, "ods_users");
        }

        @Override
        public String getKeyFromData(String data) {
            JSONObject jsonObject = JSONObject.parseObject(data);
            return "user_" + jsonObject.getString("id");
        }

        @Override
        public String getValueFromData(String data) {
            return data;
        }
    }
}
