locals {
  deployment_resources       = [
    for resource in vra_deployment.deployment.resources :
    jsondecode(resource.properties_json)
  ]
}

output "fwName" {
  value = local.deployment_resources[0].outputs["output_fwName"]["value"]
}

output "ruleType" {
  value = local.deployment_resources[0].outputs["output_ruleType"]["value"]
}
