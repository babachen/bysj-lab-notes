package com.lab.system.service;

import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Service
public class LabReservationService {

    // 读者需注入对应的 Mapper 依赖
    // private LabReservationMapper reservationMapper;
    // private LabPunishmentMapper punishmentMapper;

    @Transactional(rollbackFor = Exception.class)
    public boolean submitReservation(Long userId, Long seatId, LocalDate date, Integer slotIndex) {
        // 1. 失信检查：30天内爽约满3次封禁至下周
        int breakCount = 0; // punishmentMapper.countActiveBreaks(userId, LocalDateTime.now());
        if (breakCount > 0) {
            throw new IllegalStateException("账号存在生效中的违规限制");
        }

        // 2. 插入数据库，依靠 uk_seat_slot 拦截同时并发
        try {
            // reservationMapper.insertReservation(userId, seatId, date, slotIndex, code);
            return true;
        } catch (DuplicateKeyException e) {
            // 仅捕获时段碰撞，不要笼统 catch Exception
            throw new IllegalArgumentException("手慢了，该台位该时段已被占用");
        }
    }

    public boolean checkin(Long reservationId, String inputCode) {
        // 核销逻辑：校对 code，并将状态置为已核销 (1)
        // 注意在此校验核销时间窗口，超出时段则算违约
        return false; // 读者自行补齐
    }
}
