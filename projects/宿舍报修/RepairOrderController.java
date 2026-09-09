@RestController
@RequestMapping("/api/repair")
public class RepairOrderController {

    @Autowired
    private StringRedisTemplate redisTemplate;
    
    @Autowired
    private RepairOrderService repairOrderService;

    @PostMapping("/submit")
    public ResponseEntity<String> submitOrder(@RequestBody @Validated RepairSubmitDTO dto, 
                                              @RequestAttribute("userId") Long userId) {
        // 构造用户针对同一宿舍、同一分类的防抖 Key
        String lockKey = String.format("repair:submit:lock:%d:%d:%d", 
                                       userId, dto.getDormId(), dto.getCategoryId());
        
        // 5秒内禁止重复发起相同报修（返回布尔值）
        Boolean acquired = redisTemplate.opsForValue()
                .setIfAbsent(lockKey, "1", Duration.ofSeconds(5));
        
        if (Boolean.FALSE.equals(acquired)) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .body("正在提交中，请勿频繁点击");
        }

        try {
            String orderNo = repairOrderService.createOrder(dto, userId);
            return ResponseEntity.ok(orderNo);
        } catch (Exception e) {
            // 出现业务异常及时清除锁，允许用户重试
            redisTemplate.delete(lockKey);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("提交失败，请重试");
        }
    }
}
