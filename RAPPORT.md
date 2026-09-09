# Rapport final — TP Infra Azure

Souscription `5e683e0f-b00c-48d6-9769-5aaf598de8f1`, groupe de ressources `msaidiRG`.

## 1. Exigences

| # | Exigence | État | Preuve concrète |
|---|---|---|---|
| 1 | Socle IaC Terraform (backend distant, provider, RG en data source) | Fait | `terraform apply` → `Apply complete! Resources: 0 added, 2 changed, 0 destroyed.` ; state distant sur storage account dédié (`tfstate/infra.tfstate`) |
| 2 | Partage de fichiers Azure (compte, share, RBAC groupe Entra) | Fait | `az storage file upload/list/download --auth-mode login --backup-intent` réussis ; rôle `Storage File Data Privileged Contributor` sur `tpmohpartage3yig8b` scopé au compte (commit `ed28762`) |
| 3 | AKS + Workload Identity + GitOps Argo CD | Fait | `kubectl get nodes` → `Ready` ; `kubectl get application bdd -n argocd` → `Synced` / `Healthy` |
| 4 | Chaîne de secret bout-en-bout (Key Vault → UAMI → PostgreSQL in-cluster) | Fait | `kubectl exec -n bdd postgres-0 -- psql -U tpuser -d tpdb -c "SELECT * FROM preuve;"` → ligne `avant sauvegarde` |
| 5 | Pipeline CI/CD (GitHub Actions, OIDC, plan/apply Terraform) | Fait | `gh run view 34338476109 --repo ororck/infra-tp` → `completed success` |
| 6 (bonus) | Sauvegarde planifiée et récurrente (Azure Backup for AKS) | Fait | Policy `aks-bdd-policy` : incrémental toutes les 4h, rétention 7j ; job `4f1802ff-bc8b-...` → `Completed` |
| 7 (bonus) | Test de restauration bout-en-bout | Fait | Namespace `bdd` supprimé puis restauré (job `52453e25-f887-...` → `Completed`) ; `SELECT * FROM preuve;` post-restauration → ligne `avant sauvegarde` toujours présente |

## 2. Décisions d'architecture

- **Azure Files OAuth over REST plutôt qu'Entra Kerberos (AADKERB)** : le mode Kerberos ne donnait pas d'accès effectif au partage en conditions réelles ; l'authentification OAuth REST (`--auth-mode login`) avec RBAC fonctionne de façon fiable, sans dépendance à un contrôleur de domaine.
- **Rôle RBAC au scope du compte de stockage et non du partage** : `Storage File Data SMB Share Contributor` au scope du partage ne donnait pas d'accès opérationnel ; seul `Storage File Data Privileged Contributor` au scope du compte a fonctionné en test réel.
- **PostgreSQL in-cluster plutôt qu'un service managé** : l'objectif pédagogique du TP est de démontrer Workload Identity, stockage CSI et Azure Backup for AKS sur une charge stateful Kubernetes-native, pas la haute disponibilité d'un PaaS.
- **PVC `managed-csi` (Azure Disk) plutôt qu'`azurefile-csi`** : PostgreSQL exige un volume bloc RWO à faible latence ; un partage fichier RWX est inadapté à un moteur de stockage transactionnel.
- **Deux dépôts Git séparés (`infra-tp` / `apps-tp`)** : sépare le cycle de vie de l'infrastructure (Terraform) de celui des applications déployées par GitOps, conforme au modèle app-repo/infra-repo attendu par Argo CD.
- **UAMI avec federated credential plutôt qu'App Registration à secret** : élimine tout secret à stocker ou faire tourner côté CI et côté charge applicative (auth OIDC keyless), réduisant la surface d'attaque.

## 3. Écarts assumés

- **Bootstrap manuel du state Terraform et de l'identité de pipeline (`id-tp-cicd`)**. Raison : dépendance circulaire — le backend distant et l'identité qui authentifie Terraform ne peuvent pas être créés par ce même Terraform. Correction possible : isoler ce bootstrap dans un second module Terraform à state local, versionné séparément.
- **Backup-instance Azure Backup for AKS créée depuis le portail, hors IaC**. Raison : la commande CLI `az dataprotection backup-instance restore initialize-for-data-recovery` échouait dans l'environnement Windows/Git Bash utilisé (conversion de chemins MSYS corrompant les ARM ID passés en argument). Correction possible : déclarer la ressource `azurerm_data_protection_backup_instance_kubernetes_cluster` en Terraform, ou exécuter la CLI depuis un environnement sans cette contrainte (WSL, Cloud Shell, runner CI).
- **Variables GitHub Actions et protection de branche configurées manuellement** dans les paramètres du dépôt. Raison : aucun provider Terraform `github` n'a été introduit dans ce TP. Correction possible : ajouter le provider `integrations/github` et déclarer `github_actions_variable` / `github_branch_protection` en code.

## 4. Contrainte plateforme rencontrée

Un principal de service identifié **SIAutomation** (`appId dc305306-c84b-4303-9f45-7286b01d07f9`) désalloue périodiquement les VMSS des clusters AKS du tenant Simplon partagé. Observation directe sur `msaidiRG` : `az vmss list-instances -g MC_msaidiRG_aks-tpmoh -n aks-system-41434209-vmss` → 0 instance, nœud `NotReady` ; résolu par réconciliation forcée (`az aks nodepool upgrade --no-wait` en no-op de version) qui a fait recréer l'instance par le RP AKS.

Preuve journal d'activité (corroborante, à l'échelle de la souscription) : le même appelant a exécuté des vagues synchronisées de `Microsoft.Compute/virtualMachineScaleSets/deallocate/action` (ex. `2026-09-07T16:34–16:35Z`) sur au moins 7 autres clusters AKS d'étudiants du même tenant (`MC_aelouadiRG_*`, `MC_asigurRG_*`, `MC_mcherfiRG_*`, `MC_fbarryRG_*`, `MC_aidialloRG_*`, `MC_abenslimaneRG_*`, `MC_lzniberRG_*`), confirmant un automate récurrent à l'échelle de la plateforme. Aucune entrée d'Activity Log n'a pu être retrouvée spécifiquement pour `MC_msaidiRG_aks-tpmoh` sur une fenêtre de 10 jours interrogée — limite de la preuve documentée ici, le symptôme opérationnel direct ayant en revanche été constaté et corrigé en session.

## 5. Reste à faire

Industrialiser en Terraform la backup-instance et les paramètres GitHub Actions actuellement configurés à la main. Ajouter un test de restauration automatisé en CI plutôt qu'une procédure déclenchée manuellement. Faire évoluer PostgreSQL vers une solution haute disponibilité (réplication, ou Azure Database for PostgreSQL Flexible Server) si un objectif de disponibilité est ajouté au périmètre.
