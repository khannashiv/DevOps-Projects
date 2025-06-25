## Azure AKS & Application Gateway Hands-on Command Reference

### 1. Azure Account & Resource Group Setup

```sh
# List all Azure accounts in a table format
az account list --output table

# Log out of Azure
az logout

# Log in to Azure
az login

# Create a resource group for AKS
az group create --name AKS_RG --location centralindia

# List all available Azure locations
az account list-locations

# Filter Azure locations for those containing 'india'
az account list-locations | grep india
```

### 2. AKS Cluster Provisioning

```sh
# List available VM sizes in the specified location
az vm list-sizes --location centralindia --out table

# Create an AKS cluster with 2 nodes and SSH keys
az aks create --resource-group AKS_RG --name AKS_Demo --node-count 2 --generate-ssh-keys --node-vm-size Standard_D2_v3

# Get AKS cluster credentials for kubectl
az aks get-credentials --resource-group AKS_RG --name AKS_Demo

# List nodes in the AKS cluster
kubectl get nodes

# Show the current kubectl context
kubectl config current-context
```

### 3. Virtual Network & Subnet Management

```sh
# List subnets in the AKS virtual network
az network vnet subnet list --resource-group MC_AKS_RG_AKS_Demo_centralindia --vnet-name aks-vnet-13452974 --output table

# Create a subnet for Application Gateway
az network vnet subnet create \
    --resource-group MC_AKS_RG_AKS_Demo_centralindia \
    --vnet-name aks-vnet-13452974 \
    --name appgw-subnet \
    --address-prefix 10.225.0.0/20
```

### 4. Public IP for Application Gateway

```sh
# Create a static public IP for Application Gateway
az network public-ip create \
    --resource-group MC_AKS_RG_AKS_Demo_centralindia \
    --name appgw-public-ip \
    --allocation-method Static \
    --sku Standard
```

### 5. Network & Public IP Information

```sh
# List subnets again to verify
az network vnet subnet list --resource-group MC_AKS_RG_AKS_Demo_centralindia --vnet-name aks-vnet-13452974 --output table

# Show the VNet resource ID
az network vnet show \
    --name aks-vnet-13452974 \
    --resource-group MC_AKS_RG_AKS_Demo_centralindia \
    --query id --output tsv

# Show the public IP resource ID
az network public-ip show \
    --name appgw-public-ip \
    --resource-group MC_AKS_RG_AKS_Demo_centralindia \
    --query id --output tsv
```

### 6. Deploy Application Gateway using Bicep

```sh
# Deploy Application Gateway using a Bicep template
az deployment group create \
    --resource-group MC_AKS_RG_AKS_Demo_centralindia \
    --template-file appGateway.bicep \
    --parameters \
        vnetName="aks-vnet-13452974" \
        vnetResourceGroup="MC_AKS_RG_AKS_Demo_centralindia" \
        publicIpName="appgw-public-ip" \
        publicIpResourceGroup="MC_AKS_RG_AKS_Demo_centralindia"
```

### 7. Managed Identity for AGIC

```sh
# Create a managed identity for AGIC
az identity create \
    --name agic-identity \
    --resource-group MC_AKS_RG_AKS_Demo_centralindia
```

### 8. Application Gateway & Role Assignment

```sh
# Get Application Gateway resource ID
APPGW_ID=$(az network application-gateway show \
    --name my-app-gw \
    --resource-group MC_AKS_RG_AKS_Demo_centralindia \
    --query id -o tsv)
echo $APPGW_ID

# Assign Contributor role to the managed identity for Application Gateway
az role assignment create \
    --assignee d1a309d1-04b8-4de0-a6c2-8420bee439b6 \
    --scope "subscriptions/0ba4f41e-5d59-49c5-8c3e-2908eb546d77/resourceGroups/MC_AKS_RG_AKS_Demo_centralindia/providers/Microsoft.Network/applicationGateways/my-app-gw" \
    --role "Contributor"
```

### 9. Identity & Role Verification

```sh
# Show the managed identity resource ID
az identity show \
    --name agic-identity \
    --resource-group MC_AKS_RG_AKS_Demo_centralindia \
    --query id -o tsv

# Show the Azure tenant ID
az account show --query tenantId -o tsv

# List role assignments for the managed identity
az role assignment list \
    --assignee d1a309d1-04b8-4de0-a6c2-8420bee439b6 \
    --scope "subscriptions/0ba4f41e-5d59-49c5-8c3e-2908eb546d77/resourceGroups/MC_AKS_RG_AKS_Demo_centralindia/providers/Microsoft.Network/applicationGateways/my-app-gw" \
    --output table
```

### 10. AKS Node Pool & VMSS Operations

```sh
# Get the AKS agent pool name
az aks show \
    --resource-group <correct-RG-name> \
    --name AKS_Demo \
    --query agentPoolProfiles[0].name

# Update all instances in the VMSS (Virtual Machine Scale Set)
az vmss update-instances \
    --resource-group MC_AKS_RG_AKS_Demo_centralindia \
    --name aks-nodepool1-36146003-vmss \
    --instance-ids "*"
```

### 11. Kubernetes & Helm Operations

```sh
# Get environment variables from a specific pod
kubectl get pod ingress-azure-7546457476-zl9fv -o jsonpath='{.spec.containers[0].env}'

# Get pod YAML and filter for environment variables
kubectl get pod ingress-azure-7546457476-zl9fv -o yaml | grep -A20 "env:"

# Uninstall the ingress-azure Helm release
helm uninstall ingress-azure --no-hooks --timeout 60s

# Delete pods with the label app=ingress-azure
kubectl delete pod -l app=ingress-azure
```

### 12. Git & Docker Operations

```sh
# Fetch all tags from the remote repository
git fetch --tags

# List all git tags
git tag --list

# Build a custom Docker image for AGIC
docker build \
    --build-arg BUILD_BASE_IMAGE=golang:1.23.3-bookworm \
    --build-arg BINARY_BASE_IMAGE=ubuntu:22.04 \
    -t khannashiv/agic:custom-msi .

# Push the custom Docker image to Docker Hub
docker push khannashiv/agic:custom-msi
```

### 13. Helm Install & Debugging

```sh
# Uninstall ingress-azure Helm release (if needed)
helm uninstall ingress-azure --no-hooks --timeout 60s

# Install ingress-azure Helm chart with custom values
helm install ingress-azure . -f ../../../agic-values.yaml

# View logs for ingress-azure pods and filter for 'authorizer'
kubectl logs -l app=ingress-azure | grep -i authorizer

# Exec into the ingress-azure deployment and check version
kubectl exec -it deployment/ingress-azure -- /app/ingress-azure --version
```

### 14. Clean Up Resources

```sh
# Delete the AKS cluster and associated resources
az aks delete --resource-group AKS_RG --name AKS_Demo --yes --no-wait
# Delete the Application Gateway
az network application-gateway delete --resource-group MC_AKS_RG_AKS_Demo_centralindia --name my-app-gw
```
### NOTE : In this demo, we have created Application gateway on azure using Bicep template.