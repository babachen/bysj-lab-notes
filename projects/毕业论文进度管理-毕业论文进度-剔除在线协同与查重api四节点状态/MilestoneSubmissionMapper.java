// MilestoneSubmissionMapper.java (MyBatis 接口示意)
package com.example.thesis.mapper;

import org.apache.ibatis.annotations.*;

@Mapper
public interface MilestoneSubmissionMapper {

    @Select("SELECT * FROM milestone_submission WHERE id = #{id} FOR UPDATE")
    MilestoneSubmissionEntity selectByIdForUpdate(@Param("id") Long id);

    @Update("UPDATE milestone_submission SET status = #{newStatus}, update_time = NOW() " +
            "WHERE id = #{id} AND status = 1")
    int updateStatus(@Param("id") Long id, @Param("newStatus") Integer newStatus);
}
