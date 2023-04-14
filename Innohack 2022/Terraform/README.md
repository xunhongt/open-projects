# **TERRAFORM - UP AND RUNNING: Writing Infrastructure as Code**

## Refer to Sample Code [Here](https://github.com/brikis98/terraform-up-and-running-code)

## **1. Why Terraform**
---
### **Benefits**
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

### > **NOTE: Always refer to Terraform Provider Documentations!**
### **Install Terraform**
   
        Windows: 
            choco install terraform 
        
        MacOS: 
            brew tap hashicorp/tap
            brew instal hashicorp/tap/terraform 
    
        Manual install: 
            Download from: https://developer.hashicorp.com/terraform/downloads?product_intent=terraform

**For this demo, create AWS Free Tier account**

---
###  **The first step to use Terraform is to configure a provider you want to use:**

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
### **Run Terraform Init to initialize the backend**

    The terraform binary only contains basic functionality for Terraform, but does not come with code for any of the providers (e.g. AWS, Azure, GCP).  
    > *terraform init* scans the HCL code, figure out which provider is used, and download the code for them 

    By default, the provider code is downloaded into a *.terraform* folder (Terraform's scratch directory). Terraform records information about the provider code into a *.terraform.lock.hcl* file

---
### **Run Terraform Plan**

    The plan command lets you see what Terraform will do before actually making any change --> good way to sanity check your code

    - Anything with a (+) sign will be created 
    - Anything with a (-) sign will be destroyed 
    - Anything with a (~) sign will be modified in place
---
### **Run Terraform Apply**

    The apply command allows Terraform to create the declared resources
---
### **To modify resources, you can edit on the main.tf file further, and run terraform apply**

---
### **To delete resources, just run Terraform destroy**

There is no undo for the destroy command. Terraform will build the dependency graph and delete all resources in the correct order (using much parallelism as possible)

---
### **Version Control**

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
### **To reference values from other resources**
   
To access the ID of the security group resource, you need a resource attribute reference: 

        <PROVIDER>_<TYPE>.<NAME>.<ATTRIBUTE>

> ATTRIBUTE: either one of the arguments of that resource (e.g. Name) or one of the attributes exported by the resource **(available in Provider documentations!)**

E.g. Security Groups export an attribute called id, so the expression to reference will be: 

         aws_security_group.instance.id

Adding references from one resource to another creates an implicit dependency. Terraform parses these dependencies, builds a dependency graph from them and use that to determine which order it should create resources. 

---
### **To define input variables**
   
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
### **To define output variables** 
    
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
### **To define lifecycles** 
    
Every Terraform resource supports several lifecycle settings that configure how the resource is created, updated and deleted.

- set *create_before_destroy* --> Terraform will invert the order in which it replaces resources (create replacement resource first, then delete old resource)
- set *prevent_destroy* --> Will cause Terraform to exit with error, if user decides to destroy resource 

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
### **To use data sources** 
    
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


## **3. Managing Terraform State**

---
### **Terraform State** 
    
When you run Terraform in a working directory, a *terraform.tfstate* is created: 
- Custom JSON format that records a mapping from the TErraform resources in your configuration files, to the representation of those resources in the real world. 
- E.g. Resource with type *aws_instance* and name *example* corresponds to an EC2 instance in AWS account with ID xxx 
> State File format is a private API that is meant only for internal use within Terraform --> **NEVER EDIT THE TERRAFORM STATE FILES**

Only useful if you are **storing state for a personal project**. To use Terraform as a Team on a real project:
- Shared Storage for State Files --> Need to store them in a shared location
- Locking State Files --> Prevent race conditions from happening when Terraform state files are concurrently updated 
- Isolating State Files --> Best practice to isolate different environments 

---
### **Terraform Backend** 

Terraform's built-in support for remote backend --> Alternative approach to store State Files in a shared location
- Determines how Terraform loads and stores state 
- Default Backend = Local Backend --> Stores state files on local disk 

Pros of using Terraform Remote Backends:
- Prevent Manual Error --> Terraform will automatically load state file from backend everytime you run Plan or Apply 
- Allow Locking of State Files --> Most Remote Backends natively support locking; Running Terraform Apply will automatically create a lock (can configure timeout for lock)
- Allow use of Secrets --> Most Remote Backends support Encryption in Transit/Rest of State File

To create Terraform Backend, add the following to your Terraform Code: 

        terraform {
            backend "<BACKEND_NAME>" {
                [CONFIG...]
            }
        }
- BACKEND_NAME = Name of the backend you want to use (e.g. S3)
- CONFIG = One or more Arguments that are specific to the backend

> This Demo uses AWS S3 as its Terraform Backend, and State File locking via DynamoDB

**1. Terraform Configuration to create S3 and DynamoDB on AWS** 

        -- main.tf --

        #======= PROVIDER ===========
        
        provider "aws" {
            region = "us-east-2"
        }

        #======= CREATE S3 BUCKET ===========
        
        resource "aws_s3_bucket" "terraform_state" {
            bucket = "terraform-up-and-running-state"

            # Prevent accidental deletion of this S3 bucket
            lifecycle {
                prevent_destroy = true
            }
        }

        #======= ENABLE BUCKET VERSIONING - see the full revision history of your state files ===========
        
        resource "aws_s3_bucket_versioning" "enabled" {
            bucket = aws_s3_bucket.terraform_state.id

            versioning_configuration {
                status = "Enabled"
            }
        }

        #======= ENABLE SERVER-SIDE ENCRYPTION ===========

        resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
            bucket = aws_s3_bucket.terraform_state.id
            
            rule {
                apply_server_side_encryption_by_default {
                    sse_algorithm = "AES256"
                }
            }
        }

        #======= BLOCK ALL PUBLIC ACCESS TO S3 BUCKET ===========
        
        resource "aws_s3_bucket_public_access_block" "public_access" {
            bucket = aws_s3_bucket.terraform_state.id
            block_public_acls = true
            block_public_policy = true
            ignore_public_acls = true
            restrict_public_buckets = true
        }

        #======= CREATE DYNAMODB TABLE ===========
        
        resource "aws_dynamodb_table" "terraform_locks" {
            name = "terraform-up-and-running-locks"
            billing_mode = "PAY_PER_REQUEST"
            hash_key = "LockID"

            attribute {
                name = "LockID"
                type = "S"
            }
        }

**2. Terraform Configuration to add Backend** 

        -- main.tf --
        
        terraform {

        #======= SET BACKEND ===========

            backend "s3" {
                # Replace this with your bucket name!
                bucket = "terraform-up-and-running-state"
                key = "global/s3/terraform.tfstate"
                region = "us-east-2"

                # Replace this with your DynamoDB table name!
                dynamodb_table = "terraform-up-and-running-locks"
                encrypt = true
            }

        }

        #======= OUTPUT VARIABLES TO SHOW S3 BUCKET ARN for Backend ===========

        output "s3_bucket_arn" {
            value = aws_s3_bucket.terraform_state.arn
            description = "The ARN of the S3 bucket"
        }

        output "dynamodb_table_name" {
            value = aws_dynamodb_table.terraform_locks.name
            description = "The name of the DynamoDB table"
        }

Once you run *terraform init*, Terraform will automatically detect that you already have a state file locally and prompt you to copy it to the new S3 backend.

Terraform automatically push and pulls state to/from S3, and S3 is storing every revision of the state file. 


Terraform Backend Details: https://developer.hashicorp.com/terraform/language/settings/backends/configuration
Gitlab Managed Terraform State: https://docs.gitlab.com/ee/user/infrastructure/iac/terraform_state.html

**3. Terraform Backend - Limitations** 
- [IN THE INSTANCE OF THIS DEMO]: Need to deploy S3 + DynamoDB with a local backend first
  - Add Remote backend configuration in Terraform code, and run terraform init to copy local state to S3
  - If you want to delete the S3 Bucket and DynamoDB --> need to remove backend config, run terraform init to copy Terraform state back to local disk; then run Terraform destroy
- **Backend Block in Terraform does not allow you to use any variables/references**
  - Need to manually copy the S3 bucket name, region etc. into every Terraform module

---
### *To isolate State Files:** 

**1. Workspaces**

Terraform Workspaces allow users to store Terraform states in multiple separate, named workspaces.
- It starts with a single workspace called "default"

Workspace-related commands:

        terraform workspace show --> shows current workspace used in Terraform

        terraform workspace new <WORKSPACE_NAME> --> Creates a new workspace 

        terraform workspace list --> shows list of created workspaces in Terraform

        terraform workspace select <WORKSPACE_NAME> --> Choose your selected workspace 

If a new workspace is selected, and you are running a remote-backend, a separate state file will be created in the working directory.

Pros:
- Quick method to establish isolation of resources within a personal project

Cons: 
- State files of all workspaces are stored in the same backend --> Same authentication and access controls are used for all workspaces 
- Workspaces are not visible in the code/terminal unless you run the *terraform workspace* command --> Likely to create errors in IaC code

> **Because of these drawbacks, workspaces are not a suitable mechanism for isolating one environment from another (e.g. Isolating Staging from Production)**

Workspace details: https://developer.hashicorp.com/terraform/cloud-docs/workspaces

**2. File Layout**

To achieve full isolation between environments, you need to do the following: 
- Put Terraform configuration files for each environment into a separate folder 
  - E.g. Staging configurations --> put in *Stage* folder; Production configurations --> put in *Prod* folder
- Configure different backend for each environment using different authentication mechanisms and access controls

This isolation concept can also be applied to Terraform Modules and your various components.

**Example Directory Structure:**
- Stage
  - VMs
    - variables.tf
    - outputs.tf
    - main.tf
  - Network
    - variables.tf
    - outputs.tf
    - main.tf
- Prod
  - VMs
    - variables.tf
    - outputs.tf
    - main.tf
  - Network
    - variables.tf
    - outputs.tf
    - main.tf
- Global
  - backend
    - main.tf
    - outputs.tf

Within each component, there are Terraform configuration files, which are organized according to the following naming conventions: 

[MINIMUM]
- variables.tf --> Input Variables
- outputs.tf --> Output Variables
- main.tf --> Resources and data sources 

[OPTIONAL]
- dependencies.tf --> Put all data sources in a dependencies.tf file to make it easier to see what external things the code depends on
- providers.tf --> Put all provider blocks into a providers.tf file to keep track of what providers the code talks to, and what authentication methods you need
- main-xxx.tf --> Further segregate your Terraform resources based on components

> When you run Terraform, it simply looks for files in the current directory with the .tf extension --> can use whatever filenames you want! 

> When moving contents within each folder, make sure to move the .terraform folder as well --> Don't need to reinitialize everything!

Pros:
- Clear code/environment layout 
- Isolation of configuration across different environments --> Limit blast radius for wrong configurations

Cons:
- Working with multiple folders --> Will need to run Terraform apply separately in each folder
  - [SOLUTION] terragrunt --> use the run-all command
- Requires a lot of duplication (many copy/paste)
  - [SOLUTION] Can Terraform modules to keep the code DRY (Don't Repeat Yourself)
- Hard to use Resource Dependencies --> Since Infrastructure lies in different folders
  - [SOLUTION] terragrunt --> dependency blocks 
  - [SOLUTION] terraform_remote_state

Directory Structure: https://developer.hashicorp.com/terraform/language/modules/develop/structure

---
### **terraform_remote_state Data Source** 
You can use this data source to fetch the Terraform state file stored by another set of Terraform configurations. 

To call a terraform_remote_state Data Source: 

        data "terraform_remote_state" "db" {
            backend = "s3"

            config = {
                bucket = "(YOUR_BUCKET_NAME)"
                key = "stage/data-stores/mysql/terraform.tfstate"
                region = "us-east-2"
            }
        }

The config of the terraform_remote_state Data Source refers to the remote backend Terraform State stored on AWS S3. 

Like all data sources, the data returned is read-only. 

To read a terraform_remote_state data source using an attribute reference: 

        data.terraform_remote_state.<NAME>.outputs.<ATTRIBUTE>

terraform_remote_state Data Source: https://developer.hashicorp.com/terraform/language/state/remote-state-data

---
### **templatefile Function** 
Terraform includes a number of built-in functions that allow us to execute using an expression of the form: 

        function_name(...)

        e.g. format(<FMT>, <ARGS>, ...)

*templatefile* reads the file at the given path and renders its content as a template using a supplied set of template variables. This reduces the need to define inline scripts to make your Terraform configurations messier. 

To call a templatefile function: 

        templatefile(<PATH>, <VARS>)

This means the file at PATH can use the string interpolation syntax in Terraform (${...}) and Terraform will render the contents of the file, filling variable references from VARS. 

        Example: creating a stage/services/webserver-cluster/user-data.sh

            #!/bin/bash
            cat > index.xhtml <<EOF
            <h1>Hello, World</h1>
            <p>DB address: ${db_address}</p>

            <p>DB port: ${db_port}</p>
            EOF
            nohup busybox httpd -f -p ${server_port} &

        Calling the templatefile function and pass it in the variables as a map within the Terraform Configuration: 

            resource "aws_launch_configuration" "example" {
                image_id = "ami-0fb653ca2d3203ac1"
                instance_type = "t2.micro"
                security_groups = [aws_security_group.instance.id]

                # Render the User Data script as a template
                user_data = templatefile("user-data.sh", {
                    server_port = var.server_port
                    db_address = data.terraform_remote_state.db.outputs.address
                    db_port = data.terraform_remote_state.db.outputs.port
                })

                # Required when using a launch configuration with an auto scaling group.
                lifecycle {
                    create_before_destroy = true
                }
            }


templatefile Function: https://developer.hashicorp.com/terraform/language/functions/templatefile

## **4. Terraform Modules**
You can put your code inside a Terraform Module and reuse that module in multiple places throughout your code --> To create reusable, maintainable and testable Terraform code. 

---
### **Module Basics**
Any set of Terraform configuration files in a folder is called a Module. If you run apply directly on a module, it's referred to as a root module. 

To use a module in your Terraform Code: 

        module "<NAME>" {
            source = "<SOURCE>"
            [CONFIG ...]
        }

- NAME = An identifier that you can use through the Terraform code to refer to this module
- SOURCE = Path where the module code can be found 
- CONFIG = Arguments specific to the module

        -- Example -- 

        provider "aws" {
            region = "us-east-2"
        }

        # This module can be reused if you state the file path of the module in the source
        module "webserver_cluster" {
            source = "../../../modules/services/webserver-cluster"
        }

NOTE: If you use modules in different environments using this method, the Method configurations are hard-coded; so if you use this module more than once in the same AWS account, you'll get name conflict errors. 

> **Need to add configurable inputs to the module, so that it can behave differently in different environments.**  

---
### **Module Inputs**
Terraform Modules can have input parameters as well. To use inputs, use input variables.

**1. Create a variables.tf file in the module root directory**

        -- variables.tf --

        variable "cluster_name" {
            description = "The name to use for all the cluster resources"
            type = string
        }

        variable "db_remote_state_bucket" {
            description = "The name of the S3 bucket for the database's remote state"
            type = string
        }

        variable "db_remote_state_key" {
            description = "The path for the database's remote state in S3"
            type = string
        }

**2. Edit main.tf file & terraform_remote_state in module root directory to use variables**

        -- main.tf --

        resource "aws_security_group" "alb" {
            name = "${var.cluster_name}-alb"

            ingress {
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
            }

            egress {
                from_port = 0
                to_port = 0
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
            }
        }

        -- terraform_remote_state --

        data "terraform_remote_state" "db" {
            backend = "s3"

            config = {
                bucket = var.db_remote_state_bucket
                key = var.db_remote_state_key
                region = "us-east-2"
            }
        }

- ${var.cluster_name} --> used when you want to add it in a string 

**3. Update your desired Terraform Configuration file to include the Module inputs**

        module "webserver_cluster" {
            source = "../../../modules/services/webserver-cluster"

            cluster_name = "webservers-stage"
            db_remote_state_bucket = "(YOUR_BUCKET_NAME)"
            db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"
        }

Input Values: https://developer.hashicorp.com/terraform/language/values/variables
Creating Modules: https://developer.hashicorp.com/terraform/language/modules/develop

---
### **Module Locals**
You can use local values to assign a name to any Terraform expression and to use that name throughout the module --> Local variables

To define local values in a local block within your Terraform code: 

        locals {
            http_port = 80
            any_port = 0
            any_protocol = "-1"
            tcp_protocol = "tcp"
            all_ips = ["0.0.0.0/0"]
        }

To use a local value: 

        local.<VARIABLE_NAME>

Example usage of a local value: 

        -- main.tf -- 

        resource "aws_lb_listener" "http" {
            load_balancer_arn = aws_lb.example.arn
            port = local.http_port
            protocol = "HTTP"

            # By default, return a simple 404 page
            default_action {
                type = "fixed-response"

                fixed_response {
                    content_type = "text/plain"
                    message_body = "404: page not found"
                    status_code = 404
                }
            }
        }

Local Values: https://developer.hashicorp.com/terraform/language/values/locals

---
### **Module Output**
You can output variables to create output variables to be used for each Terraform Module. This can be defined in the outputs.tf file within the Module root directory.

        -- outputs.tf -- 

        output "asg_name" {
            value = aws_autoscaling_group.example.name
            description = "The name of the Auto Scaling Group"
        }

To access a Module output variable: 

        module.<MODULE_NAME>.<OUTPUT_NAME>

        e.g. module.frontend.asg_name

Output Values: https://developer.hashicorp.com/terraform/language/values/outputs

---
### **Module Gotchas**

**1. Path References**

When you use File Paths (in templatefile), Terraform interprets the path relative to the current working directory
> **templatefile will not work if you use templatefile in a module that's defined in a separate folder (a reusable module)**

To resolve this issue, you use an expression called *path reference* which is of the form path.<"TYPE">: 
- path.module --> Returns Filesystem path of module where expression is defined
- path.root --> Returns Filesystem path of the root module
- path.cwd --> Returns Filesystem path of current working directory

        E.g. to use Path References: 

        user_data = templatefile("${path.module}/user-data.sh", {
            server_port = var.server_port
            db_address = data.terraform_remote_state.db.outputs.address
            db_port = data.terraform_remote_state.db.outputs.port
        })

**2. Inline Blocks**

Terraform configurations can be defined as inline blocks or separate resources. 

An inline block is an argument that you set within a resource of the format. 

        E.g. Inline Block: 

        resource "xxx" "yyy" {
            <NAME> {
                [CONFIG...]
            }
        }
- NAME --> Name of the inline block (e.g. ingress)
- CONFIG --> One or more arguments specific to that inline block

You can then define resources (e.g. ingress & egress rules) using either inline blocks (within aws_security_group resource) or separate resources (aws_security_group_rule resources).

> **If you try mixing both inline blocks and separate resources, due to how Terraform is designed, you will get errors where configurations conflict and overwrite one another.**

> **NOTE: Always use separate resources when creating a module!**

Using separate resources allow them to be used anywhere, whereas an inline block can only be added within the module that creates a resource --> Makes your module more flexible and configurable 

E.g. for AWS security groups: 

        -- To use Inline Blocks -- 

        resource "aws_security_group" "alb" {
            name = "${var.cluster_name}-alb"


            ingress {
                from_port = local.http_port
                to_port = local.http_port
                protocol = local.tcp_protocol
                cidr_blocks = local.all_ips
            }

            egress {
                from_port = local.any_port
                to_port = local.any_port
                protocol = local.any_protocol
                cidr_blocks = local.all_ips
            }
        }
There is no way for the user of the module to add additional ingress/egress rules from outside of this module. 

        -- To use Separate Resources -- 

        resource "aws_security_group" "alb" {
            name = "${var.cluster_name}-alb"
        }

        resource "aws_security_group_rule" "allow_http_inbound" {
            type = "ingress"
            security_group_id = aws_security_group.alb.id
            from_port = local.http_port
            to_port = local.http_port
            protocol = local.tcp_protocol
            cidr_blocks = local.all_ips
        }

        resource "aws_security_group_rule" "allow_all_outbound" {
            type = "egress"
            security_group_id = aws_security_group.alb.id
            from_port = local.any_port
            to_port = local.any_port
            protocol = local.any_protocol
            cidr_blocks = local.all_ips
        }

If you want to expose an extra port in the Staging environment SG, can always add an aws_security_group_rule resource to your main.tf file: 

        module "webserver_cluster" {
            source = "../../../modules/services/webserver-cluster"

            # (parameters hidden for clarity)
        }

        resource "aws_security_group_rule" "allow_testing_inbound" {
            type = "ingress"
            security_group_id = module.webserver_cluster.alb_security_group_id

            from_port = 12345
            to_port = 12345
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }

---
### **Module Versioning**
Terraform Module source parameters support the following types of module sources: 
- Local File Path
- Git URLs
- Mercurial URLs
- arbitrary HTTP URLs

You can use this to version your modules so that different environments can point to different versions of the module. 

You can put the code for the module in a separate Git repository, and set the source parameter to the repository's URL --> Spread out the Terraform code to at least 2 repositories: 
- modules --> to store reusable modules 
- live --> live infrastructure that you are running in your environment  

Example File Directory: 
- modules
  - services
    - webserver-cluster
- live
  - stage
    - webserver-cluster
    - data-stores
      - mysql
  - prod
    - services
      - webserver-cluster
    - data-stores
      - mysql
  - global
    - s3

To use a versioned module, call the following in the main.tf of your Terraform Configurations: 

        module "webserver_cluster" {
            source = "github.com/foo/modules//services/webserver-cluster?ref=v0.0.1"

            cluster_name = "webservers-stage"
            db_remote_state_bucket = "(YOUR_BUCKET_NAME)"
            db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"

            instance_type = "t2.micro"
            min_size = 2
            max_size = 2
        }

Can try using semantic versioning naming conventions: 
- The MAJOR version when you make incompatible API changes
- The MINOR version when you add functionality in a backwardcompatible manner
- The PATCH version when you make backward-compatible bug fixes

## **5. Terraform Tips and Tricks: Loops, If-Statements, Deployment and Gotchas**

---
### **Loops**
You can use the following looping constructs to iterate in your Terraform Code: 

**1. count**
Every Terraform resource has a meta-parameter called count. It defines how many copies of the resource are required to create. 

To use the *count* parameter:

        #--- This creates 3 IAM users called "Neo" ---

        resource "aws_iam_user" "example" {
            count = 3
            name = "neo"
        }

        #--- To get the index of each iteration in the loop ---
        # This creates 3 IAM users called ("neo.0", "neo.1", "neo.2")

        resource "aws_iam_user" "example" {
            count = 3
            name = "neo.${count.index}"
        }

You can also define an array variable to be iterated: 

        #--- Define an Array variable called user_names ---

        variable "user_names" {
            description = "Create IAM users with these names"
            type = list(string)
            default = ["neo", "trinity", "morpheus"]
        }

Array lookup Syntax: 

        ARRAY[<INDEX>]

        e.g. var.user_names[1]

You can combine the Array variable with the *length* parameter to loop through an Array: 

        #--- To declare the length function ---

        length(<ARRAY>)

        #--- To loop through an Array in Terraform ---

        resource "aws_iam_user" "example" {
            count = length(var.user_names)
            name = var.user_names[count.index]
        }

Once you used count on a resource, it becomes an array of resources, which can be accessed via the following: 

        <PROVIDER>_<TYPE>.<NAME>[INDEX].ATTRIBUTE

        #----- E.g. To return the output for the first IAM User's ARN -----:

        output "first_arn" {
            value = aws_iam_user.example[0].arn
            description = "The ARN for the first user"
        }

        #----- E.g. To return all IAM User's ARNs -----:

        output "first_arn" {
            value = aws_iam_user.example[*].arn
            description = "The ARN for the first user"
        }

As of Terraform 0.13, you can also use the *count* parameter on modules. 

        #----- Terraform Code -----

        module "users" {
            source = "../../../modules/landing-zone/iam-user"

            count = length(var.user_names)
            user_name = var.user_names[count.index]
        }

        #----- Output Variables -----

        output "user_arns" {
            value = module.users[*].user_arn
            description = "The ARNs of the created IAM users"
        }

Pros: 
- *count* works pretty well with resources & modules

Cons:
- You cannot *count* within a resource to loop over inline blocks 
- Terraform identifies each resource within the array by its position (index) in that array. If you remove an item from the middle of an array, all items after it will be modified/deleted

**2. for_each**
The *for_each* expression allows you to loop over lists, sets and maps to create the following: 
- multiple copies of an entire resource
- multiple copies of an inline block within a resource
- multiple copies of a module

*for_each* syntax: 

        resource "<PROVIDER>_<TYPE>" "<NAME>" {
            for_each = <COLLECTION>
            [CONFIG ...]
        }
- COLLECTION --> Set/map to loop over 
  - Lists are not supported when using *for_each* on a resource
- CONFIG --> one or more arguments that are specific to that resource 
  - You can use *each.key* / *each.value* to access the key/value of the current item in COLLECTION 

        #--- E.g. for_each on the variable user_names ----

        resource "aws_iam_user" "example" {
            for_each = toset(var.user_names)
            name = each.value
        }

        #--- Output: Map of created users ---
        output "all_users" {
            value = aws_iam_user.example
        }

        #--- Output: To return all the the ARNs of the created users ---
        output "all_arns" {
            value = values(aws_iam_user.example)[*].arn
        }
- *toset* --> convert var.user_names list into a set 
- *values* --> return all the values within the map

Once you use *for_each* on a resource, it becomes a map of resources. If you remove an item from the middle of a collection, it will not impact the rest of the resources. 

> **You should favour the use of for_each instead of count to create multiple copies of a resource**

To use *for_each* in modules: 

        #---- Defined in the module ----

        module "users" {
            source = "../../../modules/landing-zone/iam-user"

            for_each = toset(var.user_names)
            user_name = each.value
        }

        #---- Defined in output variables ----

        output "user_arns" {
            value = values(module.users)[*].user_arn
            description = "The ARNs of the created IAM users"
        }

You can also use *for_each* to iterate inline blocks within a resource: 

        dynamic "<VAR_NAME>" {
            for_each = <COLLECTION>

            content {
            [CONFIG...]
            }
        }

- VAR_NAME --> Name to use for the variable that will store the value of each iteration (After state)
- COLLECTION --> list/map to iterate over
- CONTENT --> What to generate for each iteration 
  - Can use <VAR_NAME>.key / <VAR_NAME>.value within the content block to access the key & value respectively

## **Terraform - Command Cheatsheet**
---

| Command | Description |
| ------  | ----------- |
| terraform init  | Prepare the working directory for use with Terraform; also configures your Terraform Backend |
| terraform plan  | Generates an execution plan on what Terraform is provisioning |
| terraform apply  | Creates the resources based on the configuration files |
| terraform destroy  | Delete all resources created by Terraform |
| terraform graph  | Shows a dependency map for resources created by Terraform |
| terraform output  | List all outputs of terraform apply without applying any changes |
| terraform workspace  | Perform workspace related commands on Terraform |


## **References**
---

- https://spacelift.io/blog/terraform-commands-cheat-sheet
- https://docs.github.com/en/get-started/getting-started-with-git/managing-remote-repositories
- https://linuxize.com/post/bash-heredoc/




