# 示意草稿：按日剩余必须回源。禁止从 ES hits 读 leftover。
def leftover_or_none(conn, room_type_id, nights):
    sql = """
      SELECT stay_date, leftover, version
      FROM occupancy_day
      WHERE room_type_id=%s AND stay_date IN (%s)
      FOR UPDATE
    """
    rows = conn.execute(sql, room_type_id, nights).fetchall()
    if len(rows) != len(nights):
        return None  # 日历有洞，拒绝下单
    if any(r.leftover < 1 for r in rows):
        return None
    return rows
