package com.flinkdemo.utils;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.flinkdemo.entity.User;
import com.ververica.cdc.debezium.DebeziumDeserializationSchema;
import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.util.Collector;
import org.apache.kafka.connect.data.Struct;
import org.apache.kafka.connect.source.SourceRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Enhanced CDC data parser with type safety and comprehensive error handling.
 * 
 * <p>Architecture Design:
 * - Implements proper generic types for DebeziumDeserializationSchema&lt;String&gt;
 * - Provides comprehensive error handling and logging
 * - Separates data extraction logic for better maintainability
 * - Uses modern Jackson ObjectMapper for JSON processing
 * - Includes null safety checks and validation
 * 
 * @author Flink Demo Team
 * @version 1.1.0
 * @since 1.0.0
 */
public class ParseDataUtils implements DebeziumDeserializationSchema<String> {

    private static final Logger LOG = LoggerFactory.getLogger(ParseDataUtils.class);
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    // ==================== Constants ====================
    
    private static final String OP_DELETE = "d";
    private static final String FIELD_OP = "op";
    private static final String FIELD_TS_MS = "ts_ms";
    private static final String FIELD_BEFORE = "before";
    private static final String FIELD_AFTER = "after";
    private static final String FIELD_SOURCE = "source";

    // ==================== Public API ====================

    @Override
    public void deserialize(SourceRecord sourceRecord, Collector<String> collector) throws Exception {
        try {
            LOG.debug("Processing CDC record from topic: {}", sourceRecord.topic());
            
            // Validate input
            if (sourceRecord == null || sourceRecord.value() == null) {
                LOG.warn("Received null source record or value, skipping...");
                return;
            }

            Struct value = (Struct) sourceRecord.value();
            
            // Extract CDC metadata
            CdcMetadata metadata = extractCdcMetadata(value);
            
            // Extract business data
            UserData userData = extractUserData(value, metadata.operation);
            
            // Create JSON output
            String jsonOutput = createJsonOutput(metadata, userData);
            
            LOG.debug("Successfully parsed CDC record: op={}, id={}", 
                     metadata.operation, userData.id);
            
            collector.collect(jsonOutput);
            
        } catch (Exception e) {
            LOG.error("Failed to parse CDC record from topic: {}", 
                     sourceRecord != null ? sourceRecord.topic() : "unknown", e);
            
            // In production, you might want to send to a dead letter queue
            // For now, we'll create an error record
            String errorRecord = createErrorRecord(e);
            collector.collect(errorRecord);
        }
    }

    @Override
    public TypeInformation<String> getProducedType() {
        return TypeInformation.of(String.class);
    }

    // ==================== Private Helper Methods ====================

    /**
     * Extracts CDC metadata from the source record
     */
    private CdcMetadata extractCdcMetadata(Struct value) {
        CdcMetadata metadata = new CdcMetadata();
        
        metadata.operation = getStringValue(value, FIELD_OP);
        metadata.timestampMs = getLongValue(value, FIELD_TS_MS);
        
        Struct source = value.getStruct(FIELD_SOURCE);
        if (source != null) {
            metadata.version = getStringValue(source, "version");
            metadata.connector = getStringValue(source, "connector");
            metadata.name = getStringValue(source, "name");
            metadata.serverId = getStringValue(source, "server_id");
            metadata.file = getStringValue(source, "file");
            metadata.pos = getStringValue(source, "pos");
            metadata.row = getStringValue(source, "row");
            metadata.db = getStringValue(source, "db");
            metadata.table = getStringValue(source, "table");
        }
        
        return metadata;
    }

    /**
     * Extracts user business data from the appropriate section (before/after)
     */
    private UserData extractUserData(Struct value, String operation) {
        UserData userData = new UserData();
        
        // Determine which data section to use
        String dataSection = OP_DELETE.equals(operation) ? FIELD_BEFORE : FIELD_AFTER;
        Struct data = value.getStruct(dataSection);
        
        if (data != null) {
            userData.id = getStringValue(data, "id");
            userData.username = getStringValue(data, "username");
            userData.email = getStringValue(data, "email");
            userData.birthdate = getStringValue(data, "birthdate");
            userData.isActive = getStringValue(data, "is_active");
        }
        
        return userData;
    }

    /**
     * Creates JSON output string from metadata and user data
     */
    private String createJsonOutput(CdcMetadata metadata, UserData userData) throws Exception {
        ObjectNode jsonObject = OBJECT_MAPPER.createObjectNode();
        
        // CDC metadata
        jsonObject.put(FIELD_OP, metadata.operation);
        jsonObject.put(FIELD_TS_MS, metadata.timestampMs);
        jsonObject.put("version", metadata.version);
        jsonObject.put("connector", metadata.connector);
        jsonObject.put("name", metadata.name);
        jsonObject.put("server_id", metadata.serverId);
        jsonObject.put("file", metadata.file);
        jsonObject.put("pos", metadata.pos);
        jsonObject.put("row", metadata.row);
        jsonObject.put("db", metadata.db);
        jsonObject.put("table", metadata.table);
        
        // Business data
        jsonObject.put("id", userData.id);
        jsonObject.put("username", userData.username);
        jsonObject.put("email", userData.email);
        jsonObject.put("birthdate", userData.birthdate);
        jsonObject.put("is_active", userData.isActive);
        
        return jsonObject.toString();
    }

    /**
     * Creates an error record for failed parsing attempts
     */
    private String createErrorRecord(Exception e) throws Exception {
        ObjectNode errorObject = OBJECT_MAPPER.createObjectNode();
        errorObject.put("error", true);
        errorObject.put("error_message", e.getMessage());
        errorObject.put("error_type", e.getClass().getSimpleName());
        errorObject.put("timestamp", System.currentTimeMillis());
        
        return errorObject.toString();
    }

    /**
     * Safely extracts string value from Struct
     */
    private String getStringValue(Struct struct, String fieldName) {
        try {
            Object value = struct.get(fieldName);
            return value != null ? value.toString() : null;
        } catch (Exception e) {
            LOG.debug("Failed to extract field '{}': {}", fieldName, e.getMessage());
            return null;
        }
    }

    /**
     * Safely extracts long value from Struct
     */
    private Long getLongValue(Struct struct, String fieldName) {
        try {
            return struct.getInt64(fieldName);
        } catch (Exception e) {
            LOG.debug("Failed to extract long field '{}': {}", fieldName, e.getMessage());
            return null;
        }
    }

    // ==================== Internal Data Classes ====================

    /**
     * Internal class to hold CDC metadata
     */
    private static class CdcMetadata {
        String operation;
        Long timestampMs;
        String version;
        String connector;
        String name;
        String serverId;
        String file;
        String pos;
        String row;
        String db;
        String table;
    }

    /**
     * Internal class to hold user business data
     */
    private static class UserData {
        String id;
        String username;
        String email;
        String birthdate;
        String isActive;
    }
}
