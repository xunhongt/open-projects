# **VRA-Terraform Integration**

You can now integrate the use of Terraform into VRA Cloud Assembly. This allows us to create cloud templates by indicating Terraform as a resource type on the Canvas & YAML Code. 

You can then turn those cloud templates (with Terraform) into catalog items in the Service Broker for users to provision resources. 

---
## **1. Basic Configuration**

In order to use Terraform in VRA Cloud Templates, the following needs to be done: 
1. Prepare a Kubernetes Cluster
2. Configure a Terraform Runtime Integration that uses the K8s Cluster
3. Configure and enable the Terraform Versions that you will use
4. Enable Terraform Cloud Zone Mapping for your Project
5. Configure a Gitlab Project Repository for Terraform Configuration Files

The purpose of K8s is for VRA to spin up a Pod and run a Terraform Container Image (this is where the Terraform Configurations are executed). 

### **Setup Terraform Runtime Integration**

The following information is needed to add Terraform Integration into VRA: 
1. Terraform Runtime Integration 
     - Runtime Type
       - Managed K8s Cluster --> A K8s cluster that you have already configured under Resources > Kubernetes
       - External Kubeconfig --> Standard K8s cluster that hasn't been integrated with VRA. Need to copy whole Kubeconfig file into the page 
     - K8s Namespace to run the Terraform Runtime 
2. Runtime Container Settings
      - Image location --> In this case, Harbor
        - **Need to build the Terraform Provider into the container image?**

### **Setup Terraform Versions** 

You can add new Terraform Versions into VRA (to test your resource configurations) if you have the following: 
1. URL to Terraform Binary (Zip file) --> Likely from Gitlab 
2. SHA256 Checksum of Terraform Binary

The Terraform zip file will be downloaded from the URL and installed into the Pod that is spun up during the deployment. 



---
## **References**
- https://blog.ukotic.net/2020/12/15/configuring-terraform-integration-in-vra-8/
- https://hub.docker.com/r/hashicorp/terraform