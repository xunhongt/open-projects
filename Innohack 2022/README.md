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

Option #3 is a hybrid approach of Option #1 and #2. It combines the pros and cons of both options, but essentially this provides the most comprehensive approach to enable CI/CD of Infrastructure Code for Cloud A/B Resources, given our timeline. 
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

> Currently, I'm leaning towards Option #3, but open to discussion. 

## **3. VRA Design**
---
A declarative approach to provision infrastructure is where the user defines the desired state of the system, including what resources you need and any properties they should have, and an IaC tool will configure it for you. A declarative approach also keeps a list of the current state of your system objects, which makes taking down the infrastructure simpler to manage.

### **3.1. Clear Desired State**
A basic requirement to enable IaC is that **the resources created must be tied to the VRA Deployments' lifecycle**. If a deployment is deleted from VRA, the resources tied to the deployment will be deleted as well. 

In the context of Cloud A/B, we can enforce the following to ensure a clear Desired State:

    1. VRA Cloud Templates are declarative by design. By deleting Cloud Template deployments, the resources will be removed as well. 
    2. For VRO Workflow Catalog Items, ensure that a subscription (to delete resource) is tagged to the Catalog Item when said deployment is deleted. 

Currently, some of our catalog items do not follow this rule (e.g. Firewall-as-a-Service). These workflows need to be re-factored to fit this design consideration. 

### **3.2. Immutability**
An immutable infrastructure implies that the **infrastructure cannot be modified once deployed**. When changes are necessary, you need to deploy afresh, swing traffic to the new instance and decommission old infrastructure. 

> One key requirement to enable immutable infrastructure for Cloud A/B Resources is that **application data must be externalized from the managed infrastructure**. This ensures that when new resources are created using Terraform (e.g. Web Servers) and any additional configuration management tools (e.g. Ansible), it will not require an in-place upgrade/modification, or any data migration. The new resources can simply point to the external database, and redirect application traffic from the old instance to the new one. 

In the context of Cloud A/B, we can enforce the following to ensure immutability of resources:

    1. Restrict any Day 2 actions on the VRA Deployments --> The only Day 2 action allowed for developers is to delete their own deployments through Terraform. 

We also recognize that not all developers are comfortable with creating immutable infrastructure, as they are used to perform in-place upgrades of their application on their existing infrastructure. That's why we are offering an alternative approach to declaring resources in Cloud A/B. Developers can choose to create mutable infrastructure (through GUI) or create immutable infrastructure (through Terraform) that can be version-controlled by Gitlab.

### **3.3. Idempotency**
Idempotence is a principle of IaC where **certain operations can be applied multiple times without changing the results**. 

Terraform's configuration language is declarative by design, where developers can apply their configurations as many times as they want, but it will not change the end-state of the infrastructure. 

#### **References**
- https://www.redhat.com/en/topics/automation/what-is-infrastructure-as-code-iac
- https://learn.microsoft.com/en-us/devops/deliver/what-is-infrastructure-as-code
- https://www.hashicorp.com/resources/what-is-mutable-vs-immutable-infrastructure
- https://www.hashicorp.com/tao-of-hashicorp
- https://blogs.vmware.com/management/2020/01/infrastructure-as-code-and-vrealize-automation.html

## 4. Enabling CI/CD of Infrastructure Code
---

### **4.1. GitLab Design**
To be filled in on a later date.


## 5. Process Flow (For Developers)
---

The proposed developer process flow will be as follows: 
1. Developers spinning up a Jumphost Server (JH) in Cloud A/B
2. Git clone the Terraform Repository into JH and/or pull their custom Terraform configurations from their own repositories
3. Initialize Terraform Working Directory & get developer's VRA refresh token --> update it in their Terraform Variables file
4. Terraform init --> Terraform plan --> Terraform Apply

## 6. Milestones
---

### Main Deliverables
- [BARE MINIMUM] Complete Option #2 by March 2023
- [MEETING EXPECTATIONS] Complete Option #3 by March 2023
- [EXCEEDING EXPECTATIONS] Complete Option #4 by March 2023

### **Dec 2022**
- [ALL] 
  - Familiarize with the following in Cloud B: 
    - Gitlab Setup
    - Terraform Integration with VRA
    - Currently used VRA Workflows and Cloud Templates
- [Bob] 
  - Refactor VRA Catalog Items to have clear desired state

### **Jan 2022 - Feb 2022**
- [PERSON A + B] 
  - Configure Terraform Integration with VRA
  - Explore the use of Terraform Configurations in Cloud Templates
  - Create NSX Security Groups + Firewall Rules using Terraform Configurations declared in Cloud Templates
- [PERSON C + D] 
  - Create Gitlab Repo for Terraform-related binaries
  - Use external Terraform to create VRA Deployments in Cloud B
- [Bob]
  - Prepare for Demo (Developers' Process Flow) to showcase in Judging Panel

### **Mar 2022**
- [ALL] Judging Panel Dry-Run
- [ALL] Judging Panel


