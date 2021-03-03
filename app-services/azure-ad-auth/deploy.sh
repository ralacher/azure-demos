#!/bin/bash

mkdir -p /home/run
cp -r /mnt/azscripts/azscriptinput /home/run
cd /home/run

unzip terraform.zip
mv terraform /bin/terraform
unzip angular.zip

tenantId=$(az account show --query homeTenantId | sed 's|"||g')
#domainId=$(az ad user list | grep onmicrosoft.com | head -n 1 | cut -d '@' -f 2 | cut -d '"' -f 1)
domainId="robertlachergmail.onmicrosoft.com"

# Run Terraform and create infrastructure
terraform init
export TF_VAR_name=$AppName
export TF_VAR_location=$Location
export TF_VAR_tenant=$tenantId
export TF_VAR_domain=$domainId
terraform apply -auto-approve -no-color -no-input

clientId=$(terraform output -raw clientId)
redirectUri=$(terraform output -raw redirectUri)
resourceScope=$(terraform output -raw resourceScope)
resourceUri=$(terraform output -raw resourceUri)
blobUrl=$(terraform output -raw blobUrl)
blobAccount=$(terraform output -raw blobAccount)

mv auth-config.json angular-sample-app
cd angular11-sample-app
python3 -c "import sys,json; j = json.load(open('auth-config.json', 'r')); j['credentials']['clientId'] = sys.argv[1]; j['credentials']['tenantId'] = sys.argv[2]; j['configuration']['redirectUri'] = sys.argv[3]; j['configuration']['postLogoutRedirectUri'] = sys.argv[3]; j['resources']['todoListApi']['resourceUri'] = sys.argv[4]; j['resources']['todoListApi']['resourceScopes'][0] = sys.argv[5]; json.dump(json.dumps(json.dumps(j)), open('tmp.json', 'w'))" $clientId $tenantId $redirectUri $resourceUri $resourceScope
sed -i 's#module.exports = JSON.parse(.*#module.exports = JSON.parse('"$(cat tmp.json)"');#g' main.js
sed -i 's|""{|"{|g' main.js
sed -i 's|}""|}"|g' main.js

cd ..
az storage blob upload-batch -d '$web' --account-name $blobAccount -s angular11-sample-app