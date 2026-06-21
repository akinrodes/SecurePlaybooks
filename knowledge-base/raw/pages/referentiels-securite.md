# Référentiels de Sécurité — Vue d'ensemble comparative

*Cartographie de tous les cadres normatifs pertinents pour un ingénieur système/DevSecOps en environnement défense.*

---

## Tableau comparatif global

| Référentiel | Organisme | Portée | Usage principal | Obligatoire ? |
|-------------|-----------|--------|-----------------|---------------|
| **ANSSI BP-028** | ANSSI (FR) | Linux GNU | Durcissement serveurs/postes Linux | Recommandé DGA/DIRISI |
| **ANSSI PA-046** | ANSSI (FR) | Active Directory | Sécurisation AD/Windows | Recommandé |
| **RGS** | ANSSI (FR) | SI État | Téléservices, authentification | Obligatoire SI État |
| **IGI 1300** | SGDSN (FR) | Secret défense | Protection informations classifiées | Obligatoire défense |
| **II 901** | SGDSN (FR) | DR/NCD | SI Diffusion Restreinte | Obligatoire défense |
| **NIST SP 800-53** | NIST (USA) | SI fédéraux | Catalogue de contrôles universel | FedRAMP, FISMA |
| **NIST SP 800-171** | NIST (USA) | CUI | Industriels défense US | CMMC/DFARs |
| **NIST CSF 2.0** | NIST (USA) | Tous SI | Gouvernance risque cyber | Volontaire |
| **STIGs** | DISA (DoD) | Composants spécifiques | Durcissement prescriptif DoD | DoD/OTAN interop |
| **CIS Benchmarks** | CIS | OS, apps, cloud | Durcissement détaillé | Volontaire, très utilisé |
| **ISO 27001** | ISO/IEC | SMSI | Certification gestion sécurité | Certification optionnelle |
| **ISO 27002** | ISO/IEC | Contrôles | Guide implémentation 27001 | Référence pratique |
| **EBIOS RM** | ANSSI (FR) | Analyse risque | Homologation, SSI | Obligatoire homologation FR |
| **OTAN STANAG** | NATO | Interopérabilité | Communications, chiffrement | Obligatoire systèmes OTAN |

---

## STIGs — Security Technical Implementation Guides

*Guides de durcissement prescriptifs publiés par la DISA (Defense Information Systems Agency, DoD).*
*Disponibles sur : https://public.cyber.mil/stigs/*

### Caractéristiques
- **Format XCCDF/SCAP** — machine-readable, exploitable par des outils d'audit (OpenSCAP, SCC)
- **Catégories de sévérité :**
  - CAT I (HIGH) — vulnérabilité critique, à corriger immédiatement
  - CAT II (MEDIUM) — risque significatif, à corriger en priorité
  - CAT III (LOW) — risque faible mais à traiter
- **Cadence de mise à jour :** tous les 6 à 12 mois

### STIGs les plus pertinents

| STIG | Cible | Version actuelle |
|------|-------|-----------------|
| RHEL 9 STIG | Red Hat Enterprise Linux 9 | V1R3+ |
| Ubuntu 22.04 STIG | Ubuntu LTS | V2R1+ |
| Windows Server 2022 STIG | Windows Server | V2R2+ |
| Windows 11 STIG | Poste de travail Windows | V2R1+ |
| Ansible STIG | Ansible Tower/AWX | V1R1 |
| Docker Enterprise STIG | Conteneurs Docker | V2R1+ |
| Kubernetes STIG | Orchestrateur K8s | V2R1+ |
| Apache Server STIG | Serveur web Apache | V3R1+ |
| PostgreSQL STIG | Base de données | V2R1+ |

### Utilisation avec OpenSCAP
```bash
# Audit RHEL 9 contre le STIG
oscap xccdf eval \
  --profile xccdf_mil.disa.stig_profile_MAC-2_Sensitive \
  --results results.xml \
  --report report.html \
  /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml
```

---

## CIS Benchmarks

*Publications du Center for Internet Security — consensus d'experts, gratuits en niveau 1.*
*Disponibles sur : https://www.cisecurity.org/cis-benchmarks*

### Niveaux
- **Level 1** — recommandations minimes, faible impact sur la disponibilité. Point de départ.
- **Level 2** — défense en profondeur, peut impacter les services. Haute sensibilité.

### Benchmarks prioritaires

| Benchmark | Pertinence |
|-----------|-----------|
| CIS RHEL 9 | Serveurs Linux Red Hat |
| CIS Ubuntu 22.04 | Serveurs/postes Ubuntu |
| CIS Windows Server 2022 | Serveurs Windows |
| CIS Windows 11 | Postes Windows |
| CIS Docker | Conteneurs |
| CIS Kubernetes | Orchestration |
| CIS Ansible | Automatisation |
| CIS AWS/Azure/GCP | Cloud (si applicable) |

---

## Hiérarchie d'application en contexte défense française

```
IGI 1300 / II 901 / II 910   ← OBLIGATOIRE (classification défense)
        │
        ▼
ANSSI (guides, RGS, EBIOS)   ← RÉFÉRENTIEL NATIONAL (opposable)
        │
        ▼
NIST SP 800-53 / STIGs       ← INTEROPÉRABILITÉ OTAN/DoD
        │
        ▼
CIS Benchmarks               ← IMPLÉMENTATION PRATIQUE (complément)
        │
        ▼
ISO 27001/27002              ← CERTIFICATIONS (si exigées contractuellement)
```

---

## Connexions

- [[anssi]] — détail ANSSI
- [[nist]] — détail NIST
- [[hardening-linux]] — application pratique
- [[hardening-windows]] — application pratique
- [[playbooks-securises]] — traduction en Ansible
- [[devsecops]] — intégration dans le pipeline

---
*Dernière mise à jour : 2026-06-21 | Sources : ssi.gouv.fr, csrc.nist.gov, public.cyber.mil, cisecurity.org*
