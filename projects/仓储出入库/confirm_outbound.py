# app/routes/outbound.py
from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models import Material, OutboundOrder, OutboundDetail

outbound_bp = Blueprint('outbound', __name__)

@outbound_bp.route('/api/outbound/confirm', methods=['POST'])
def confirm_outbound():
    data = request.get_json() or {}
    order_id = data.get('order_id')
    
    if not order_id:
        return jsonify({'code': 400, 'msg': '缺少单据ID'}), 400

    try:
        # 开启显式事务控制
        with db.session.begin_nested():
            order = OutboundOrder.query.filter_by(id=order_id).with_for_update().first()
            if not order or order.status != 1:
                return jsonify({'code': 400, 'msg': '单据状态非法或未处于锁定状态'}), 400
            
            details = OutboundDetail.query.filter_by(outbound_id=order.id).all()
            
            for item in details:
                # 锁定对应的物料记录行，避免并发篡改
                mat = Material.query.filter_by(id=item.material_id).with_for_update().first()
                
                if mat.stock_qty < item.quantity:
                    raise ValueError(f'物料 {mat.material_code} 实际库存不足')
                if mat.frozen_qty < item.quantity:
                    raise ValueError(f'物料 {mat.material_code} 冻结库存异常')
                
                # 实扣物理库存与解除冻结
                mat.stock_qty -= item.quantity
                mat.frozen_qty -= item.quantity
            
            # 状态流转为已出库
            order.status = 2
            
        db.session.commit()
        return jsonify({'code': 200, 'msg': '出库核销完成'})
        
    except ValueError as val_err:
        db.session.rollback()
        return jsonify({'code': 422, 'msg': str(val_err)}), 422
    except Exception as e:
        db.session.rollback()
        return jsonify({'code': 500, 'msg': '系统异常，操作已回滚'}), 500
