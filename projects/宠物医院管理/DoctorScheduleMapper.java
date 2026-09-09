package com.pet.hospital.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Update;

@Mapper
public interface DoctorScheduleMapper {
    
    @Update("UPDATE doctor_schedule SET used_quota = used_quota + 1, version = version + 1 " +
            "WHERE id = #{id} AND version = #{version} AND used_quota < total_quota")
    int increaseUsedQuotaWithVersion(@Param("id") Long id, @Param("version") Integer version);
}
