# NIST — National Institute of Standards and Technology

*Organisme américain de normalisation technique. Référentiel incontournable en cyberdéfense internationale et pour les systèmes interopérables OTAN.*
*Site : https://csrc.nist.gov*

---

## Pourquoi le NIST est pertinent en contexte défense française

Le NIST est le référentiel de facto pour :
- Les systèmes interopérables avec les alliés (OTAN, US DoD, Five Eyes)
- Le cadre CMMC (Cybersecurity Maturity Model Certification) imposé aux industriels de défense travaillant avec le DoD américain
- La structuration des contrôles de sécurité (catalogs de controls très complets)
- Complémentarité avec l'ANSSI : ANSSI = prescriptif et France-centrique ; NIST = structurel et international

---

## Référentiels clés

### NIST SP 800-53 Rev. 5 — Security and Privacy Controls
*Le catalogue de référence. 20 familles de contrôles, ~1000 contrôles.*

Familles pertinentes pour l'intégration système et DevSecOps :

| Famille | Code | Pertinence |
|---------|------|-----------|
| Access Control | AC | Moindre privilège, RBAC, séparation des rôles |
| Audit and Accountability | AU | Logs, traçabilité, SIEM |
| Configuration Management | CM | Durcissement, baseline, change control |
| Identification & Authentication | IA | MFA, gestion des comptes, IAM |
| System & Communication Protection | SC | Chiffrement, TLS, segmentation |
| System & Information Integrity | SI | Patch management, anti-malware, intégrité |
| Supply Chain Risk Management | SR | Intégrité des composants logiciels/matériels |
| Incident Response | IR | Procédures de réponse, forensics |
| Risk Assessment | RA | Analyse de risque, scan de vulnérabilités |
| Program Management | PM | Gouvernance sécurité |

**Baseline recommandée selon le niveau de criticité :**
- Low → contrôles baseline Low (SI non sensibles)
- Moderate → baseline Moderate (DR, données sensibles)
- High → baseline High (SI classifiés, CD, TS)

### NIST SP 800-171 Rev. 3 — CUI Protection
*Applicable aux systèmes traitant des CUI (Controlled Unclassified Information) — équivalent défense restreinte.*
- 110 exigences de sécurité dérivées de SP 800-53
- Base du CMMC 2.0 (niveau 2)
- Très pertinent pour les industriels de défense (PME/ETI sous contrat DGA)

### NIST SP 800-190 — Container Security
*Guide sécurité pour les environnements conteneurisés (Docker, Kubernetes).*
- Risques liés aux images, registres, orchestrateurs
- Contrôles : scan d'images, politique de tags, isolation des namespaces
- Voir [[hardening-linux]] pour l'implémentation

### NIST SP 800-207 — Zero Trust Architecture
*Définition et architecture de référence du Zero Trust.*
- 7 principes fondamentaux
- 3 approches d'implémentation (Enhanced Identity Governance, Micro-segmentation, Network-based)
- Voir [[zero-trust]] pour le détail

### NIST SP 800-218 — SSDF (Secure Software Development Framework)
*Framework pour le développement logiciel sécurisé — clé pour DevSecOps.*
- 4 groupes de pratiques : Prepare (PO), Protect (PS), Produce (PW), Respond (RV)
- Intègre la sécurité dans tout le SDLC
- Voir [[devsecops]] pour l'implémentation pipeline

### NIST Cybersecurity Framework (CSF) 2.0
*Framework de gestion du risque cyber — 6 fonctions.*

| Fonction | Description |
|----------|-------------|
| **GOVERN** (nouveau v2.0) | Stratégie, politiques, rôles |
| **IDENTIFY** | Inventaire, risques, dépendances |
| **PROTECT** | Contrôles préventifs, accès, durcissement |
| **DETECT** | Surveillance, détection d'anomalies |
| **RESPOND** | Réponse aux incidents, communications |
| **RECOVER** | Reprise d'activité, résilience |

### NIST SP 800-61 — Incident Response
*Guide complet de réponse aux incidents — phases : Preparation, Detection, Containment, Eradication, Recovery, Post-Incident.*

---

## Correspondance ANSSI ↔ NIST

| Concept ANSSI | Équivalent NIST |
|---------------|----------------|
| Homologation | ATO (Authority to Operate) |
| EBIOS RM | SP 800-30 (Risk Assessment) |
| Diffusion Restreinte | CUI / SP 800-171 |
| Confidentiel Défense | SECRET // SP 800-53 High baseline |
| PASSI | Authorized Penetration Testing |
| RGS niveau 1/2/3 | NIST IAL/AAL 1/2/3 (SP 800-63) |

---

## Connexions

- [[anssi]] — référentiel français complémentaire
- [[referentiels-securite]] — vue d'ensemble comparative
- [[zero-trust]] — SP 800-207 détaillé
- [[devsecops]] — SSDF SP 800-218 et pipeline sécurisé
- [[hardening-linux]] — contrôles CM et SI appliqués à Linux
- [[hardening-windows]] — contrôles CM et SI appliqués à Windows
- [[playbooks-securises]] — traduction des contrôles NIST en Ansible

---
*Dernière mise à jour : 2026-06-21 | Source : csrc.nist.gov*
