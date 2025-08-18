import boto3
import json
import base64
import os
from datetime import datetime
from boto3.dynamodb.conditions import Key
from botocore.exceptions import BotoCoreError, ClientError

# Initialize AWS Clients
dynamodb = boto3.resource("dynamodb")
kms_client = boto3.client("kms")

# Environment Variables
table_name = os.getenv("DYNAMODB_TABLE", "otp_main")
kms_key_id = os.getenv("KMS_KEY_ID")

# Initialize DynamoDB Table
table = dynamodb.Table(table_name)

# Common headers for all responses
CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "OPTIONS,POST",
    "Access-Control-Allow-Headers": "Content-Type",
}

def create_response(status_code, message):
    """Helper function to create consistent response objects"""
    return {
        'statusCode': status_code,
        'headers': CORS_HEADERS,
        'body': json.dumps({'message': message}, ensure_ascii=False)
    }

def decrypt_otp(encrypted_otp):
    """Decrypts the OTP using AWS KMS."""
    try:
        decrypted = kms_client.decrypt(CiphertextBlob=base64.b64decode(encrypted_otp))
        decrypted_otp = decrypted["Plaintext"].decode("utf-8")
        print(f"Decrypted OTP: {decrypted_otp}")  # Debug log
        return decrypted_otp
    except (BotoCoreError, ClientError) as e:
        print(f"KMS Decryption Error: {e}")
        return None

def verify_otp(user_id, otp_entered):
    """Verifies the OTP entered by the user."""
    try:
        print(f"Fetching OTP for user_id: {user_id}")
        response = table.query(
            KeyConditionExpression=Key("user_id").eq(user_id),
            ScanIndexForward=False,
            Limit=1  # Fetch the latest OTP
        )
        print(f"DynamoDB Response: {response}")  # Debug log

        if "Items" not in response or not response["Items"]:
            # OTP not found or expired
            return create_response(400, "You have reached time limit. Please request a new OTP to continue")  

        item = response["Items"][0]
        decrypted_otp = decrypt_otp(item["otp_code"])

        if not decrypted_otp:
            return create_response(500, "Failed to decrypt OTP")

        if decrypted_otp != otp_entered:
            remaining_attempts = int(item.get("attempts", 3)) - 1
            table.update_item(
                Key={"user_id": user_id, "creation_timestamp": item["creation_timestamp"]},
                UpdateExpression="SET attempts = :attempts",
                ExpressionAttributeValues={":attempts": remaining_attempts}
            )
            
            if remaining_attempts <= 0:
                print(f"Deleting expired OTP for user_id: {user_id} and creation_timestamp: {item.get('creation_timestamp')}")
                table.delete_item(
                    Key={
                        "user_id": user_id,
                        "creation_timestamp": item["creation_timestamp"]
                    }
                )
                # OTP expired or max attempts reached
                return create_response(400, "Too many incorrect attempts. Please request a new OTP to continue") 
            
            return create_response(400, "Invalid OTP")

        # Check expiration time
        expiration_time = datetime.fromisoformat(item["expiration_timestamp"])
        if datetime.utcnow() > expiration_time:
            print(f"Deleting expired OTP for user_id: {user_id} and creation_timestamp: {item.get('creation_timestamp')}")
            table.delete_item(
                Key={
                    "user_id": user_id,
                    "creation_timestamp": item["creation_timestamp"]
                }
            )
            return create_response(400, "OTP expired")

        # Delete OTP after successful verification
        print(f"Deleting successfully verified OTP for user_id: {user_id} and creation_timestamp: {item.get('creation_timestamp')}")
        table.delete_item(
            Key={
                "user_id": user_id,
                "creation_timestamp": item["creation_timestamp"]
            }
        )
        
        return create_response(200, "OTP verified successfully")

    except Exception as e:
        print(f"Error in verify_otp: {str(e)}")
        import traceback
        print(traceback.format_exc())
        return create_response(500, "Internal server error")

def lambda_handler(event, context):
    try:
        # Check if event contains a body
        if 'body' not in event:
            print("Error: 'body' not found in event: ", event)
            return create_response(400, "Missing request body")
        
        # Handle empty body
        if event['body'] is None:
            print("Error: 'body' is None")
            return create_response(400, "Empty request body")
        
        # Parse body based on its type
        try:
            body = event['body'] if isinstance(event['body'], dict) else json.loads(event['body'])
        except json.JSONDecodeError as e:
            print(f"Error parsing JSON body: {e}, Body: {event['body']}")
            return create_response(400, "Invalid JSON in request body")
        
        # Extract and validate required fields
        user_id = body.get("user_id")
        otp_code = body.get("otp_code")

        if not user_id or not otp_code:
            missing_fields = []
            if not user_id: missing_fields.append("user_id")
            if not otp_code: missing_fields.append("otp_code")
            return create_response(400, f"Missing required fields: {', '.join(missing_fields)}")

        return verify_otp(user_id, otp_code)
        
    except Exception as e:
        print(f"Lambda Handler Error: {str(e)}")
        import traceback
        print(traceback.format_exc())
        return create_response(500, "Internal server error")