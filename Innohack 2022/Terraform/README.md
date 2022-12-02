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
Terraform is written in Hashicorp Configuration Language (HCL) in files with .tf extension. Terraform creates infrastructure across a wide variety of platforms (providers). 

> **NOTE: Always refer to Terraform Provider Documentations!**
**Install Terraform**
   
        Windows: 
            choco install terraform 
        
        MacOS: 
            brew tap hashicorp/tap
            brew instal hashicorp/tap/terraform 
    
        Manual install: 
            Download from: https://developer.hashicorp.com/terraform/downloads?product_intent=terraform

**For this demo, create AWS Free Tier account**

---
**The first step to use Terraform is to configure a provider you want to use:**

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

---
**Run Terraform Init to initialize the backend**

    The terraform binary only contains basic functionality for Terraform, but does not come with code for any of the providers (e.g. AWS, Azure, GCP).  
    > *terraform init* scans the HCL code, figure out which provider is used, and download the code for them 

    By default, the provider code is downloaded into a *.terraform* folder (Terraform's scratch directory). Terraform records information about the provider code into a *.terraform.lock.hcl* file

---
**Run Terraform Plan**

    The plan command lets you see what Terraform will do before actually making any change --> good way to sanity check your code

    - Anything with a (+) sign will be created 
    - Anything with a (-) sign will be destroyed 
    - Anything with a (~) sign will be modified in place
---
**Run Terraform Apply**

    The apply command allows Terraform to create the declared resources
---
**To modify resources, you can edit on the main.tf file further, and run terraform apply**

---
**To delete resources, just run Terraform destroy**

There is no undo for the destroy command. Terraform will build the dependency graph and delete all resources in the correct order (using much parallelism as possible)

---
**Version Control**

Ideally, you would want to share your code with other team members. 

To create a local Git repository and use it to store Terraform configuration files and the lock file: 

        git init
        git add main.tf .terraform.lock.hcl
        git commit -m "Initial commit"

You should also create a .gitignore file with the following contents:

        .terraform
        *.tfstate
        *.tfstate.backup

The .gitignore file ignores the *.terraform* folder, which Terraform uses as a temporary scratch directory, as well as the **.tfstate* file, which Terraform uses to store state. 

Commit the .gitignore as well. 

        git add .gitignore
        git commit -m "Add a .gitignore file"

Configure your local Git repository to use the new GitHub repository as a remote endpoint named origin, as follows:
        
        git remote add origin git@github.com:<YOUR_USERNAME>/<YOUR_REPO_NAME>.git

Now, whenever you want to share your commits with your teammates, you can push them to origin:
        
        git push origin main    

If you want to know what your friends did, can pull from origin: 

        git pull origin main

---
To run additional post-provision scripts after your server is provisioned, AWS EC2 allows users to pass user data to configure servers after they are launched:      

        ========== main.tf ===========

        provider "aws" {
            region = "us-east-2"
        }

        resource "aws_instance" "example" {
            ami = "ami-0fb653ca2d3203ac1"
            instance_type = "t2.micro"
            vpc_security_group_ids = [aws_security_group.instance.id]

            user_data = <<-EOF
                        #!/bin/bash
                        echo "Hello, World" > index.xhtml
                        nohup busybox httpd -f -p 8080 &
                        EOF

            user_data_replace_on_change = true

            tags = {
                Name = "terraform-example"
            }
        }

        resource "aws_security_group" "instance" {
            name = "terraform-example-instance"

            ingress {
                from_port = 8080
                to_port = 8080
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
            }
        }

- <<-EOF and EOF are Terraform's heredoc syntax --> create multiline strings without having to insert \n characters
- user_data_replace_on_change = true --> When you change user_data parameter and run apply, Terraform will terminate the original instance and launch a totally new one (since user data scripts can only be run once upon boot)
- Create a new resource (AWS Security Group) to allow incoming TCP requests on port 8080 from CIDR block 0.0.0.0/0 (any traffic)

---
**To reference values from other resources**
   
To access the ID of the security group resource, you need a resource attribute reference: 

        <PROVIDER>_<TYPE>.<NAME>.<ATTRIBUTE>

> ATTRIBUTE: either one of the arguments of that resource (e.g. Name) or one of the attributes exported by the resource **(available in Provider documentations!)**

E.g. Security Groups export an attribute called id, so the expression to reference will be: 

         aws_security_group.instance.id

Adding references from one resource to another creates an implicit dependency. Terraform parses these dependencies, builds a dependency graph from them and use that to determine which order it should create resources. 

---
**To define input variables**
   
Terraform allows us to define input variables: 

        variable "NAME" {
            [CONFIG ...]
        }

The body of the variable declaration can contain the following optional parameters: 
- Description --> Use this parameter to document how a variable is used
- Default --> If no value is passed in, the variable will fall back to this default value
- Type --> Enforce type constrtaints on a variable a user pases in
    - String
    - Number
    - Boolean
    - List
    - Map
    - Set
    - Object
    - Tupie
    - Any
- Validation --> Define custom validation rules for the input variable that goes beyond basic type checks
- Sensitive --> Terraform will not log the parameter when you run plan or apply. Use this on any secrets you pass into Terraform code

        -- Example variable declaration --
        
        variable "object_example" {
            description = "An example of a structural type in Terraform"
            type = object({
                name = string
                age = number
                tags = list(string)
                enabled = bool
        })

To use the value from an input variable in your Terraform code, you can use a new type of expression called a variable reference, which has the following syntax:
            
            var.<VARIABLE_NAME>

For example, you can set the from_port and to_port parameters of the security group to the value of the server_port variable:

        resource "aws_security_group" "instance" {
            name = "terraform-example-instance"
            
            ingress {
                from_port = var.server_port
                to_port = var.server_port
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
            }
        }

To use a reference inside a string literal, you can use a new type of expression called interpolation: 

        ${...}

        Example:
            user_data = <<-EOF
                        #!/bin/bash
                        echo "Hello, World" > index.xhtml
                        nohup busybox httpd -f -p ${var.server_port} &
                        EOF

---
**To define output variables** 
    
Terraform also allows us to define output variables via the following syntax: 

        output "<NAME>" {
            value = <VALUE>
            [CONFIG ...]
        }

You can also include the following optional parameters: 
- Description --> document what type of data is contained in output variable
- Sensitive --> if parameter is true, Terraform will not log this output at the end of plan or apply (used to mask secrets)
- depends_on --> maps dependency of different resources in the configuration file 

E.g. to set IP Address as an output variable:
    
        output "public_ip" {
            value = aws_instance.example.public_ip
            description = "The public IP address of the web server"
        }

You can use terraform output to list down output values from the terraform apply. This is particularly useful for creating deployment scripts that run terraform apply to deploy a web server, use terraform output public_ip to grab the public IP, and curl the IP as a quick smoke test to validate that the deployment worked. 

        $ terraform output
        public_ip = "54.174.13.5"

Output Variable Details: https://developer.hashicorp.com/terraform/language/values/outputs

---
**To define lifecycles** 
    
Every Terraform resource supports several lifecycle settings that configure how the resource is created, updated and deleted.

E.g. set *create_before_destroy* --> Terraform will invert the order in which it replaces resources (create replacement resource first, then delete old resource)

        resource "aws_launch_configuration" "example" {
            image_id = "ami-0fb653ca2d3203ac1"
            instance_type = "t2.micro"

            security_groups = [aws_security_group.instance.id]

            user_data = <<-EOF
                        #!/bin/bash
                        echo "Hello, World" > index.xhtml
                        nohup busybox httpd -f -p ${var.server_port} &
                        EOF

            # Required when using a launch configuration with an auto scaling group.
            lifecycle {
                create_before_destroy = true
            }
        }

Full list of Parameters in Lifecycle meta-argument: https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle

---
**To use data sources** 
    
A Data Source = a piece of Read-only information that is fetched from the provider everytime you run Terraform --> Another way to query the provider's API for data to make the data available to the rest of the Terraform code. 

Syntax for using a data source: 

        data "<PROVIDER>_<TYPE>" "<NAME>" {
            [CONFIG ...]
        }

Example usage of Data Sources in Configuration code: 

        # Find the latest available AMI that is tagged with Component = web

        data "aws_ami" "web" {
        filter {
            name   = "state"
            values = ["available"]
        }

        filter {
            name   = "tag:Component"
            values = ["web"]
        }

        most_recent = true
        }

To get the data out of a data source, you use the following attribute reference syntax:

        data.<PROVIDER>_<TYPE>.<NAME>.<ATTRIBUTE>

You can combine data sources together:

        # E.g. data source aws_subnets, to look up the subnets within that VPC:

        data "aws_subnets" "default" {
            filter {
                name = "vpc-id"
                values = [data.aws_vpc.default.id]
            }
        }

Data Sources details: https://developer.hashicorp.com/terraform/language/data-sources

---
**To use data sources** 
    
A Data Source = a piece of Read-only information that is fetched from the provider everytime you run Terraform --> Another way to query the provider's API for data to make the data available to the rest of the Terraform code. 


## **Terraform - Command Cheatsheet**
---

| Command | Description |
| ------  | ----------- |
| terraform init  | Prepare the working directory for use with Terraform |
| terraform plan  | Generates an execution plan on what Terraform is provisioning |
| terraform apply  | Creates the resources based on the configuration files |
| terraform graph  | Shows a dependency map for resources created by Terraform |
| terraform output  | List all outputs of terraform apply without applying any changes |
| terraform destroy  | Delete all resources created by Terraform |

## **References**
---

- https://spacelift.io/blog/terraform-commands-cheat-sheet
- https://docs.github.com/en/get-started/getting-started-with-git/managing-remote-repositories
- https://linuxize.com/post/bash-heredoc/




