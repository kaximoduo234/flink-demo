package com.flinkdemo.cdcdemo;


import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.esotericsoftware.kryo.util.ObjectMap;
import com.flinkdemo.entity.users;
import com.flinkdemo.utils.ParseDataUtils;
import com.ververica.cdc.connectors.mysql.source.MySqlSource;
import org.apache.flink.api.common.eventtime.*;
import org.apache.flink.api.common.functions.FlatMapFunction;
import org.apache.flink.api.common.serialization.SerializationSchema;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.api.java.functions.KeySelector;
import org.apache.flink.contrib.streaming.state.RocksDBStateBackend;
import org.apache.flink.runtime.state.StateBackend;
import org.apache.flink.runtime.state.filesystem.FsStateBackend;
import org.apache.flink.streaming.api.CheckpointingMode;
import org.apache.flink.streaming.api.TimeCharacteristic;
import org.apache.flink.streaming.api.datastream.*;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.ProcessFunction;
import org.apache.flink.streaming.api.functions.windowing.ProcessWindowFunction;
import org.apache.flink.streaming.api.windowing.assigners.SlidingEventTimeWindows;
import org.apache.flink.streaming.api.windowing.assigners.TumblingEventTimeWindows;
import org.apache.flink.streaming.api.windowing.time.Time;
import org.apache.flink.streaming.api.windowing.windows.TimeWindow;
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaProducer;
import org.apache.flink.streaming.connectors.kafka.KafkaSerializationSchema;
import org.apache.flink.streaming.util.serialization.KeyedSerializationSchema;
import org.apache.flink.util.Collector;
import org.apache.flink.util.OutputTag;
import org.apache.kafka.clients.producer.ProducerRecord;

import javax.annotation.Nullable;
import java.time.Duration;
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

        MySqlSource<String> sourceFunction = MySqlSource.<String>builder()
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

        //设置时间语义
        env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime);


        DataStreamSource<String> stringDataStreamSource = env.fromSource(sourceFunction, WatermarkStrategy.forMonotonousTimestamps(), "mysql-cdc-source");

        WatermarkStrategy<String> watermarkStrategy = WatermarkStrategy.<String>forBoundedOutOfOrderness(Duration.ofSeconds(5))
                .withTimestampAssigner((event, ts)->{
                    JSONObject jsonObject = JSON.parseObject(event);
                    return jsonObject.getLong("ts_ms");
                });
        SingleOutputStreamOperator<String> sso = stringDataStreamSource.assignTimestampsAndWatermarks(watermarkStrategy);
        SingleOutputStreamOperator<String> usersSingleOutputStreamOperator = sso.flatMap(new FlatMapFunction<String, String>() {
            @Override
            public void flatMap(String value, Collector<String> out) throws Exception {
                Object parse = JSONObject.parse(value);
                out.collect(parse.toString());
            }
        });
        // 1. 定义侧输出流标签
        OutputTag<String> sideOutputTag = new OutputTag<String>("side-output") {};


        SingleOutputStreamOperator<String> mainStream  = usersSingleOutputStreamOperator.keyBy(new KeySelector<String, String>() {
                    @Override
                    public String getKey(String value) throws Exception {
                        users users = JSONObject.parseObject(value, users.class);
                        return users.getId();
                    }
                }).window(SlidingEventTimeWindows.of(Time.seconds(30),Time.seconds(10)))
                .allowedLateness(Time.seconds(5))
                .sideOutputLateData(sideOutputTag)
                .process(new ProcessWindowFunction<String, String, String, TimeWindow>() {

                    @Override
                    public void process(String s, ProcessWindowFunction<String, String, String, TimeWindow>.Context ctx, Iterable<String> iterable, Collector<String> collector) throws Exception {
                            for (String user : iterable) {
                                System.out.println("窗口[" + ctx.window() + "]");
                                collector.collect("窗口[" + ctx.window() + "] 结果: " + user);
                            }
                    }
                });

        //获取迟到数据
        DataStream<String> sideOutput = usersSingleOutputStreamOperator.getSideOutput(sideOutputTag);


        //stringDataStreamSource.print();
        // 输出到kafka
        Properties kafkaProperties = new Properties();
        kafkaProperties.setProperty("bootstrap.servers", "localhost:9092");
        kafkaProperties.setProperty("group.id", "flink-cdc-mysql");
        kafkaProperties.setProperty("key.serializer", "org.apache.kafka.common.serialization.ByteArraySerializer");
        kafkaProperties.setProperty("value.serializer", "org.apache.kafka.common.serialization.ByteArraySerializer");


        FlinkKafkaProducer<String> loginUser = new FlinkKafkaProducer<String>(
                "Login-User",
                new SimpleStringSchema(),
                kafkaProperties
                //FlinkKafkaProducer.Semantic.AT_LEAST_ONCE,
                //3
        );

        FlinkKafkaProducer<String> laterUser = new FlinkKafkaProducer<String>(
                "Later-User",
                new SimpleStringSchema(),
                kafkaProperties
                //FlinkKafkaProducer.Semantic.AT_LEAST_ONCE,
                //3
        );

        mainStream.addSink(loginUser);
        sideOutput.addSink(laterUser);

        mainStream.print("正常数据");
        sideOutput.print("迟到数据");
        env.execute();
    }
}
