#!/bin/bash
errcho(){ >&2 echo $@; }

errcho "Starting in $PWD"

echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
apk add terraform --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main

#curl -o terraform.zip https://releases.hashicorp.com/terraform/0.14.7/terraform_0.14.7_linux_amd64.zip
#errcho "Downloaded Terraform"
curl -o main.tf https://raw.githubusercontent.com/ralacher/azure-demos/main/app-services/azure-ad-auth/main.tf
errcho "Downloaded Terraform configuration file"
curl -L -o angular.zip https://github.com/ralacher/azure-demos/releases/download/azure-ad-angular-aspnetcore/angular.zip
errcho "Downloaded Angular site"
#unzip terraform.zip
#mv terraform /bin/terraform
#errcho "Unzipped Terraform"
unzip angular.zip
errcho "Unzipped Angular"

errcho "Getting tenant and domain"
tenantId=$(az account show --query homeTenantId | sed 's|"||g')
#domainId=$(az ad user list | grep onmicrosoft.com | head -n 1 | cut -d '@' -f 2 | cut -d '"' -f 1)
domainId="robertlachergmail.onmicrosoft.com"
errcho "Tenant $tenantId Domain $domainId"

# Run Terraform and create infrastructure
errcho "Initializing Terraform"
export TF_LOG=TRACE
terraform init
terraform init
terraform init
export TF_VAR_name=$AppName
export TF_VAR_location=$Location
export TF_VAR_tenant=$tenantId
export TF_VAR_domain=$domainId
errcho "Running Terraform with $TF_VAR_name, $TF_VAR_location, $TF_VAR_tenant, $TF_VAR_domain"
terraform apply -auto-approve -no-color -var name="$AppName" -var location="$Location" -var tenant="$tenantId" -var domain="$domainId"

errcho "Getting Terraform outputs"
clientId=$(terraform output -raw clientId)
redirectUri=$(terraform output -raw redirectUri)
resourceScope=$(terraform output -raw resourceScope)
resourceUri=$(terraform output -raw resourceUri)
blobUrl=$(terraform output -raw blobUrl)
blobAccount=$(terraform output -raw blobAccount)

errcho "Downloading authentication configuration"
cd angular11-sample-app
curl -o auth-config.json https://raw.githubusercontent.com/Azure-Samples/ms-identity-javascript-angular-spa-dotnetcore-webapi-roles-groups/master/chapter1/TodoListSPA/src/app/auth-config.json
python3 -c "import sys,json; j = json.load(open('auth-config.json', 'r')); j['credentials']['clientId'] = sys.argv[1]; j['credentials']['tenantId'] = sys.argv[2]; j['configuration']['redirectUri'] = sys.argv[3]; j['configuration']['postLogoutRedirectUri'] = sys.argv[3]; j['resources']['todoListApi']['resourceUri'] = sys.argv[4]; j['resources']['todoListApi']['resourceScopes'][0] = sys.argv[5]; json.dump(json.dumps(json.dumps(j)), open('tmp.json', 'w'))" $clientId $tenantId $redirectUri $resourceUri $resourceScope
sed -i 's#module.exports = JSON.parse(.*#module.exports = JSON.parse('"$(cat tmp.json)"');#g' main.js
sed -i 's|""{|"{|g' main.js
sed -i 's|}""|}"|g' main.js

errcho "Uploading website"
cd ..
az storage blob upload-batch -d '$web' --account-name $blobAccount -s angular11-sample-app