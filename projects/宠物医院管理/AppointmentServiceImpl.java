package com.pet.hospital.service.impl;

import com.pet.hospital.entity.DoctorSchedule;
import com.pet.hospital.mapper.AppointmentOrderMapper;
import com.pet.hospital.mapper.DoctorScheduleMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AppointmentServiceImpl {

    private final DoctorScheduleMapper scheduleMapper;
    private final AppointmentOrderMapper orderMapper;

    public AppointmentServiceImpl(DoctorScheduleMapper sMapper, AppointmentOrderMapper oMapper) {
        this.scheduleMapper = sMapper;
        this.orderMapper = oMapper;
    }

    @Transactional(rollbackFor = Exception.class)
    public boolean bookAppointment(String chipId, Long scheduleId, String orderNo) {
        DoctorSchedule schedule = scheduleMapper.selectById(scheduleId);
        if (schedule == null || schedule.getUsedQuota() >= schedule.getTotalQuota()) {
            return false;
        }

        // CAS 乐观锁更新号源，避免超卖
        int updated = scheduleMapper.increaseUsedQuotaWithVersion(
                scheduleId, schedule.getVersion());
        if (updated == 0) {
            return false; // 存在并发冲突，让前端提示重试
        }

        // 插入挂号单，依靠数据库外键或逻辑字段关联
        orderMapper.insertOrder(orderNo, chipId, schedule.getDoctorId(), scheduleId, 1);
        return true;
    }
}
