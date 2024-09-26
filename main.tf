resource "google_compute_instance_template" "default" {
  name           = "apache-instance-template"
  machine_type   = "e2-medium"
  region         = "us-central1"

  disk {
    auto_delete  = true
    boot         = true
    source_image = "projects/debian-cloud/global/images/family/debian-11"
  }

  network_interface {
    network = "default"
    access_config {}
  }
resource "google_compute_instance_group_manager" "default" {
  name               = "apache-instance-group"
  version {
    instance_template = google_compute_instance_template.default.id
  }
  base_instance_name = "apache-instance"
  target_size        = 2
  zone               = "us-central1-a"

  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_backend_service" "default" {
  name          = "apache-backend-service"
  backend {
    group = google_compute_instance_group_manager.default.instance_group
  }
  health_checks = [google_compute_http_health_check.default.id]
  port_name     = "http"
  protocol      = "HTTP"
  timeout_sec   = 30
  load_balancing_scheme = "EXTERNAL"
}

resource "google_compute_http_health_check" "default" {
  name                    = "apache-health-check"
  request_path            = "/"
  port                    = 80
  check_interval_sec      = 20
  timeout_sec             = 15
  healthy_threshold       = 1
  unhealthy_threshold     = 3
}

resource "google_compute_url_map" "default" {
  name            = "apache-url-map"
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_target_http_proxy" "default" {
  name    = "apache-http-proxy"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "apache-forwarding-rule"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
}
output "instance_group_ips" {
  value = google_compute_instance_group_manager.default.instance_group
}

output "instance_ips" {
  value = google_compute_instance_template.default.network_interface[0].access_config[0].nat_ip
}
