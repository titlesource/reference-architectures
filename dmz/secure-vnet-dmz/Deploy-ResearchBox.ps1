# Current virtual machine sizes and pricing
# https://azure.microsoft.com/en-us/pricing/details/virtual-machines/windows/
# Deploy_ResearchBox.ps1
#
param(
  [Parameter(Mandatory=$true)]
  $SubscriptionId,
  [Parameter(Mandatory=$false)]
  $Location = "East US 2"
)

$ErrorActionPreference = "Stop"

$buildingBlocksRootUriString = $env:TEMPLATE_ROOT_URI
if ($buildingBlocksRootUriString -eq $null) {
  $buildingBlocksRootUriString = "https://raw.githubusercontent.com/mspnp/template-building-blocks/v1.0.0/"
}

if (![System.Uri]::IsWellFormedUriString($buildingBlocksRootUriString, [System.UriKind]::Absolute)) {
  throw "Invalid value for TEMPLATE_ROOT_URI: $env:TEMPLATE_ROOT_URI"
}

Write-Host
Write-Host "Using $buildingBlocksRootUriString to locate templates"
Write-Host

$templateRootUri = New-Object System.Uri -ArgumentList @($buildingBlocksRootUriString)
$virtualNetworkTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vnet-n-subnet/azuredeploy.json")
$loadBalancerTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/loadBalancer-backend-n-vm/azuredeploy.json")
$multiVMsTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json")
$dmzTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/dmz/azuredeploy.json")
$vpnTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vpn-gateway-vpn-connection/azuredeploy.json")
$networkSecurityGroupsTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/networkSecurityGroups/azuredeploy.json")

$virtualNetworkParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters", "virtualNetwork.parameters.json")
$webSubnetLoadBalancerAndVMsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters", "loadBalancer-web-subnet.parameters.json")
$bizSubnetLoadBalancerAndVMsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters", "loadBalancer-biz-subnet.parameters.json")
$dataSubnetLoadBalancerAndVMsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters", "loadBalancer-data-subnet.parameters.json")
$mgmtSubnetVMsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters", "virtualMachines-mgmt-subnet.parameters.json")
$researchSubnetVMsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters", "virtualMachines-research-subnet.parameters.json")
$dmzParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters", "dmz.parameters.json")
$internetDmzParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters", "internet-dmz.parameters.json")
$vpnParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters", "vpn.parameters.json")
$networkSecurityGroupsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters", "networkSecurityGroups.parameters.json")

$networkResourceGroupName = "ts-public-dmz-network-rg"
$workloadResourceGroupName = "ts-public-dmz-wl-rg"

# Login to Azure and select your subscription
Login-AzureRmAccount -SubscriptionId $SubscriptionId | Out-Null

# Get the resource group
$networkResourceGroup = Get-AzureRmResourceGroup -Name $networkResourceGroupName -Location $Location
$workloadResourceGroup = Get-AzureRmResourceGroup -Name $workloadResourceGroupName -Location $Location

# This removes all the deployment audit records because the limit is 800 and we don't need 800 audit records (or any for that matter)
Get-AzureRmResourceGroupDeployment -ResourceGroupName $networkResourceGroupName | Remove-AzureRmResourceGroupDeployment
	
Write-Host "Deploying boxes in research subnet..."
New-AzureRmResourceGroupDeployment -Mode Incremental -Name "ts-research-vms-deployment" -ResourceGroupName $networkResourceGroup.ResourceGroupName `
    -TemplateUri $multiVMsTemplate.AbsoluteUri -TemplateParameterFile $researchSubnetVMsParametersFile
