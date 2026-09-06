# task_service.py (对照草稿，禁止直接当成全套工程)
from django.db import transaction
from django.core.exceptions import ValidationError
from .models import ErrandTask

class TaskService:
    @staticmethod
    def grab_task(task_id: int, runner_id: int) -> bool:
        """
        核心抢单逻辑：行级版本控制，防止超卖与重复认领
        """
        with transaction.atomic():
            # 使用 select_for_update 锁定当前行，阻止并发事务脏读
            try:
                task = ErrandTask.objects.select_for_update().get(id=task_id)
            except ErrandTask.DoesNotExist:
                raise ValidationError("订单不存在")

            if task.publisher_id == runner_id:
                raise ValidationError("无法承接自己发布的订单")

            if task.status != ErrandTask.Status.PENDING:
                raise ValidationError("该任务已被接单或已失效")

            # 状态更新
            task.runner_id = runner_id
            task.status = ErrandTask.Status.ACCEPTED
            task.version += 1
            task.save(update_fields=['runner_id', 'status', 'version'])
            return True

    @staticmethod
    def complete_delivery(task_id: int, runner_id: int, input_code: str) -> bool:
        """
        核销校验：仅持单骑手与正确验证码可核销
        """
        task = ErrandTask.objects.filter(id=task_id, runner_id=runner_id).first()
        if not task or task.status != ErrandTask.Status.ACCEPTED:
            raise ValidationError("无效的核销请求")

        if task.verify_code != input_code.strip():
            raise ValidationError("取件核销码错误")

        task.status = ErrandTask.Status.FINISHED
        task.save(update_fields=['status'])
        return True
