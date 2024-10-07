variable "project_id" {
}

variable "compute_name" {
}

variable "region" {  
}

variable "zone" {  
}

resource "google_compute_instance" "default" {
  project = var.project_id
  name         = var.compute_name
  machine_type = "n1-standard-1"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-2210-kinetic-amd64-v20230126"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }
}
