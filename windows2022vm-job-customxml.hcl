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
        source = "http://192.168.0.5/windows-good.xml"
      } 
      config {
        domain_xml = "local/windows-good.xml"
        image = "/var/lib/virt/Win2022_20324.qcow2"
      }
      resources {
        cores  = 2
        memory = 4000
      }
    }
  }
}
