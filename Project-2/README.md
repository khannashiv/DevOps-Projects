## End-to-End CI/CD Implementation Using Azure DevOps (Voting Application)

- This project showcases a comprehensive CI/CD pipeline leveraging Azure DevOps and key Azure resources such as Azure Virtual Machines (VMs), Azure Container Registry (ACR), Azure Kubernetes Service (AKS), and related services.

---

## Project Overview

- Automate the deployment of a sample voting application using Azure DevOps pipelines. The application is composed of multiple containerized services, orchestrated and deployed to an AKS cluster. The CI/CD pipeline is designed to build, test, and deploy the application automatically upon code changes.

---

## Prerequisites

- Azure DevOps account and organization
- Git repository with the voting application source code
- Azure CLI installed and configured
- Access to an Azure subscription with resource creation permissions
- Basic knowledge of Docker, Kubernetes, and Azure DevOps

---

## Implementation Steps

### 1. Create Azure DevOps Project and Repository

- Sign in to Azure DevOps and create a new project.
- Create a Git repository within the project to host the voting application code.

---

### 2. AKS Installation & Configuration

You can deploy AKS either via CLI or the Azure Portal UI.

**Method 1: CLI Deployment**

```bash
AKS_SUBNET_ID=$(az network vnet subnet show \
   --resource-group Azure-CICD \
   --vnet-name Azure-VNET-1 \
   --name AKSSubnet \
   --query id -o tsv)

echo $AKS_SUBNET_ID

az aks create \
   -g Azure-CICD \
   -n myAKS \
   --node-vm-size Standard_B2ms \
   --node-count 1 \ # Adjust node count as needed
   --network-plugin azure \
   --vnet-subnet-id "$AKS_SUBNET_ID" \
   --enable-oidc-issuer \
   --enable-workload-identity
```

**Method 2: Portal Deployment**

- Deploy AKS via the Azure Portal with minimal configuration for proof-of-concept.

Once AKS is installed and accessible from your local machine, proceed to the next step.

---

### 3. ArgoCD Setup and Configuration

- Install ArgoCD and update the `argocd-server` service type to `LoadBalancer` for web UI access.
- Retrieve the initial admin password from the `argocd-initial-admin-secret`.
- **Note:** ArgoCD is deployed in the `argocd` namespace. Refer to [ArgoCD official documentation](https://argo-cd.readthedocs.io/en/stable/) for details.

**Key Commands:**

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml  # Install
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml # Uninstall
```

---

### 4. Azure Repo Integration

- Configure Azure Repo credentials in ArgoCD (for private repositories). Add a Personal Access Token (PAT) from Azure DevOps under `Settings > Connect Repo` in the ArgoCD UI.

   ```
   https://<PAT>@dev.azure.com/<Organization>/<Project>/_git/<RepoName>
   ```

- Clone the Azure Repo locally:

   ```bash
   git clone https://USERNAME:PAT@dev.azure.com/YourOrg/YourProject/_git/RepoName
   ```

   **Example Parameters:**

   | Parameter         | Value                       |
   |-------------------|----------------------------|
   | User Name         | devopspractice668          |
   | PAT/Access Token  | X_X_X                      |
   | Organization      | devopspractice6680482      |
   | Project           | Azure-CICD-voting-app      |
   | Repo Name         | Azure-CICD-voting-app      |
   | Email             | devopspractice668@gmail.com|

- Convert shell scripts to LF format to avoid CRLF errors:

   ```bash
   dos2unix updatek8manifests.sh
   git add .
   git commit -m "Convert scripts to LF"
   git push
   ```

---

### 5. Azure Container Registry (ACR) Integration

To prevent `ErrImagePull` or `ImagePullBackOff` errors, ensure AKS can pull images from the private ACR by creating Kubernetes secrets and updating your manifests.

- Enable ACR admin user and do check credentials:

   ```bash
   az acr update -n <acr-name> --admin-enabled true
   az acr credential show --name <acr-name>
   ```

- Create Kubernetes secret for ACR:

   ```bash
   kubectl create secret docker-registry regcred \
      --docker-server=<acr-name>.azurecr.io \ 
      --docker-username=<acr-username> \
      --docker-password='<acr-password>' \
      --docker-email=<your-email> \
      --namespace=default
   ```
   <!-- 
      -- In above command in my case : 
            - docker-server=shivacr356.azurecr.io
            - docker-username=ShivACR356
            - docker-email=devopspractice668@gmail.com
   -->
- Reference the secret in your Kubernetes deployment manifests under `imagePullSecrets`.

### 6. Accessing Services Using `kubectl port-forward`

- Since the ArgoCD service is of type `LoadBalancer`, it is accessible directly via a public IP through the web browser. However, the other two services—`result` and `vote`—are exposed as `NodePort` services. In Azure Kubernetes Service (AKS), nodes typically reside within a Virtual Network (VNet) and are managed by a Virtual Machine Scale Set (VMSS), which means the nodes have only private IP addresses and no public/external IPs by default.

- As a result, even though the services are of type `NodePort`, they are not accessible externally from the internet. To access these microservices from your local machine, we can use the `kubectl port-forward` command. This command forwards a local port on your machine to a port on the Kubernetes service, allowing you to interact with the service as if it were running locally.

**Usage:**

```bash
kubectl port-forward service/<service-name> <local-port>:<service-port>
```

**Example:**

```bash
kubectl port-forward service/vote 1234:8080
kubectl port-forward service/result 5678:8081
```

After running the above command, you can access the `vote` service in your web browser at [http://localhost:1234/](http://localhost:1234/).

After running the above command, you can access the `result` service in your web browser at [http://localhost:5678/](http://localhost:5678/).

**Summary:**
- Use `kubectl port-forward` to access internal AKS services from your local machine.
- This is especially useful when services are not exposed via public IPs or external load balancers.
- Replace `<service-name>`, `<local-port>`, and `<service-port>` with your actual service name and desired ports.

---

## Reference Documentation

- [Example Voting App on GitHub](https://github.com/dockersamples/example-voting-app)
- [Azure DevOps for Beginners](https://techcommunity.microsoft.com/blog/educatordeveloperblog/azure-devops-for-beginners-how-to-set-up-your-account-organization-and-repositor/3790002)
- [Azure Pipelines Linux Agent Documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/linux-agent?view=azure-devops&tabs=IP-V4)
- [Azure DevOps Labs: YAML Pipelines](https://azuredevopslabs.com/labs/azuredevops/yaml/)
- [Building a Simple CI/CD Pipeline with Azure DevOps (Medium)](https://medium.com/@lamjed.gaidi070/building-a-simple-ci-cd-pipeline-with-azure-devops-218e5dac2d61)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/en/stable/)
- [Kubernetes: Pull an Image from a Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)
- [Refer repository for Azure practice](https://github.com/iam-veeramalla/Azure-zero-to-hero)

---

## Outcomes: End-to-End Azure CI/CD Pipeline

---

Below are sample screenshots illustrating the pipeline and deployment process:

- ![Azure-CICD-1.png](./Images/Azure-CICD-1.png)
- ![Azure-CICD-2.png](./Images/Azure-CICD-2.png)
- ![Azure-CICD-3.png](./Images/Azure-CICD-3.png)
- ![Azure-CICD-4.png](./Images/Azure-CICD-4.png)
- ![Azure-CICD-5.png](./Images/Azure-CICD-5.png)
- ![Azure-CICD-6.png](./Images/Azure-CICD-6.png)
- ![Azure-CICD-7.png](./Images/Azure-CICD-7.png)
- ![Azure-CICD-8.png](./Images/Azure-CICD-8.png)
- ![Azure-CICD-9.png](./Images/Azure-CICD-9.png)
- ![Azure-CICD-10.png](./Images/Azure-CICD-10.png)
- ![Azure-CICD-11.png](./Images/Azure-CICD-11.png)
- ![Azure-CICD-12.png](./Images/Azure-CICD-12.png)
- ![Azure-CICD-13.png](./Images/Azure-CICD-13.png)
- ![Azure-CICD-14.png](./Images/Azure-CICD-14.png)
- ![Azure-CICD-15.png](./Images/Azure-CICD-15.png)
- ![Azure-CICD-16.png](./Images/Azure-CICD-16.png)
- ![Azure-CICD-17.png](./Images/Azure-CICD-17.png)
- ![Azure-CICD-18.png](./Images/Azure-CICD-18.png)
- ![Azure-CICD-19.png](./Images/Azure-CICD-19.png)
- ![Azure-CICD-20.png](./Images/Azure-CICD-20.png)
- ![Azure-CICD-21.png](./Images/Azure-CICD-21.png)
- ![Azure-CICD-22.png](./Images/AZure-CICD-22.png)
- ![Azure-CICD-23.png](./Images/Azure-CICD-23.png)
- ![Azure-CICD-24.png](./Images/Azure-CICD-24.png)
- ![Azure-CICD-25.png](./Images/Azure-CICD-25.png)
- ![Azure-CICD-26.png](./Images/Azure-CICD-26.png)
- ![Azure-CICD-27.png](./Images/Azure-CICD-27.png)
- ![Azure-CICD-28.png](./Images/Azure-CICD-28.png)
- ![Azure-CICD-29.png](./Images/Azure-CICD-29.png)
- ![Azure-CICD-30.png](./Images/Azure-CICD-30.png)
- ![Azure-CICD-31.png](./Images/Azure-CICD-31.png)
- ![Azure-CICD-32.png](./Images/Azure-CICD-32.png)
- ![Azure-CICD-33.png](./Images/Azure-CICD-33.png)
- ![Azure-CICD-34.png](./Images/Azure-CICD-34.png)
- ![Azure-CICD-35.png](./Images/Azure-CICD-35.png)
- ![Azure-CICD-36.png](./Images/Azure-CICD-36.png)
- ![Azure-CICD-37.png](./Images/Azure-CICD-37.png)
- ![Azure-CICD-38.png](./Images/Azure-CICD-38.png)
- ![Azure-CICD-39.png](./Images/Azure-CICD-39.png)
- ![Azure-CICD-40.png](./Images/Azure-CICD-40.png)
- ![Azure-CICD-41.png](./Images/Azure-CICD-41.png)
- ![Azure-CICD-42.png](./Images/Azure-CICD-42.png)
- ![Azure-CICD-43.png](./Images/Azure-CICD-43.png)
- ![Azure-CICD-44.png](./Images/Azure-CICD-44.png)
- ![Azure-CICD-45.png](./Images/Azure-CICD-45.png)
- ![Azure-CICD-46.png](./Images/Azure-CICD-46.png)
- ![Azure-CICD-47.png](./Images/Azure-CICD-47.png)
- ![Azure-CICD-48.png](./Images/Azure-CICD-48.png)
- ![Azure-CICD-49.png](./Images/Azure-CICD-49.png)
- ![Azure-CICD-50.png](./Images/Azure-CICD-50.png)
- ![Azure-CICD-51.png](./Images/Azure-CICD-51.png)
- ![Azure-CICD-52.png](./Images/Azure-CICD-52.png)
- ![Azure-CICD-53.png](./Images/Azure-CICD-53.png)
- ![Azure-CICD-54.png](./Images/Azure-CICD-54.png)
- ![Azure-CICD-55.png](./Images/Azure-CICD-55.png)
- ![Azure-CICD-56.png](./Images/Azure-CICD-56.png)

---