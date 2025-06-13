package com.flinkdemo.utils;

import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
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


        JsonObject jsonObject = new JsonObject();
        jsonObject.addProperty("op", op);
        jsonObject.addProperty("ts_ms", ts_ms);
        jsonObject.addProperty("id", id);
        jsonObject.addProperty("username", username);
        jsonObject.addProperty("email", email);
        jsonObject.addProperty("birthdate", birthdate);
        jsonObject.addProperty("is_active", is_active);
        jsonObject.addProperty("version", version);
        jsonObject.addProperty("connector", connector);
        jsonObject.addProperty("name", name);
        jsonObject.addProperty("server_id", server_id);
        jsonObject.addProperty("file", file);
        jsonObject.addProperty("pos", pos);
        jsonObject.addProperty("row", row);
        jsonObject.addProperty("db", db);
        jsonObject.addProperty("table", table);

        String string = jsonObject.toString();


        collector.collect(string);
    }

    @Override
    public TypeInformation getProducedType() {
        return TypeInformation.of(java.lang.String.class);
    }
}
