// 对照草稿：方法签名和校验顺序需自行补全，不是完整工程
@Service
public class OrderService {
    @Transactional
    public Long create(Long userId, List<CartItemCmd> items) {
        if (items == null || items.isEmpty()) {
            throw new BizException("购物车为空");
        }
        Long merchantId = cartValidator.onlyOneMerchant(items);
        merchantGuard.requireApproved(merchantId);

        Order order = Order.pending(userId, merchantId);
        for (CartItemCmd cmd : items) {
            Dish dish = dishMapper.selectForUpdate(cmd.dishId());
            dishGuard.checkSellable(dish, merchantId, cmd.quantity());
            order.addSnapshot(dish.getId(), dish.getName(),
                    dish.getPrice(), cmd.quantity());
            dishMapper.decreaseStock(dish.getId(), cmd.quantity());
        }
        orderMapper.insert(order);
        statusLogMapper.insertCreated(order.getId(), userId);
        return order.getId();
    }
}
