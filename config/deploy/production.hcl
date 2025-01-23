variable "branch_or_sha" {
  type = string
  default = "main"
}
job "abid-production" {
  region = "global"
  datacenters = ["dc1"]
  node_pool = "production"
  type = "service"
  group "web" {
    count = 2
    network {
      port "http" { to = 3000 }
    }
    service {
      port = "http"
      check {
        type = "http"
        port = "http"
        path = "/health.json"
        interval = "10s"
        timeout = "1s"
      }
    }
    task "webserver" {
      driver = "podman"
      config {
        image = "ghcr.io/pulibrary/abid:${ var.branch_or_sha }"
        ports = ["http"]
        force_pull = true
      }
      resources {
        cpu    = 1000
        memory = 500
      }
      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env = true
        change_mode = "restart"
        data = <<EOF
        {{- with nomadVar "nomad/jobs/abid-production" -}}
        SECRET_KEY_BASE = '{{ .ABID_SECRET_KEY_BASE }}'
        APP_DB = {{ .APP_DB }}
        APP_DB_USERNAME = {{ .APP_DB_USERNAME }}
        APP_DB_PASSWORD = {{ .APP_DB_PASSWORD }}
        APP_DB_HOST = {{ .APP_DB_HOST }}
        APPLICATION_HOST = 'abid.princeton.edu'
        APPLICATION_HOST_PROTOCOL = 'https'
        APPLICATION_PORT = '443'
        RAILS_ENV = 'production'
        HONEYBADGER_API_KEY = {{ .HONEYBADGER_API_KEY }}
        ASPACE_USER = {{ .ASPACE_USER }}
        ASPACE_PASSWORD = {{ .ASPACE_PASSWORD }}
        ALMA_API_KEY = {{ .ALMA_API_KEY }}
        RAILS_MASTER_KEY = {{ .RAILS_MASTER_KEY }}
        {{- end -}}
        EOF
      }
    }
  }
}
