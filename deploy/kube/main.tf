provider "kubernetes" {
  config_path = "./kubeconfig"

}

provider "helm" {
  kubernetes {
    config_path = "./kubeconfig"
  }
}

resource "helm_release" "mysql" {
  name = "mysql"

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mysql"

}

resource "kubernetes_deployment_v1" "api" {
  metadata {
    name = "wasi-demo-api"
    labels = {
      app = "wasi-demo-api"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "wasi-demo-api"
      }
    }
    template {
      metadata {
        labels = {
          app = "wasi-demo-api"
        }
      }
      spec {
        topology_spread_constraint {
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "ScheduleAnyway"
          label_selector {
            match_labels = {
              "app" = "wasi-demo-api"
            }
          }
        }
        container {
          env {
            name  = "DATABASE_URL"
            value = "mysql://root:pass@mysql:3306/mysql"
          }
          image = "ghcr.io/inpulse-tv/wasi-demo-api:latest"
          name  = "wasi-demo-api"
        }
      }
    }
  }
  wait_for_rollout = false
}

resource "kubernetes_service_v1" "api" {
  metadata {
    name = kubernetes_deployment_v1.api.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.api.metadata.0.labels.app
    }
    session_affinity = "ClientIP"
    port {
      port        = 8090
      target_port = 8090
    }
    type = "LoadBalancer"
  }
  lifecycle {
    ignore_changes = [
      metadata
    ]
  }
}

# Get info by ID
data "scaleway_lb" "api" {
  name = "${local.k8s_id}_${kubernetes_service_v1.api.metadata.0.uid}"
}


resource "kubernetes_deployment_v1" "front" {
  metadata {
    name = "wasi-demo-front"
    labels = {
      app = "wasi-demo-front"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "wasi-demo-front"
      }
    }
    template {
      metadata {
        labels = {
          app = "wasi-demo-front"
        }
      }
      spec {
        container {
          env {
            name  = "API_URL"
            value = "${data.scaleway_lb.api.ip_address}:8090"
          }
          image = "ghcr.io/inpulse-tv/wasi-demo-front:latest"
          name  = "wasi-demo-front"
        }
        topology_spread_constraint {
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "ScheduleAnyway"
          label_selector {
            match_labels = {
              "app" = "wasi-demo-api"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "front" {
  metadata {
    name = kubernetes_deployment_v1.front.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.front.metadata.0.labels.app
    }
    session_affinity = "ClientIP"
    port {
      port        = 8080
      target_port = 80
    }
    type = "LoadBalancer"
  }
  lifecycle {
    ignore_changes = [
      metadata
    ]
  }
}


output "front" {
  value = "http://${data.scaleway_lb.front.ip_address}:8080"
}

output "api" {
  value = "http://${data.scaleway_lb.api.ip_address}:8090"
}
