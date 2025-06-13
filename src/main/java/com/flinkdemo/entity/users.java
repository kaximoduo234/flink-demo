package com.flinkdemo.entity;

import org.apache.kafka.connect.data.Struct;

import java.util.Objects;

/**
 * description:
 *
 * @author: jj.Sun
 * date: 2025/6/5.
 */
public class users {

    private String op;
    private String ts_ms;
    private String id;
    private String username;
    private String email;
    private String birthdate;
    private String is_active;

    private String version;
    private String connector;
    private String name;
    private String server_id;
    private String file;
    private String pos;
    private String row;
    private String db;
    private String table;

    public users() {
    }

    public users(String op, String ts_ms, String id, String username, String email, String birthdate, String is_active, String version, String connector, String name, String server_id, String file, String pos, String row, String db, String table) {
        this.op = op;
        this.ts_ms = ts_ms;
        this.id = id;
        this.username = username;
        this.email = email;
        this.birthdate = birthdate;
        this.is_active = is_active;
        this.version = version;
        this.connector = connector;
        this.name = name;
        this.server_id = server_id;
        this.file = file;
        this.pos = pos;
        this.row = row;
        this.db = db;
        this.table = table;
    }

    public String getOp() {
        return op;
    }

    public void setOp(String op) {
        this.op = op;
    }

    public String getTs_ms() {
        return ts_ms;
    }

    public void setTs_ms(String ts_ms) {
        this.ts_ms = ts_ms;
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

    public String getIs_active() {
        return is_active;
    }

    public void setIs_active(String is_active) {
        this.is_active = is_active;
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

    public String getServer_id() {
        return server_id;
    }

    public void setServer_id(String server_id) {
        this.server_id = server_id;
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

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        users users = (users) o;
        return Objects.equals(op, users.op) && Objects.equals(ts_ms, users.ts_ms) && Objects.equals(id, users.id) && Objects.equals(username, users.username) && Objects.equals(email, users.email) && Objects.equals(birthdate, users.birthdate) && Objects.equals(is_active, users.is_active) && Objects.equals(version, users.version) && Objects.equals(connector, users.connector) && Objects.equals(name, users.name) && Objects.equals(server_id, users.server_id) && Objects.equals(file, users.file) && Objects.equals(pos, users.pos) && Objects.equals(row, users.row) && Objects.equals(db, users.db) && Objects.equals(table, users.table);
    }

    @Override
    public int hashCode() {
        return Objects.hash(op, ts_ms, id, username, email, birthdate, is_active, version, connector, name, server_id, file, pos, row, db, table);
    }

    @Override
    public String toString() {
        return "users{" +
                "op='" + op + '\'' +
                ", ts_ms='" + ts_ms + '\'' +
                ", id='" + id + '\'' +
                ", username='" + username + '\'' +
                ", email='" + email + '\'' +
                ", birthdate='" + birthdate + '\'' +
                ", is_active='" + is_active + '\'' +
                ", version='" + version + '\'' +
                ", connector='" + connector + '\'' +
                ", name='" + name + '\'' +
                ", server_id='" + server_id + '\'' +
                ", file='" + file + '\'' +
                ", pos='" + pos + '\'' +
                ", row='" + row + '\'' +
                ", db='" + db + '\'' +
                ", table='" + table + '\'' +
                '}';
    }
}
