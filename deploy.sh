#!/bin/bash
# ============================================================
# Script de déploiement - Lab SOC Wazuh sur OCI
# Auteur : Prince Yvan
# ============================================================
set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}=================================================${NC}"
echo -e "${CYAN}  Lab SOC Wazuh - Déploiement OCI avec Terraform${NC}"
echo -e "${CYAN}=================================================${NC}"

# Vérification des prérequis
echo -e "\n${YELLOW}[1/5] Vérification des prérequis...${NC}"
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}ERREUR: terraform non installé. Voir https://developer.hashicorp.com/terraform/install${NC}"; exit 1; }
command -v oci >/dev/null 2>&1 || echo -e "${YELLOW}AVIS: OCI CLI non détecté (optionnel)${NC}"

terraform version

# Vérification du fichier de variables
echo -e "\n${YELLOW}[2/5] Vérification de terraform.tfvars...${NC}"
if [ ! -f "terraform.tfvars" ]; then
  echo -e "${RED}ERREUR: terraform.tfvars absent.${NC}"
  echo -e "Copier et compléter : cp terraform.tfvars.example terraform.tfvars"
  exit 1
fi

# Vérification de la clé privée OCI
PRIV_KEY=$(grep private_key_path terraform.tfvars | cut -d'"' -f2 | tr -d ' ')
PRIV_KEY_EXPANDED="${PRIV_KEY/#\~/$HOME}"
if [ ! -f "$PRIV_KEY_EXPANDED" ]; then
  echo -e "${RED}ERREUR: Clé privée OCI non trouvée : $PRIV_KEY_EXPANDED${NC}"
  echo "Générer avec : oci setup keys"
  exit 1
fi
echo -e "${GREEN}Clé OCI trouvée : $PRIV_KEY_EXPANDED${NC}"

# Initialisation Terraform
echo -e "\n${YELLOW}[3/5] Initialisation Terraform (téléchargement providers)...${NC}"
terraform init -upgrade

# Plan de déploiement
echo -e "\n${YELLOW}[4/5] Génération du plan Terraform...${NC}"
terraform plan -out=tfplan

# Confirmation
echo -e "\n${YELLOW}[5/5] Déploiement...${NC}"
echo -e "${RED}ATTENTION: Cette action va créer des ressources OCI.${NC}"
read -p "Continuer le déploiement ? (oui/non) : " CONFIRM
if [ "$CONFIRM" != "oui" ]; then
  echo "Déploiement annulé."
  exit 0
fi

terraform apply tfplan

echo -e "\n${GREEN}=================================================${NC}"
echo -e "${GREEN}  Déploiement terminé !${NC}"
echo -e "${GREEN}=================================================${NC}"
echo -e "\n${CYAN}Outputs importants :${NC}"
terraform output

echo -e "\n${YELLOW}IMPORTANT: L'installation de Wazuh prend ~10-15 minutes.${NC}"
echo -e "Surveiller l'installation avec la commande 'installation_log_command' ci-dessus."
echo -e "\n${CYAN}Credentials Dashboard Wazuh par défaut :${NC}"
echo -e "  Utilisateur : admin"
echo -e "  Mot de passe : voir /var/log/wazuh-install.log sur le Manager"
