-- 1. 设备/节点注册表（充当网关与大棚归属凭据）
CREATE TABLE iot_device (
    id SERIAL PRIMARY KEY,
    device_code VARCHAR(32) UNIQUE NOT NULL,    -- 节点唯一硬件码/网关标识
    greenhouse_name VARCHAR(64) NOT NULL,       -- 所属大棚编号，如：1号日光温室
    auth_token VARCHAR(64) NOT NULL,            -- 网关鉴权 Token
    is_active BOOLEAN DEFAULT TRUE,
    last_seen_at TIMESTAMP WITH TIME ZONE
);

-- 2. 遥测时序快照表（高写入、只追加、加复合索引）
CREATE TABLE iot_telemetry (
    id BIGSERIAL PRIMARY KEY,
    device_id INT NOT NULL REFERENCES iot_device(id),
    temperature NUMERIC(4, 1) NOT NULL,         -- 温度：单位摄氏度，-20.0 ~ 60.0
    humidity NUMERIC(4, 1) NOT NULL,            -- 湿度：单位百分比，0.0 ~ 100.0
    co2_ppm INT NOT NULL,                       -- 二氧化碳浓度：单位 ppm
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_telemetry_device_time ON iot_telemetry(device_id, recorded_at DESC);

-- 3. 阈值越界告警记录表
CREATE TABLE iot_alert_log (
    id SERIAL PRIMARY KEY,
    device_id INT NOT NULL REFERENCES iot_device(id),
    metric_name VARCHAR(16) NOT NULL,           -- 超标指标：temp / hum / co2
    trigger_value NUMERIC(6, 1) NOT NULL,       -- 触发时的实测值
    threshold_value NUMERIC(6, 1) NOT NULL,     -- 预设的阈值上限/下限
    resolved BOOLEAN DEFAULT FALSE,             -- 是否已处置（联动水泵/通风）
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
