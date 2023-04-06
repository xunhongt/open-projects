# **Exploration Log**

## **Option 1: Configuring Terraform Integration in VRA**
---
### **Exploration**

Option #1 involves configuring Terraform Integration with VRA, allowing Cloud Admins and developers to declare custom Terraform configurations in Cloud Templates. 

The implementation details can be found **[here](VRA-Terraform%20Integration/README.md)**.

### **Observations**

**1. Sharing of Terraform configurations not out-of-the-box**

You can refer to the VMWare Doc **[here](https://docs.vmware.com/en/vRealize-Automation/8.8/Using-and-Managing-Cloud-Assembly/GUID-FE4AC633-E1BF-4E52-82DC-D38E90A7006B.html)** for the limitations involving using Terraform Integrations in VRA. 

1. When validating a design with Terraform configurations, the TEST button checks Cloud Assembly syntax but not the native Terraform code syntax.
2. In addition, the TEST button doesn't validate commit IDs associated with Terraform configurations.
3. For a cloud template that includes Terraform configurations, cloning the template to a different project requires the following workaround.
     - In the new project, under the Integrations tab, copy the repositoryId for your integration.
     - Open the clone template. In the code editor, replace the repositoryId with the one you copied.
     - In the version control repository, don't include a Terraform state file with configuration files. If terraform.tfstate is present, errors occur during deployment.

> For point #3, this implies that: 
> - Every VRA Project would need to configure a Gitlab integration to the same Repository --> to access the Terraform Configuration files 
> - **Terraform-integrated Cloud Templates cannot be shared across different projects.** 
> 
> For another VRA Project to use the same Teraform-integrated cloud template, you'll need to do the following: 
>   1. Add a Gitlab Integration for the Project to connect to the same Gitlab Project (with Terraform Configurations)
>   2. Clone the Same Cloud Template, and replace the repository ID with the specified Project's Repository ID
> 
> **[2023-01-25] WORKAROUND:**
> - Set Repository ID as an input parameter in the Cloud template.
> - Set Repository ID as a custom property in Each VRA Project
> - Use a vRO action to pull out Project's Repository ID when developers are loading the catalog item. 

**2. Addressing Configuration Drift**

There are 2 different States managed by VRA: 
1. Terraform State (*.tfstate) --> Where Terraform checks the Infrastructure State. Will be stored within vRA
2. VRA Deployment State

> The vRA and Terraform States are **NOT automatically synchronized**.  
  
When there is a configuration drift (i.e. Infrastructure State is different from Terraform State), it is not directly reflected in VRA Deployment. It is shown in the Attributes tab in the Terraform Object (within the vRA Deployment)

Users will have to refresh the Terraform state on the vRA Deployment.
   - This is done under **Deployment > Actions > Refresh Terraform State**

The Terraform state will then be refreshed in the Terraform Object within the vRA Deployment. However, the input parameters to the vRA Deployment **will NOT be updated**. When you update the input parameters within the vRA Deployment, it will not take into account of the Terraform State stored within vRA as well.

> If there are Infrastructure Configuration Drifts, Project admins & users **will not be alerted**. 

**3. Difficulty in coding the Terraform Modules Logic**

Our current Firewall service encompasses the following scenarios: 

| Scenario  | Source                                        | Destination |
| :------   | :-----------                                  | :-----------|
| Type 3    | External Environment                          | Cloud A/B VMs
| Type 4    | Cloud A/B VMs                                 | Cloud A/B VMs
| Type 5    | External Environment / Cloud A/B Tanzu Egress | Cloud A/B Tanzu Ingress 

In our current practice (in Cloud A/B), developers can choose multiple IP addresses/security groups to be added as sources/destinations in their firewall rule. The submission of a catalog item will trigger a vRO workflow, which will parse the users' IP Addresses/Security Groups input into an array, and search for the respective Security Groups' path in NSX-T

> I faced some difficulty when I try to code the Terraform Modules to map to the developers' practices when using our current Firewall Service. This is because Terraform's HCL language is quite simple, and its syntax does not have advanced looping concepts. As such, I find difficulty in doing the following:
>    1. Getting the Security Groups' Paths from NSX-T based on the users' inputs in the catalog item
>    2. Adding Security Groups into Distributed Firewall (DFW) and Gateway Firewall (GFW) resources

Without this logic in place, developers can only add 1 security group as source or destination in the Firewall Catalog Item. 

### **Feasibility**

The additional dependencies to be managed by our Section include: 
1. An external Kubernetes cluster 
2. Terraform Runtime Container Images (needs to be custom configured)
3. Terraform-related binaries
4. Terraform Provider Binaries
     - NSX-T Provider
5. Terraform Modules
     - Security Groups
     - DFWs
     - GFWs


## **Option 2: Using External Terraform to interface with VRA**
---
### **Exploration**

I can change the deployment name LOL

### **Observations**

### **Feasibility**

## **Option 3: Hybrid Approach**
---
### **Exploration**

Option #3 is a hybrid approach of Option #1 and #2. It combines the pros and cons of both options. 

The implementation details can be found **[here](VRA-Terraform%20Integration/README.md)**.

### **Observations**

The limitations involved in Option #3 

### **Feasibility**

With the compounded problems from Option #1 and #2, this makes Option 3 the least feasible option to achieve IaC in Cloud A/B. 
- Combined dependencies 

## **Further Improvements**
---

## **Conclusion**
---
