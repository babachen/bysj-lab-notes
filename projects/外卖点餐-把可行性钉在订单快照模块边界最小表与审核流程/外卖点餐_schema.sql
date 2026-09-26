-- 示意结构，不是可直接运行的完整建库脚本
user_account(id, username, password_hash, role, status, created_at)
merchant(id, name, audit_status, address, created_at)
dish(id, merchant_id, name, description, price, stock, sale_status, version)
orders(id, user_id, merchant_id, total_amount, status, created_at)
order_item(id, order_id, dish_id, dish_name_snapshot, unit_price_snapshot,
           quantity, line_amount)
order_status_log(id, order_id, from_status, to_status, operator_id, created_at)
