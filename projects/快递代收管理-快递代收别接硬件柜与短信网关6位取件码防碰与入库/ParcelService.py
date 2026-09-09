# services.py (对照草稿，读者需自行完善异常细分)
from django.db import transaction
from django.utils import timezone
from .models import Parcel, Shelf, PickupAuditLog

class ParcelService:
    @staticmethod
    def verify_and_pickup(pickup_code: str, operator_name: str) -> bool:
        """
        执行核销出库：排他锁行记录，校验状态，释放货架库位，记录日志
        """
        with transaction.atomic():
            # 使用 select_for_update 防止同一取件码被多窗口连击并发核销
            parcel = Parcel.objects.select_for_update().filter(pickup_code=pickup_code).first()
            if not parcel:
                raise ValueError("未找到该取件码对应的包裹")
            
            if parcel.status != 0:
                raise ValueError(f"包裹状态异常，当前状态代码为：{parcel.status}，不可重复核销")
            
            # 更新包裹状态
            parcel.status = 1
            parcel.outbound_time = timezone.now()
            parcel.save(update_fields=["status", "outbound_time"])
            
            # 货架在架计数原子减 1
            Shelf.objects.filter(id=parcel.shelf_id).update(
                current_count=models.F("current_count") - 1
            )
            
            # 记录审计日志
            PickupAuditLog.objects.create(
                parcel=parcel,
                operator_name=operator_name,
                verify_type="PICKUP_CODE"
            )
            return True
