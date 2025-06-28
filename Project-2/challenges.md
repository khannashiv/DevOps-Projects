## Common AKS Deployment Issues & Solutions

### 1. `vnet-subnet-id` is not a valid Azure resource ID

**Solution:**  
If using Git Bash, run:
```bash
export MSYS_NO_PATHCONV=1
```

---

### 2. Service CIDR Overlap Error

**Error:**  
```
(ServiceCidrOverlapExistingSubnetsCidr) The specified service CIDR 10.0.0.0/16 is conflicted with an existing subnet CIDR 10.0.0.0/24.
```
[See official docs](https://aka.ms/aks/servicecidroverlap)

**Solution:**  
Specify a non-overlapping service CIDR:
```bash
az aks create \
  -g Azure-CICD \
  -n myAKS \
  --node-vm-size Standard_B2s \
  --node-count 2 \
  --network-plugin azure \
  --vnet-subnet-id "$AKS_SUBNET_ID" \
  --enable-addons ingress-appgw \
  --appgw-name myAppGw \
  --appgw-subnet-id "$APPGW_SUBNET_ID" \
  --service-cidr 10.1.0.0/16 \
  --dns-service-ip 10.1.0.10 \
  --enable-oidc-issuer \
  --enable-workload-identity
```

---

### 3. Insufficient Regional vCPU Quota

**Error:**  
```
(ErrCode_InsufficientVCPUQuota) Insufficient regional vcpu quota left for location eastus. left regional vcpu quota 3, requested quota 4.
```
[How to increase quota](https://learn.microsoft.com/en-us/azure/quotas/view-quotas)

**Solution:**  
Use a smaller VM size or reduce node count:
```bash
az aks create \
  -g Azure-CICD \
  -n myAKS \
  --node-vm-size Standard_B1ms \
  --node-count 2 \
  ...
```
If you get a VM SKU error, try:
- Lowering node count to 1
- Using a VM size with more than 2 cores and 4GB memory (e.g., `Standard_B2ms`)

---

## Useful Commands & Tips

### `sed` Command for Image Replacement

**Problem:**  
Incorrect regex in:
```bash
sed -i "s/image:*/image: shivacr356.azurecr.io/$2:$3/g"
```
**Solution:**  
Use:
```bash
sed -i "s|image: .*|image: shivacr356.azurecr.io/$2:$3|g" k8s-specifications/$1-deployment.yaml
```
- `image: .*` matches any image line in Kubernetes YAML.

---

### Image Pull Errors from Private ACR

**Error:**  
```
failed to authorize: failed to fetch anonymous token: ... 401 Unauthorized
```

**Solution Steps:**
1. **Create a Kubernetes secret with correct ACR credentials:**
   ```bash
   kubectl create secret docker-registry regcred \
     --docker-server=shivacr356.azurecr.io \
     --docker-username=<username> \
     --docker-password=<password> \
     --docker-email=<email>
   ```
2. **Reference the secret in your deployment:**
   ```yaml
   spec:
     containers:
       - image: shivacr356.azurecr.io/vote-app:<tag>
         name: vote
     imagePullSecrets:
       - name: regcred
   ```
3. **Verify the secret exists in the correct namespace:**
   ```bash
   kubectl get secret regcred --namespace=default
   ```
4. **Check and decode the secret:**
   ```bash
   kubectl get secret regcred -o jsonpath="{.data.\.dockerconfigjson}" | base64 --decode
   ```
5. **Double-check ACR credentials:**
   ```bash
   az acr credential show --name shivacr356
   ```

---

## Reference Commands

- Check AKS private cluster status:
  ```bash
  az aks show -g Azure-CICD -n myAKS --query apiServerAccessProfile.enablePrivateCluster
  ```
- List public IPs:
  ```bash
  az network public-ip list -g Azure-CICD --output table
  ```
- List NSGs:
  ```bash
  az network nsg list --resource-group Azure-CICD --output table
  ```
- Get ArgoCD server service:
  ```bash
  kubectl get svc argocd-server -n argocd -o yaml
  ```

---

**Tip:**  
Always ensure your AKS cluster is authorized to pull from your private ACR and that all resource quotas and VM SKUs are compatible with your deployment.
Q : vnet-subnet-id is not a valid Azure resource ID.

Sol : export MSYS_NO_PATHCONV=1 ( Since I'm using Git-Bash.)


Q : While deploying AKS, I was getting following error i.e. The specified service CIDR 10.0.0.0/16 is conflicted with an existing subnet CIDR 10.0.0.0/24. Please see https://aka.ms/aks/servicecidroverlap for how to fix the error.
    & Code: ServiceCidrOverlapExistingSubnetsCidr

Shiv@LAPTOP-49SH4K4V MINGW64 /d/Git-repository/DevOps-Projects/Project-2 (main)
$ az aks create \
  -g Azure-CICD \
  -n myAKS \
  --node-vm-size Standard_B2s \
  --node-count 2 \
  --network-plugin azure \
  --vnet-subnet-id $AKS_SUBNET_ID \
  --enable-addons ingress-appgw \
  --appgw-name myAppGw \
  --appgw-subnet-id $APPGW_SUBNET_ID \
  --enable-oidc-issuer \
  --enable-workload-identity
docker_bridge_cidr is not a known attribute of class <class 'azure.mgmt.containerservice.v2025_03_01.models._models_py3.ContainerServiceNetworkProfile'> and will be ignored
(ServiceCidrOverlapExistingSubnetsCidr) The specified service CIDR 10.0.0.0/16 is conflicted with an existing subnet CIDR 10.0.0.0/24. Please see https://aka.ms/aks/servicecidroverlap for how to fix the error.
Code: ServiceCidrOverlapExistingSubnetsCidr
Message: The specified service CIDR 10.0.0.0/16 is conflicted with an existing subnet CIDR 10.0.0.0/24. Please see https://aka.ms/aks/servicecidroverlap for how to fix the error.
Target: networkProfile.serviceCIDR


Sol : 

az aks create \
  -g Azure-CICD \
  -n myAKS \
  --node-vm-size Standard_B2s \
  --node-count 2 \
  --network-plugin azure \
  --vnet-subnet-id "$AKS_SUBNET_ID" \
  --enable-addons ingress-appgw \
  --appgw-name myAppGw \
  --appgw-subnet-id "$APPGW_SUBNET_ID" \
  --service-cidr 10.1.0.0/16 \
  --dns-service-ip 10.1.0.10 \
  --docker-bridge-address 172.17.0.1/16 \
  --enable-oidc-issuer \
  --enable-workload-identity

Q : Shiv@LAPTOP-49SH4K4V MINGW64 /d/Git-repository/DevOps-Projects/Project-2 (main)

$ az aks create \
  -g Azure-CICD \
  -n myAKS \
  --node-vm-size Standard_B2s \
  --node-count 2 \
  --network-plugin azure \
  --vnet-subnet-id "$AKS_SUBNET_ID" \
  --enable-addons ingress-appgw \
  --appgw-name myAppGw \
  --appgw-subnet-id "$APPGW_SUBNET_ID" \
  --service-cidr 10.1.0.0/16 \
  --dns-service-ip 10.1.0.10 \
  --docker-bridge-address 172.17.0.1/16 \
  --enable-oidc-issuer \
  --enable-workload-identity
Option '--docker-bridge-address' has been deprecated and will be removed in a future release.
docker_bridge_cidr is not a known attribute of class <class 'azure.mgmt.containerservice.v2025_03_01.models._models_py3.ContainerServiceNetworkProfile'> and will be ignored
(ErrCode_InsufficientVCPUQuota) Insufficient regional vcpu quota left for location eastus. left regional vcpu quota 3, requested quota 4. If you want to increase the quota, please follow this instruction: https://learn.microsoft.com/en-us/azure/quotas/view-quotas. Surge nodes would also consume vcpu quota, please consider use smaller maxSurge or use maxUnavailable to proceed upgrade without surge nodes, details: aka.ms/aks/maxUnavailable.
Code: ErrCode_InsufficientVCPUQuota
Message: Insufficient regional vcpu quota left for location eastus. left regional vcpu quota 3, requested quota 4. If you want to increase the quota, please follow this instruction: https://learn.microsoft.com/en-us/azure/quotas/view-quotas. Surge nodes would also consume vcpu quota, please consider use smaller maxSurge or use maxUnavailable to proceed upgrade without surge nodes, details: aka.ms/aks/maxUnavailable.


Sol : 

az aks create \
  -g Azure-CICD \
  -n myAKS \
  --node-vm-size Standard_B1ms \
  --node-count 2 \
  --network-plugin azure \
  --vnet-subnet-id "$AKS_SUBNET_ID" \
  --enable-addons ingress-appgw \
  --appgw-name myAppGw \
  --appgw-subnet-id "$APPGW_SUBNET_ID" \
  --service-cidr 10.1.0.0/16 \
  --dns-service-ip 10.1.0.10 \
  --enable-oidc-issuer \
  --enable-workload-identity


  Q : Shiv@LAPTOP-49SH4K4V MINGW64 /d/Git-repository/DevOps-Projects/Project-2 (main)
$ az aks create \
  -g Azure-CICD \
  -n myAKS \
  --node-vm-size Standard_B1ms \
  --node-count 2 \
  --network-plugin azure \
  --vnet-subnet-id "$AKS_SUBNET_ID" \
  --enable-addons ingress-appgw \
  --appgw-name myAppGw \
  --appgw-subnet-id "$APPGW_SUBNET_ID" \
  --service-cidr 10.1.0.0/16 \
  --dns-service-ip 10.1.0.10 \
  --enable-oidc-issuer \
  --enable-workload-identity
docker_bridge_cidr is not a known attribute of class <class 'azure.mgmt.containerservice.v2025_03_01.models._models_py3.ContainerServiceNetworkProfile'> and will be ignored
(SystemPoolSkuTooLow) System node pool must use VM sku with more than 2 cores and 4GB memory. Nodepool name: nodepool1.
Code: SystemPoolSkuTooLow
Message: System node pool must use VM sku with more than 2 cores and 4GB memory. Nodepool name: nodepool1.


Sol : Finally Working .Changing the node count to 1 since facing some resource quota issue along with that changed node-vm-size to Standard_B2ms from Standard_B1ms

## Some commands for refrence used during deployment.

Q: Problem with sed command i.e. sed -i "s/image:*/image: shivacr356.azurecr.io/$2:$3/g"


S: This is broken because:
    -- image:* is a wrong regex — it tries to match a literal image: followed by zero or more asterisks.
    -- It doesn’t escape slashes properly.
    -- It may not match existing lines like image: old-image-name:tag

    Working command is as follows : 
      - sed -i "s|image: .*|image: shivacr356.azurecr.io/$2:$3|g" k8s-specifications/$1-deployment.yaml

Q: image: .* — What it Means ?

S: It’s a regular expression used to match a line in a Kubernetes YAML that looks like: image: <anything>

    image: — matches the literal keyword image:
    (space) — matches a single space after the colon
    .* — matches any characters (including image name and tag)


Error : failed to authorize: failed to fetch anonymous token: ... 401 Unauthorized

Events:
  Type     Reason     Age                  From               Message
  ----     ------     ----                 ----               -------
  Normal   Scheduled  17m                  default-scheduler  Successfully assigned default/vote-7679b446d-wc8mp to aks-agentpool-26612357-vmss000000
  Normal   Pulling    15m (x4 over 17m)    kubelet            Pulling image "shivacr356.azurecr.io/vote-app:27"
  Warning  Failed     15m (x4 over 17m)    kubelet            Failed to pull image "shivacr356.azurecr.io/vote-app:27": failed to pull and unpack image "shivacr356.azurecr.io/vote-app:27": failed to resolve reference "shivacr356.azurecr.io/vote-app:27": failed to authorize: failed to fetch anonymous token: unexpected status from GET request to https://shivacr356.azurecr.io/oauth2/token?scope=repository%3Avote-app%3Apull&service=shivacr356.azurecr.io: 401 Unauthorized
  Warning  Failed     15m (x4 over 17m)    kubelet            Error: ErrImagePull
  Warning  Failed     15m (x6 over 17m)    kubelet            Error: ImagePullBackOff
  Normal   BackOff    2m2s (x64 over 17m)  kubelet            Back-off pulling image "shivacr356.azurecr.io/vote-app:27"

Sol : 

This means:

  - Kubernetes tried to pull the image without proper credentials
  - Your ACR is private (as it should be), and your AKS cluster isn't authorized to access it


Ref Docs : https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/

kubectl create secret docker-registry regcred --docker-server=shivacr356.azurecr.io --docker-username=devopspractice668 --docker-password=XXXXX
 --docker-email=devopspractice668@gmail.com     ------ > This was incorrect configuration means creds were incorrect .

Along with that updated deployment.yaml for vote service such that :

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: vote
  name: vote
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vote
  template:
    metadata:
      labels:
        app: vote
    spec:
      containers:
        - image: shivacr356.azurecr.io/vote-app:28
          name: vote
          ports:
            - containerPort: 80
              name: vote
      imagePullSecrets:
        - name: regcred

        --------------------------- 

Since we are still getting ImagePullBackoff,

1.  Verify Secret Exists in the Same Namespace : Make sure the secret regcred exists in the same namespace where your pod is deployed (default namespace unless specified otherwise): kubectl get secret regcred --namespace=default

2. Check the Secret's Data (Decode and Inspect) i.e. kubectl get secret regcred -o yaml

3. The .dockerconfigjson field should exist and contain a valid JSON base64-encoded config. You can decode it to double-check: 
    kubectl get secret regcred -o jsonpath="{.data.\.dockerconfigjson}" | base64 --decode

4. Double-Check ACR Credentials & Access : az acr credential show --name shivacr356

az aks show -g Azure-CICD -n myAKS --query apiServerAccessProfile.enablePrivateCluster
az aks show -g MC_Azure-CICD_myAKS_eastus -n myAKS --query apiServerAccessProfile.enablePrivateCluster


az network public-ip list -g Azure-CICD --output table
az network public-ip list -g MC_Azure-CICD_myAKS_eastus --output table

az network nsg list --resource-group Azure-CICD --output table
az network nsg list --resource-group MC_Azure-CICD_myAKS_eastus --output table

kubectl get svc argocd-server -n argocd -o yaml