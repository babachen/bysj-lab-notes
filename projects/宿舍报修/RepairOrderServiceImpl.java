@Service
public class RepairOrderServiceImpl implements RepairOrderService {

    @Autowired
    private RepairOrderMapper orderMapper;
    @Autowired
    private RepairOrderLogMapper logMapper;

    @Transactional(rollbackFor = Exception.class)
    @Override
    public void transitionStatus(Long orderId, Integer targetStatus, Long operatorId, String remark) {
        RepairOrder order = orderMapper.selectById(orderId);
        if (order == null) {
            throw new IllegalArgumentException("工单不存在");
        }

        Integer current = order.getStatus();
        // 严格状态跃迁校验，禁止逆向流转与越级流转
        boolean valid = (current == 10 && targetStatus == 20)
                     || (current == 20 && targetStatus == 30)
                     || (current == 30 && targetStatus == 40)
                     || ((current == 10 || current == 20) && targetStatus == 99);

        if (!valid) {
            throw new IllegalStateException(String.format("非法操作：工单无法从[%d]流转至[%d]", current, targetStatus));
        }

        // 更新主表状态
        order.setStatus(targetStatus);
        orderMapper.updateById(order);

        // 写流转审计日志
        RepairOrderLog log = new RepairOrderLog();
        log.setOrderId(orderId);
        log.setPreStatus(current);
        log.setPostStatus(targetStatus);
        log.setOperatorId(operatorId);
        log.setRemark(remark);
        logMapper.insert(log);
    }
}
