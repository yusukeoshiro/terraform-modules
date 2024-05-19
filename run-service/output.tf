output "run_instance" {
  value = google_cloud_run_service.run_service
}
output "run_url" {
  value = element(google_cloud_run_service.run_service.status, 0).url
}

output "neg_id" {
  value = google_compute_region_network_endpoint_group.neg.id
}

output "neg" {
  value = google_compute_region_network_endpoint_group.neg
}

output "service_name" {
  value = google_cloud_run_service.run_service.name
}
output "location" {
  value = google_cloud_run_service.run_service.location
}

output "backend_id" {
  value = google_compute_backend_service.backend.id
}

output "backend" {
  value = google_compute_backend_service.backend
}

output "rgn_backend" {
  value = google_compute_region_backend_service.backend
}
