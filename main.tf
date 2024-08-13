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

resource "random_id" "random_suffix" {
  byte_length = 4
}

resource "google_project_service" "project_services" {
  project                    = var.project_id
  count                      = var.enable_apis ? length(var.activate_apis) : 0
  service                    = element(var.activate_apis, count.index)
  disable_on_destroy         = var.disable_services_on_destroy
  disable_dependent_services = var.disable_dependent_services
}

resource "google_service_account" "user_managed_service_accounts" {
  project      = var.project_id
  for_each     = toset(split("\n", replace(join("\n", tolist(var.instance_owners)), "/\\S+:/", "")))
  account_id   = "${var.environment}-${split("@", replace(each.value, "/[.'_]+/", "-"))[0]}"
  display_name = "Workbench Service Account for ${each.value}"
}

resource "google_service_account_iam_binding" "service_account_user" {
  for_each           = toset(split("\n", replace(join("\n", tolist(var.instance_owners)), "/\\S+:/", "")))
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.environment}-${split("@", replace(each.value, "/[.'_]+/", "-"))[0]}@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  members = [
    "user:${each.value}",
  ]

  depends_on = [google_service_account.user_managed_service_accounts]
}

resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = "${var.environment}-${random_id.random_suffix.hex}"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "workbench" {
  project                  = var.project_id
  name                     = "${var.environment}-${random_id.random_suffix.hex}-workbench"
  ip_cidr_range            = "10.2.0.0/16"
  region                   = var.region
  private_ip_google_access = true
  network                  = google_compute_network.vpc_network.name

}

resource "google_compute_subnetwork" "proxy" {
  project       = var.project_id
  name          = "${var.environment}-${random_id.random_suffix.hex}-web-proxy"
  network       = google_compute_network.vpc_network.name
  region        = var.region
  ip_cidr_range = "192.168.0.0/23"
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_firewall" "egress" {
  project            = var.project_id
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
  project       = var.project_id
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
  project            = var.project_id
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
  project            = var.project_id
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


data "template_file" "startup_script_config" {
  template = file("${path.module}/files/post_startup_script.sh")
}

resource "google_storage_bucket" "bucket" {
  project                     = var.project_id
  name                        = "${var.project_id}-${random_id.random_suffix.hex}"
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


resource "google_workbench_instance" "vertex_workbench_instance" {
  project  = var.project_id
  for_each = toset(split("\n", replace(join("\n", tolist(var.instance_owners)), "/\\S+:/", "")))
  name     = format("${var.environment}-%s-%s", split("@", replace(each.value, "/[.'_]+/", "-"))[0], random_id.random_suffix.hex)
  location = var.zone

  gce_setup {

    service_accounts {
      email = "${var.environment}-${split("@", replace(each.value, "/[.'_]+/", "-"))[0]}@${var.project_id}.iam.gserviceaccount.com"
    }

    vm_image {
      project = var.workbench_source_image_project
      family  = var.workbench_source_image_family
    }

    machine_type = var.machine_type

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

    disable_public_ip    = true
    enable_ip_forwarding = false

    network_interfaces {
      network  = google_compute_network.vpc_network.id
      subnet   = google_compute_subnetwork.workbench.id
      nic_type = "GVNIC"
    }

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
  instance_owners      = [each.value]
  desired_state        = "ACTIVE"

  depends_on = [google_storage_bucket.bucket, google_storage_bucket_object.post_startup_script, google_service_account_iam_binding.service_account_user]
}
