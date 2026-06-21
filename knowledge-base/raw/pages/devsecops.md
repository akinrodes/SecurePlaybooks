# DevSecOps — Sécurité intégrée dans le développement et l'exploitation

*Intégration de la sécurité ("Sec") dans la culture et les pratiques DevOps. Objectif : détecter et corriger les problèmes de sécurité le plus tôt possible dans le cycle de vie (shift-left security).*

---

## Pourquoi DevSecOps en environnement défense

Dans un contexte de défense :
- Les délais de déploiement sont courts (opérations, urgences)
- La tolérance aux vulnérabilités est nulle sur les SI classifiés
- L'auditabilité de la chaîne de déploiement est une exigence réglementaire
- La supply chain (composants logiciels tiers) est un vecteur d'attaque prioritaire (SolarWinds, XZ Utils...)

DevSecOps répond à ces contraintes en rendant la sécurité **automatique**, **reproductible** et **traçable**.

---

## Les 3 piliers

### 1. Shift-Left — Sécurité dès la conception
Ne pas attendre les tests de fin de projet. Intégrer les contrôles de sécurité dès le commit.

```
Coût de correction d'une vulnérabilité :
  Design  :   1x
  Dev     :   6x
  Test    :  15x
  Prod    : 100x
```

### 2. Automatisation — Sécurité sans friction
Chaque contrôle de sécurité doit être automatisé dans la pipeline CI/CD. Un développeur ne doit pas avoir à penser à la sécurité à chaque commit — les outils s'en chargent.

### 3. Feedback continu — Métriques et visibilité
Mean Time To Remediate (MTTR), nombre de vulnérabilités ouvertes, couverture des contrôles — métriques suivies et affichées.

---

## Pipeline DevSecOps sécurisé — étape par étape

```
Code → Commit → Build → Test → Deploy → Operate → Monitor
  │       │        │       │       │         │          │
  │    Secrets   SAST    DAST   Sign &    RBAC &    SIEM/
  │    scan      SBOM    IAST   Verify    Least    SOC
  │    (git)    Lint     Pentest Image    Priv.   Alerting
  │                             Sign
  │
Pre-commit hooks
(gitleaks, talisman)
```

### Étape 1 — Pre-commit (IDE + hooks)
| Outil | Fonction |
|-------|---------|
| `pre-commit` framework | Orchestration des hooks |
| `gitleaks` | Détection de secrets dans le code (clés API, passwords) |
| `talisman` | Bloquer les commits contenant des données sensibles |
| `detect-secrets` | Scan de secrets (Yelp) |
| Linters (ansible-lint, tflint...) | Qualité et sécurité du code IaC |

### Étape 2 — Analyse statique (SAST)
| Outil | Cible |
|-------|-------|
| `semgrep` | Multi-langage, règles custom |
| `bandit` | Python |
| `gosec` | Go |
| `ansible-lint` | Playbooks Ansible |
| `tfsec` / `checkov` | Terraform / IaC |
| `kics` | Multi-IaC (K8s, Docker, Ansible, Terraform) |
| `trivy` (mode FS) | Systèmes de fichiers, IaC |

### Étape 3 — Gestion des dépendances (SCA + SBOM)
| Outil | Fonction |
|-------|---------|
| `syft` | Génération SBOM (Software Bill of Materials) |
| `grype` | Scan de vulnérabilités sur SBOM |
| `trivy` (mode image) | Vulnérabilités dans les images conteneurs |
| `dependency-check` (OWASP) | Dépendances Java/Python/Node |
| `renovate` / `dependabot` | Mise à jour automatique des dépendances |

### Étape 4 — Signature et intégrité des artefacts
| Outil | Fonction |
|-------|---------|
| `cosign` | Signature des images OCI (Sigstore) |
| `in-toto` | Attestations de chaîne de build |
| `notary` v2 | Signature d'artefacts OCI |
| `gpg` | Signature des commits et releases |
| Registre privé + TLS | Contrôle de l'origine des images |

**Règle :** toute image déployée doit être signée et vérifiable. Refuser les images `latest` non signées.

### Étape 5 — Tests dynamiques (DAST / IAST)
| Outil | Fonction |
|-------|---------|
| `OWASP ZAP` | DAST web automatisé |
| `nuclei` | Templates de vulnérabilités |
| `nmap` / `nessus` | Scan réseau automatisé |
| Tests d'intrusion PASSI | Obligatoire avant homologation |

### Étape 6 — Déploiement sécurisé (IaC + Secrets)
| Pratique | Détail |
|----------|--------|
| Secrets management | HashiCorp Vault, AWS Secrets Manager, Ansible Vault |
| Jamais de secrets en clair | Ni dans le code, ni dans les variables Ansible en clair |
| GitOps | ArgoCD, Flux — déploiement déclaratif et auditable |
| Immutable infrastructure | Pas de modifications manuelles en production |
| Rollback automatique | En cas d'échec de déploiement |

### Étape 7 — Supervision continue
| Outil | Fonction |
|-------|---------|
| ELK Stack / OpenSearch | SIEM open source |
| Wazuh | HIDS + SIEM intégré |
| Falco | Détection d'anomalies runtime (K8s/conteneurs) |
| Prometheus + Grafana | Métriques et alerting |
| OpenSCAP | Contrôle de conformité continu |

---

## Sécurité du pipeline CI/CD lui-même

Le pipeline est une surface d'attaque critique. Mesures obligatoires :

| Contrôle | Description |
|----------|-------------|
| Runners isolés | Agents CI/CD isolés du réseau de prod |
| Secrets chiffrés | Variables CI/CD chiffrées (Vault, pas en clair) |
| Accès minimal | Le runner n'a accès qu'à ce dont il a besoin |
| Signature des pipelines | Vérifier que le `.gitlab-ci.yml` n'a pas été modifié |
| Audit logs CI/CD | Tout déclenchement de pipeline est loggué |
| Branch protection | Merge requests + review obligatoire avant main |
| Environnements séparés | dev → staging → prod avec gates de sécurité |

---

## SSDF — Secure Software Development Framework (NIST SP 800-218)

| Groupe | Code | Pratiques clés |
|--------|------|---------------|
| Prepare | PO | Organisation, outils, environnements sécurisés |
| Protect | PS | Protection du code source et des pipelines |
| Produce | PW | Conception sécurisée, vérification, tests |
| Respond | RV | Gestion des vulnérabilités découvertes |

---

## Connexions

- [[playbooks-securises]] — Ansible dans le pipeline DevSecOps
- [[defense-en-profondeur]] — DevSecOps sécurise la couche applicative (6)
- [[zero-trust]] — ZTA appliqué au pipeline
- [[nist]] — SP 800-218 SSDF, SP 800-53 (CM, SI, SR families)
- [[anssi]] — Guide Ansible ANSSI, recommandations supply chain
- [[hardening-linux]] — durcissement des runners et serveurs CI/CD
- [[referentiels-securite]] — STIGs Ansible, CIS Benchmarks

---
*Dernière mise à jour : 2026-06-21 | Sources : NIST SP 800-218, OWASP DevSecOps, ANSSI*
