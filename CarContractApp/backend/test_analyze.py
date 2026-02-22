import urllib.request
import urllib.error
import json

data = json.dumps({
    "text": "This is a mock contract. The seller agrees to sell the car to the buyer for $10,000.",
    "contract_type": "lease"
}).encode("utf-8")

req = urllib.request.Request(
    "http://127.0.0.1:8000/contracts/analyze-text",
    data=data,
    headers={"Content-Type": "application/json"}
)

try:
    with urllib.request.urlopen(req) as f:
        print(f.read().decode("utf-8"))
except urllib.error.HTTPError as e:
    print(f"HTTP Error: {e.code}")
    print(e.read().decode("utf-8"))
except Exception as e:
    print(f"Error: {e}")
