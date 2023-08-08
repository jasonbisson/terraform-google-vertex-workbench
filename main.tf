/**
 * Copyright 2021 Google LLC
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
  version = "~> 11.0"

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

module "org-policy-requireShieldedVm" {
  source      = "terraform-google-modules/org-policy/google"
  policy_for  = "project"
  project_id  = module.project.project_id
  constraint  = "compute.requireShieldedVm"
  policy_type = "boolean"
  enforce     = false
}

resource "time_sleep" "wait_for_org_policy" {
  depends_on      = [module.org-policy-requireShieldedVm]
  create_duration = "90s"
}


data "template_file" "startup_script_config" {
  template = file("${path.module}/files/startup.sh")
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

resource "google_storage_bucket_iam_binding" "bucket_iam" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.main.email}"
  ]
}


resource "google_notebooks_instance" "vertex_workbench_instance" {
  project         = module.project.project_id
  name            = "${var.environment}-${random_id.random_suffix.hex}"
  service_account = google_service_account.main.email
  location        = var.zone
  vm_image {
    project      = var.source_image_project
    image_family = var.source_image_family
  }

  post_startup_script = data.template_file.startup_script_config.rendered
  machine_type        = var.machine_type

  accelerator_config {
    type       = var.gpu_type
    core_count = 1
  }
  install_gpu_driver = var.install_gpu_driver

  boot_disk_type    = var.disk_type
  boot_disk_size_gb = var.disk_size_gb
  network           = google_compute_network.vpc_network.id
  subnet            = google_compute_subnetwork.workbench.id
  no_public_ip      = true
  # If true, forces to use an SSH tunnel.
  no_proxy_access = false
  instance_owners = var.instance_owners

  metadata = {
    notebook-disable-root      = "true"
    notebook-disable-downloads = "true"
    notebook-disable-nbconvert = "true"
    notebook-upgrade-schedule  = "00 19 * * SUN"
  }

  depends_on = [google_storage_bucket.bucket, time_sleep.wait_for_org_policy]
}

resource "null_resource" "set_secure_boot" {
  provisioner "local-exec" {
    command = <<EOF
    gcloud config set project ${module.project.project_id}
    gcloud compute instances stop ${google_notebooks_instance.vertex_workbench_instance.name} --zone ${var.zone}
    sleep 120
    gcloud compute instances update ${google_notebooks_instance.vertex_workbench_instance.name} --shielded-secure-boot --zone ${var.zone}
    gcloud compute instances start ${google_notebooks_instance.vertex_workbench_instance.name} --zone ${var.zone}
    gcloud compute instances update ${google_notebooks_instance.vertex_workbench_instance.name} --shielded-learn-integrity-policy --zone ${var.zone}
    EOF
  }
  depends_on = [google_notebooks_instance.vertex_workbench_instance]
}
