#!/bin/bash

echo $1 > params.json

# Cloudant credentials and the _id of the attachment/document to download.
CLOUDANT_ACCOUNT=`cat params.json | jq -r .CLOUDANT_ACCOUNT`
CLOUDANT_TOKEN=`cat params.json | jq -r .CLOUDANT_TOKEN`
# CLOUDANT_USERNAME=`cat params.json | jq -r '.CLOUDANT_USERNAME'`
# CLOUDANT_PASSWORD=`cat params.json | jq -r '.CLOUDANT_PASSWORD'`
CLOUDANT_AUDITED_DATABASE=`cat params.json | jq -r '.CLOUDANT_AUDITED_DATABASE'`
IMAGE_ID=`cat params.json | jq -r '.IMAGE_ID'`

# Download the revision from Cloudant.
# curl -s -X GET -o imgInfo "https://$CLOUDANT_USERNAME:$CLOUDANT_PASSWORD@$CLOUDANT_USERNAME.cloudant.com/$CLOUDANT_AUDITED_DATABASE/$IMAGE_ID"
curl -s -X GET -H "Authorization: Bearer $CLOUDANT_TOKEN" -o imgInfo "https://$CLOUDANT_ACCOUNT.cloudant.com/$CLOUDANT_AUDITED_DATABASE/$IMAGE_ID"
EMAIL=`cat imgInfo | jq -r '.email'`
TOACCOUNT=`cat imgInfo | jq -r '.toAccount'`
AMOUNT=`cat imgInfo | jq -r '.amount'`
ATTACHMENT_NAME=`cat imgInfo | jq -r '.attachmentName'`
TIMESTAMP=`cat imgInfo | jq -r '.timestamp'`

# Download the image from Cloudant.
curl -s -X GET -H "Authorization: Bearer $CLOUDANT_TOKEN" -o imgData "https://$CLOUDANT_ACCOUNT.cloudant.com/$CLOUDANT_AUDITED_DATABASE/$IMAGE_ID/$ATTACHMENT_NAME?attachments=true&include_docs=true"

# Extract the account number and routing number as text by parsing for MICR font values.
tesseract imgData imgData.txt -l mcr2 >/dev/null 2>&1

# This matcher works with two of the checks we're using as samples for the PoC.
declare -a values=($(grep -Eo "\[[[0-9]+" imgData.txt.txt | sed -e 's/\[//g'))

# Extract the two values.
ROUTING=${values[0]}
ACCOUNT=${values[1]}
PLAINTEXT=`cat imgData.txt.txt | base64`
PLAINTEXT=`echo "$PLAINTEXT" | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g'`

# Return JSON formatted values.
echo '{ "result": {"email": "'$EMAIL'", "timestamp": "'$TIMESTAMP'", "toAccount": "'$TOACCOUNT'", "amount": "'$AMOUNT'", "routing": "'$ROUTING'", "account": "'$ACCOUNT'", "plaintext": "'$PLAINTEXT'", "attachmentname": "'$ATTACHMENT_NAME'" } }'
