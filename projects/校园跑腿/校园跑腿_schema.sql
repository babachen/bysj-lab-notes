CREATE TABLE campus_building (
    id SERIAL PRIMARY KEY,
    zone_code VARCHAR(16) NOT NULL,      -- 例如: DORM_NORTH (北区宿舍), CANTEEN (食堂区)
    building_name VARCHAR(64) NOT NULL,  -- 例如: 12号楼
    is_active BOOLEAN DEFAULT TRUE
);

-- 预置跨区计价权重示例：同一 zone 基础费 2 元，跨 zone 累加 1.5 元
