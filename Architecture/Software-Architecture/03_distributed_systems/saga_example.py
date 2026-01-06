# Simple Saga Flow (Python)

def payment_service(order):
    print(f"Processing payment for order {order['id']}")
    if order['amount'] > 1000:
        raise Exception("Payment failed")
    return True

def shipping_service(order):
    print(f"Shipping order {order['id']}")
    return True

def compensate_payment(order):
    print(f"Refunding order {order['id']}")

def process_order(order):
    try:
        payment_service(order)
        shipping_service(order)
        print("Order completed successfully")
    except Exception:
        compensate_payment(order)
        print("Order failed, compensation triggered")

# Example
process_order({"id": 1, "amount": 1500})
