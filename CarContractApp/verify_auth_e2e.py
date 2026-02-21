import requests
import json
import os

BASE_URL = "http://127.0.0.1:8000"

def test_full_flow():
    # 1. Register a Buyer
    print("1. Registering Buyer...")
    buyer_res = requests.post(
        f"{BASE_URL}/api/auth/signup",
        json={
            "email": "buyer.test@example.com",
            "password": "password123",
            "full_name": "Test Buyer",
            "role": "buyer"
        }
    )
    # Ignore if already exists, just login
    print("Buyer Signup Response:", buyer_res.status_code)
    
    buyer_login = requests.post(
        f"{BASE_URL}/api/auth/login",
        data={"username": "buyer.test@example.com", "password": "password123"}
    )
    buyer_token = buyer_login.json().get("access_token")
    buyer_headers = {"Authorization": f"Bearer {buyer_token}"}
    print("Buyer logged in.")

    # 2. Register a Dealer
    print("2. Registering Dealer...")
    dealer_res = requests.post(
        f"{BASE_URL}/api/auth/signup",
        json={
            "email": "dealer.test@example.com",
            "password": "password123",
            "full_name": "Test Dealer",
            "role": "dealer"
        }
    )
    print("Dealer Signup Response:", dealer_res.status_code)

    dealer_login = requests.post(
        f"{BASE_URL}/api/auth/login",
        data={"username": "dealer.test@example.com", "password": "password123"}
    )
    dealer_token = dealer_login.json().get("access_token")
    dealer_headers = {"Authorization": f"Bearer {dealer_token}"}
    print("Dealer logged in.")
    
    # Get Dealer ID
    dealer_me = requests.get(f"{BASE_URL}/api/auth/me", headers=dealer_headers).json()
    dealer_id = dealer_me.get("id")

    # 3. Create a Dummy PDF and Upload it
    print("3. Uploading Contract...")
    dummy_pdf_path = "test_contract.pdf"
    with open(dummy_pdf_path, "wb") as f:
        f.write(b"%PDF-1.4\n1 0 obj\n<< /Type /Catalog ... >>\nendobj\n")
    
    with open(dummy_pdf_path, "rb") as f:
        upload_res = requests.post(
            f"{BASE_URL}/contracts/upload",
            headers=buyer_headers,
            files={"file": ("test_contract.pdf", f, "application/pdf")}
        )
    print("Upload Response:", upload_res.status_code, upload_res.text)
    
    if upload_res.status_code in [200, 201]:
        contract_id = upload_res.json().get("id")
        print(f"Contract ID: {contract_id}")
    else:
        print("Upload failed, skipping analysis.")
        contract_id = None
        
    # Cleanup dummy PDF
    if os.path.exists(dummy_pdf_path):
        os.remove(dummy_pdf_path)

    # 4. Create a conversation from Buyer to Dealer
    print("4. Creating Conversation...")
    conv_res = requests.post(
        f"{BASE_URL}/api/messaging/conversations",
        headers=buyer_headers,
        json={
            "dealer_id": dealer_id,
            "contract_id": contract_id,
            "subject": "Question about my contract"
        }
    )
    print("Conversation Create Response:", conv_res.status_code)
    
    if conv_res.status_code == 200:
        conv_id = conv_res.json().get("id")
        
        # 5. Send a message
        print("5. Sending Message...")
        msg_res = requests.post(
            f"{BASE_URL}/api/messaging/conversations/{conv_id}/messages",
            headers=buyer_headers,
            json={"content": "Hi, I have a question about the disposition fee."}
        )
        print("Message Send Response:", msg_res.status_code)
        
        # 6. Dealer gets conversations
        print("6. Dealer checking messages...")
        dealer_convs = requests.get(
            f"{BASE_URL}/api/messaging/conversations",
            headers=dealer_headers
        )
        print("Dealer Convs:", len(dealer_convs.json()))
        
    print("E2E Test Completed.")

if __name__ == "__main__":
    try:
        test_full_flow()
    except Exception as e:
        print(f"Test failed with exception: {e}")
