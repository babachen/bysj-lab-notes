# 示意草稿：Service 层
@transaction.atomic
def verify_store(parcel_id, slot_id, operator):
    parcel = Parcel.objects.select_for_update().get(id=parcel_id)
    slot = StorageSlot.objects.select_for_update().get(id=slot_id)

    if parcel.status != 'PENDING':
        raise DomainError('parcel cannot be verified')
    if not slot.is_enabled or slot.used_count >= slot.capacity:
        raise DomainError('slot unavailable')

    ParcelSlot.objects.create(parcel=parcel, slot=slot)
    slot.used_count += 1
    slot.save(update_fields=['used_count'])
    parcel.status = 'STORED'
    parcel.verified_at = timezone.now()
    parcel.save(update_fields=['status', 'verified_at'])
    OperationLog.objects.create(
        parcel=parcel, operator=operator, action='VERIFY_STORE'
    )
