resource "google_dns_managed_zone" "googleapis" {
  project     = module.project.project_id
  name        = "${var.environment}-${random_id.random_suffix.hex}-googleapis"
  dns_name    = "googleapis.com."
  description = "Private DNS zone for googleapis api"
  visibility  = "private"
  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc_network.id
    }
  }
}

resource "google_dns_record_set" "private_googleapis_com_a" {
  project      = module.project.project_id
  managed_zone = google_dns_managed_zone.googleapis.name
  name         = "private.googleapis.com."
  type         = "A"
  rrdatas      = ["199.36.153.8", "199.36.153.9", "199.36.153.10", "199.36.153.11"]
  ttl          = 86400

  depends_on = [
    google_dns_managed_zone.googleapis
  ]
}

resource "google_dns_record_set" "private_googleapis_com_cname" {
  project      = module.project.project_id
  managed_zone = google_dns_managed_zone.googleapis.name
  name         = "*.googleapis.com."
  type         = "CNAME"
  rrdatas      = [google_dns_record_set.private_googleapis_com_a.name]
  ttl          = 300
}


resource "google_dns_managed_zone" "notebooks" {
  project     = module.project.project_id
  name        = "${var.environment}-${random_id.random_suffix.hex}-notebooks"
  dns_name    = "notebooks.cloud.google.com."
  description = "Private DNS zone for notebook api"
  visibility  = "private"
  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc_network.id
    }
  }
}

resource "google_dns_record_set" "notebooks_a" {
  project      = module.project.project_id
  managed_zone = google_dns_managed_zone.notebooks.name
  name         = "notebooks.cloud.google.com."
  type         = "A"
  rrdatas      = ["199.36.153.8", "199.36.153.9", "199.36.153.10", "199.36.153.11"]
  ttl          = 86400
}

resource "google_dns_record_set" "notebooks_cname" {
  project      = module.project.project_id
  managed_zone = google_dns_managed_zone.notebooks.name
  name         = "*.notebooks.cloud.google.com."
  type         = "CNAME"
  rrdatas      = [google_dns_record_set.notebooks_a.name]
  ttl          = 300
}

resource "google_dns_managed_zone" "googleusercontent" {
  project     = module.project.project_id
  name        = "${var.environment}-${random_id.random_suffix.hex}-googleusercontent"
  dns_name    = "notebooks.googleusercontent.com."
  description = "Private DNS zone for notebook user content api"
  visibility  = "private"
  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc_network.id
    }
  }
}


resource "google_dns_record_set" "googleusercontent_a" {
  project      = module.project.project_id
  managed_zone = google_dns_managed_zone.googleusercontent.name
  name         = "notebooks.googleusercontent.com."
  type         = "A"
  rrdatas      = ["199.36.153.8", "199.36.153.9", "199.36.153.10", "199.36.153.11"]
  ttl          = 86400
}


resource "google_dns_record_set" "googleusercontent_cname" {
  project      = module.project.project_id
  managed_zone = google_dns_managed_zone.googleusercontent.name
  name         = "*.notebooks.googleusercontent.com."
  type         = "CNAME"
  rrdatas      = [google_dns_record_set.googleusercontent_a.name]
  ttl          = 300
}



resource "google_dns_managed_zone" "gcr" {
  project     = module.project.project_id
  name        = "${var.environment}-${random_id.random_suffix.hex}-gcr"
  dns_name    = "gcr.io."
  description = "Private DNS zone for gcr api"
  visibility  = "private"
  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc_network.id
    }
  }
}

resource "google_dns_record_set" "gcr_a" {
  project      = module.project.project_id
  managed_zone = google_dns_managed_zone.gcr.name
  name         = "gcr.io."
  type         = "A"
  rrdatas      = ["199.36.153.8", "199.36.153.9", "199.36.153.10", "199.36.153.11"]
  ttl          = 86400

}

resource "google_dns_record_set" "gcr_cname" {
  project      = module.project.project_id
  managed_zone = google_dns_managed_zone.gcr.name
  name         = "*.gcr.io."
  type         = "CNAME"
  rrdatas      = [google_dns_record_set.gcr_a.name]
  ttl          = 300
}
