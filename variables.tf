/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
variable "project_id" {
  description = "The numeric organization id"
  type        = string
}

variable "environment" {
  description = "Unique environment variable"
  type        = string
}

variable "enable_apis" {
  description = "Whether to actually enable the APIs. If false, this module is a no-op."
  default     = "true"
}

variable "disable_services_on_destroy" {
  description = "Whether project services will be disabled when the resources are destroyed. https://www.terraform.io/docs/providers/google/r/google_project_service.html#disable_on_destroy"
  default     = "false"
  type        = string
}

variable "disable_dependent_services" {
  description = "Whether services that are enabled and which depend on this service should also be disabled when this service is destroyed. https://www.terraform.io/docs/providers/google/r/google_project_service.html#disable_dependent_services"
  default     = "false"
  type        = string
}

variable "activate_apis" {
  description = "The list of apis to activate for Cloud Function"
  default = [
    "iam.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "notebooks.googleapis.com",
    "containerregistry.googleapis.com",
    "aiplatform.googleapis.com",
    "networkservices.googleapis.com",
    "certificatemanager.googleapis.com",
    "dataform.googleapis.com",
    "storage.googleapis.com"
  ]
  type = list(string)
}

variable "region" {
  description = "The GCP region to create and test resources in"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone to create the instance in"
  type        = string
  default     = "us-central1-a"
}

variable "dnszone" {
  description = "The Private DNS zone to resolve private storage api"
  type        = string
  default     = "private.googleapis.com."
}

variable "machine_type" {
  description = "Machine type to application"
  type        = string
  default     = "n1-standard-1"
}

variable "gpu_type" {
  description = "GPU Type"
  type        = string
  default     = "NVIDIA_TESLA_T4"
}

variable "install_gpu_driver" {
  description = "Install GPU drivers"
  type        = string
  default     = false
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB"
  default     = "150"
}

variable "boot_disk_type" {
  description = "Boot disk type, can be either pd-ssd, local-ssd, or pd-standard"
  default     = "PD_STANDARD"
}

variable "data_disk_size_gb" {
  description = "The size of the disk in GB attached to this VM instance, up to a maximum of 64000 GB (64 TB). If not specified, this defaults to 100."
  default     = "100"
}

variable "data_disk_type" {
  description = "Indicates the type of the disk. Possible values are: PD_STANDARD, PD_SSD, PD_BALANCED, PD_EXTREME."
  default     = "PD_STANDARD"
}

variable "can_ip_forward" {
  description = "Enable IP forwarding, for NAT instances for example"
  type        = string
  default     = "false"
}

variable "labels" {
  type        = map(any)
  description = "Labels, provided as a map"
  default     = {}
}

variable "workbench_source_image_family" {
  description = "The OS Image family"
  type        = string
  default     = "workbench-instances"
  # https://cloud.google.com/vertex-ai/docs/workbench/instances/create-specific-version
  #gcloud compute images list --project deeplearning-platform-release
}

variable "workbench_source_image_project" {
  description = "Google Cloud project with OS Image"
  type        = string
  default     = "cloud-notebooks-managed"
}


variable "instance_owners" {
  description = "User Email address that will own Vertex Workbench"
  type        = list(any)
}
