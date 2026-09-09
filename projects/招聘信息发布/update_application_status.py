# app_service.py - 投递流转核心接口示意
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://root:123456@127.0.0.1:3306/job_db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# 状态常量定义
STATUS_SUBMITTED = 10
STATUS_PASSED_SCREEN = 20
STATUS_INTERVIEWING = 30
STATUS_OFFERED = 40
STATUS_REJECTED = 90

# 合法的状态跃迁映射表
VALID_TRANSITIONS = {
    STATUS_SUBMITTED: [STATUS_PASSED_SCREEN, STATUS_REJECTED],
    STATUS_PASSED_SCREEN: [STATUS_INTERVIEWING, STATUS_REJECTED],
    STATUS_INTERVIEWING: [STATUS_OFFERED, STATUS_REJECTED],
}

@app.route('/api/application/<int:app_id>/status', methods=['PUT'])
def update_application_status(app_id):
    data = request.get_json() or {}
    target_status = data.get('status')
    reject_reason = data.get('reject_reason', '').strip()

    # 1. 基础参数校验
    if not target_status or not isinstance(target_status, int):
        return jsonify({"code": 400, "msg": "无效的目标状态"}), 400

    # 2. 查询当前单据并加上行级排他锁，防止并发审批
    record = db.session.query(JobApplication).filter_by(id=app_id).with_for_update().first()
    if not record:
        return jsonify({"code": 404, "msg": "投递记录不存在"}), 404

    current_status = record.status
    allowed_next_states = VALID_TRANSITIONS.get(current_status, [])

    # 3. 校验跃迁是否合法
    if target_status not in allowed_next_states:
        return jsonify({
            "code": 422,
            "msg": f"状态流转非法：不可从 {current_status} 变更到 {target_status}"
        }), 422

    # 4. 淘汰必须填写理由
    if target_status == STATUS_REJECTED and not reject_reason:
        return jsonify({"code": 422, "msg": "淘汰操作必须附带原因说明"}), 422

    # 5. 执行原子流转
    record.status = target_status
    if target_status == STATUS_REJECTED:
        record.reject_reason = reject_reason
    
    record.updated_at = datetime.now()
    db.session.commit()

    return jsonify({"code": 200, "msg": "状态更新成功", "current_status": target_status})
