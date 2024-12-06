job "WindowsWorkload" {
  
  datacenters = ["edge"]

  group "OfficeEdge" {
    count = 1
    network {
      mode = "host"
      port "ssh" {
        to = 22
      }
    }
    task "WindowsPrintServer" {
      driver = "nomad-driver-virt"

      artifact {
        source = "http://192.168.0.5/Win2022_20324.qcow2.tgz"
      } 
      config {
        image  = "local/Win2022_20324.qcow2"
        primary_disk_size     = 10000
        use_thin_copy         = true
        default_user_password = "password"
        network_interface {
          bridge {
            name  = "virbr0"
            ports = ["ssh"]
          }
        }
      }
      resources {
        cores  = 2
        memory = 4000
      }
    }
  }
}
