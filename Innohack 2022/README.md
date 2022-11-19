# **Innohack Project 2022 - Enabling IaC in Cloud A/B**

## **1. Objectives and Design Considerations**
---
### **1.1. Background**
Currently, developers are only able to provision their resources through our Cloud A/B landing page (GUI). 

When users request for resources (e.g. VMs, Firewalls) from the Service Catalog in VRA, they are created in the form of Deployments. With that, developers can track their deployed resources, and manage these deployed resources using actions. 

However, this implies that developers have to manually request for their own resources through our Cloud A/B landing page, and this creates multiple deployments in the process. Developers will also have to manage their own Day-2 actions for each of their deployments.

    E.g. if a Developer wants to create a Cluster of VMs on Cloud A/B, and they want to test in Cloud B first:

    He/she will request for the following resources from Cloud A/B Landing Page: 
      1. 2x Windows 2019 VMs 
        - Will require 2 VMs to form my Application Cluster
      2. Security Group (SG) - Create
        - To create a SG in NSX to host my VMs
      3. Add Members to SG
        - To add my newly-created VMs into the SG
      4. FW - Create
        - To allow incoming connectivity between external VMs to my SG
    
    This creates a total of 4 deployments within their VRA Project in Cloud B only. 
    They will have to replicate this process in Cloud A as well. 

Some of these catalog items are also on a fire-and-forget basis (e.g. Firewall-as-a-Service). This means even if the VRA deployment is deleted, the Firewall Rule will still persist in NSX-T. This also implies that 2 separate deployments have to be created just to create and delete a firewall rule. 

[To be confirmed] ~~Moreover, there is currently no known method to perform source control of resources in Cloud A/B. This implies that infrastructure in Cloud B could potentially be inconsistent with Cloud B.~~

> **Ultimately, there is a need to reduce that resource management overhead for developers, providing them with a more streamlined developer experience in Cloud A/B.**

### **1.2. Objectives**

We aim to enable developers with a platform to utilize Infrastructure-as-Code (IaC) to provision our Cloud A/B Resources.

### **1.3. Design Considerations**
1. Developers will still follow the VRA Project Construct
     - Can only request for resources within their project resource limits
     - Follows the RBAC in VRA --> unable to bypass any approval policies 
2. Resources provisioned through Terraform will still be integrated with our existing services in Cloud A/B 
3. Developers should be able to manage their IaC using source control tools e.g. Gitlab 

### **1.4. Project Scope**
1. To propose an operational design to enable IaC for Cloud A/B Resources
2. To refactor our VRA Resources to be idempotent and immutable --> allowing these services to be IaC-Compatible
3. To enable CI/CD of IaC templates 
4. To perform a walkthrough of declaring Cloud A/B resources from a developers' perspective

Our scope of work will be done in Cloud B first. 

## **2. Terraform Design**
---
### **2.1. Option 1: Configuring Terraform Integration in VRA**
    VRA + Terraform --> Cloud A/B Resources

Option #1 involves configuring Terraform Integration with VRA, allowing Cloud Admins and developers to declare custom Terraform configurations in Cloud Templates. Since Cloud Templates are declarative by default (e.g. Resources will be deleted when the deployment is deleted), we can leverage option #1 to declare resources that are not idempotent in Cloud A/B (e.g. Firewall Rules)

The general developer process flow will be very similar to what is present in Cloud A/B. The Terraform configurations are abstracted from the developers (only declared in Cloud Templates).

#### **Pros**
- Using NSX-T Terraform Provider, we can declare the following in our Cloud Templates (Hybrid TF-VRA Blueprints): 
  - NSX-T Policies (DFW + GFW)
  - NSX-T Security Groups

#### **Cons**
- Requires an External Kubernetes Cluster to be integrated with VRA to host Terraform Runtime (likely managed by us)
- Developers still have to manage their deployments through VRA Service Catalog, doesn't provide an option to use CI/CD for their resources

#### **References**
- https://blogs.vmware.com/management/2020/09/terraform-service-in-vra.html
- https://docs.vmware.com/en/vRealize-Automation/8.8/Using-and-Managing-Cloud-Assembly/GUID-FBA52A2A-F34F-4D1B-8247-DA1364C8DB16.html
- https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs
- https://registry.terraform.io/providers/vmware/nsxt/latest/docs


### **2.2. Option 2: Using External Terraform to interface with VRA**
    Terraform [External] --> Cloud A/B Resources

Option #2 involves using an external Terraform Runtime to interface with VRA to create resources. 

We will create a public repository (E.g. Terraform) within our self-hosted Gitlab to store the following:
    - Terraform CLI 
    - Terraform Providers (VMWare vRealize Automation Provider)
    - Sample Terraform Configuration Templates
    - Shellscript to initialize Terraform Working Directory + extract developers' VRA Refresh Token

Developers are free to fork the repository and configure their own custom Terraform Configuration templates to state how much resources they need. 

A separate Content Source (for Cloud Templates and VRO Workflows) will be tailor-made just for Terraform compatibility.
> Note: To simpliy the declaration of infrastructure, 1 Deployment will be tied to 1 resource (VM, SG, FW Rule). These deployments will then be managed via developers' Terraform Configurations. 

The general developer process flow will be as follows: 
1. Developers spinning up a Jumphost Server (JH) in Cloud A/B
2. Git clone the Terraform Repository into JH and/or pull their custom Terraform configurations from their own repositories
3. Initialize Terraform Working Directory & get developer's VRA refresh token --> update it in their Terraform Variables file
4. Terraform init --> Terraform plan --> Terraform Apply

#### **Pros**
- Terraform binaries and configuration templates are stored in Gitlab, allowing version control of Cloud A/B infrastructure
- Developers are able to integrate Cloud A/B infrastructure codes into their CI/CD pipeline, streamlining their application development process 

#### **Cons**
- Some of our catalog items are not IaC Compatible (e.g. Firewall as a Service). Will need to refactor the catalog items to achieve idempotency 
- only vra_deployment resource in VRA Terraform Provider is relevant, and is very limited in functionality (Day 2 custom actions like update deployment / add disk cannot be done through Terraform) 
- [Need to review] Day 2 Action policies to be set for Terraform Content Source to ensure resources are immutable 
- Developers still need to spin up a jumphost server manaually to initialize their Terraform runtime (it's current practices now)

#### **References**
- https://registry.terraform.io/providers/vmware/vra/latest/docs
- https://blogs.vmware.com/management/2020/01/getting-started-with-vra-terraform-provider.html

### **2.3. Option 3: Hybrid Approach**
    Terraform [External] --> VRA + Terraform --> Cloud A/B Resources

Option #3 is a hybrid approach of Option #1 and #2. It combines the pros and cons of both options, but essentially this provides a more comprehensive approach to enable CI/CD of Infrastructure Code for Cloud A/B Resources. 
- NSX-T related Cloud Templates backed by Terraform Configurations
- VM related Cloud Templates declared via external Terraform runtime


### **2.4. Option 4 (UNEXPLORED): Gitlab to Interface with VRA**
    Gitlab --> VRA --> Cloud A/B Resources

Option #4 involves developers interfacing with Gitlab to manage their Terraform configurations. Once developers push their configurations onto Gitlab, it triggers a CI/CD pipeline to create a Gitlab Runner (with Terraform Runtime) that provisions the necessary resources. Gitlab will store the Terraform state for Cloud A/B Resources. 

#### **Pros** 
- Developers do not need to create a jumphost server in SDC manually. Terraform State management is outsourced to Gitlab. 
- CI/CD pipeline for Terraform can be integrated with developers' existing application CI/CD pipeines 

#### **Cons**
- Further exploration is required for this approach. Possibly can push it to Phase 2 of project.

#### **References**
- https://docs.gitlab.com/ee/user/project/integrations/webhooks.html
- https://docs.gitlab.com/ee/user/infrastructure/iac/

## 3. VRA Design
---


To make VRA services immutable
- Set Day 2 Action Policies to Terraform-compatible cloud templates to prevent modification of resources. If you require any updates on the resources, please request for your resources through GUI
- 


## 4. Enabling CI/CD of Infrastructure Code
---

## 5. Developers' Pespectives
---

## 6. Milestones
---



