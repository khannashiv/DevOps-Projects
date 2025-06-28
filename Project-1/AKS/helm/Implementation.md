## Refrence Docs.
- [Azure CLI AKS documentation](https://learn.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest)  
    Official documentation for managing Azure Kubernetes Service (AKS) using the Azure Command-Line Interface (CLI).

- [Azure AKS overview](https://learn.microsoft.com/en-us/azure/aks/)  
    Comprehensive overview and documentation for Azure Kubernetes Service, including concepts, how-tos, and best practices.

- [Quickstart: Deploy to AKS using Azure Portal](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-portal?tabs=azure-cli)  
    Step-by-step guide to deploying a Kubernetes cluster on AKS using the Azure Portal and Azure CLI.

- [Quickstart: Deploy to AKS using Azure CLI](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-cli)  
    Tutorial for deploying a Kubernetes cluster on AKS directly from the Azure CLI.

- [Install Application Gateway Ingress Controller on existing AKS](https://learn.microsoft.com/en-us/azure/application-gateway/ingress-controller-install-existing)  
    Instructions for installing the Azure Application Gateway Ingress Controller on an existing AKS cluster.

- [Sample Helm configuration for AGIC](https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/sample-helm-config.yaml)  
    Example Helm configuration YAML file for deploying the Application Gateway Ingress Controller.

- [Application Gateway Ingress Controller documentation](https://azure.github.io/application-gateway-kubernetes-ingress/)  
    Project documentation and guides for the Azure Application Gateway Ingress Controller.

- [Application Gateway Ingress Controller GitHub repository](https://github.com/Azure/application-gateway-kubernetes-ingress)  
    Source code and resources for the Azure Application Gateway Ingress Controller.

- [Azure Bicep documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)  
    Official documentation for Bicep, a domain-specific language for deploying Azure resources declaratively.

- [Azure Bicep GitHub repository](https://github.com/Azure/bicep)  
    Source code and releases for the Azure Bicep project.

- [Three-tier architecture demo](https://github.com/iam-veeramalla/three-tier-architecture-demo)  
    Example project demonstrating a three-tier application architecture on Kubernetes.

- [Robot Shop demo application](https://github.com/khannashiv/robot-shop)  
    Sample microservices-based application for demonstrating Kubernetes deployments and architectures.


### Simple Implementation Steps of AKS with AGIC and Workload Identity

- This section outlines the steps to create an Azure Kubernetes Service (AKS) cluster with Application Gateway Ingress Controller (AGIC) and Workload Identity, along with Helm chart operations for deploying a sample application.

1. **Create an AKS Cluster with Application Gateway Ingress Controller (AGIC) and Workload Identity**
    ```sh
    az aks create \
      -g AKS_RG -n myAKS \
      --node-vm-size Standard_B2s \
      --node-count 2 \
      --network-plugin azure \
      --enable-addons ingress-appgw \
      --appgw-name myAppGw \
      --appgw-subnet-cidr 10.225.0.0/16 \
      --enable-oidc-issuer \
      --enable-workload-identity
    ```
    - Provisions an AKS cluster named `myAKS` in resource group `AKS_RG` with 2 nodes, Azure CNI networking, and enables AGIC and Workload Identity.

2. **Remove the AKS Preview Extension (if previously installed)**
    ```sh
    az extension remove --name aks-preview
    ```
    - Cleans up the Azure CLI by removing the deprecated or unneeded `aks-preview` extension.

3. **Get AKS Cluster Credentials & verify kubernetes intallation**
    ```sh
    az aks get-credentials --resource-group AKS_RG --name myAKS
    kubectl get nodes
    kubectl config current-context
    ```
    - Downloads and merges the AKS cluster credentials into your local kubeconfig for `kubectl` access.

4. **Verify Helm Installation**
    ```sh
    helm version
    ```
    - Checks that Helm is installed and displays the current version.

5. **Render Helm Chart Templates Locally**
    ```sh
    helm template robot-shop --namespace robot-shop . > rendered.yaml
    ls -lh rendered.yaml
    ```
    - Renders the Helm chart for `robot-shop` into Kubernetes manifests and saves them to `rendered.yaml` for inspection.

<!--
    ** Meaning of the above command **
        - Renders the Helm templates in the current directory (.).
        - Uses the release name robot-shop and namespace robot-shop.
        - Produces a complete Kubernetes manifest YAML (but does not apply it to the cluster).
        - Outputs all manifests into rendered.yaml (which you can inspect or apply manually with kubectl apply -f).
        - In this example i.e. helm template robot-shop --namespace robot-shop .
            - robot-shop after template → is the Helm release name, not the chart name.
            - Example : Chart.yaml
                name: awesome-service
                version: 1.0.0
            - We can run: helm template my-release-name --namespace staging ./awesome-service/
                my-release-name = Helm release name (your label for the deployment)awesome-service = actual chart name from Chart.yaml
            - We can use any release name — it doesn’t need to match the chart name.
            - helm template robot-shop --namespace robot-shop .
               -- robot-shop is the release name
               -- Chart name is taken from Chart.yaml (in your case, likely also robot-shop, but it doesn’t have to be)             
-->

6. **Install the Helm Chart with Debugging**
    ```sh
    kubectl create ns robot-shop
    helm install robot-shop --namespace robot-shop . --debug
    ```
    - Installs the `robot-shop` chart into the `robot-shop` namespace with debug output for troubleshooting.

7. **Dry Run Helm Installation (optional)**
    ```sh
    helm install robot-shop --namespace robot-shop . --dry-run --debug
    ```
    - Simulates the installation without making changes, useful for validating the chart and values.

8. **Package the Helm Chart (optional)**
    ```sh
    helm package .
    ```
    - Packages the current chart directory into a `.tgz` archive for distribution or versioning.

9. **Install the Packaged Helm Chart (optional)**
    ```sh
    helm install robot-shop --namespace robot-shop ./robot-shop-*.tgz --debug
    ```
    - Installs the packaged chart archive into the `robot-shop` namespace with debug output.

10. **Install ingress resource & Verify Ingress Resources**
     ```sh
     kubectl apply -f ingress.yaml
     kubectl get ing -n robot-shop
     ```
     - Lists the ingress resources in the `robot-shop` namespace to confirm successful deployment and ingress setup.

## Outcomes of hands-on where application gateway is deployed after AKS was deployed using bicep to see functionality of AGIC.
- ![AKS-1.png](./Images/AKS-1.png)
- ![AKS-2.png](./Images/AKS-2.png)
- ![AKS-3.png](./Images/AKS-3.png)
- ![AKS-4.png](./Images/AKS-4.png)
- ![AKS-5.png](./Images/AKS-5.png)
- ![AKS-6.png](./Images/AKS-6.png)
- ![AKS-7.png](./Images/AKS-7.png)
- ![AKS-8.png](./Images/AKS-8.png)
- ![AKS-9.png](./Images/AKS-9.png)
- ![AKS-10.png](./Images/AKS-10.png)
- ![AKS-11.png](./Images/AKS-11.png)
- ![AKS-12.png](./Images/AKS-12.png)
- ![AKS-13.png](./Images/AKS-13.png)
- ![AKS-14.png](./Images/AKS-14.png)
- ![AKS-15.png](./Images/AKS-15.png)
- ![AKS-16.png](./Images/AKS-16.png)
- ![AKS-17.png](./Images/AKS-17.png)
- ![AKS-18.png](./Images/AKS-18.png)
- ![AKS-19.png](./Images/AKS-19.png)
- ![AKS-20.png](./Images/AKS-20.png)
- ![AKS-21.png](./Images/AKS-21.png)
- ![AKS-22.png](./Images/AKS-22.png)
- ![AKS-23.png](./Images/AKS-23.png)
- ![AKS-24.png](./Images/AKS-24.png)
- ![AKS-25.png](./Images/AKS-25.png)
- ![AKS-26.png](./Images/AKS-26.png)
- ![AKS-27.png](./Images/AKS-27.png)
- ![AKS-28.png](./Images/AKS-28.png)

## Deployed application gateway along with AKS using the command mentioned as pointer 1 to see the functionality of AGIC.

- ![AKS-29](./Images/AKS-29.png)
- ![AKS-30](./Images/AKS-30.png)
- ![AKS-31](./Images/AKS-31.png)
- ![AKS-32](./Images/AKS-32.png)
- ![AKS-33](./Images/AKS-33.png)
- ![AKS-34](./Images/AKS-34.png)
- ![AKS-35](./Images/AKS-35.png)
- ![AKS-36](./Images/AKS-36.png)
- ![AKS-37](./Images/AKS-37.png)
- ![AKS-38](./Images/AKS-38.png)
- ![AKS-39](./Images/AKS-39.png)
- ![AKS-40](./Images/AKS-40.png)
- ![AKS-41](./Images/AKS-41.png)
- ![AKS-42](./Images/AKS-42.png)
- ![AKS-43](./Images/AKS-43.png)
- ![AKS-44](./Images/AKS-44.png)
---

### 11. Clean Up Resources

```sh
# Delete the AKS cluster and associated resources
az aks delete --resource-group AKS_RG --name myAKS --yes --no-wait

# Delete the Application Gateway
az network application-gateway delete --name myAppGw --resource-group AKS_RG

# To delete all the resources residing inside resource group at once.
az group delete --name AKS_RG --yes --no-wait

```