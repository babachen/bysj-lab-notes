package com.community.care.service;

import org.apache.ibatis.annotations.*;

@Mapper
public interface CareOrderMapper {
    @Select("SELECT * FROM care_order WHERE verify_code = #{code} LIMIT 1")
    CareOrder selectByVerifyCode(@Param("code") String code);

    @Update("UPDATE care_order SET order_status = 2, staff_id = #{staffId} " +
            "WHERE order_no = #{orderNo} AND order_status = 1")
    int updateStatusToFinished(@Param("orderNo") String orderNo, @Param("staffId") Long staffId);
}
