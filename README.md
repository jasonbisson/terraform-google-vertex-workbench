# terraform-google-vertex-workbench

This module was generated from [terraform-google-module-template](https://github.com/terraform-google-modules/terraform-google-module-template/), which by default generates a module that creates an isolated Vertex Workbench to provide a tactical solution to enable Secure Boot and GPUs. A a strategic solution will come out in the near future, but provides an option to keep moving forward.

The resources/services/activations/deletions that this module will create/trigger are:

- Create a project 
- Create a service account for Vertex Workbench
- Create a GCS bucket
- Create a isolated VPC Network
- Create multiple private DNS zones for googleapis and notebook domains 
- Updates Secure boot flag via Compute engine

## Usage

Basic usage of this module is as follows:

```hcl
module "vertex_workbench" {
  source  = "terraform-google-modules/vertex-workbench/google"
  version = "~> 0.1"
}
```

Functional examples are included in the
[examples](./examples/) directory.

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
| install\_gpu\_driver | Install GPU drivers | `string` | n/a | yes |
| instance\_owners | User Email address that will own Vertex Workbench | `list` | n/a | yes |
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

- [Terraform][terraform] v0.13
- [Terraform Provider for GCP][terraform-provider-gcp] plugin v3.0

### Service Account

A service account with the following roles must be used to provision
the resources of this module:

- Storage Admin: `roles/storage.admin`

The [Project Factory module][project-factory-module] and the
[IAM module][iam-module] may be used in combination to provision a
service account with the necessary roles applied.

### APIs

A project with the following APIs enabled must be used to host the
resources of this module:

- Google Cloud Storage JSON API: `storage-api.googleapis.com`

The [Project Factory module][project-factory-module] can be used to
provision a project with the necessary APIs enabled.

## Contributing

Refer to the [contribution guidelines](./CONTRIBUTING.md) for
information on contributing to this module.

[project-factory-module]: https://registry.terraform.io/modules/terraform-google-modules/project-factory/google
[terraform-provider-gcp]: https://www.terraform.io/docs/providers/google/index.html
[terraform]: https://www.terraform.io/downloads.html

## Security Disclosures

Please see our [security disclosure process](./SECURITY.md).
