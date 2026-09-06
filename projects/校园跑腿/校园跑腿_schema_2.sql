CREATE TABLE errand_task (
    id BIGSERIAL PRIMARY KEY,
    task_no VARCHAR(32) UNIQUE NOT NULL,
    publisher_id BIGINT NOT NULL,
    runner_id BIGINT DEFAULT NULL,
    from_building_id INT REFERENCES campus_building(id),
    to_building_id INT REFERENCES campus_building(id),
    bounty_cents INT NOT NULL,            -- 赏金（单位：分，避免浮点数计算错误）
    verify_code VARCHAR(8) NOT NULL,      -- 交付核销码
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    version INT NOT NULL DEFAULT 0,       -- 乐观锁版本号
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_task_pool ON errand_task (status, from_building_id);
