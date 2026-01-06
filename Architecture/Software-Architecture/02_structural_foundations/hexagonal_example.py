# Hexagonal Architecture Example (Python)

# ----------------- Core Business Logic -----------------
class OrderService:
    def __init__(self, repository):
        self.repository = repository

    def create_order(self, order_data):
        # Business rule: cannot order negative quantity
        if order_data['quantity'] <= 0:
            raise ValueError("Quantity must be positive")
        return self.repository.save(order_data)

# ----------------- Adapters -----------------
class InMemoryOrderRepository:
    def __init__(self):
        self.orders = []

    def save(self, order_data):
        self.orders.append(order_data)
        return order_data

# ----------------- Ports / Interfaces -----------------
repository = InMemoryOrderRepository()
service = OrderService(repository)

order = service.create_order({"id": 1, "quantity": 3})
print(order)
