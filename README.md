# AWS EC2 Monitoring with Prometheus, Grafana, Ansible & Terraform

This project provisions an AWS EC2-based monitoring environment using **Terraform**, **Ansible**, **Prometheus**, **Node Exporter**, and **Grafana**.

YouTube video link - https://www.youtube.com/watch?v=N9itZYUAJmc



The setup creates:

- 1 **Monitor EC2 instance**
- 2 **Node EC2 instances**
- Node Exporter on all EC2 instances
- Prometheus on the Monitor instance
- Grafana on the Monitor instance
- Prometheus configured to monitor both Node instances using their **private IP addresses**
- Grafana connected to Prometheus for visualization

## Architecture

```text
                         AWS VPC
                   172.31.0.0/16
                         |
        +----------------+----------------+
        |                                 |
        v                                 v
+------------------+             +------------------+
| Monitor EC2      |             | Node 1 EC2       |
|                  |             |                  |
| Prometheus :9090 |----+        | Node Exporter    |
| Grafana :3000    |    |        | :9100            |
| Node Exporter    |    |        +------------------+
+------------------+    |
        |               |        +------------------+
        +---------------+------->| Node 2 EC2       |
                                 |                  |
                                 | Node Exporter    |
                                 | :9100            |
                                 +------------------+

Prometheus ---> Node 1 private IP:9100
Prometheus ---> Node 2 private IP:9100

Grafana ---> Prometheus:9090
```

## Technologies

| Technology | Purpose |
|---|---|
| Terraform | Provision AWS EC2 infrastructure |
| AWS EC2 | Monitor and monitored nodes |
| Ansible | Server configuration and software installation |
| Node Exporter | Collect Linux system metrics |
| Prometheus | Store and query metrics |
| Grafana | Visualize monitoring metrics |
| AWS Security Groups | Control network access |

## Project Flow

### 1. Create EC2 Instances with Terraform

Create three EC2 instances:

- Monitor
- Node 1
- Node 2

Run:

```bash
terraform plan
terraform apply --auto-approve
```

After Terraform completes, the three EC2 instances should be available in AWS.

---

### 2. Update Ansible Inventory

After the EC2 instances are created, obtain their public IP addresses.

Update:

```text
ansible/inventory.ini
```

Example:

```ini
[monitor]
monitor ansible_host=<MONITOR_PUBLIC_IP>

[nodes]
node1 ansible_host=<NODE1_PUBLIC_IP>
node2 ansible_host=<NODE2_PUBLIC_IP>
```

> **Important:** Ansible uses the public IP addresses to connect to the EC2 instances over SSH.

---

### 3. Install Node Exporter

Install Node Exporter on the Monitor, Node 1, and Node 2 instances:

```bash
ansible-playbook -i inventory.ini node_exporter.yml
```

Node Exporter exposes Linux system metrics on:

```text
:9100
```

Examples of metrics include:

- CPU usage
- Memory usage
- Disk usage
- Network statistics
- System load

---

### 4. Configure Prometheus Targets

Update the Prometheus configuration in:

```text
monitor.yml
```

Use the **private IP addresses** of Node 1 and Node 2 as Prometheus targets.

Example:

```yaml
targets:
  - "<NODE1_PRIVATE_IP>:9100"
  - "<NODE2_PRIVATE_IP>:9100"
```

### Why use private IPs?

Ansible needs the **public IP** to connect to the servers from outside the VPC.

Prometheus runs inside the AWS VPC, so it can communicate with the nodes using their **private IP addresses**.

This is more secure because monitoring traffic does not need to travel through the public internet.

---

### 5. Install Prometheus and Grafana

Run:

```bash
ansible-playbook -i inventory.ini monitor.yml
```

This installs:

- Prometheus
- Grafana

on the Monitor EC2 instance.

Prometheus:

```text
http://<MONITOR_IP>:9090
```

Grafana:

```text
http://<MONITOR_IP>:3000
```

---

## 6. Configure AWS Security Groups

Initially, Prometheus may not be able to retrieve metrics from Node 1 and Node 2.

This happens because the Node security group does not allow the Monitor instance to access Node Exporter's port.

Update the Node security group to allow the required traffic.

### Recommended rules

| Port | Source | Purpose |
|---:|---|---|
| 9100 | VPC CIDR `172.31.0.0/16` | Node Exporter |
| 22 | Monitor IP | SSH |
| 9090 | Monitor IP | Prometheus |
| 3000 | Monitor IP | Grafana |

For example:

```text
9100   VPC CIDR (172.31.0.0/16)   Node Exporter
22     Monitor IP                 SSH
9090   Monitor IP                 Prometheus
3000   Monitor IP                 Grafana
```

### Security recommendation

Prefer **security-group-to-security-group rules** where possible instead of allowing public IP ranges.

For example:

```text
Node SG
  |
  +-- TCP 9100
       Source: Monitor Security Group
```

This avoids exposing Node Exporter unnecessarily.

---

## 7. Verify Prometheus Targets

Open:

```text
http://<MONITOR_IP>:9090
```

Check the Prometheus targets page.

You should see Node 1 and Node 2 as targets.

The expected target format is:

```text
<NODE1_PRIVATE_IP>:9100
<NODE2_PRIVATE_IP>:9100
```

The targets should eventually show:

```text
UP
```

If they show `DOWN`, check:

1. Node Exporter service status
2. Node security group
3. Private IP addresses
4. Port `9100`
5. Prometheus configuration
6. Network connectivity between instances

---

## 8. Create Node Exporter Dashboard in Grafana

Open:

```text
http://<MONITOR_IP>:3000
```

In Grafana:

```text
Dashboards
    -> New Dashboard
    -> Import
```

Use the Node Exporter dashboard ID:

```text
1860
```

Then:

```text
Load
    -> Name: Node Exporter Full
    -> Import
```

Dashboard:

```text
1860 - Node Exporter Full
```

This dashboard provides visibility into the EC2 node metrics.

Another useful dashboard is:

```text
15661 - Kubernetes Dashboard
```

> Dashboard 15661 is primarily intended for Kubernetes environments and is not required for the basic EC2 Node Exporter setup.

---

## 9. Connect Grafana to Prometheus

Grafana needs Prometheus configured as a data source before it can display the collected metrics.

In Grafana:

```text
Data Sources
    -> Add data source
    -> Prometheus
```

Configure the Prometheus URL using the Monitor instance's private IP:

```text
http://<MONITOR_PRIVATE_IP>:9090
```

If your Grafana and Prometheus services are running on the same Monitor instance, you can also use:

```text
http://localhost:9090
```

Then click:

```text
Save & Test
```

Grafana should confirm that the Prometheus data source is working.

---

## 10. Verify Node Metrics

Open:

```text
Dashboards
    -> Node Exporter Full
```

Select the appropriate node/instance.

You should see metrics such as:

- CPU utilization
- Memory utilization
- Disk usage
- Network traffic
- System load
- Filesystem usage
- Uptime

It may take a short amount of time for metrics to appear after Node Exporter and Prometheus are configured.

---

## 11. Generate CPU and RAM Load

To test the monitoring setup, run the Ansible playbook:

```bash
ansible-playbook -i inventory.ini skipe.yml
```

This generates CPU/RAM load on the nodes.

Then open the Grafana dashboard and observe the changes in:

- CPU usage
- Memory usage
- Load average
- System metrics

This is useful for verifying that:

```text
Node
  -> Node Exporter
  -> Prometheus
  -> Grafana
```

is working correctly.

---

# Ansible Playbooks

The project uses Ansible playbooks for server configuration.

Example structure:

```text
.
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── ansible/
│   ├── inventory.ini
│   ├── node_exporter.yml
│   ├── monitor.yml
│   └── skipe.yml
│
└── README.md
```

Adjust the structure above to match the actual repository layout.

## Useful Commands

### Check Prometheus status

```bash
systemctl status prometheus
```

### Restart Prometheus

```bash
sudo systemctl restart prometheus
```

### View Prometheus configuration

```bash
cat /etc/prometheus/prometheus.yml
```

### Check Node Exporter

```bash
systemctl status node_exporter
```

### Restart Node Exporter

```bash
sudo systemctl restart node_exporter
```

### Check Grafana

```bash
systemctl status grafana-server
```

### Restart Grafana

```bash
sudo systemctl restart grafana-server
```

---

# Troubleshooting

## Prometheus target is DOWN

Check the target configuration:

```bash
cat /etc/prometheus/prometheus.yml
```

Make sure the Node private IP and port are correct:

```text
<NODE_PRIVATE_IP>:9100
```

Check Node Exporter:

```bash
systemctl status node_exporter
```

Test locally on the node:

```bash
curl http://localhost:9100/metrics
```

Check connectivity from the Monitor:

```bash
curl http://<NODE_PRIVATE_IP>:9100/metrics
```

If this fails, check the AWS security group and VPC networking.

---

## Grafana shows no data

First verify that Prometheus is receiving metrics.

Open:

```text
http://<MONITOR_IP>:9090
```

Check the targets and confirm they are:

```text
UP
```

Then verify the Grafana Prometheus data source:

```text
Grafana
  -> Data Sources
  -> Prometheus
  -> Save & Test
```

---

## Security Notes

For production environments:

- Do not expose Node Exporter port `9100` to `0.0.0.0/0`.
- Prefer private IP communication between Monitor and Nodes.
- Prefer AWS Security Group references over individual public IP addresses where possible.
- Restrict SSH (`22`) to trusted IP addresses or a bastion/VPN.
- Restrict Prometheus (`9090`) and Grafana (`3000`) to trusted networks.
- Store AWS credentials and SSH private keys outside Git.
- Never commit secrets or private keys to the repository.

## End-to-End Flow

```text
Terraform
   |
   | Creates infrastructure
   v
AWS EC2
   |
   +-------------------+
   |                   |
   v                   v
Monitor              Node 1 / Node 2
   |                   |
   |                   +--> Node Exporter :9100
   |
   +--> Prometheus :9090
            |
            | Scrapes private IPs
            v
       Node 1 / Node 2
            |
            v
       Prometheus Metrics
            |
            v
       Grafana :3000
            |
            v
      Monitoring Dashboard
```

## Key Design Decision

The project deliberately uses:

```text
Ansible SSH connection -> Public IP
Prometheus monitoring  -> Private IP
```

This separation provides a better security model:

```text
Ansible
   |
   | SSH via public IP
   v
EC2 Nodes

Prometheus
   |
   | Internal VPC traffic
   v
Private IP:9100
```

The monitoring traffic therefore remains inside the AWS VPC instead of requiring Prometheus to scrape Node Exporter through public IP addresses.

---

## Result

After completing the setup, the environment provides a centralized monitoring solution:

- Terraform provisions the infrastructure.
- Ansible configures the EC2 instances.
- Node Exporter collects system metrics.
- Prometheus stores and queries the metrics.
- Grafana visualizes the metrics.
- AWS Security Groups control access between the Monitor and Node instances.

This creates a reusable foundation for monitoring EC2 infrastructure and can be extended with alerts, Alertmanager, additional exporters, dashboards, and automated incident notifications.
