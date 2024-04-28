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

module "project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 14.5"

  name              = "${var.project_name}-${var.environment}-${random_id.random_suffix.hex}"
  random_project_id = "false"
  org_id            = var.org_id
  folder_id         = var.folder_id
  billing_account   = var.billing_account

  activate_apis = [
    "iam.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "notebooks.googleapis.com",
    "containerregistry.googleapis.com",
    "aiplatform.googleapis.com",
    "networkservices.googleapis.com",
    "certificatemanager.googleapis.com",
    "storage.googleapis.com"
  ]
}


data "template_file" "startup_script_config" {
  template = file("${path.module}/files/post_startup_script.sh")
}

resource "random_id" "random_suffix" {
  byte_length = 4
}

resource "google_service_account" "main" {
  project      = module.project.project_id
  account_id   = "${var.environment}-${random_id.random_suffix.hex}"
  display_name = "${var.environment}${random_id.random_suffix.hex}"
}

resource "google_project_iam_member" "notebook_iam_compute" {
  project = module.project.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.main.email}"
}

resource "google_project_iam_member" "source_repo" {
  project = module.project.project_id
  role    = "roles/source.reader"
  member  = "serviceAccount:${google_service_account.main.email}"
}

resource "google_project_iam_member" "notebook_iam_serviceaccount" {
  project = module.project.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.main.email}"
}

resource "google_compute_network" "vpc_network" {
  project                 = module.project.project_id
  name                    = "${var.environment}-${random_id.random_suffix.hex}"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "workbench" {
  project                  = module.project.project_id
  name                     = "${var.environment}-${random_id.random_suffix.hex}-workbench"
  ip_cidr_range            = "10.2.0.0/16"
  region                   = var.region
  private_ip_google_access = true
  network                  = google_compute_network.vpc_network.name

}


resource "google_compute_subnetwork" "proxy" {
  project       = module.project.project_id
  name          = "${var.environment}-${random_id.random_suffix.hex}-web-proxy"
  network       = google_compute_network.vpc_network.name
  region        = var.region
  ip_cidr_range = "192.168.0.0/23"
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_firewall" "egress" {
  project            = module.project.project_id
  name               = "deny-all-egress"
  description        = "Block all egress ${var.environment}"
  network            = google_compute_network.vpc_network.name
  priority           = 1000
  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]
  deny {
    protocol = "all"
  }
}

resource "google_compute_firewall" "ingress" {
  project       = module.project.project_id
  name          = "deny-all-ingress"
  description   = "Block all Ingress ${var.environment}"
  network       = google_compute_network.vpc_network.name
  priority      = 1000
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  deny {
    protocol = "all"
  }
}

resource "google_compute_firewall" "googleapi_egress" {
  project            = module.project.project_id
  name               = "allow-googleapi-egress"
  description        = "Allow connectivity to storage ${var.environment}"
  network            = google_compute_network.vpc_network.name
  priority           = 999
  direction          = "EGRESS"
  destination_ranges = ["199.36.153.8/30"]
  allow {
    protocol = "tcp"
    ports    = ["443", "8080", "80"]
  }
}


resource "google_compute_firewall" "secure_web_proxy_egress" {
  project            = module.project.project_id
  name               = "secure-web-proxy"
  description        = "Allow secure web proxy connectivity ${var.environment}"
  network            = google_compute_network.vpc_network.name
  priority           = 998
  direction          = "EGRESS"
  destination_ranges = ["10.2.0.0/16"]
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}

resource "google_storage_bucket" "bucket" {
  project                     = module.project.project_id
  name                        = "${module.project.project_id}-${random_id.random_suffix.hex}"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "post_startup_script" {
  name         = "post_startup_script.sh"
  source       = "${path.module}/files/post_startup_script.sh"
  content_type = "text/plain"
  bucket       = google_storage_bucket.bucket.id

  depends_on = [google_storage_bucket.bucket]
}

resource "google_storage_bucket_iam_binding" "bucket_iam" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.main.email}"
  ]
}


resource "google_workbench_instance" "vertex_workbench_instance" {
  project         = module.project.project_id
  name            = "${var.environment}-${random_id.random_suffix.hex}"
  service_account = google_service_account.main.email
  location        = var.zone

  gce_setup {
    service_accounts {
      email = google_service_account.main.email
    }

    vm_image {
      project = var.workbench_source_image_project
      family  = var.workbench_source_image_family
    }

    post_startup_script = data.template_file.startup_script_config.rendered
    machine_type        = var.machine_type

    shielded_instance_config {
      enable_secure_boot          = true
      enable_vtpm                 = true
      enable_integrity_monitoring = true
    }

    boot_disk {
      disk_type    = var.boot_disk_type
      disk_size_gb = var.boot_disk_size_gb
    }

    data_disks {
      disk_type    = var.data_disk_type
      disk_size_gb = var.data_disk_size_gb
    }

    disable_public_ip    = false
    enable_ip_forwarding = false

    network_interfaces {
      network  = google_compute_network.vpc_network.id
      subnet   = google_compute_subnetwork.workbench.id
      nic_type = "GVNIC"
    }

    network = google_compute_network.vpc_network.id
    subnet  = google_compute_subnetwork.workbench.id

    metadata = {
      terraform                    = "true"
      idle-timeout-seconds         = "10800"
      install-nvidia-driver        = var.install_gpu_driver
      post-startup-script          = "gs://${google_storage_bucket.bucket.id}/${google_storage_bucket_object.post_startup_script.name}"
      post-startup-script-behavior = "DOWNLOAD_AND_RUN_EVERY_START"
      notebook-disable-root        = "true"
      notebook-disable-downloads   = "true"
      notebook-disable-nbconvert   = "true"
      notebook-upgrade-schedule    = "00 19 * * SUN"
    }
    tags = ["workbench-instance-terraform"]
  }

  labels = {
    workbench-instance-terraform = "true"
  }

  # If true, forces to use an SSH tunnel.
  disable_proxy_access = false
  instance_owners      = var.instance_owners
  desired_state        = "ACTIVE"

  depends_on = [google_storage_bucket.bucket, google_storage_bucket_object.post_startup_script]
}
