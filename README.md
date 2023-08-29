# terraform-google-vertex-workbench

This module creates an isolated Vertex Workbench to provide a tactical solution to enable Secure Boot and GPUs. When the Vertex Workbench product is updated to support the combination of Secure Boot & GPUs the repo will be updated to eliminate the tactical components and focus on a secure Workbench deployment.

The resources/services/activations/deletions that this module will create/trigger are:

- Create a project
- Create a service account for Vertex Workbench
- Create a GCS bucket
- Create a isolated VPC Network
- Create multiple private DNS zones for googleapis and notebook domains
- Creates a Vertex Workbench instances within isolated network
- Updates Secure boot flag via Compute engine
- Optional Secure Web Proxy script to allow code downloads from 

## Usage

## Usage
1. Clone repo
```
git clone https://github.com/jasonbisson/terraform-google-vertex-workbench.git

```

2. Rename and update required variables in terraform.tvfars.template
```
mv terraform.tfvars.template terraform.tfvars
#Update required variables
```
3. Execute Terraform commands with existing identity (human or service account) to build Vertex Workbench Infrastructure 

```
cd ~/terraform-google-vertex-workbench/
terraform init
terraform plan
terraform apply
```

4. Optional deployment of Secure Web Proxy
```
Create:
cd ~/terraform-google-vertex-workbench/files 
mv source.env.template source.env
##Update required variables
./create_secure_web_proxy.sh --project_id <Vertex Workbench Project ID >

Destroy if you don't need or want it:
./destroy_secure_web_proxy.sh --project_id <Vertex Workbench Project ID >

```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| billing\_account | The billing account id associated with the project, e.g. XXXXXX-YYYYYY-ZZZZZZ | `string` | n/a | yes |
| can\_ip\_forward | Enable IP forwarding, for NAT instances for example | `string` | `"false"` | no |
| disk\_size\_gb | Boot disk size in GB | `string` | `"100"` | no |
| disk\_type | Boot disk type, can be either pd-ssd, local-ssd, or pd-standard | `string` | `"PD_STANDARD"` | no |
| dnszone | The Private DNS zone to resolve private storage api | `string` | `"private.googleapis.com."` | no |
| environment | Environment tag to help identify the entire deployment | `string` | n/a | yes |
| folder\_id | The folder to deploy project in | `string` | n/a | yes |
| gpu\_type | GPU Type | `string` | `"NVIDIA_TESLA_T4"` | no |
| install\_gpu\_driver | Install GPU drivers | `string` | `true` | no |
| instance\_owners | User Email address that will own Vertex Workbench | `list(any)` | n/a | yes |
| labels | Labels, provided as a map | `map(any)` | `{}` | no |
| machine\_type | Machine type to application | `string` | `"n1-standard-1"` | no |
| org\_id | The numeric organization id | `string` | n/a | yes |
| project\_name | Prefix of Google Project name | `string` | n/a | yes |
| region | The GCP region to create and test resources in | `string` | `"us-central1"` | no |
| source\_image\_family | The OS Image family | `string` | `"common-container-notebooks-debian-10"` | no |
| source\_image\_project | Google Cloud project with OS Image | `string` | `"deeplearning-platform-release"` | no |
| zone | The GCP zone to create the instance in | `string` | `"us-central1-a"` | no |

## Outputs

No output.

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

These sections describe requirements for using this module.

### Software

The following dependencies must be available:

- [Terraform][terraform] v0.13 or above
- [Terraform Provider for GCP][terraform-provider-gcp] plugin v3.0 or above

### Deployment Account

The account used for the deployment will require the following roles:

- Project Creator 
- Project Deleter
- Billing User


### APIs

A project with the following APIs enabled must be used to host the
resources of this module:

- iam.googleapis.com
- compute.googleapis.com
- dns.googleapis.com
- notebooks.googleapis.com
- containerregistry.googleapis.com
- aiplatform.googleapis.com
- networkservices.googleapis.com
- certificatemanager.googleapis.com
- storage.googleapis.com


## Contributing

Refer to the [contribution guidelines](./CONTRIBUTING.md) for
information on contributing to this module.

[project-factory-module]: https://registry.terraform.io/modules/terraform-google-modules/project-factory/google
[terraform-provider-gcp]: https://www.terraform.io/docs/providers/google/index.html
[terraform]: https://www.terraform.io/downloads.html

## Security Disclosures

Please see our [security disclosure process](./SECURITY.md).
