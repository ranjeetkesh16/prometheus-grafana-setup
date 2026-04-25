YouTube video link - https://www.youtube.com/watch?v=N9itZYUAJmc

Step 1 - Create Ec2 using Terraform
Go inside terraform folder and run Terraform commands

Step 2 - Install Node exporter in all nodes
Go inside ansible folder
using ansible, Config file -> node_exporter.yml

Step 3 - Install Prometheus and Grafana on Monitor Node
using ansible, Config file -> monitor.yml

Step 4 - Integrate Grafana with Prometheus
Grafana UI -> Connections -> Data source

Step 5 - Import Dashbaord
I have used 1860, you can use anyone else as well.

Step 6 - Increase CPU and RAM on Targent Nodes
using ansible, Config file -> spike.yml

Step 7 - Don't forget to destroy the resources
terraform destroy
