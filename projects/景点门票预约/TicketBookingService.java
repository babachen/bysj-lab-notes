// TicketBookingService.java（示意可跑逻辑）
@Service
public class TicketBookingService {

    @Autowired
    private TicketStockMapper stockMapper;
    
    @Autowired
    private TicketOrderMapper orderMapper;

    @Transactional(rollbackFor = Exception.class)
    public String createBooking(Long stockId, Long userId, Integer buyNum) {
        // 1. 严格原子扣减：利用数据库行锁，在 UPDATE 时做库存下限校验，避免超卖
        int affectedRows = stockMapper.decreaseStock(stockId, buyNum);
        if (affectedRows == 0) {
            throw new BusinessException("当前场次门票已售罄或余票不足");
        }

        // 2. 生成本地唯一订单
        String orderSn = "TK" + System.currentTimeMillis() + ThreadLocalRandom.current().nextInt(100, 999);
        TicketOrder order = new TicketOrder();
        order.setOrderSn(orderSn);
        order.setStockId(stockId);
        order.setUserId(userId);
        order.setTicketCount(buyNum);
        order.setOrderStatus(1); // 毕业设计直接置为预订成功，避开外部公网支付回调沙箱
        orderMapper.insert(order);

        return orderSn;
    }
}
