# **TERRAFORM - UP AND RUNNING: Writing Infrastructure as Code**

## **1. Why Terraform**
---
### **1.1. Benefits**
- Configuration Management vs Provisioning
- Mutable Infrastructure vs Immutable Infrastructure
- Procedural Language vs Declarative Language
  - E.g. Ansible --> Procedural Language, Terraform --> Declarative Language
  - State Management 
    - Procedural Code does not fully capture the state of the infrastructure --> Since state is constantly changing, resuability is limited 
      - E.g. In Ansible, you need to write an additional task to get the tags for each resource you manage, before performing your changes 
    - With Declarative code, all you need is to declare the end state that you want, and Terraform will figure out how to get to that end state
    - Terraform is also aware of state of infrastructure, will only create/destroy infrastructure that you have declared
- General Purpose Language (GPL) vs Domain Specific Language (DSL)
  - E.g. Terraform uses HCL (Hashicorp Configuration Language) --> DSL, Pulumi uses a variety of languages (Python, Javascript...) --> GPL
  - DSL > GPL
    - DSL is easier to learn, since it deals with 1 domain by design 
    - DSL is more specific (designed for one purpose) --> easier to understand and more concise than GPL
    - Code written in DSL is more uniform
  - DSL < GPL
    - Don't need to learn a new language when using GPL
    - More mature tooling --> since GPL is used in many domains (high number of IDEs and Libraries)
    - GPL --> more functionality 
- Master vs Masterless
  - E.g. Chef & Puppet --> require a Master Server
    - Pros
      - Central Control Plane to store infrastructure state of Infrastructure 
      - Can enforce configuration by running continuously in the background 
    - Cons
      - Extra Infrastructure to manage
      - Maintenance --> Upgrade/backup/monitor servers  
      - Security --> Need to establish communication [Client --> Master Server --> Other servers]
  - E.g. Terraform, Ansible, CloudFormation --> Masterless
    - Terraform talks to cloud providers using the Cloud Providers' API 
    - Ansible directly SSHs to other VMs 
- Agent vs Agentless
  - E.g. Chef and Puppet --> Install Agent software (run in the background of each server, responsible for installing latest config management updates)
    - Concerns:
      - Bootstrapping --> How to provision servers and install agent software on them in the first place?
      - Maintenance --> How to update agent software on a periodic basis?
      - Security --> Open additional ports for each server 
  - As a user of Terraform, you don’t need to worry about any of that: you just issue commands, and the cloud provider’s agents execute them for you on all of your servers


## **2. Terraform - Quickstart**
---
### **2.1. Deploy a Single Server**
Terraform is written in Hashicorp Configuration Language (HCL) in files with .tf extension. Terraform creates infrastructure across a wide variety of platforms (providers). 

> **NOTE: Always refer to Terraform Provider Documentations!**
0. Install Terraform 
   
        Windows: 
            choco install terraform 
        
        MacOS: 
            brew tap hashicorp/tap
            brew instal hashicorp/tap/terraform 
    
        Manual install: 
            Download from: https://developer.hashicorp.com/terraform/downloads?product_intent=terraform

1. The first step to use Terraform is to configure a provider you want to use: 

    Create an empty folder and put a file in it called **main.tf**
   
        provider "aws" {
            region = "us-east-2"
        }
    This tells Terraform that you will be using AWS as your provider and you want to deploy in the "us-east-2" region. 

    For each Provider, there are many different kinds of resources that can be created (e.g. Servers, Databases and LBs). The general syntax is: 

        resource "<PROVIDER>_<TYPE>" "<NAME>" {
            [CONFIG ...]
        }
    - PROVIDER = Name of provider 
    - TYPE = Type of resource to create in that provider
    - NAME = Identifier that you can use throughout your Terraform code
    - CONFIG = One or more arguments specific to that resource

    E.g. to create a single server in AWS, add the following in the main.tf file: 

        resource "aws_instance" "example" {
            ami = "ami-0fb653ca2d3203ac1"
            instance_type = "t2.micro"
        }

2. Run Terraform Init to initialize the backend

    The terraform binary only contains basic functionality for Terraform, but does not come with code for any of the providers (e.g. AWS, Azure, GCP).  
    > *terraform init* scans the HCL code, figure out which provider is used, and download the code for them 

    By default, the provider code is downloaded into a *.terraform* folder (Terraform's scratch directory). Terraform records information about the provider code into a *.terraform.lock.hcl* file

3. Run Terraform Plan

    The plan command lets you see what Terraform will do before actually making any change --> good way to sanity check your code

    - Anything with a (+) sign will be created 
    - Anything with a (-) sign will be destroyed 
    - Anything with a (~) sign will be modified in place

4. Run Terraform Apply

    The apply command allows Terraform to create the declared resources

5. To modify resources, you can edit on the .tf file further, and run terraform apply



## **Terraform - Command Cheatsheet**
---

| Command | Description |
| ------  | ----------- |
| terraform init  | Prepare the working directory for use with Terraform |
| terraform plan  | Generates an execution plan on what Terraform is provisioning |
| terraform apply  | Creates the resources based on the configuration files |

#### **References**
- https://spacelift.io/blog/terraform-commands-cheat-sheet


