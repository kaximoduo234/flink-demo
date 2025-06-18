package com.flinkdemo.cdcdemo;

import com.flinkdemo.utils.ParseDataUtils;
import com.ververica.cdc.connectors.mysql.source.MySqlSource;
import org.apache.flink.api.common.RuntimeExecutionMode;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.configuration.StateBackendOptions;
import org.apache.flink.configuration.CheckpointingOptions;
import org.apache.flink.streaming.api.datastream.DataStreamSource;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.connector.kafka.sink.KafkaSink;
import org.apache.flink.connector.kafka.sink.KafkaRecordSerializationSchema;

import java.util.Properties;

/**
 * Flink CDC MySQL to Kafka 示例
 * 使用 Flink 1.20.1 推荐的配置方式
 * 
 * @author: jj.Sun
 * @date: 2025/6/12.
 */
public class FlinkCDCMysql {

    public static void main(String[] args) throws Exception {

        // ✅ 使用 Configuration 配置状态后端和检查点（Flink 1.20.1 推荐方式）
        Configuration config = new Configuration();
        
        // 设置 RocksDB 为状态后端
        config.set(StateBackendOptions.STATE_BACKEND, "rocksdb");
        
        // 设置检查点存储路径
        config.set(CheckpointingOptions.CHECKPOINTS_DIRECTORY, "file:///opt/flink/checkpoints");
        
        // 可选：设置 savepoint 路径
        config.set(CheckpointingOptions.SAVEPOINT_DIRECTORY, "file:///opt/flink/savepoints");

        // 创建带配置的执行环境
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment(config);
        
        // 设置执行模式为流处理
        env.setRuntimeMode(RuntimeExecutionMode.STREAMING);
        
        // 设置并行度
        env.setParallelism(1);

        // ✅ 启用检查点（Flink 1.20.1 新API）
        env.enableCheckpointing(5000); // 每5秒触发一次检查点
        env.getCheckpointConfig().setCheckpointTimeout(60000); // 设置检查点超时时间为60秒
        env.getCheckpointConfig().setMaxConcurrentCheckpoints(1); // 设置最大并发检查点数量为1
        env.getCheckpointConfig().setMinPauseBetweenCheckpoints(500); // 设置两次检查点之间的最小间隔为500毫秒

        // 配置 MySQL CDC Source
        Properties properties = new Properties();
        properties.setProperty("scan.startup.mode", "latest-offset"); // 修复：去掉多余空格
        properties.setProperty("database.serverTimezone", "Asia/Shanghai");

        MySqlSource<String> sourceFunction = MySqlSource.<String>builder()
                .hostname("mysql")
                .port(3306)
                .databaseList("ods")
                .tableList("ods.users")
                .username("root")
                .password("root123")
                .debeziumProperties(properties)
                .deserializer(new ParseDataUtils())
                .build();
        

        // 从 MySQL 读取数据流
        DataStreamSource<String> dataStream = env.fromSource(
                sourceFunction, 
                WatermarkStrategy.noWatermarks(), 
                "MySQL CDC Source"
        );

        // ✅ 配置 Kafka Sink（使用新的 KafkaSink API）
        KafkaSink<String> kafkaSink = KafkaSink.<String>builder()
                .setBootstrapServers("kafka:9092")
                .setRecordSerializer(KafkaRecordSerializationSchema.builder()
                        .setTopic("Login-User")
                        .setValueSerializationSchema(new SimpleStringSchema())
                        .build())
                .build();

        // 输出到 Kafka 和控制台
        dataStream.sinkTo(kafkaSink);
        dataStream.print("MySQL CDC Output");

        // 执行作业
        env.execute("Flink CDC MySQL to Kafka Job");
    }
}
