#!/bin/bash
mkdir deploy
cd deploy
curl -o terraform.zip https://releases.hashicorp.com/terraform/0.14.7/terraform_0.14.7_linux_amd64.zip
echo Downloaded Terraform
curl -o main.tf https://raw.githubusercontent.com/ralacher/azure-demos/main/app-services/azure-ad-auth/main.tf
echo Downloaded Terraform configuration file
curl -L -o angular.zip https://github.com/ralacher/azure-demos/releases/download/azure-ad-angular-aspnetcore/angular.zip
echo Downloaded Angular site
unzip terraform.zip
echo Unzipped Terraform
unzip angular.zip
echo Unzipped Angular

echo Getting tenant and domain
tenantId=$(az account show --query homeTenantId | sed 's|"||g')
domainId=$(az ad signed-in-user show --query userPrincipalName | cut -d '@' -f 2 | sed 's|"||g')

# Run Terraform and create infrastructure
echo Initializing Terraform
./terraform init
export TF_VAR_name=$AppName
export TF_VAR_location=$Location
export TF_VAR_tenant=$tenantId
export TF_VAR_domain=$domainId
echo Running Terraform
./terraform apply -auto-approve -no-color -var name=$AppName -var location=$Location -var tenant=$tenantId -var domain=$domainId

echo Getting Terraform outputs
clientId=$(./terraform output -raw clientId)
redirectUri=$(./terraform output -raw redirectUri)
resourceScope=$(./terraform output -raw resourceScope)
resourceUri=$(./terraform output -raw resourceUri)
blobUrl=$(./terraform output -raw blobUrl)
blobAccount=$(./terraform output -raw blobAccount)

echo Downloading authentication configuration
cd angular11-sample-app
curl -o auth-config.json https://raw.githubusercontent.com/Azure-Samples/ms-identity-javascript-angular-spa-dotnetcore-webapi-roles-groups/master/chapter1/TodoListSPA/src/app/auth-config.json
python3 -c "import sys,json; j = json.load(open('auth-config.json', 'r')); j['credentials']['clientId'] = sys.argv[1]; j['credentials']['tenantId'] = sys.argv[2]; j['configuration']['redirectUri'] = sys.argv[3]; j['configuration']['postLogoutRedirectUri'] = sys.argv[3]; j['resources']['todoListApi']['resourceUri'] = sys.argv[4]; j['resources']['todoListApi']['resourceScopes'][0] = sys.argv[5]; json.dump(json.dumps(json.dumps(j)), open('tmp.json', 'w'))" $clientId $tenantId $redirectUri $resourceUri $resourceScope
sed -i 's#module.exports = JSON.parse(.*#module.exports = JSON.parse('"$(cat tmp.json)"');#g' main.js
sed -i 's|""{|"{|g' main.js
sed -i 's|}""|}"|g' main.js

echo Uploading website
cd ..
az storage blob upload-batch -d '$web' --account-name $blobAccount -s angular11-sample-app