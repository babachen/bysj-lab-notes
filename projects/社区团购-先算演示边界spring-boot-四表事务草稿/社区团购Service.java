// ActivityMapper.java：示意草稿
@Select("""
  select id, product_id, leader_id, group_price,
         stock_total, stock_used, start_at, end_at, status
  from group_activity where id = #{id} for update
""")
Activity selectForUpdate(Long id);

@Update("""
  update group_activity
  set stock_used = stock_used + #{qty}
  where id = #{id}
    and status = 'OPEN'
    and stock_used + #{qty} <= stock_total
""")
int increaseUsed(@Param("id") Long id,
                 @Param("qty") Integer qty);
