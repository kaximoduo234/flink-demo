package com.flinkdemo.entity;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.Objects;

/**
 * User entity representing CDC change data from MySQL users table.
 * 
 * <p>This class encapsulates both business data (user information) and 
 * CDC metadata (operation type, timestamps, source information).
 * 
 * <p>Architecture Design:
 * - Implements Serializable for Flink serialization
 * - Uses proper Java naming conventions
 * - Separates business data from CDC metadata
 * - Includes comprehensive documentation
 * 
 * @author Flink Demo Team
 * @version 1.1.0
 * @since 1.0.0
 */
public class User implements Serializable {

    private static final long serialVersionUID = 1L;

    // ==================== CDC Metadata ====================
    
    /**
     * CDC operation type: 'c' (create), 'u' (update), 'd' (delete), 'r' (read)
     */
    @JsonProperty("op")
    private String operation;
    
    /**
     * Timestamp when the change occurred (in milliseconds)
     */
    @JsonProperty("ts_ms")
    private String timestampMs;
    
    /**
     * CDC connector version
     */
    private String version;
    
    /**
     * Connector name (e.g., "mysql")
     */
    private String connector;
    
    /**
     * Source connector name
     */
    private String name;
    
    /**
     * MySQL server ID
     */
    @JsonProperty("server_id")
    private String serverId;
    
    /**
     * MySQL binlog file name
     */
    private String file;
    
    /**
     * Position in binlog file
     */
    private String pos;
    
    /**
     * Row number in the transaction
     */
    private String row;
    
    /**
     * Source database name
     */
    private String db;
    
    /**
     * Source table name
     */
    private String table;

    // ==================== Business Data ====================
    
    /**
     * User unique identifier
     */
    private String id;
    
    /**
     * User login name
     */
    private String username;
    
    /**
     * User email address
     */
    private String email;
    
    /**
     * User birth date (ISO format: YYYY-MM-DD)
     */
    private String birthdate;
    
    /**
     * User active status: 'true' or 'false'
     */
    @JsonProperty("is_active")
    private String isActive;

    // ==================== Constructors ====================
    
    /**
     * Default constructor for serialization frameworks
     */
    public User() {
    }

    /**
     * Full constructor for creating User instances with all fields
     */
    public User(String operation, String timestampMs, String id, String username, String email, 
                String birthdate, String isActive, String version, String connector, String name, 
                String serverId, String file, String pos, String row, String db, String table) {
        this.operation = operation;
        this.timestampMs = timestampMs;
        this.id = id;
        this.username = username;
        this.email = email;
        this.birthdate = birthdate;
        this.isActive = isActive;
        this.version = version;
        this.connector = connector;
        this.name = name;
        this.serverId = serverId;
        this.file = file;
        this.pos = pos;
        this.row = row;
        this.db = db;
        this.table = table;
    }

    /**
     * Business data constructor for creating User instances with core user information
     */
    public User(String id, String username, String email, String birthdate, String isActive) {
        this.id = id;
        this.username = username;
        this.email = email;
        this.birthdate = birthdate;
        this.isActive = isActive;
    }

    // ==================== Business Logic Methods ====================
    
    /**
     * Checks if this is a delete operation
     * @return true if operation is 'd' (delete)
     */
    public boolean isDeleteOperation() {
        return "d".equals(operation);
    }
    
    /**
     * Checks if this is an insert operation
     * @return true if operation is 'c' (create) or 'r' (read)
     */
    public boolean isInsertOperation() {
        return "c".equals(operation) || "r".equals(operation);
    }
    
    /**
     * Checks if this is an update operation
     * @return true if operation is 'u' (update)
     */
    public boolean isUpdateOperation() {
        return "u".equals(operation);
    }
    
    /**
     * Checks if user is active
     * @return true if isActive is "true" or "1"
     */
    public boolean isUserActive() {
        return "true".equals(isActive) || "1".equals(isActive);
    }

    // ==================== Getters and Setters ====================
    
    public String getOperation() {
        return operation;
    }

    public void setOperation(String operation) {
        this.operation = operation;
    }

    public String getTimestampMs() {
        return timestampMs;
    }

    public void setTimestampMs(String timestampMs) {
        this.timestampMs = timestampMs;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getBirthdate() {
        return birthdate;
    }

    public void setBirthdate(String birthdate) {
        this.birthdate = birthdate;
    }

    public String getIsActive() {
        return isActive;
    }

    public void setIsActive(String isActive) {
        this.isActive = isActive;
    }

    public String getVersion() {
        return version;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public String getConnector() {
        return connector;
    }

    public void setConnector(String connector) {
        this.connector = connector;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getServerId() {
        return serverId;
    }

    public void setServerId(String serverId) {
        this.serverId = serverId;
    }

    public String getFile() {
        return file;
    }

    public void setFile(String file) {
        this.file = file;
    }

    public String getPos() {
        return pos;
    }

    public void setPos(String pos) {
        this.pos = pos;
    }

    public String getRow() {
        return row;
    }

    public void setRow(String row) {
        this.row = row;
    }

    public String getDb() {
        return db;
    }

    public void setDb(String db) {
        this.db = db;
    }

    public String getTable() {
        return table;
    }

    public void setTable(String table) {
        this.table = table;
    }

    // ==================== Object Methods ====================
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        User user = (User) o;
        return Objects.equals(operation, user.operation) && 
               Objects.equals(timestampMs, user.timestampMs) && 
               Objects.equals(id, user.id) && 
               Objects.equals(username, user.username) && 
               Objects.equals(email, user.email) && 
               Objects.equals(birthdate, user.birthdate) && 
               Objects.equals(isActive, user.isActive) && 
               Objects.equals(version, user.version) && 
               Objects.equals(connector, user.connector) && 
               Objects.equals(name, user.name) && 
               Objects.equals(serverId, user.serverId) && 
               Objects.equals(file, user.file) && 
               Objects.equals(pos, user.pos) && 
               Objects.equals(row, user.row) && 
               Objects.equals(db, user.db) && 
               Objects.equals(table, user.table);
    }

    @Override
    public int hashCode() {
        return Objects.hash(operation, timestampMs, id, username, email, birthdate, isActive, 
                          version, connector, name, serverId, file, pos, row, db, table);
    }

    @Override
    public String toString() {
        return "User{" +
                "operation='" + operation + '\'' +
                ", timestampMs='" + timestampMs + '\'' +
                ", id='" + id + '\'' +
                ", username='" + username + '\'' +
                ", email='" + email + '\'' +
                ", birthdate='" + birthdate + '\'' +
                ", isActive='" + isActive + '\'' +
                ", version='" + version + '\'' +
                ", connector='" + connector + '\'' +
                ", name='" + name + '\'' +
                ", serverId='" + serverId + '\'' +
                ", file='" + file + '\'' +
                ", pos='" + pos + '\'' +
                ", row='" + row + '\'' +
                ", db='" + db + '\'' +
                ", table='" + table + '\'' +
                '}';
    }
} 