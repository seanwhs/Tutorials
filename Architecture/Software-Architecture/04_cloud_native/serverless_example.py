# Serverless Handler (Python / AWS Lambda Style)

def lambda_handler(event, context):
    order = event.get("order")
    print(f"Received order: {order}")
    # Process order asynchronously
    return {"status": "processed", "order_id": order["id"]}

# Example invocation
event = {"order": {"id": 123, "quantity": 2}}
print(lambda_handler(event, None))
