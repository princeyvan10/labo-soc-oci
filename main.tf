# ============================================================
# LOCALS
# ============================================================
locals {
  common_tags = {
    Project     = var.project_name
    Environment = "lab"
    ManagedBy   = "terraform"
  }
}

# ============================================================
# DATA SOURCES
# ============================================================

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.E4.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_core_images" "ubuntu_amd" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# ============================================================
# RÉSEAU
# ============================================================

resource "oci_core_vcn" "soc_vcn" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.project_name}-vcn"
  cidr_blocks    = [var.vcn_cidr]
  dns_label      = "socvcn"
  freeform_tags  = local.common_tags
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.soc_vcn.id
  display_name   = "${var.project_name}-igw"
  enabled        = true
  freeform_tags  = local.common_tags
}

resource "oci_core_route_table" "main_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.soc_vcn.id
  display_name   = "${var.project_name}-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }

  freeform_tags = local.common_tags
}

# ============================================================
# SECURITY LIST
# ============================================================

resource "oci_core_security_list" "main_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.soc_vcn.id
  display_name   = "${var.project_name}-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  ingress_security_rules {
    protocol  = "6"
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 22
      max = 22
    }
    description = "SSH"
  }

  ingress_security_rules {
    protocol  = "6"
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 443
      max = 443
    }
    description = "HTTPS Dashboard"
  }

  ingress_security_rules {
    protocol  = "6"
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 55000
      max = 55000
    }
    description = "Wazuh API"
  }

  ingress_security_rules {
    protocol  = "6"
    source    = var.vcn_cidr
    stateless = false
    tcp_options {
      min = 1514
      max = 1514
    }
    description = "Agent events TCP"
  }

  ingress_security_rules {
    protocol  = "17"
    source    = var.vcn_cidr
    stateless = false
    udp_options {
      min = 1514
      max = 1514
    }
    description = "Agent events UDP"
  }

  ingress_security_rules {
    protocol  = "6"
    source    = var.vcn_cidr
    stateless = false
    tcp_options {
      min = 1515
      max = 1515
    }
    description = "Agent registration"
  }

  ingress_security_rules {
    protocol  = "6"
    source    = var.vcn_cidr
    stateless = false
    tcp_options {
      min = 9200
      max = 9200
    }
    description = "OpenSearch interne"
  }

  freeform_tags = local.common_tags
}

# ============================================================
# NSG - Wazuh Manager
# ============================================================

resource "oci_core_network_security_group" "wazuh_manager_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.soc_vcn.id
  display_name   = "${var.project_name}-manager-nsg"
  freeform_tags  = local.common_tags
}

resource "oci_core_network_security_group_security_rule" "manager_egress_all" {
  network_security_group_id = oci_core_network_security_group.wazuh_manager_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "Egress complet"
}

resource "oci_core_network_security_group_security_rule" "manager_ingress_ssh" {
  network_security_group_id = oci_core_network_security_group.wazuh_manager_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  description               = "SSH"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "manager_ingress_https" {
  network_security_group_id = oci_core_network_security_group.wazuh_manager_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  description               = "HTTPS Dashboard"
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "manager_ingress_api" {
  network_security_group_id = oci_core_network_security_group.wazuh_manager_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  description               = "Wazuh API"
  tcp_options {
    destination_port_range {
      min = 55000
      max = 55000
    }
  }
}

resource "oci_core_network_security_group_security_rule" "manager_ingress_agent_tcp" {
  network_security_group_id = oci_core_network_security_group.wazuh_manager_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  description               = "Agent events TCP 1514"
  tcp_options {
    destination_port_range {
      min = 1514
      max = 1514
    }
  }
}

resource "oci_core_network_security_group_security_rule" "manager_ingress_agent_udp" {
  network_security_group_id = oci_core_network_security_group.wazuh_manager_nsg.id
  direction                 = "INGRESS"
  protocol                  = "17"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  description               = "Agent events UDP 1514"
  udp_options {
    destination_port_range {
      min = 1514
      max = 1514
    }
  }
}

resource "oci_core_network_security_group_security_rule" "manager_ingress_agent_reg" {
  network_security_group_id = oci_core_network_security_group.wazuh_manager_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  description               = "Agent registration 1515"
  tcp_options {
    destination_port_range {
      min = 1515
      max = 1515
    }
  }
}

# ============================================================
# NSG - Agent
# ============================================================

resource "oci_core_network_security_group" "wazuh_agent_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.soc_vcn.id
  display_name   = "${var.project_name}-agent-nsg"
  freeform_tags  = local.common_tags
}

resource "oci_core_network_security_group_security_rule" "agent_egress_all" {
  network_security_group_id = oci_core_network_security_group.wazuh_agent_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "Egress complet agent"
}

resource "oci_core_network_security_group_security_rule" "agent_ingress_ssh" {
  network_security_group_id = oci_core_network_security_group.wazuh_agent_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  description               = "SSH depuis VCN"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

# ============================================================
# SOUS-RÉSEAU
# ============================================================

resource "oci_core_subnet" "main_subnet" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.soc_vcn.id
  display_name               = "${var.project_name}-subnet"
  cidr_block                 = var.public_subnet_cidr
  dns_label                  = "mainsubnet"
  route_table_id             = oci_core_route_table.main_rt.id
  security_list_ids          = [oci_core_security_list.main_sl.id]
  prohibit_public_ip_on_vnic = false
  freeform_tags              = local.common_tags
}

# ============================================================
# USER DATA
# ============================================================

locals {
  wazuh_manager_userdata = <<-EOT
    #!/bin/bash
    set -euxo pipefail
    exec > /var/log/wazuh-install.log 2>&1

    apt-get update -y
    apt-get upgrade -y
    apt-get install -y curl wget gnupg2 apt-transport-https lsb-release

    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp
    ufw allow 443/tcp
    ufw allow 1514/tcp
    ufw allow 1514/udp
    ufw allow 1515/tcp
    ufw allow 55000/tcp
    ufw allow 9200/tcp
    ufw --force enable

    curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh

    cat > config.yml <<'WAZUH_CONFIG'
    nodes:
      indexer:
        - name: node-1
          ip: "127.0.0.1"
      server:
        - name: wazuh-1
          ip: "127.0.0.1"
      dashboard:
        - name: dashboard
          ip: "127.0.0.1"
    WAZUH_CONFIG

    bash wazuh-install.sh --generate-config-files
    bash wazuh-install.sh --wazuh-indexer node-1
    bash wazuh-install.sh --start-cluster
    bash wazuh-install.sh --wazuh-server wazuh-1
    bash wazuh-install.sh --wazuh-dashboard dashboard

    systemctl enable wazuh-indexer wazuh-manager wazuh-dashboard
    echo "=== Installation Wazuh terminee ==="
  EOT

  wazuh_agent_userdata = <<-EOT
    #!/bin/bash
    set -euxo pipefail
    exec > /var/log/wazuh-agent-install.log 2>&1

    apt-get update -y
    apt-get upgrade -y
    apt-get install -y curl wget

    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp
    ufw --force enable

    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" \
      > /etc/apt/sources.list.d/wazuh.list
    apt-get update -y

    WAZUH_MANAGER="${oci_core_instance.wazuh_manager.private_ip}" \
    WAZUH_AGENT_NAME="oci-agent-01" \
    apt-get install -y wazuh-agent

    systemctl daemon-reload
    systemctl enable wazuh-agent
    systemctl start wazuh-agent
    echo "=== Agent Wazuh installe ==="
  EOT
}

# ============================================================
# INSTANCE - Wazuh Manager (ARM Ampere A1 - Always Free)
# ============================================================

resource "oci_core_instance" "wazuh_manager" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "${var.project_name}-manager"
  shape               = var.manager_shape

  shape_config {
    ocpus         = var.manager_ocpus
    memory_in_gbs = var.manager_memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_arm.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.main_subnet.id
    display_name     = "${var.project_name}-manager-vnic"
    assign_public_ip = true
    hostname_label   = "wazuhmanager"
    nsg_ids          = [oci_core_network_security_group.wazuh_manager_nsg.id]
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.wazuh_manager_userdata)
  }

  freeform_tags = local.common_tags

  timeouts {
    create = "20m"
  }
}

# ============================================================
# INSTANCE - Agent Wazuh (AMD E2 Micro - Always Free)
# ============================================================

resource "oci_core_instance" "wazuh_agent" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "${var.project_name}-agent-01"
  shape               = var.agent_shape

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_amd.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.main_subnet.id
    display_name     = "${var.project_name}-agent-vnic"
    assign_public_ip = true
    hostname_label   = "wazuhagent01"
    nsg_ids          = [oci_core_network_security_group.wazuh_agent_nsg.id]
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.wazuh_agent_userdata)
  }

  freeform_tags = local.common_tags

  timeouts {
    create = "15m"
  }

  depends_on = [oci_core_instance.wazuh_manager]
}

# ============================================================
# TORONTO - DATA SOURCES
# ============================================================

data "oci_identity_availability_domains" "ads_toronto" {
  provider       = oci.toronto
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "ubuntu_arm_toronto" {
  provider                 = oci.toronto
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.E4.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_core_images" "ubuntu_amd_toronto" {
  provider                 = oci.toronto
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard3.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# ============================================================
# TORONTO - RÉSEAU
# ============================================================

resource "oci_core_vcn" "soc_vcn_toronto" {
  provider       = oci.toronto
  compartment_id = var.compartment_ocid
  display_name   = "${var.project_name}-vcn-toronto"
  cidr_blocks    = [var.vcn_cidr_toronto]
  dns_label      = "socvcntor"
  freeform_tags  = local.common_tags
}

resource "oci_core_internet_gateway" "igw_toronto" {
  provider       = oci.toronto
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.soc_vcn_toronto.id
  display_name   = "${var.project_name}-igw-toronto"
  enabled        = true
  freeform_tags  = local.common_tags
}

resource "oci_core_route_table" "main_rt_toronto" {
  provider       = oci.toronto
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.soc_vcn_toronto.id
  display_name   = "${var.project_name}-rt-toronto"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw_toronto.id
  }

  freeform_tags = local.common_tags
}

# ============================================================
# TORONTO - SECURITY LIST
# ============================================================

resource "oci_core_security_list" "main_sl_toronto" {
  provider       = oci.toronto
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.soc_vcn_toronto.id
  display_name   = "${var.project_name}-sl-toronto"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  ingress_security_rules {
    protocol  = "6"
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 22
      max = 22
    }
    description = "SSH"
  }

  ingress_security_rules {
    protocol  = "6"
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 443
      max = 443
    }
    description = "HTTPS Dashboard"
  }

  ingress_security_rules {
    protocol  = "6"
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 55000
      max = 55000
    }
    description = "Wazuh API"
  }

  ingress_security_rules {
    protocol  = "6"
    source    = var.vcn_cidr_toronto
    stateless = false
    tcp_options {
      min = 1514
      max = 1514
    }
    description = "Agent events TCP"
  }

  ingress_security_rules {
    protocol  = "17"
    source    = var.vcn_cidr_toronto
    stateless = false
    udp_options {
      min = 1514
      max = 1514
    }
    description = "Agent events UDP"
  }

  ingress_security_rules {
    protocol  = "6"
    source    = var.vcn_cidr_toronto
    stateless = false
    tcp_options {
      min = 1515
      max = 1515
    }
    description = "Agent registration"
  }

  ingress_security_rules {
    protocol  = "6"
    source    = var.vcn_cidr_toronto
    stateless = false
    tcp_options {
      min = 9200
      max = 9200
    }
    description = "OpenSearch interne"
  }

  freeform_tags = local.common_tags
}

# ============================================================
# TORONTO - NSG Manager
# ============================================================

resource "oci_core_network_security_group" "wazuh_manager_nsg_toronto" {
  provider       = oci.toronto
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.soc_vcn_toronto.id
  display_name   = "${var.project_name}-manager-nsg-toronto"
  freeform_tags  = local.common_tags
}

resource "oci_core_network_security_group_security_rule" "manager_egress_all_toronto" {
  provider                  = oci.toronto
  network_security_group_id = oci_core_network_security_group.wazuh_manager_nsg_toronto.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "Egress complet"
}

resource "oci_core_network_security_group_security_rule" "manager_ingress_ssh_toronto" {
  provider                  = oci.toronto
  network_security_group_id = oci_core_network_security_group.wazuh_manager_nsg_toronto.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  description               = "SSH"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "manager_ingress_https_toronto" {
  provider                  = oci.toronto
  network_security_group_id = oci_core_network_security_group.wazuh_manager_nsg_toronto.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  description               = "HTTPS Dashboard"
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "manager_ingress_api_toronto" {
  provider                  = oci.toronto
  network_security_group_id = oci_core_network_security_group.wazuh_manager_nsg_toronto.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  description               = "Wazuh API"
  tcp_options {
    destination_port_range {
      min = 55000
      max = 55000
    }
  }
}

resource "oci_core_network_security_group_security_rule" "manager_ingress_agent_tcp_toronto" {
  provider                  = oci.toronto
  network_security_group_id = oci_core_network_security_group.wazuh_manager_nsg_toronto.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.vcn_cidr_toronto
  source_type               = "CIDR_BLOCK"
  description               = "Agent events TCP 1514"
  tcp_options {
    destination_port_range {
      min = 1514
      max = 1514
    }
  }
}

resource "oci_core_network_security_group_security_rule" "manager_ingress_agent_udp_toronto" {
  provider                  = oci.toronto
  network_security_group_id = oci_core_network_security_group.wazuh_manager_nsg_toronto.id
  direction                 = "INGRESS"
  protocol                  = "17"
  source                    = var.vcn_cidr_toronto
  source_type               = "CIDR_BLOCK"
  description               = "Agent events UDP 1514"
  udp_options {
    destination_port_range {
      min = 1514
      max = 1514
    }
  }
}

resource "oci_core_network_security_group_security_rule" "manager_ingress_agent_reg_toronto" {
  provider                  = oci.toronto
  network_security_group_id = oci_core_network_security_group.wazuh_manager_nsg_toronto.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.vcn_cidr_toronto
  source_type               = "CIDR_BLOCK"
  description               = "Agent registration 1515"
  tcp_options {
    destination_port_range {
      min = 1515
      max = 1515
    }
  }
}

# ============================================================
# TORONTO - NSG Agent
# ============================================================

resource "oci_core_network_security_group" "wazuh_agent_nsg_toronto" {
  provider       = oci.toronto
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.soc_vcn_toronto.id
  display_name   = "${var.project_name}-agent-nsg-toronto"
  freeform_tags  = local.common_tags
}

resource "oci_core_network_security_group_security_rule" "agent_egress_all_toronto" {
  provider                  = oci.toronto
  network_security_group_id = oci_core_network_security_group.wazuh_agent_nsg_toronto.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "Egress complet agent"
}

resource "oci_core_network_security_group_security_rule" "agent_ingress_ssh_toronto" {
  provider                  = oci.toronto
  network_security_group_id = oci_core_network_security_group.wazuh_agent_nsg_toronto.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.vcn_cidr_toronto
  source_type               = "CIDR_BLOCK"
  description               = "SSH depuis VCN Toronto"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

# ============================================================
# TORONTO - SOUS-RÉSEAU
# ============================================================

resource "oci_core_subnet" "main_subnet_toronto" {
  provider                   = oci.toronto
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.soc_vcn_toronto.id
  display_name               = "${var.project_name}-subnet-toronto"
  cidr_block                 = var.public_subnet_cidr_toronto
  dns_label                  = "mainsubnettor"
  route_table_id             = oci_core_route_table.main_rt_toronto.id
  security_list_ids          = [oci_core_security_list.main_sl_toronto.id]
  prohibit_public_ip_on_vnic = false
  freeform_tags              = local.common_tags
}

# ============================================================
# TORONTO - USER DATA
# ============================================================

locals {
  wazuh_agent_toronto_userdata = <<-EOT
    #!/bin/bash
    set -euxo pipefail
    exec > /var/log/wazuh-agent-install.log 2>&1

    apt-get update -y
    apt-get upgrade -y
    apt-get install -y curl wget

    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp
    ufw --force enable

    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" \
      > /etc/apt/sources.list.d/wazuh.list
    apt-get update -y

    WAZUH_MANAGER="${oci_core_instance.wazuh_manager_toronto.private_ip}" \
    WAZUH_AGENT_NAME="oci-agent-toronto-01" \
    apt-get install -y wazuh-agent

    systemctl daemon-reload
    systemctl enable wazuh-agent
    systemctl start wazuh-agent
    echo "=== Agent Wazuh Toronto installe ==="
  EOT
}

# ============================================================
# TORONTO - INSTANCE Wazuh Manager (ARM Ampere A1)
# ============================================================

resource "oci_core_instance" "wazuh_manager_toronto" {
  provider            = oci.toronto
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads_toronto.availability_domains[0].name
  display_name        = "${var.project_name}-manager-toronto"
  shape               = var.manager_shape

  shape_config {
    ocpus         = var.manager_ocpus
    memory_in_gbs = var.manager_memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_arm_toronto.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.main_subnet_toronto.id
    display_name     = "${var.project_name}-manager-vnic-toronto"
    assign_public_ip = true
    hostname_label   = "wazuhmanagertor"
    nsg_ids          = [oci_core_network_security_group.wazuh_manager_nsg_toronto.id]
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.wazuh_manager_userdata)
  }

  freeform_tags = local.common_tags

  timeouts {
    create = "20m"
  }
}

# ============================================================
# TORONTO - INSTANCE Agent Wazuh (AMD E2 Micro)
# ============================================================

resource "oci_core_instance" "wazuh_agent_toronto" {
  provider            = oci.toronto
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads_toronto.availability_domains[0].name
  display_name        = "${var.project_name}-agent-toronto-01"
  shape               = var.agent_shape_toronto

  shape_config {
    ocpus         = var.agent_toronto_ocpus
    memory_in_gbs = var.agent_toronto_memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_amd_toronto.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.main_subnet_toronto.id
    display_name     = "${var.project_name}-agent-vnic-toronto"
    assign_public_ip = true
    hostname_label   = "wazuhagenttor"
    nsg_ids          = [oci_core_network_security_group.wazuh_agent_nsg_toronto.id]
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.wazuh_agent_toronto_userdata)
  }

  freeform_tags = local.common_tags

  timeouts {
    create = "15m"
  }

  depends_on = [oci_core_instance.wazuh_manager_toronto]
}
