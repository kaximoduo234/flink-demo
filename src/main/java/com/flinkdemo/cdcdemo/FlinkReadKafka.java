package com.flinkdemo.cdcdemo;

import com.flinkdemo.utils.ParseDataUtils;
import com.ververica.cdc.connectors.mysql.source.MySqlSource;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.functions.FilterFunction;
import org.apache.flink.api.common.serialization.SerializationSchema;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.contrib.streaming.state.RocksDBStateBackend;
import org.apache.flink.runtime.state.StateBackend;
import org.apache.flink.runtime.state.filesystem.FsStateBackend;
import org.apache.flink.streaming.api.CheckpointingMode;
import org.apache.flink.streaming.api.datastream.DataStreamSource;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer;
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaProducer;
import org.apache.flink.streaming.connectors.kafka.KafkaSerializationSchema;
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
        properties.setProperty("group.id", "flink-consumer-group");       // 消费者组 ID
        properties.setProperty("auto.offset.reset", "latest");            // 从最新位点开始消费
        properties.setProperty("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        properties.setProperty("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");



        FlinkKafkaConsumer<String> loginUser = new FlinkKafkaConsumer<>(
                "login_user",
                new SimpleStringSchema(),
                properties
        );

        loginUser.setStartFromEarliest();

        // 5. 添加 Source 到数据流
        DataStreamSource<String> dataStream = env.addSource(loginUser);

        // 6. 数据处理（示例：打印）
        dataStream.print();

        // 解析数据
        //stringDataStreamSource.filter(new FilterFunction<String>() {
        //    @Override
        //    public boolean filter(String s) throws Exception {
        //        return ;
        //    }
        //});

        env.execute();
    }
}
