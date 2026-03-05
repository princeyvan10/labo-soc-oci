# ============================================================
# OUTPUTS - Informations post-déploiement
# ============================================================

output "wazuh_manager_public_ip" {
  description = "IP publique du Wazuh Manager - accès Dashboard et SSH"
  value       = oci_core_instance.wazuh_manager.public_ip
}

output "wazuh_manager_private_ip" {
  description = "IP privée du Wazuh Manager (utilisée par les agents)"
  value       = oci_core_instance.wazuh_manager.private_ip
}

output "wazuh_agent_private_ip" {
  description = "IP privée de l'agent Wazuh (sous-réseau privé)"
  value       = oci_core_instance.wazuh_agent.private_ip
}

output "wazuh_dashboard_url" {
  description = "URL du Dashboard Wazuh (disponible ~15 min après le déploiement)"
  value       = "https://${oci_core_instance.wazuh_manager.public_ip}"
}

output "ssh_manager_command" {
  description = "Commande SSH pour se connecter au Wazuh Manager"
  value       = "ssh -i <ta_cle_privee> ubuntu@${oci_core_instance.wazuh_manager.public_ip}"
}

output "ssh_agent_via_bastion" {
  description = "Commande SSH pour atteindre l'agent via le Manager (bastion)"
  value       = "ssh -i <ta_cle_privee> -J ubuntu@${oci_core_instance.wazuh_manager.public_ip} ubuntu@${oci_core_instance.wazuh_agent.private_ip}"
}

output "vcn_id" {
  description = "OCID du VCN créé"
  value       = oci_core_vcn.soc_vcn.id
}

output "wazuh_manager_nsg_id" {
  description = "OCID du NSG du Wazuh Manager"
  value       = oci_core_network_security_group.wazuh_manager_nsg.id
}

output "installation_log_command" {
  description = "Commande pour suivre l'installation Wazuh en temps réel"
  value       = "ssh -i <ta_cle_privee> ubuntu@${oci_core_instance.wazuh_manager.public_ip} 'sudo tail -f /var/log/wazuh-install.log'"
}

# ============================================================
# OUTPUTS - Toronto (région secondaire)
# ============================================================

output "toronto_wazuh_manager_public_ip" {
  description = "IP publique du Wazuh Manager Toronto"
  value       = oci_core_instance.wazuh_manager_toronto.public_ip
}

output "toronto_wazuh_manager_private_ip" {
  description = "IP privée du Wazuh Manager Toronto"
  value       = oci_core_instance.wazuh_manager_toronto.private_ip
}

output "toronto_wazuh_agent_private_ip" {
  description = "IP privée de l'agent Wazuh Toronto"
  value       = oci_core_instance.wazuh_agent_toronto.private_ip
}

output "toronto_wazuh_dashboard_url" {
  description = "URL du Dashboard Wazuh Toronto (~15 min après déploiement)"
  value       = "https://${oci_core_instance.wazuh_manager_toronto.public_ip}"
}

output "toronto_ssh_manager_command" {
  description = "Commande SSH pour le Wazuh Manager Toronto"
  value       = "ssh -i <ta_cle_privee> ubuntu@${oci_core_instance.wazuh_manager_toronto.public_ip}"
}

output "toronto_installation_log_command" {
  description = "Suivre l'installation Wazuh Toronto en temps réel"
  value       = "ssh -i <ta_cle_privee> ubuntu@${oci_core_instance.wazuh_manager_toronto.public_ip} 'sudo tail -f /var/log/wazuh-install.log'"
}

output "toronto_vcn_id" {
  description = "OCID du VCN Toronto"
  value       = oci_core_vcn.soc_vcn_toronto.id
}
