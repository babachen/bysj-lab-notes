// RepairOrderServiceImpl.java (示意草稿，需自行实现依赖注入)
package com.example.repair.service.impl;

import com.example.repair.entity.RepairOrder;
import com.example.repair.entity.RepairLog;
import com.example.repair.mapper.RepairOrderMapper;
import com.example.repair.mapper.RepairLogMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.redis.core.StringRedisTemplate;
import java.util.concurrent.TimeUnit;

@Service
public class RepairOrderServiceImpl {
    private final RepairOrderMapper orderMapper;
    private final RepairLogMapper logMapper;
    private final StringRedisTemplate redisTemplate;

    public RepairOrderServiceImpl(RepairOrderMapper om, RepairLogMapper lm, StringRedisTemplate rt) {
        this.orderMapper = om;
        this.logMapper = lm;
        this.redisTemplate = rt;
    }

    @Transactional(rollbackFor = Exception.class)
    public boolean dispatch(Long orderId, Long workerId, Long adminId) {
        String lockKey = "lock:dispatch:" + orderId;
        Boolean acquired = redisTemplate.opsForValue().setIfAbsent(lockKey, "1", 3, TimeUnit.SECONDS);
        if (Boolean.FALSE.equals(acquired)) {
            throw new IllegalStateException("派工请求正在处理，请稍后刷新");
        }
        try {
            // 基于数据库当前状态条件更新，返回影响行数，抗并发重派
            int rows = orderMapper.updateStatusToDispatched(orderId, workerId, 10, 20);
            if (rows == 0) {
                throw new IllegalStateException("派工失败：工单不存在或已不再是待派工状态");
            }
            RepairLog log = new RepairLog(orderId, adminId, "ADMIN", "指派工单", "工单已转交维修工ID:" + workerId);
            logMapper.insert(log);
            return true;
        } finally {
            redisTemplate.delete(lockKey);
        }
    }
}
