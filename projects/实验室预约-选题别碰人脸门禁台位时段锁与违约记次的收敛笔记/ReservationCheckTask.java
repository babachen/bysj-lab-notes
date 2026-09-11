package com.lab.system.task;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import java.time.LocalDate;

@Component
public class ReservationCheckTask {

    // 每小时跑一次，标记过期未核销记录
    @Scheduled(cron = "0 0 * * * ?")
    public void scanBreachReservations() {
        LocalDate today = LocalDate.now();
        // 1. 查出当前时间槽之前、状态仍为 0（待核销）的预约单
        // List<LabReservation> overdueList = mapper.selectOverdue(today, currentSlot);
        
        // 2. 批量将状态扭转为 2 (已爽约)
        // 3. 统计该用户违约总数，如果 >= 3 则写入一条惩罚记录到 lab_punishment
    }
}
