# **VRA-Terraform Integration**

You can now integrate the use of Terraform into VRA Cloud Assembly. This allows us to create cloud templates by indicating Terraform as a resource type on the Canvas & YAML Code. 

You can then turn those cloud templates (with Terraform) into catalog items in the Service Broker for users to provision resources. 

---
## **Pre-requisites**

In order to use Terraform in VRA Cloud Templates, the following needs to be done: 
1. Prepare a Kubernetes Cluster
2. Configure a Terraform Runtime Integration that uses the K8s Cluster
3. Configure and enable the Terraform Versions that you will use
4. Enable Terraform Cloud Zone Mapping for your Project
5. Configure a Gitlab Project Repository for Terraform Configuration Files

The purpose of K8s is for VRA to spin up a Pod and run a Terraform Container Image (this is where the Terraform Configurations are executed). 

---
## **Setup Terraform Runtime Integration**

The following information is needed to add Terraform Integration into VRA: 
1. Terraform Runtime Integration 
     - Runtime Type
       - Managed K8s Cluster --> A K8s cluster that you have already configured under Resources > Kubernetes
       - External Kubeconfig --> Standard K8s cluster that hasn't been integrated with VRA. Need to copy whole Kubeconfig file into the page 
     - K8s Namespace to run the Terraform Runtime 
2. Runtime Container Settings
      - Image location --> In this case, Harbor
      - Refer to point below to build terraform container image

---
## **Setup Terraform Versions**

You can add new Terraform Versions into VRA (to test your resource configurations) if you have the following: 
1. URL to Terraform Binary (Zip file) --> Likely from Gitlab 
2. SHA256 Checksum of Terraform Binary

The Terraform zip file will be downloaded from the URL and installed into the Pod that is spun up during the deployment. 

---
## **Building Terraform Runtime Container Image**

For environments with no internet access, you will need to build a custom container image with the relevant Terraform Providers. Please follow the guide attached **[here](https://docs.vmware.com/en/vRealize-Automation/8.8/Using-and-Managing-Cloud-Assembly/GUID-FBA52A2A-F34F-4D1B-8247-DA1364C8DB16.html)**.

### **Docker build from Internet --> push image to Cloud B:**

Sample Dockerfile:

    FROM projects.registry.vmware.com/vra/terraform:latest as final

    # Create provider plug-in directory
    RUN mkdir -m 777 -p ~/.terraform.d/plugins/registry.terraform.io/vmware/nsxt/3.1.1/linux_amd64

    # Download and unzip all required provider plug-ins from hashicorp to provider directory
    RUN cd ~/.terraform.d/plugins/registry.terraform.io/vmware/nsxt/3.1.1/linux_amd64 \
        && wget -q https://github.com/vmware/terraform-provider-nsxt/releases/download/v3.1.1/terraform-provider-nsxt_3.1.1_linux_amd64.zip \
        && unzip *.zip \
        && rm *.zip


Docker Build:

    cd <DOCKER_BUILD_DIR>

    docker build . -t <CLOUD_B_CONTAINER_REGISTRY>/project/<IMAGE_NAME>:<IMAGE_TAG>

    docker push <CLOUD_B_CONTAINER_REGISTRY>/project/<IMAGE_NAME>:<IMAGE_TAG>

### **Docker build from Cloud B**

Sample Dockerfile:

    FROM <CLOUD_B_CONTAINER_REGISTRY>/project/<BASE_IMAGE>:<IMAGE_TAG> as final

    # Create provider plug-in directory
    RUN mkdir -m 777 -p ~/.terraform.d/plugins/registry.terraform.io/vmware/nsxt/3.1.1/linux_amd64

    # Download and unzip all required provider plug-ins from hashicorp to provider directory
    RUN cd ~/.terraform.d/plugins/registry.terraform.io/vmware/nsxt/3.1.1/linux_amd64 \
        && wget -q <CLOUD_B_GITLAB_TERRAFORM_PROVIDER_PATH> \
        && unzip *.zip \
        && rm *.zip

Docker Build:

    cd <DOCKER_BUILD_DIR>

    docker build . -t <CLOUD_B_CONTAINER_REGISTRY>/project/<IMAGE_NAME>:<IMAGE_TAG>

    docker push <CLOUD_B_CONTAINER_REGISTRY>/project/<IMAGE_NAME>:<IMAGE_TAG>

---
## **References**
- https://blog.ukotic.net/2020/12/15/configuring-terraform-integration-in-vra-8/
- https://hub.docker.com/r/hashicorp/terraform