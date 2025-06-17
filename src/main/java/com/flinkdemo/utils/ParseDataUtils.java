package com.flinkdemo.utils;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.ververica.cdc.debezium.DebeziumDeserializationSchema;
import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.util.Collector;
import org.apache.kafka.connect.data.Field;
import org.apache.kafka.connect.data.Struct;
import org.apache.kafka.connect.source.SourceRecord;

import java.util.HashMap;
import java.util.List;

public class ParseDataUtils implements DebeziumDeserializationSchema {

    @Override
    public void deserialize(SourceRecord sourceRecord, Collector collector) throws Exception {
        Struct value = (Struct) sourceRecord.value();
        String op = value.getString("op");
        Long ts_ms = value.getInt64("ts_ms");
        Struct data = null;
        String id = null;
        String username = null;
        String email = null;
        String birthdate = null;
        String is_active = null;
        if(op.equals("d")){
             data = value.getStruct("before");
        }else{
             data = value.getStruct("after");
        }
        if(data!= null){
            id = data.getInt32("id").toString();
            username = data.getString("username");
            email = data.getString("email");
            birthdate = data.get("birthdate").toString();
            is_active = data.getInt16("is_active").toString();
        }

        Struct source = value.getStruct("source");
        String version = source.getString("version");
        String connector = source.getString("connector");
        String name = source.getString("name");
        String server_id = source.get("server_id").toString();
        String file = source.getString("file");
        String pos = source.get("pos").toString();
        String row = source.get("row").toString();
        String db = source.getString("db");
        String table = source.getString("table");


        ObjectMapper mapper = new ObjectMapper();
        ObjectNode jsonObject = mapper.createObjectNode();
        jsonObject.put("op", op);
        jsonObject.put("ts_ms", ts_ms);
        jsonObject.put("id", id);
        jsonObject.put("username", username);
        jsonObject.put("email", email);
        jsonObject.put("birthdate", birthdate);
        jsonObject.put("is_active", is_active);
        jsonObject.put("version", version);
        jsonObject.put("connector", connector);
        jsonObject.put("name", name);
        jsonObject.put("server_id", server_id);
        jsonObject.put("file", file);
        jsonObject.put("pos", pos);
        jsonObject.put("row", row);
        jsonObject.put("db", db);
        jsonObject.put("table", table);

        String string = jsonObject.toString();


        collector.collect(string);
    }

    @Override
    public TypeInformation getProducedType() {
        return TypeInformation.of(java.lang.String.class);
    }
}
