-- 货位基础表：采用三段码结构，例如 A-01-03 表示 A区 1架 3层
CREATE TABLE shelf_slot (
    id SERIAL PRIMARY KEY,
    slot_code VARCHAR(16) NOT NULL UNIQUE,
    zone_code VARCHAR(8) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 包裹流转表
CREATE TABLE package_item (
    id BIGSERIAL PRIMARY KEY,
    tracking_number VARCHAR(64) NOT NULL,
    receiver_phone VARCHAR(11) NOT NULL,
    shelf_slot_id INT NOT NULL REFERENCES shelf_slot(id),
    pickup_code VARCHAR(6) NOT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'STORED', -- STORED(在库), PICKED(已取), OVERDUE(滞留)
    inbound_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    outbound_at TIMESTAMP WITH TIME ZONE
);

-- 核心约束：在库包裹不得共享同一货位（部分唯一索引）
CREATE UNIQUE INDEX uidx_active_shelf_slot 
ON package_item (shelf_slot_id) 
WHERE status = 'STORED';
