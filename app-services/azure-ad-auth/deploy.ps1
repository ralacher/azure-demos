Expand-Archive terraform_0.14.7_linux_amd64.zip -DestinationPath /bin -Force
Expand-Archive angular.zip -DestinationPath . -Force

$tenantId=(Get-AzContext).Tenant.Id
#domainId=$(az ad user list | grep onmicrosoft.com | head -n 1 | cut -d '@' -f 2 | cut -d '"' -f 1)
$domainId="robertlachergmail.onmicrosoft.com"

# Run Terraform and create infrastructure
chmod u+x /bin/terraform
terraform init -input=false
terraform init -input=false
$Env:TF_VAR_name=$Env:AppName
$Env:TF_VAR_location=$Env:Location
$Env:TF_VAR_tenant=$tenantId
$Env:TF_VAR_domain=$domainId
terraform apply -auto-approve -no-color -input=false

$clientId=$(terraform output -raw clientId)
$redirectUri=$(terraform output -raw redirectUri)
$resourceScope=$(terraform output -raw resourceScope)
$resourceUri=$(terraform output -raw resourceUri)
$blobUrl=$(terraform output -raw blobUrl)
$blobAccount=$(terraform output -raw blobAccount).String

mv auth-config.json angular11-sample-app
cd angular11-sample-app

apt update
apt install -y python3
python3 -c "import sys,json; j = json.load(open('auth-config.json', 'r')); j['credentials']['clientId'] = sys.argv[1]; j['credentials']['tenantId'] = sys.argv[2]; j['configuration']['redirectUri'] = sys.argv[3]; j['configuration']['postLogoutRedirectUri'] = sys.argv[3]; j['resources']['todoListApi']['resourceUri'] = sys.argv[4]; j['resources']['todoListApi']['resourceScopes'][0] = sys.argv[5]; json.dump(json.dumps(json.dumps(j)), open('tmp.json', 'w'))" $clientId $tenantId $redirectUri $resourceUri $resourceScope
sed -i 's/module.exports = JSON.parse(.*/module.exports = JSON.parse('"$(cat tmp.json)"');/g' main.js
sed -i 's/""{/"{/g' main.js
sed -i 's/}""/}"/g' main.js

cd ..
$context=New-AzStorageContext -StorageAccountName $blobAccount
Get-ChildItem -File -Recurse | Set-AzStorageBlobContent -Container '$web' -Context $context