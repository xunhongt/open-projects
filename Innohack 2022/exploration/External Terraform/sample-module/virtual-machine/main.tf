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

data "vra_catalog_item" "rhelVM" {
  name            = var.catalog_item_name
  expand_versions = true
}

resource "null_resource" "vmName" {
  triggers = {
      vmName = var.vm_name
  }
}

resource "vra_deployment" "deployment" {
  name        = var.deployment_name
  description = "RHEL VM - Terraform Deployment"

  catalog_item_id      = data.vra_catalog_item.rhelVM.id
  project_id           = data.vra_project.project.id

  inputs = {
   "vmSize" = var.vm_size
   "vmCount"  = "1"
   "serverType" = var.vm_name
  }

  timeouts {
    create = "30m"
    delete = "30m"
    update = "30m"
  }

  lifecycle {
    replace_triggered_by = [null_resource.vmName]
    create_before_destroy = true
  }
}
 

