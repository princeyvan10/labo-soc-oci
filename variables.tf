# ============================================================
# AUTHENTIFICATION OCI
# ============================================================
variable "tenancy_ocid" {
  description = "OCID du tenancy OCI (trouvé dans Identity > Tenancy)"
  type        = string
}

variable "user_ocid" {
  description = "OCID de ton utilisateur OCI"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint de ta clé API OCI"
  type        = string
}

variable "private_key_path" {
  description = "Chemin vers ta clé privée API OCI (.pem)"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "region" {
  description = "Région OCI principale (home region)"
  type        = string
  default     = "ca-montreal-1"
}

variable "region_toronto" {
  description = "Région OCI secondaire (Toronto)"
  type        = string
  default     = "ca-toronto-1"
}

# ============================================================
# COMPARTIMENT
# ============================================================
variable "compartment_ocid" {
  description = "OCID du compartiment cible (root par défaut)"
  type        = string
}

# ============================================================
# RÉSEAU
# ============================================================
variable "vcn_cidr" {
  description = "Bloc CIDR du VCN principal"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Bloc CIDR du sous-réseau public (Wazuh Manager)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "Bloc CIDR du sous-réseau privé (agents)"
  type        = string
  default     = "10.0.2.0/24"
}

# ============================================================
# INSTANCES
# ============================================================
variable "ssh_public_key" {
  description = "Clé publique SSH pour accéder aux instances"
  type        = string
}

variable "manager_shape" {
  description = "Shape AMD E4 Flex x86_64 (compatible Wazuh installer)"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "manager_ocpus" {
  description = "Nombre de vCPUs pour le Wazuh Manager"
  type        = number
  default     = 4
}

variable "manager_memory_gb" {
  description = "RAM en GB pour le Wazuh Manager"
  type        = number
  default     = 24
}

variable "agent_shape" {
  description = "Shape AMD E2 (Always Free)"
  type        = string
  default     = "VM.Standard.E2.1.Micro"
}

variable "agent_shape_toronto" {
  description = "Shape agent Toronto (Flex universel, disponible dans toutes les régions)"
  type        = string
  default     = "VM.Standard3.Flex"
}

variable "agent_toronto_ocpus" {
  description = "Nombre de vCPUs pour l'agent Toronto"
  type        = number
  default     = 1
}

variable "agent_toronto_memory_gb" {
  description = "RAM en GB pour l'agent Toronto"
  type        = number
  default     = 1
}

variable "ubuntu_image_ocid" {
  description = "OCID de l'image Ubuntu 22.04 ARM (trouver via OCI Console > Compute > Images)"
  type        = string
  # Exemple pour ca-toronto-1 : mettre à jour selon ta région
  # https://docs.oracle.com/en-us/iaas/images/
  default     = "REMPLACER_PAR_OCID_IMAGE_UBUNTU_22_ARM"
}

variable "ubuntu_amd_image_ocid" {
  description = "OCID de l'image Ubuntu 22.04 AMD x86 pour l'agent"
  type        = string
  default     = "REMPLACER_PAR_OCID_IMAGE_UBUNTU_22_AMD"
}

variable "availability_domain" {
  description = "Availability Domain région principale (Montréal)"
  type        = string
  default     = "Uocm:CA-MONTREAL-1-AD-1"
}

# ============================================================
# RÉSEAU - Toronto (région secondaire)
# ============================================================
variable "vcn_cidr_toronto" {
  description = "Bloc CIDR du VCN Toronto"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidr_toronto" {
  description = "Bloc CIDR du sous-réseau public Toronto (Wazuh Manager)"
  type        = string
  default     = "10.1.1.0/24"
}

variable "private_subnet_cidr_toronto" {
  description = "Bloc CIDR du sous-réseau privé Toronto (agents)"
  type        = string
  default     = "10.1.2.0/24"
}

# ============================================================
# TAGS
# ============================================================
variable "project_name" {
  description = "Nom du projet (pour les tags OCI)"
  type        = string
  default     = "labo-soc-wazuh"
}
