# Lab SOC Cloud-Native — Oracle Cloud Infrastructure

> Déploiement d'un SOC (Security Operations Center) multi-région sur Oracle Cloud Infrastructure avec Wazuh SIEM, orchestré par Terraform.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Oracle Cloud Infrastructure               │
│                                                             │
│   ┌──────────────────────┐    ┌──────────────────────┐     │
│   │  ca-montreal-1       │    │  ca-toronto-1        │     │
│   │  (Région principale) │    │  (Région secondaire) │     │
│   │                      │    │                      │     │
│   │  VCN 10.0.0.0/16    │    │  VCN 10.1.0.0/16    │     │
│   │  ┌────────────────┐  │    │  ┌────────────────┐  │     │
│   │  │ Wazuh Manager  │  │    │  │ Wazuh Manager  │  │     │
│   │  │ E4.Flex x86_64 │  │    │  │ E4.Flex x86_64 │  │     │
│   │  │ 4 OCPU / 24GB  │  │    │  │ 4 OCPU / 24GB  │  │     │
│   │  │ Dashboard :443 │  │    │  │ Dashboard :443 │  │     │
│   │  └────────────────┘  │    │  └────────────────┘  │     │
│   │  ┌────────────────┐  │    │  ┌────────────────┐  │     │
│   │  │  Wazuh Agent   │  │    │  │  Wazuh Agent   │  │     │
│   │  │  E2.1.Micro    │  │    │  │ Standard3.Flex │  │     │
│   │  └────────────────┘  │    │  └────────────────┘  │     │
│   └──────────────────────┘    └──────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

## Stack Technologique

| Composant | Technologie |
|---|---|
| Cloud Provider | Oracle Cloud Infrastructure (OCI) |
| IaC | Terraform >= 1.3 |
| SIEM | Wazuh 4.7.5 (Manager + Indexer + Dashboard) |
| OS | Ubuntu 22.04 LTS (x86_64) |
| Sécurité réseau | Security Lists + NSG (double couche) |
| Firewall VM | UFW |

## Fonctionnalités

- **Multi-région canadienne** : Montréal (ca-montreal-1) + Toronto (ca-toronto-1)
- **Infrastructure as Code** : 100% automatisé via Terraform
- **Sécurité en couches** : OCI Security Lists + NSG + UFW
- **Installation automatique** : Wazuh déployé via cloud-init (user_data)
- **Dashboard HTTPS** : Interface web Wazuh accessible sur port 443
- **Agent connecté** : Agent Wazuh opérationnel sur Montréal (oci-agent-01)
- **Détection brute force SSH** : Alertes MITRE ATT&CK en temps réel (rules 5710, 5760, 5503)
- **Simulation d'attaques** : Tests hydra + nmap validés avec 6000+ alertes générées

## Prérequis

- Compte Oracle Cloud Infrastructure (Pay-as-you-go)
- Terraform >= 1.3 installé
- Clé API OCI configurée dans `~/.oci/`
- Clé SSH RSA générée

## Déploiement

```bash
# 1. Cloner le repo
git clone https://github.com/princeyvan10/labo-soc-oci.git
cd labo-soc-oci

# 2. Configurer les variables
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars avec vos OCIDs et clés

# 3. Initialiser Terraform
terraform init

# 4. Vérifier le plan
terraform plan

# 5. Déployer (~20 min)
terraform apply
```

## Structure des fichiers

```
.
├── provider.tf          # Provider OCI (Montréal + alias Toronto)
├── variables.tf         # Variables : auth, réseau, instances
├── main.tf              # Ressources : VCN, NSG, Instances (2 régions)
├── outputs.tf           # IPs, URLs, commandes SSH
├── terraform.tfvars     # Vos valeurs (non versionné)
├── terraform.tfvars.example  # Template
├── deploy.sh            # Script de déploiement assisté
└── .gitignore
```

## Sécurité réseau

| Port | Protocole | Source | Usage |
|------|-----------|--------|-------|
| 22 | TCP | 0.0.0.0/0 | SSH Admin |
| 443 | TCP | 0.0.0.0/0 | Wazuh Dashboard |
| 1514 | TCP/UDP | VCN | Événements agents |
| 1515 | TCP | VCN | Enregistrement agents |
| 55000 | TCP | 0.0.0.0/0 | API Wazuh |
| 9200 | TCP | VCN | OpenSearch interne |

## Accès au Dashboard

Après déploiement (~15 min pour cloud-init) :

```
URL      : https://<wazuh_manager_public_ip>
User     : admin
Password : (généré lors de l'installation — voir logs)
```

Suivre l'installation :
```bash
ssh -i ~/.ssh/oci-key ubuntu@<ip> 'sudo tail -f /var/log/wazuh-install.log'
```

## Note importante — iptables OCI

OCI Ubuntu ajoute une règle iptables REJECT par défaut. Après déploiement, supprimer cette règle :

```bash
sudo iptables -D INPUT 5
sudo netfilter-persistent save
```

## Simulations d'attaques réalisées

| Attaque | Outil | Règles déclenchées | MITRE ATT&CK |
|---------|-------|-------------------|--------------|
| Brute Force SSH | Hydra | 5710, 5760, 5503 | T1110 - Brute Force |
| Scan de ports | Nmap | Connexions SSH anormales | T1046 - Network Service Discovery |

## Compétences démontrées

- Terraform multi-provider (alias de région OCI)
- Architecture réseau cloud (VCN, IGW, Security Lists, NSG)
- Administration Linux (UFW, iptables, systemd)
- Déploiement SIEM Wazuh en production
- Connexion et configuration d'agents Wazuh
- Simulation d'attaques et analyse d'alertes (SOC Analyst)
- Mapping MITRE ATT&CK des menaces détectées
- Sécurité défensive et monitoring cloud
- Infrastructure as Code et automatisation

---

**Auteur** : Prince Yvan Djine Kadji
**Contact** : kadjiyvan8@gmail.com
**LinkedIn** : [Prince Yvan Djine Kadji](https://www.linkedin.com/in/prince-yvan-djine-kadji-40a91737b)
