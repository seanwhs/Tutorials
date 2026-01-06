# Event Sourcing Example

event_log = []

def create_order(order_id, item):
    event = {"type": "OrderCreated", "order_id": order_id, "item": item}
    event_log.append(event)
    return event

def ship_order(order_id):
    event = {"type": "OrderShipped", "order_id": order_id}
    event_log.append(event)
    return event

# Replay events
create_order(1, "Book")
ship_order(1)

for e in event_log:
    print(e)
