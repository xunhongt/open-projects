# **The NSX Terraform Provider**

The NSX Terraform provider gives the NSX administrator a way to automate NSX to provide virtualized networking and security services using both ESXi and KVM based hypervisor hosts as well as container networking and security.

---
## **1. Basic Configuration**

In order to use the NSX Terraform provider you must first configure the provider to communicate with the **VMware NSX manager**, which serves the NSX-T REST API and provides a way to configure desired state of the NSX System. 

### **Using the Provider**
As of 17 Jan 2023, the latest version of this provider requires Terraform v0.12 or higher to run.

The VMware supported version of the provider requires **NSX version 3.0.0 onwards** and **Terraform 0.12 onwards**. Version 2.0.0 of the provider offers NSX consumption via policy APIs, which is the recommended way. Most policy resources are supported with NSX version 3.0.0 onwards, however some resources or attributes require later releases. Please refer to documentation for more details. The recommended vSphere provider to be used in conjunction with the NSX-T Terraform Provider is 1.3.3 or above.

Note that you need to run terraform init to fetch the provider before deploying.

### **Argument Reference**
The following arguments are used to configure the VMware NSX-T Provider:

| Parameter | Required? | Description |
| --------- | --------- | ----------- |
| host      | Yes       | The host name or IP address of the NSX-T manager. Can also be specified with the NSXT_MANAGER_HOST environment variable. Do not include http:// or https:// in the host. |
| username  | Yes        | The user name to connect to the NSX-T manager as. Can also be specified with the NSXT_USERNAME environment variable. |
| password  | Yes        | The password for the NSX-T manager user. Can also be specified with the NSXT_PASSWORD environment variable. |
| allow_unverified_ssl  | No        | Boolean that can be set to true to disable SSL certificate verification. This should be used with care as it could allow an attacker to intercept your auth token. If omitted, default value is false. Can also be specified with the NSXT_ALLOW_UNVERIFIED_SSL environment variable. |
| max_retries  | No        | The maximum number of retires before failing an API request. Default: 4 Can also be specified with the NSXT_MAX_RETRIES environment variable. For Global Manager, it is recommended to increase this value since slower realization times tend to delay resolution of some errors. |

*The full list can be found on the Terraform Registry Page

---
## **2. Sample Terraform Configurations**

### **Terraform Block** 
This configuration block type is used to configure some behaviours of Terraform itself e.g. require a minimum Terraform version to apply your configurations.

    terraform {
    required_providers {
        nsxt = {
          source = "vmware/nsxt"
          version = "~> 3.2"
        }
      }
    }

### **Provider Block - with Credentials** 
Update attributes like host, username and password to match your NSX Deployment. 

    provider "nsxt" {
      host                 = "<IP_ADDRESS>"
      username             = "<NSX_MANAGER_USERNAME>"
      password             = "<NSX_MANAGER_PASSWORD>"
      allow_unverified_ssl = true                       # If true, Terraform Client skips server certificate verification.
      max_retries          = 2
    }

### **Resource Block - [nsxt_policy_group](https://registry.terraform.io/providers/vmware/nsxt/latest/docs/resources/policy_group)**
This resource is used to create a security group within NSX. 

    resource "nsxt_policy_group" "group1" {
      display_name = "tf-group1"
      description  = "Terraform provisioned Security Group"

      #--- Good to know - Can select VMs based on filter to be added into SG ---
      criteria {
        condition {
          key         = "Name"
          member_type = "VirtualMachine"
          operator    = "STARTSWITH"
          value       = "public"
        }
        condition {
          key         = "OSName"
          member_type = "VirtualMachine"
          operator    = "CONTAINS"
          value       = "Ubuntu"
        }
      }

      conjunction {
          operator = "OR"
      }

      #--- Likely to use this ---
      criteria {
          ipaddress_expression {
            ip_addresses = ["211.1.1.1", "212.1.1.1", "192.168.1.1-192.168.1.100"]
          }
      }
  
      conjunction {
          operator = "OR"
      }
  
      #--- Slightly Relevant - Might need this as well. Need to test ---
      criteria {
          external_id_expression {
            member_type  = "VirtualMachine"
            external_ids = ["520ba7b0-d9f8-87b1-6f44-15bbeb7935c7", "52748a9e-d61d-e29b-d54b-07f169ff0ee8-4000"]
          }
      }
    }

### **Resource Block - [nsxt_policy_security_policy](https://registry.terraform.io/providers/vmware/nsxt/latest/docs/resources/policy_security_policy)**
This resource is used to create a Distributed Firewall (DFW) within NSX.  
  
    resource "nsxt_policy_security_policy" "policy1" {
        display_name = "policy1"
        description  = "Terraform provisioned Security Policy"
        category     = "Application"
        locked       = false
        stateful     = true
        tcp_strict   = false
        scope        = [nsxt_policy_group.pets.path]   #Likely output value for the Security Group Path 
    
        rule {
        display_name       = "block_icmp"
        destination_groups = [nsxt_policy_group.cats.path, nsxt_policy_group.dogs.path]
        action             = "DROP"
        services           = [nsxt_policy_service.icmp.path]
        logged             = true
        }

        #--- Can use a Map + For_Each to create a list of rules to create? ---

        rule {
        display_name     = "allow_udp"
        source_groups    = [nsxt_policy_group.fish.path]
        sources_excluded = true
        scope            = [nsxt_policy_group.aquarium.path]
        action           = "ALLOW"
        services         = [nsxt_policy_service.udp.path]
        logged           = true
        disabled         = true
        notes            = "Disabled by starfish for debugging"
        }
    }

### **Resource Block - [nsxt_policy_gateway_policy](https://registry.terraform.io/providers/vmware/nsxt/latest/docs/resources/policy_gateway_policy)**
This resource is used to create a Gateway Firewall (DFW) within NSX.  
  
    resource "nsxt_policy_gateway_policy" "test" {
        display_name    = "tf-gw-policy"
        description     = "Terraform provisioned Gateway Policy"
        category        = "LocalGatewayRules"
        locked          = false
        sequence_number = 3
        stateful        = true
        tcp_strict      = false
    
        tag {
          scope = "color"
          tag   = "orange"
        }
    
        rule {
        display_name       = "rule1"
        destination_groups = [nsxt_policy_group.group1.path, nsxt_policy_group.group2.path]
        disabled           = true
        action             = "DROP"
        logged             = true
        scope              = [nsxt_policy_tier1_gateway.policygateway.path]
        }
    }
  

---
## **References**
- [Terraform Registry - NSX-T](https://registry.terraform.io/providers/vmware/nsxt/latest/docs)
- [Terraform NSX-T Provider - Github](https://github.com/vmware/terraform-provider-nsxt)
