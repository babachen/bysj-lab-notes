# models.py (对照草稿，按需补充完整)
from django.db import models
from django.utils import timezone

class Shelf(models.Model):
    code = models.CharField(max_length=16, unique=True, verbose_name="货架编号(如A01)")
    capacity = models.PositiveIntegerField(default=50, verbose_name="最大容纳量")
    current_count = models.PositiveIntegerField(default=0, verbose_name="当前在架量")

    class Meta:
        db_table = "tb_shelf"

class Parcel(models.Model):
    STATUS_CHOICES = (
        (0, "待取件"),
        (1, "已签收"),
        (2, "异常/退件"),
    )
    tracking_number = models.CharField(max_length=64, unique=True, verbose_name="快递单号")
    recipient_phone = models.CharField(max_length=11, db_index=True, verbose_name="收件人手机")
    shelf = models.ForeignKey(Shelf, on_delete=models.PROTECT, related_name="parcels")
    pickup_code = models.CharField(max_length=32, unique=True, verbose_name="物理取件码")
    status = models.SmallIntegerField(choices=STATUS_CHOICES, default=0, db_index=True)
    inbound_time = models.DateTimeField(default=timezone.now, verbose_name="入库时间")
    outbound_time = models.DateTimeField(null=True, blank=True, verbose_name="出库时间")

    class Meta:
        db_table = "tb_parcel"

class PickupAuditLog(models.Model):
    parcel = models.ForeignKey(Parcel, on_delete=models.CASCADE, verbose_name="关联包裹")
    operator_name = models.CharField(max_length=32, verbose_name="经办店员")
    action_time = models.DateTimeField(default=timezone.now, verbose_name="操作时间")
    verify_type = models.CharField(max_length=16, default="CODE", verbose_name="核销方式")

    class Meta:
        db_table = "tb_pickup_log"
