# Modular Monolith Example (Python)
# Three modules: Billing, Orders, Inventory

# --- Billing Module ---
def bill_order(order):
    print(f"Billing order {order['id']}, amount: {order['amount']}")

# --- Orders Module ---
def create_order(order_id, quantity, amount):
    order = {"id": order_id, "quantity": quantity, "amount": amount}
    print(f"Order created: {order}")
    bill_order(order)
    return order

# --- Inventory Module ---
def reserve_inventory(order):
    print(f"Reserved {order['quantity']} items for order {order['id']}")

# --- Application Flow ---
order = create_order(1, 5, 100)
reserve_inventory(order)
