// GroupOrderService.java：示意草稿
@Service
public class GroupOrderService {
    @Transactional
    public Long create(Long userId, Long activityId, Integer qty) {
        if (qty == null || qty <= 0) {
            throw new BizException("数量错误");
        }
        Activity a = activityMapper.selectForUpdate(activityId);
        if (a == null || !a.isOpenAt(LocalDateTime.now())) {
            throw new BizException("活动不可下单");
        }
        int remain = a.getStockTotal() - a.getStockUsed();
        if (remain < qty) {
            throw new BizException("库存不足");
        }
        BigDecimal total = a.getGroupPrice()
            .multiply(BigDecimal.valueOf(qty));
        orderMapper.insertPending(userId, activityId, qty,
            a.getGroupPrice(), total);
        activityMapper.increaseUsed(activityId, qty);
        return orderMapper.lastId();
    }
}
