# Minimal CQRS Example (Python)
from collections import defaultdict

# --- Write Model ---
orders = []

def create_order(order_id, item):
    orders.append({"id": order_id, "item": item})

# --- Read Model (Index) ---
orders_by_item = defaultdict(list)

def update_read_model():
    orders_by_item.clear()
    for order in orders:
        orders_by_item[order["item"]].append(order["id"])

# Usage
create_order(1, "Book")
create_order(2, "Pen")
update_read_model()

print(orders_by_item)
