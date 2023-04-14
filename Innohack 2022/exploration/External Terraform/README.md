# **External Terraform Integration**

"INSERT INTRODUCTION HERE"

## **Pre-requisites**
---
The developer is required to spin up a Jumphost server.


## **Observations**
---

### **Gitlab Design**

![GITLAB_DESIGN](../../images/4_gitlabDesign.png)

**Gitlab Project (Terraform) Contents:**
```
├── terraform-cli
│   ├── <TERRAFORM_CLI_BINARIES>       //  Allows developers to run Terraform commands on their Jumphost Servers
├── terraform-providers
│   ├── <TERRAFORM_PROVIDERS_BINARIES> //  Terraform Plugins that allow developers to interact with Cloud Providers (Specifically vRA) APIs
├── samples
│   └── sdc-terraform
│       ├── main.tf                    //  Sample Terraform Configuration File - developers can reference them to declare their resources
│       ├── variables.tf               //  Sample Terraform Variables File - to declare the parameters required for their resource creation (e.g. VM Name, VM T-shirt size etc.)
│       ├── outputs.tf                 //  Sample Terraform Outputs File - Output variables generated from your Terraform resources 
│       └── terraform.tfvars           //  Actual variables used in Terraform Runtime (e.g. vRA Refresh Token, vRA Project Name)
|
|
├── generate-access-token.sh           //  Generates vRA Refresh Token to be used in Developers' Terraform Configurations
├── terraform-setup.sh                 //  Setup Terraform CLI and Providers to be used in Developers' Jumphost Server
└── terraform-gitlab-init.sh           //  Initializes Terraform working directory, with Gitlab Project as backend
```

**Gitlab Group (terraform-cloud-b) Contents:**
```
├── terraform-cloud-b
│   └── vra
│       ├── networking
|       |   ├── firewall-ext-env-to-A
|       |   ├── firewall-A-to-A
|       |   └── firewall-ext-env-to-A-tanzu
│       └── virtual-machines
|           ├── ubuntu-mate            // Terraform Module (Expanded)
|           │   ├── main.tf            //  Terraform Configuration that contains resources created from this Module
|           │   ├── variables.tf       //  pre-defined variables that are used in this Terraform Module
|           │   ├── outputs.tf         //  Terraform Output variables after resource is created
|           ├── ubuntu
|           ├── rhel
|           └── windows
```

### **Terraform Module Design**

Terraform Modules are containers for multiple resources that are used together in a Terraform Configuration. It allows developers to create reusable components in their Terraform configurations.

In the context of Cloud A/B, **1 Terraform Module will be associated to 1 vRA catalog item.** Developers will reference our Terraform Modules in their Terraform configuration files, in order to declare what Cloud resources they want to create. 

```
Terraform --(Manages)--> vRA Deployments --(Manages)--> Cloud Resources
```

You can refer to a sample Module configuration [**here**](sample-module/firewall/main.tf): 


The vra_deployment resource is offered by Terraform's vRA Provider to create vRA deployments through Terraform. Each Terraform Module will have a variable that points to its respective Catalog Item name. 

#### **Limitations**

However, there are some limitations in using vra_deployment resource as our main resource block:

1. Terraform directly manages vRA Deployments, and deployments are a container to hold the created resources. **Terraform State and the state of Cloud resources are not synchronized**.

In the event when the state of the Cloud Resources have been changed (i.e. a Firewall Rule gets modified, VM changes its CPU), vRA Deployments do not reflect those changes in these Cloud Resources. As a result, Terraform does not detect a configuration drift, since the state of the vRA Deployment remains unchanged. 

2. **You cannot trigger Day 2 actions on vRA Deployments through Terraform.**

When you attempt to modify the vRA deployment resource parameters, Terraform will throw an error saying that "The Update action is currently not supported."


The primary use-case for the null_resource is as a do-nothing container for arbitrary actions taken by a developer. 

 In this example, three EC2 instances are created and then a
 null_resource instance is used to gather data about all three
 and execute a single action that affects them all. Due to the triggers
 map, the null_resource will be replaced each time the instance ids
 change, and thus the remote-exec provisioner will be re-run.

The null_resource is an empty resource block that keeps track

---
## **References**
- https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource
- https://registry.terraform.io/providers/vmware/vra/latest/docs/resources/vra_deployment