# Agentic Orchestration Skeleton

def service_router(intent):
    if "order" in intent:
        return "Order Service"
    elif "payment" in intent:
        return "Payment Service"
    else:
        return "Unknown"

def agent_handle_request(user_input):
    service = service_router(user_input)
    print(f"Routing to {service}")
    # Here you would invoke the service API
    return service

agent_handle_request("Process my payment for order 123")
