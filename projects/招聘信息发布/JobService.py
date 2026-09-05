# services/job_service.py (代码示意草稿，约 35 行)
from datetime import datetime
import json
from models import db, JobPost, JobApplication, OnlineResume

class JobService:
    @staticmethod
    def submit_application(student_id: int, job_id: int):
        # 1. 验证岗位是否处于可投状态（已通过审核且未下架）
        job = JobPost.query.filter_by(id=job_id, status=1).first()
        if not job:
            return False, "岗位不存在或未开放投递"
        
        # 2. 获取求职者当前有效在线简历
        resume = OnlineResume.query.filter_by(user_id=student_id).first()
        if not resume or not resume.is_complete:
            return False, "在线简历未完善"
            
        # 3. 封装只读快照数据
        job_snap = json.dumps({"title": job.title, "salary": f"{job.salary_min}-{job.salary_max}k"})
        resume_snap = json.dumps({"name": resume.real_name, "contact": resume.phone, "detail": resume.content})
        
        # 4. 创建投递记录
        app = JobApplication(
            job_id=job.id,
            student_id=student_id,
            job_snapshot=job_snap,
            resume_snapshot=resume_snap,
            status=0,
            created_at=datetime.utcnow()
        )
        try:
            db.session.add(app)
            db.session.commit()
            return True, "投递成功"
        except Exception:
            db.session.rollback()
            return False, "已投递过该岗位，请勿重复操作"
