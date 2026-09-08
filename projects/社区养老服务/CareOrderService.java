package com.community.care.service;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CareOrderService {
    private final StringRedisTemplate redisTemplate;
    private final CareOrderMapper orderMapper;

    public CareOrderService(StringRedisTemplate redisTemplate, CareOrderMapper orderMapper) {
        this.redisTemplate = redisTemplate;
        this.orderMapper = orderMapper;
    }

    @Transactional(rollbackFor = Exception.class)
    public boolean verifyOrder(String verifyCode, Long staffId) {
        // 1. 按照核销码检索处于待履约状态的工单
        CareOrder order = orderMapper.selectByVerifyCode(verifyCode);
        if (order == null || order.getOrderStatus() != 1) {
            throw new IllegalArgumentException("核销码无效或服务单不在待核销状态");
        }

        // 2. 状态机流转：从待服务(1)更新为已核销(2)，带行版本更新
        int affected = orderMapper.updateStatusToFinished(order.getOrderNo(), staffId);
        if (affected == 0) {
            throw new IllegalStateException("工单已被其他服务人员核销");
        }
        return true;
    }
}
