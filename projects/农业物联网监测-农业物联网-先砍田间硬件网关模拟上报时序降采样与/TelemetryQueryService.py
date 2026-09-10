# query_service.py - 仅做对照参考，依赖 PostgreSQL 特有时序函数
from django.db.models import Avg
from django.db.models.functions import TruncHour
from .models import Telemetry

class TelemetryQueryService:
    @staticmethod
    def get_hourly_trends(device_id: int, start_time, end_time):
        """
        避免拉取几万条原始打点搞垮前端折线图，按小时窗口降采样求均值
        """
        return (
            Telemetry.objects.filter(
                device_id=device_id,
                recorded_at__range=(start_time, end_time)
            )
            .annotate(hour_slot=TruncHour('recorded_at'))
            .values('hour_slot')
            .annotate(
                avg_temp=Avg('temperature'),
                avg_hum=Avg('humidity'),
                avg_co2=Avg('co2_ppm')
            )
            .order_by('hour_slot')
        )
