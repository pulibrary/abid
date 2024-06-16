variable "branch_or_sha" {
  type = string
  default = "main"
}
job "abid-staging" {
  region = "global"
  datacenters = ["dc1"]
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
        path = "/"
        interval = "10s"
        timeout = "1s"
      }
    }
    task "webserver" {
      driver = "docker"
      config {
        image = "ghcr.io/pulibrary/abid:${ var.branch_or_sha }"
        ports = ["http"]
        force_pull = true
      }
      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env = true
        change_mode = "restart"
        data = <<EOF
        {{- with nomadVar "nomad/jobs/abid-staging" -}}
        RAILS_MASTER_KEY = {{ .RAILS_MASTER_KEY }}
        ABID_SECRET_KEY_BASE = '{{ .SECRET_KEY_BASE }}'
        APP_DB = {{ .DB_NAME }}
        APP_DB_USERNAME = {{ .DB_USER }}
        APP_DB_PASSWORD = {{ .DB_PASSWORD }}
        APP_DB_HOST = {{ .POSTGRES_HOST }}
        APPLICATION_HOST = 'abid-staging.princeton.edu'
        APPLICATION_HOST_PROTOCOL = 'http'
        HONEYBADGER_API_KEY = {{ .HONEYBADGER_API_KEY }}
        ASPACE_USER = {{ .ASPACE_USER }}
        ASPACE_PASSWORD = {{ .ASPACE_PASSWORD }}
        ALMA_API_KEY = {{ .ALMA_API_KEY }}
        {{- end -}}
        EOF
      }
    }
  }
}
