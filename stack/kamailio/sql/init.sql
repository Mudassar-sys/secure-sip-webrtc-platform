-- Kamailio subscriber database init
-- This runs once when the MySQL container first starts

CREATE DATABASE IF NOT EXISTS kamailio CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS homer CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE kamailio;

CREATE TABLE IF NOT EXISTS subscriber (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  username    VARCHAR(64)  NOT NULL,
  domain      VARCHAR(64)  NOT NULL,
  password    VARCHAR(128) NOT NULL,
  ha1         VARCHAR(64)  NOT NULL DEFAULT '',
  ha1b        VARCHAR(64)  NOT NULL DEFAULT '',
  UNIQUE KEY user_domain (username, domain)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS location (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  ruid        VARCHAR(64)  NOT NULL DEFAULT '',
  username    VARCHAR(64)  NOT NULL DEFAULT '',
  domain      VARCHAR(64)  DEFAULT NULL,
  contact     VARCHAR(512) NOT NULL DEFAULT '',
  received    VARCHAR(128) DEFAULT NULL,
  path        VARCHAR(512) DEFAULT NULL,
  expires     DATETIME     NOT NULL DEFAULT '2030-05-28 21:32:15',
  q           FLOAT(10,2)  NOT NULL DEFAULT '1.00',
  callid      VARCHAR(255) NOT NULL DEFAULT 'Default-Call-ID',
  cseq        INT          NOT NULL DEFAULT 13,
  last_modified DATETIME   NOT NULL DEFAULT '2000-01-01 00:00:01',
  flags       INT          NOT NULL DEFAULT 0,
  cflags      INT          NOT NULL DEFAULT 0,
  user_agent  VARCHAR(255) NOT NULL DEFAULT '',
  socket      VARCHAR(64)  DEFAULT NULL,
  methods     INT          DEFAULT NULL,
  instance    VARCHAR(255) DEFAULT NULL,
  reg_id      INT          NOT NULL DEFAULT 0,
  server_id   INT          NOT NULL DEFAULT 0,
  connection_id INT        NOT NULL DEFAULT 0,
  keepalive   INT          NOT NULL DEFAULT 0,
  partition   INT          NOT NULL DEFAULT 0,
  UNIQUE KEY ruid_idx (ruid)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dispatcher (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  setid       INT          NOT NULL DEFAULT 0,
  destination VARCHAR(192) NOT NULL DEFAULT '',
  flags       INT          NOT NULL DEFAULT 0,
  priority    INT          NOT NULL DEFAULT 0,
  attrs       VARCHAR(128) NOT NULL DEFAULT '',
  description VARCHAR(64)  NOT NULL DEFAULT ''
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS topos_t (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  rectime     DATETIME     NOT NULL,
  s_method    VARCHAR(64)  NOT NULL DEFAULT '',
  s_cseq      VARCHAR(64)  NOT NULL DEFAULT '',
  a_callid    VARCHAR(255) NOT NULL DEFAULT '',
  a_uuid      VARCHAR(255) NOT NULL DEFAULT '',
  b_uuid      VARCHAR(255) NOT NULL DEFAULT '',
  direction   INT          NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS topos_d (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  rectime     DATETIME     NOT NULL,
  a_callid    VARCHAR(255) NOT NULL DEFAULT '',
  a_uuid      VARCHAR(255) NOT NULL DEFAULT '',
  b_uuid      VARCHAR(255) NOT NULL DEFAULT '',
  a_contact   VARCHAR(512) NOT NULL DEFAULT '',
  b_contact   VARCHAR(512) NOT NULL DEFAULT '',
  as_contact  VARCHAR(512) NOT NULL DEFAULT '',
  bs_contact  VARCHAR(512) NOT NULL DEFAULT '',
  a_tag       VARCHAR(255) NOT NULL DEFAULT '',
  b_tag       VARCHAR(255) NOT NULL DEFAULT '',
  a_rr        TEXT,
  b_rr        TEXT,
  s_rr        TEXT,
  iflags      INT          NOT NULL DEFAULT 0,
  a_uri       VARCHAR(255) NOT NULL DEFAULT '',
  b_uri       VARCHAR(255) NOT NULL DEFAULT '',
  r_uri       VARCHAR(255) NOT NULL DEFAULT '',
  a_srcaddr   VARCHAR(255) NOT NULL DEFAULT '',
  b_srcaddr   VARCHAR(255) NOT NULL DEFAULT ''
) ENGINE=InnoDB;

-- Insert Asterisk as a dispatcher destination (set 1)
-- Update the IP to match your Asterisk container IP or hostname
INSERT INTO dispatcher (setid, destination, flags, priority, attrs, description)
  VALUES (1, 'sip:asterisk:5060', 0, 10, '', 'Asterisk instance 1')
  ON DUPLICATE KEY UPDATE destination=destination;

-- Homer tables (simplified)
USE homer;
CREATE TABLE IF NOT EXISTS hep_proto_1_default (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  date        DATETIME,
  micro_ts    BIGINT NOT NULL DEFAULT 0,
  method      VARCHAR(50) NOT NULL DEFAULT '',
  reply_reason VARCHAR(100) NOT NULL DEFAULT '',
  ruri        VARCHAR(200) NOT NULL DEFAULT '',
  from_user   VARCHAR(100) NOT NULL DEFAULT '',
  from_domain VARCHAR(150) NOT NULL DEFAULT '',
  from_tag    VARCHAR(64) NOT NULL DEFAULT '',
  to_user     VARCHAR(100) NOT NULL DEFAULT '',
  to_domain   VARCHAR(150) NOT NULL DEFAULT '',
  to_tag      VARCHAR(64) NOT NULL DEFAULT '',
  pid_user    VARCHAR(100) NOT NULL DEFAULT '',
  contact_user VARCHAR(120) NOT NULL DEFAULT '',
  auth_user   VARCHAR(120) NOT NULL DEFAULT '',
  callid      VARCHAR(120) NOT NULL DEFAULT '',
  callid_aleg VARCHAR(120) NOT NULL DEFAULT '',
  via_1       VARCHAR(256) NOT NULL DEFAULT '',
  via_1_branch VARCHAR(80) NOT NULL DEFAULT '',
  cseq        VARCHAR(25) NOT NULL DEFAULT '',
  diversion   VARCHAR(256) NOT NULL DEFAULT '',
  reason      VARCHAR(200) NOT NULL DEFAULT '',
  content_type VARCHAR(256) NOT NULL DEFAULT '',
  auth        VARCHAR(256) NOT NULL DEFAULT '',
  user_agent  VARCHAR(256) NOT NULL DEFAULT '',
  source_ip   VARCHAR(60) NOT NULL DEFAULT '',
  source_port SMALLINT NOT NULL DEFAULT 0,
  destination_ip VARCHAR(60) NOT NULL DEFAULT '',
  destination_port SMALLINT NOT NULL DEFAULT 0,
  contact_ip  VARCHAR(60) NOT NULL DEFAULT '',
  contact_port SMALLINT NOT NULL DEFAULT 0,
  originator_ip VARCHAR(60) NOT NULL DEFAULT '',
  originator_port SMALLINT NOT NULL DEFAULT 0,
  correlation_id VARCHAR(256) NOT NULL DEFAULT '',
  proto       SMALLINT NOT NULL DEFAULT 0,
  family      SMALLINT DEFAULT NULL,
  rtp_stat    VARCHAR(256) NOT NULL DEFAULT '',
  type        SMALLINT NOT NULL DEFAULT 0,
  node        VARCHAR(125) NOT NULL DEFAULT '',
  msg         BLOB NOT NULL,
  KEY callid_idx (callid),
  KEY date_idx (date),
  KEY src_ip_idx (source_ip)
) ENGINE=InnoDB PARTITION BY RANGE (to_days(date)) (
  PARTITION pmax VALUES LESS THAN MAXVALUE
);
