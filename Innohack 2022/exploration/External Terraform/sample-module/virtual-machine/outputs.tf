locals {
  deployment_resources       = [
    for resource in vra_deployment.deployment.resources :
    jsondecode(resource.properties_json)
  ]
}

output "vm_name" {
  value = local.deployment_resources[1].resourceName
}
