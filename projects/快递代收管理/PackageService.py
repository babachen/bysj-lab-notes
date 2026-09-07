# services.py (草稿示意，不超过40行)
from django.db import transaction, IntegrityError
from django.utils import timezone
from .models import PackageItem, ShelfSlot

class PackageService:
    @staticmethod
    def process_inbound(tracking_num: str, phone: str, slot_id: int) -> dict:
        try:
            with transaction.atomic():
                # 利用 PostgreSQL partial index 阻断重复绑定
                item = PackageItem.objects.create(
                    tracking_number=tracking_num,
                    receiver_phone=phone,
                    shelf_slot_id=slot_id,
                    pickup_code=PackageService._calc_pickup_code(phone),
                    status='STORED'
                )
                return {"code": 200, "pickup_code": item.pickup_code}
        except IntegrityError:
            return {"code": 409, "message": "货位冲突或单号在库重复"}

    @staticmethod
    def process_outbound(pickup_code: str, phone_tail: str) -> bool:
        with transaction.atomic():
            item = PackageItem.objects.select_for_update().filter(
                pickup_code=pickup_code,
                receiver_phone__endswith=phone_tail,
                status='STORED'
            ).first()
            if not item:
                return False
            item.status = 'PICKED'
            item.outbound_at = timezone.now()
            item.save(update_fields=['status', 'outbound_at'])
            return True
