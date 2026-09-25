# 示意草稿：查询映射
STATUS_TEXT = {
    'PENDING': '待审核',
    'STORED': '已入库',
    'PICKED': '已取件',
    'EXCEPTION': '异常'
}

def to_view(parcel):
    slot = parcel.active_slot()
    return {
        'trackingNo': parcel.tracking_no,
        'receiverName': parcel.receiver_name,
        'phone4': parcel.receiver_phone4,
        'status': STATUS_TEXT.get(parcel.status, '未知'),
        'slotCode': slot.slot.code if slot else None
    }
