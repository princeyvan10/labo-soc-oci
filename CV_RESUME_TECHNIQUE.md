# Résumé Technique - Lab SOC Cloud Native sur OCI
## À utiliser dans ton CV / entretiens chez Desjardins

---

## Titre du projet (pour ton CV)
**Lab SOC Cloud-Native | Oracle Cloud Infrastructure | Terraform | Wazuh SIEM**

---

## Description courte (1-2 lignes pour CV)
Déploiement automatisé d'un laboratoire SOC complet sur Oracle Cloud (Always Free Tier)
via Terraform, intégrant Wazuh SIEM/XDR avec une architecture réseau sécurisée Cloud-Native.

---

## Description longue (pour section "Projets" du CV)

Conception et déploiement d'une infrastructure SOC (Security Operations Center) complète
sur Oracle Cloud Infrastructure (OCI) en adoptant une approche Infrastructure-as-Code (IaC).

**Réalisations techniques :**
- Remplacement d'un pare-feu pfSense traditionnel par une architecture Cloud-Native utilisant
  les Security Lists et Network Security Groups (NSG) d'OCI, offrant une sécurité périmétrique
  gérée par code et versionnable sous Git.
- Déploiement automatisé via Terraform d'un VCN segmenté (sous-réseau public + privé) avec
  Internet Gateway, NAT Gateway et tables de routage distinctes.
- Provisionnement d'une instance ARM Ampere A1 (4 vCPUs, 24 GB RAM - Always Free) hébergeant
  la stack Wazuh complète : Indexer (OpenSearch), Manager et Dashboard.
- Automatisation de l'installation Wazuh via user_data (cloud-init) sans intervention manuelle.
- Configuration UFW (Uncomplicated Firewall) intra-VM en complément des NSG OCI, appliquant
  le principe de défense en profondeur (Defense in Depth).

---

## Stack technologique
| Catégorie         | Technologies                                      |
|-------------------|---------------------------------------------------|
| IaC               | Terraform >= 1.3, Provider OCI >= 5.0             |
| Cloud             | Oracle Cloud Infrastructure (OCI)                 |
| Réseau            | VCN, Security Lists, NSG, IGW, NAT Gateway        |
| SIEM/XDR          | Wazuh 4.x (Manager + Indexer + Dashboard)         |
| OS                | Ubuntu 22.04 LTS (ARM64 + AMD64)                  |
| Firewall intra-VM | UFW (iptables)                                    |
| CI/CD possible    | GitHub Actions + Terraform Cloud                  |

---

## Compétences démontrées (pour les entretiens)

### Sécurité réseau Cloud-Native
> "J'ai remplacé pfSense par les Security Lists et NSG d'OCI. La différence clé est que
> cette approche est stateful, déclarative et versionnée sous Git. Les Security Lists
> s'appliquent au niveau du sous-réseau (périmètre large), tandis que les NSG offrent
> un contrôle granulaire au niveau de la VNIC de chaque instance - similaire aux
> Security Groups AWS. Cette double couche implémente le principe de défense en profondeur."

### Infrastructure as Code
> "Tout le lab est reproductible avec 'terraform apply'. Zéro clic dans la console OCI.
> Le code est versionnable, auditable et peut être intégré dans un pipeline CI/CD."

### Principe du moindre privilège
> "Les agents Wazuh sont dans un sous-réseau privé sans IP publique. Ils n'ont accès
> qu'aux ports Wazuh du Manager (1514/1515). L'accès SSH se fait uniquement via le
> Manager comme bastion host (SSH ProxyJump)."

---

## Points à mentionner à Desjardins

1. **Coût zéro** : Utilisation exclusive du Always Free Tier OCI (2 micro VMs AMD + 4 OCPU ARM)
2. **Cloud-Native** : Architecture portable et conforme aux bonnes pratiques CIS Benchmarks
3. **Monitoring** : Wazuh collecte les logs système, détecte les anomalies, génère des alertes
4. **Scalabilité** : Architecture extensible - ajout d'agents via Terraform avec une variable
5. **Conformité** : Wazuh supporte les frameworks PCI-DSS, HIPAA, GDPR (pertinent pour Desjardins)

---

## Commandes clés à connaître pour l'entretien

```bash
# Déploiement complet
terraform init && terraform plan && terraform apply

# Vérifier le statut Wazuh
ssh ubuntu@<IP_MANAGER> 'sudo systemctl status wazuh-manager wazuh-indexer wazuh-dashboard'

# Lister les agents connectés
ssh ubuntu@<IP_MANAGER> 'sudo /var/ossec/bin/agent_control -l'

# Voir les alertes en temps réel
ssh ubuntu@<IP_MANAGER> 'sudo tail -f /var/ossec/logs/alerts/alerts.json | jq .'
```
