job "openvino" {
  datacenters = ["edge"]
  type = "service"

  group "openvino" {
    count = 1

    network {
       mode = "bridge"

       port "http_jupyter" {
         to = 8888
       }
       port "grpc_models" {
         to = 9000
       }
       port "http_models" {
         to = 9001
       }
    }

    service {
      name = "openvino-notebooks"
      port = "http_jupyter"
      provider = "consul"
      
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.openvino.rule=PathPrefix(`/openvino`)"
      ]

      check {
        type     = "http"
        path     = "/openvino/api"
        interval = "10s"
        timeout  = "2s"
      }
    }

    service {
      name = "openvino-model-server"
      port = "grpc_models"
      provider = "consul"
      
      #check {
      #  type     = "grpc"
      #  port     = "grpc_models"
      #  interval = "10s"
      #  timeout  = "2s"
      #}
    }
    
    service {
      name = "openvino-model-server"
      port = "http_models"
      provider = "consul"

      check {
        type     = "http"
        port     = "http_models"
        path     = "/v1/config"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "jupyter" {
      env {
        JUPYTER_PORT = "${NOMAD_PORT_http_jupyter}"
        JUPYTERHUB_SERVICE_PREFIX = "/openvino"
      }
   
      driver = "docker"

      config {
        image = "mwrightpivotal/openvino_notebooks:3.3"
        image_pull_timeout = "10m"
        ports = ["http_jupyter"]
        shm_size = 1024
        command = "jupyter"
        args = [
          "lab",
          "--NotebookApp.base_url=/openvino",
          "--ip=*",
          "--allow-root",
          "/opt/app-root/notebooks"
        ]
      }
      resources {
        cpu    = 1000
        memory = 2048
      }
    }
    task "openvino-model-server" {
      constraint {
        attribute = "${node.class}"
        value     = "intel-igpu"
      }
      artifact {
        source = "http://192.168.0.5/models.tgz"
      }
   
      driver = "docker"

      config {
        image = "openvino/model_server:latest-gpu"
        ports = ["http_models","grpc_models"]
        shm_size = 1024
        volumes = [
          "local/.:/models"
        ]
        args = [
          "--model_path",
          "/models/horizontal-text-detection",
          "--model_name",
          "horizontal-text-detection",
          "--log_level",
          "DEBUG",
          "--target_device",
          "GPU",
          "--port",
          "${NOMAD_PORT_grpc_models}",
          "--rest_port",
          "${NOMAD_PORT_http_models}"
        ]
        devices = [
          {
            host_path = "/dev/dri"
          }
        ]
        privileged = true
        group_add = [
          "109"
        ]
      }
      resources {
        
        cpu    = 1000
        memory = 8192
      }
    }
  }
}

