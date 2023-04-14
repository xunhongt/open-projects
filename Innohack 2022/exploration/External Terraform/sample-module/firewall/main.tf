terraform {
  required_providers {
    vra = {
      source  = "local/vmware/vra"
      version = ">= 0.6.0"
    }
    null = {
      source  = "local/hashicorp/null"
      version = ">= 3.2.1"
    }
  }
  required_version = ">= 0.12"
}

data "vra_project" "project" {
  name = var.project_name
}

data "vra_catalog_item" "firewall" {
  name            = var.catalog_item_name
  expand_versions = true
}

resource "null_resource" "firewall" {
  triggers = {
      fwName        = var.fwName
      environment   = var.environment         
      sourceVMList  = var.sourceVMList
      sourceIPList  = var.sourceIPList
      sourceSGList  = var.sourceSGList
      destVMList    = var.destVMList
      protocols     = var.protocols
      tcpPorts      = var.tcpPorts
      udpPorts      = var.udpPorts      
  }
}

resource "vra_deployment" "deployment" {
  name        = var.deployment_name
  description = "Firewall (Ext Env to A) - Terraform Deployment"

  catalog_item_id      = data.vra_catalog_item.firewall.id
  project_id           = data.vra_project.project.id

  inputs = {
   "fwName"        = var.fwName
   "projectId"     = data.vra_project.project.id
   "environment"   = var.environment      
   "sourceVMList"  = var.sourceVMList
   "sourceIPList"  = var.sourceIPList
   "sourceSGList"  = var.sourceSGList   
   "destVMList"    = var.destVMList
   "protocols"     = var.protocols
   "tcpPorts"      = var.tcpPorts
   "udpPorts"      = var.udpPorts
  }

  timeouts {
    create = "30m"
    delete = "30m"
    update = "30m"
  }

  lifecycle {
    replace_triggered_by = [null_resource.firewall]
    create_before_destroy = true

    precondition {
      condition = alltrue([
        for vm in split(",", var.destVMList) : startswith(vm, format("%s%s", "DSP1", var.project_name))
      ])
      error_message = "Destination must only contain your own projects' VMs!"
    }

    precondition {
      condition = var.environment == "DEV1" || var.environment == "DEV2"
      error_message = "Please select an appropriate Environment (DEV1, DEV2)"
    }
  }  
}
