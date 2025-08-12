from flask import Flask, request, jsonify
import random
import time
import threading
import requests

app = Flask(__name__)

import os
POCKETBASE_URL = os.getenv("POCKETBASE_URL", "http://127.0.0.1:8090")
ROBOT_USER_EMAIL = "mashraf3@emich.edu"
ROBOT_USER_PASSWORD = "may42005"

robot_deliveries = {}
robot_id = "delivery_robot_001"

pb_robot_token = None

def authenticate_pocketbase():
    global pb_robot_token
    auth_url = f"{POCKETBASE_URL}/api/collections/users/auth-with-password"
    payload = {
        "identity": ROBOT_USER_EMAIL,
        "password": ROBOT_USER_PASSWORD
    }
    
    print(f"[PB Auth Debug] Using User: {ROBOT_USER_EMAIL}") 
    
    try:
        response = requests.post(auth_url, json=payload)
        response.raise_for_status()
        token = response.json()['token']
        pb_robot_token = token
        print(f"[PB Auth] Successfully authenticated with PocketBase as robot user. Token: {token[:10]}...")
    except requests.exceptions.RequestException as e:
        print(f"[PB Auth] Error authenticating with PocketBase as robot user: {e}")
        pb_robot_token = None

def update_pocketbase_order_status(order_id, status, pin=None):
    global pb_robot_token

    if not pb_robot_token:
        print("[PB API] No robot token. Attempting re-authentication...")
        authenticate_pocketbase()
        if not pb_robot_token:
            print("[PB API] Failed to get robot token. Cannot update PocketBase.")
            return False

    update_url = f"{POCKETBASE_URL}/api/collections/orders/records/{order_id}"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {pb_robot_token}"
    }
    payload = {"status": status}
    if pin:
        payload["pin"] = pin
    
    try:
        response = requests.patch(update_url, headers=headers, json=payload)
        response.raise_for_status()
        print(f"[PB API] Order {order_id} status updated to '{status}' in PocketBase.")
        return True
    except requests.exceptions.HTTPError as e:
        print(f"[PB API] HTTP Error updating order {order_id}: {e.response.text}")
        if e.response.status_code == 401:
            print("[PB API] Robot user token expired/invalid. Re-authenticating...")
            authenticate_pocketbase()
        return False
    except requests.exceptions.RequestException as e:
        print(f"[PB API] Network Error updating order {order_id}: {e}")
        return False

def simulate_delivery_process(order_id):
    print(f"\n[ROBOT - Order {order_id}] Starting delivery simulation...")
    current_delivery = robot_deliveries.get(order_id)
    if not current_delivery:
        print(f"[ROBOT - Order {order_id}] Error: Delivery not found in robot_deliveries.")
        return

    print(f"[ROBOT - Order {order_id}] Package collected. Changing status to 'delivery_started'.")
    current_delivery['status'] = 'delivery_started'
    update_pocketbase_order_status(order_id, 'delivery_started')

    time.sleep(5) 

    print(f"[ROBOT - Order {order_id}] Arrived at destination. Generating PIN.")
    generated_pin = ''.join(random.choices('0123456789', k=4))
    current_delivery['status'] = 'arrived'
    current_delivery['pin'] = generated_pin
    print(f"[ROBOT - Order {order_id}] Displaying PIN: {generated_pin}")
    update_pocketbase_order_status(order_id, 'arrived', pin=generated_pin)


@app.route('/robot_status', methods=['GET'])
def get_robot_status():
    return jsonify({
        'robot_id': robot_id,
        'active_deliveries': list(robot_deliveries.keys()),
        'current_time': time.ctime()
    })

@app.route('/dispatch_robot', methods=['POST'])
def dispatch_robot():
    data = request.get_json()
    order_id = data.get('order_id')
    user_id = data.get('user_id')

    if not order_id:
        return jsonify({'status': 'error', 'message': 'Missing order_id'}), 400

    if order_id in robot_deliveries:
        return jsonify({'status': 'info', 'message': 'Robot already handling this order.'}), 200

    robot_deliveries[order_id] = {
        'status': 'dispatched',
        'user_id': user_id,
        'pin': None
    }
    print(f"[SERVER] Robot {robot_id} dispatched for order {order_id}.")
    
    threading.Thread(target=simulate_delivery_process, args=(order_id,)).start()

    return jsonify({
        'status': 'success',
        'message': f'Robot {robot_id} dispatched for order {order_id}.'
    }), 200

@app.route('/verify_pin', methods=['POST'])
def verify_pin():
    data = request.get_json()
    order_id = data.get('order_id')
    entered_pin = data.get('pin')

    current_delivery = robot_deliveries.get(order_id)

    if not current_delivery:
        print(f"[SERVER] Verification failed: Order {order_id} not active with this robot.")
        return jsonify({'status': 'error', 'message': 'Order not active or invalid ID'}), 404

    if current_delivery['status'] != 'arrived':
        print(f"[SERVER] Verification failed: Robot not in 'arrived' state for order {order_id}.")
        return jsonify({'status': 'error', 'message': 'Robot not ready for pickup yet.'}), 400

    if current_delivery['pin'] == entered_pin:
        print(f"[SERVER] Access granted for order {order_id}. Opening box...")
        current_delivery['status'] = 'box_open'
        update_pocketbase_order_status(order_id, 'box_opened')
        return jsonify({'status': 'success', 'message': 'PIN verified. Robot box is opening.'}), 200
    else:
        print(f"[SERVER] Wrong PIN '{entered_pin}' for order {order_id}. Correct: {current_delivery['pin']}")
        return jsonify({'status': 'error', 'message': 'Invalid PIN'}), 401

@app.route('/package_received', methods=['POST'])
def package_received():
    data = request.get_json()
    order_id = data.get('order_id')

    current_delivery = robot_deliveries.get(order_id)

    if not current_delivery:
        print(f"[SERVER] Package received signal failed: Order {order_id} not active.")
        return jsonify({'status': 'error', 'message': 'Order not active or invalid ID'}), 404

    print(f"[SERVER] Package for order {order_id} marked as received by user. Robot completing delivery.")
    current_delivery['status'] = 'delivered'
    update_pocketbase_order_status(order_id, 'delivered')

    del robot_deliveries[order_id]
    print(f"[ROBOT - Order {order_id}] Delivery complete. Robot ready for next task.")

    return jsonify({'status': 'success', 'message': 'Package received confirmed. Delivery finalized.'}), 200

if __name__ == '__main__':
    authenticate_pocketbase()
    app.run(debug=True, port=5000)