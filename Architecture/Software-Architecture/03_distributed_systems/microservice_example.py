# Microservice Skeleton (Python + Flask)
from flask import Flask, request, jsonify

app = Flask(__name__)

# Service A: Orders
@app.route("/orders", methods=["POST"])
def create_order():
    order = request.json
    # Here you might call Service B (Billing)
    return jsonify({"status": "order created", "order": order})

if __name__ == "__main__":
    app.run(port=5000)
