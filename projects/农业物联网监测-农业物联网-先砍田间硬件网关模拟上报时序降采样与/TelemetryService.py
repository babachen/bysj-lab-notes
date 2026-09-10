# telemetry_service.py - 仅做对照参考，需自行补齐全局事务与配置注入
from datetime import datetime
from django.db import transaction
from django.core.exceptions import PermissionDenied, ValidationError
from .models import Device, Telemetry, AlertLog

class TelemetryService:
    TEMP_MAX_THRESHOLD = 35.0  # 摄氏度

    @classmethod
    @transaction.atomic
    def process_incoming_report(cls, token: str, code: str, temp: float, hum: float, co2: int):
        device = Device.objects.filter(device_code=code, auth_token=token, is_active=True).first()
        if not device:
            raise PermissionDenied("Device authentication failed")

        if not (-30.0 <= temp <= 70.0 and 0.0 <= hum <= 100.0):
            raise ValidationError("Sensor reading outside physical boundary")

        # 记录遥测数据
        record = Telemetry.objects.create(
            device=device,
            temperature=temp,
            humidity=hum,
            co2_ppm=co2,
            recorded_at=datetime.now()
        )
        device.last_seen_at = record.recorded_at
        device.save(update_fields=['last_seen_at'])

        # 阈值核对与事件生成
        if temp > cls.TEMP_MAX_THRESHOLD:
            AlertLog.objects.create(
                device=device,
                metric_name="temperature",
                trigger_value=temp,
                threshold_value=cls.TEMP_MAX_THRESHOLD,
                resolved=False
            )
        return record.id
