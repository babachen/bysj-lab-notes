// RepairOrderMapper.java (示意草稿)
package com.example.repair.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Update;

@Mapper
public interface RepairOrderMapper {
    @Update("UPDATE repair_order SET worker_id = #{workerId}, status = #{targetStatus} " +
            "WHERE id = #{orderId} AND status = #{expectStatus}")
    int updateStatusToDispatched(@Param("orderId") Long orderId,
                                 @Param("workerId") Long workerId,
                                 @Param("expectStatus") Integer expectStatus,
                                 @Param("targetStatus") Integer targetStatus);
}
