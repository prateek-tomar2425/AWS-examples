#!/bin/bash

JIRA_DOMAIN="fetch-pet.atlassian.net"
ISSUE_ID="FDD-12613"

EC2_USER="ubuntu"
EC2_IP="10.23.11.50"
LOCAL_ATTACHMENT_PATH=/mnt/c/Users/prateek.tomar/Downloads/
REMOTE_UTILITY_PATH=/path/on/ec2/for/utility
SSH_KEY_PATH="qa2-migration-box.pem"
OUTPUT_FILE_NAME=output_file_name_here

AUTH="Basic cHJhdGVlay50b21hckBnbG9iYWxsb2dpYy5jb206QVRBVFQzeEZmR0YwQTFhbV8xb1dfaktNS3owZ2dfbzB0aEtEZjRQYnZrM1ZCNzBlZGQtbmdYbFdXOWVFMDJ6dF9zM2Y2NTlibElFeG0tQWVQZEVQMW5oNTZtdlRWTlRiTkw5cUtWZGhwU0Q0QVBadG1hclJZTTJoLVA1U0tQTW55NEROSkpnTmZLNENBZEt4aVhVMzh1QkZNZF82RFE5a0VzU2tLZzd1QTgyWWhmam9kUTBZMzFFPTgwRjY1Q0Uy"

API_URL="https://$JIRA_DOMAIN/rest/api/2/issue/$ISSUE_ID?fields=attachment"

response=$(curl -H "authorization: $AUTH" \
     -H "Content-Type: application/json" \
     "$API_URL" | jq -r '.fields.attachment[] | "\(.content)|\(.filename)"')
file=$(curl -H "authorization: $AUTH" \
     -H "Content-Type: application/json" \
     "$API_URL" | jq -r '.fields.attachment[0,1].filename')

# Check if attachments are available
if [ -z "$response" ]; then
    echo "No attachments found for issue $ISSUE_ID."
    exit 1
fi

# Download each attachment
while IFS='|' read -r url filename; do
    echo "Downloading $filename..."
    curl -s -L -o "$filename" -H "Authorization: Basic $AUTH" "$url"
done <<< "$response"

echo "Download complete."

# EC2 part:

ssh -i $SSH_KEY_PATH ubuntu@10.23.11.50 "mkdir -p $ISSUE_ID"

while IFS=' ' read fileno; do
    scp -i $SSH_KEY_PATH -r $LOCAL_ATTACHMENT_PATH$fileno $EC2_USER@$EC2_IP:~/$ISSUE_ID/
done <<< "$file"



# ssh -i $SSH_KEY_PATH $EC2_USER@$EC2_IP "cd $ISSUE_ID && java -jar $REMOTE_UTILITY_PATH/your_java_utility.jar"

# scp -i $SSH_KEY_PATH $EC2_USER@$EC2_IP:~/$ISSUE_ID/$OUTPUT_FILE_NAME ./local_destination/

echo "Process complete."