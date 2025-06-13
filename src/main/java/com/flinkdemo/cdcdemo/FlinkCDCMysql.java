package com.flinkdemo.cdcdemo;


import com.flinkdemo.utils.ParseDataUtils;
import com.ververica.cdc.connectors.mysql.source.MySqlSource;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.serialization.SerializationSchema;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.contrib.streaming.state.RocksDBStateBackend;
import org.apache.flink.runtime.state.StateBackend;
import org.apache.flink.runtime.state.filesystem.FsStateBackend;
import org.apache.flink.streaming.api.CheckpointingMode;
import org.apache.flink.streaming.api.datastream.DataStreamSource;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaProducer;
import org.apache.flink.streaming.connectors.kafka.KafkaSerializationSchema;
import org.apache.kafka.clients.producer.ProducerRecord;

import javax.annotation.Nullable;
import java.util.Properties;

public class FlinkCDCMysql {

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



        Properties properties = new Properties();
        properties.setProperty(" scan.startup.mode","latest-offset");

        env.setParallelism(1);

        MySqlSource sourceFunction = MySqlSource.builder()
                .hostname("localhost")
                .port(3306)
                .databaseList("ods")
                .tableList("ods.users")
                .username("root")
                .password("root123")
                .debeziumProperties(properties)
                //.startupOptions(StartupOptions.initial())
                .deserializer(new ParseDataUtils())
                .build();

//        env.enableCheckpointing(3000);

        DataStreamSource stringDataStreamSource =  env.fromSource(sourceFunction, WatermarkStrategy.noWatermarks(), "MySQL Source");

        //stringDataStreamSource.print();
        // 输出到kafka
        Properties kafkaProperties = new Properties();
        kafkaProperties.setProperty("bootstrap.servers", "localhost:9092");
        kafkaProperties.setProperty("group.id", "flink-cdc-mysql");
        kafkaProperties.setProperty("key.serializer", "org.apache.kafka.common.serialization.ByteArraySerializer");
        kafkaProperties.setProperty("value.serializer", "org.apache.kafka.common.serialization.ByteArraySerializer");


        FlinkKafkaProducer<String> loginUser = new FlinkKafkaProducer<>(
                "Login-User",
                new SimpleStringSchema(),
                kafkaProperties
                //FlinkKafkaProducer.Semantic.AT_LEAST_ONCE,
                //3
        );

        stringDataStreamSource.addSink(loginUser);
        stringDataStreamSource.print();

        env.execute();
    }
}
