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

## **Use Terraform Configurations in your Cloud Templates**

### **Create a Cloud Template**
- When users request for a Cloud Template (with Terraform Configurations), the Kubernetes Cluster will create a Pod (with the Terraform Runtime Container Image) which wil run the Terraform Plan & Apply job
- Seems like Terraform State is stored in the VRA Deployment 
- VRA pulls the Terraform related configurations from Gitlab 

### **Infrastructure Provision Process**
- When users request for a Cloud Template (with Terraform Configurations), the Kubernetes Cluster will create a Pod (with the Terraform Runtime Container Image) which wil run the Terraform Plan & Apply job
- Seems like Terraform State is stored in the VRA Deployment 
- VRA pulls the Terraform related configurations from Gitlab 


---
## **Limitations**

You can refer to the VMWare Doc **[here](https://docs.vmware.com/en/vRealize-Automation/8.8/Using-and-Managing-Cloud-Assembly/GUID-FE4AC633-E1BF-4E52-82DC-D38E90A7006B.html)** for the limitations involving using Terraform Integrations in VRA. 

### **Terraform configurations**
1. When validating a design with Terraform configurations, the TEST button checks Cloud Assembly syntax but not the native Terraform code syntax.
2. In addition, the TEST button doesn't validate commit IDs associated with Terraform configurations.
3. For a cloud template that includes Terraform configurations, cloning the template to a different project requires the following workaround.
     - In the new project, under the Integrations tab, copy the repositoryId for your integration.
     - Open the clone template. In the code editor, replace the repositoryId with the one you copied.
     - In the version control repository, don't include a Terraform state file with configuration files. If terraform.tfstate is present, errors occur during deployment.

For point #3, this implies that: 
- Every VRA Project would need to configure a Gitlab integration to the same Repository --> to access the Terraform Configuration files 
- **Terraform-integrated Cloud Templates cannot be shared across different projects.** For another VRA Project to use the same Teraform-integrated cloud template, you'll need to do the following: 
  1. Add a Gitlab Integration for the Project to connect to the same Gitlab Project (with Terraform Configurations)
  2. Clone the Same Cloud Template, and replace the repository ID with the specified Project's Repository ID

[2023-01-25] WORKAROUND:
- Set Repository ID as an input variable in the Cloud template
- Set Repository ID as a custom property in Each VRA Project

4. There are 2 different States managed by VRA: 
- Terraform State (*.tfstate) --> Where Terraform checks the Infrastructure State. Will be stored within vRA
- VRA Deployment State
  
When there is a configuration drift (i.e. Infrastructure State is different from Terraform State), it is not directly reflected in VRA Deployment.
  - It is shown in the Attributes tab in the Terraform Object (within the vRA Deployment)

When unauthorized changes are done on the infrastructure, users need to manually refresh the Terraform state on the vRA Deployment. The Terraform state will then be refreshed in the Terraform Object within the vRA Deployment
  - The variables inputted to the vRA Deployment **will NOT be updated**

When you update the variables within the vRA Deployment, it will not take into account of the Terraform State stored within vRA

5. If there are Infrastructure Configuration Drifts, Project admins & users **will not be alerted**. 

---
## **References**
- https://blog.ukotic.net/2020/12/15/configuring-terraform-integration-in-vra-8/
- https://hub.docker.com/r/hashicorp/terraform
- https://docs.vmware.com/en/vRealize-Automation/8.8/Using-and-Managing-Cloud-Assembly/GUID-FBA52A2A-F34F-4D1B-8247-DA1364C8DB16.html