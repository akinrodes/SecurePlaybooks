# Zero Trust Architecture (ZTA)

*Modèle de sécurité fondé sur le principe "Ne jamais faire confiance, toujours vérifier" (Never Trust, Always Verify).*
*Référence principale : NIST SP 800-207. Recommandé par l'ANSSI, la NSA, le CISA.*

---

## Concept et rupture avec le modèle périmétrique

**Modèle périmétrique (ancien) :** tout ce qui est à l'intérieur du réseau est de confiance. Un attaquant qui franchit le périmètre dispose d'un accès latéral quasi-illimité.

**Zero Trust :** il n'existe pas de réseau "de confiance". Chaque accès, depuis n'importe quel réseau, doit être authentifié, autorisé et vérifié en continu — même depuis l'intranet.

**Pertinence défense :** les menaces internes (insider threat), les mouvements latéraux post-intrusion, et les environnements multi-domaines (coalition OTAN) rendent le modèle périmétrique inadapté.

---

## Les 7 principes du Zero Trust (NIST SP 800-207)

1. **Toutes les ressources sont traitées comme des ressources** — qu'elles soient on-prem, cloud, ou hybrides.
2. **Toutes les communications sont sécurisées** — chiffrement systématique, même sur le réseau interne.
3. **L'accès aux ressources est accordé par session** — pas de confiance persistante, révocable à tout moment.
4. **L'accès est déterminé par une politique dynamique** — identité + état du poste + contexte (heure, localisation, comportement).
5. **L'intégrité de tous les équipements est surveillée** — inventaire continu, contrôle de conformité (MDM/NAC).
6. **Toutes les authentifications et autorisations sont strictement appliquées** — le principe de moindre privilège est la règle, pas l'exception.
7. **La collecte de données et la détection sont continues** — amélioration de la posture de sécurité en temps réel.

---

## Architecture ZTA — composants techniques

```
┌─────────────────────────────────────────────────────────┐
│                   Control Plane                          │
│  ┌───────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ Identity      │  │ Policy       │  │ PKI / Cert   │ │
│  │ Provider (IdP)│  │ Engine (PE)  │  │ Authority    │ │
│  │ (LDAP/AD/OIDC)│  │              │  │              │ │
│  └───────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────┬───────────────────────────────┘
                          │ décisions d'accès
┌─────────────────────────▼───────────────────────────────┐
│                   Data Plane                             │
│  ┌───────────────┐       ┌──────────────────────────┐   │
│  │ Sujet/Poste   │──────▶│ Policy Enforcement       │──▶│ Ressource│
│  │ (utilisateur) │       │ Point (PEP)              │   │          │
│  └───────────────┘       │ (proxy, gateway, SD-WAN) │   └──────────┘
└─────────────────────────────────────────────────────────┘
```

---

## Approches d'implémentation (NIST 800-207)

### 1. Enhanced Identity Governance (EIG)
- L'identité est le nouveau périmètre
- IAM robuste : MFA, PAM, gestion des comptes à privilèges
- SSO fédéré + RBAC/ABAC granulaire
- **Idéal pour :** SI avec Active Directory, accès distants (VPN → ZTNA)

### 2. Micro-segmentation
- Division du réseau en segments très fins (jusqu'à la VM ou le pod)
- Politique de flux entre chaque segment (whitelist)
- Implémentation : SDN, VXLAN, pare-feu distribué (NSX, Cilium, Calico)
- **Idéal pour :** data centers, environnements virtualisés/conteneurisés

### 3. Network-Based ZTA (ZTNA / SDP)
- Software-Defined Perimeter : aucun port exposé, tunnel chiffré à la demande
- Remplacement du VPN traditionnel par du ZTNA (SASE, BeyondCorp)
- **Idéal pour :** accès distants, workforce mobile, cloud hybride

---

## Implémentation progressive — roadmap recommandée

```
Phase 1 — Visibilité (inventaire + logs)
  ├── Inventaire complet des assets (CMDB)
  ├── Journalisation centralisée (SIEM)
  └── Cartographie des flux réseau

Phase 2 — Identité forte
  ├── MFA sur tous les accès (utilisateurs + services)
  ├── PAM (gestion des comptes à privilèges)
  └── Revue des droits d'accès (certification des habilitations)

Phase 3 — Moindre privilège
  ├── RBAC/ABAC appliqué à toutes les ressources
  ├── Just-In-Time access (accès temporaires)
  └── Suppression des comptes partagés

Phase 4 — Micro-segmentation
  ├── Segmentation réseau (VLAN → SDN)
  ├── Politique de flux inter-segments (whitelist)
  └── Isolation des workloads critiques

Phase 5 — Contrôle continu
  ├── NAC/MDM — conformité postes en temps réel
  ├── UEBA — détection comportementale
  └── Zero Trust Network Access (ZTNA)
```

---

## Zero Trust vs Défense en Profondeur

| Aspect | Défense en Profondeur | Zero Trust |
|--------|----------------------|-----------|
| Modèle | Périmètre + couches | Sans périmètre |
| Confiance réseau | Réseau interne = confiance | Aucun réseau = confiance |
| Authentification | À l'entrée du réseau | Continue, par session |
| Complémentarité | ✅ Les deux sont complémentaires | ✅ ZT s'appuie sur DiD |

ZTA est une **évolution** de la DiD, pas un remplacement. On applique les deux ensemble : les couches DiD restent mais sans leur accorder de confiance intrinsèque.

---

## Outils open source pour ZTA

| Outil | Rôle |
|-------|------|
| **Keycloak** | IdP/SSO OIDC/SAML (remplace AD FS) |
| **HashiCorp Vault** | Gestion des secrets, PKI dynamique |
| **Cilium/Calico** | Network policy K8s, micro-segmentation |
| **OpenZiti** | SDP/ZTNA open source |
| **AIDE / IMA** | Intégrité des fichiers (Linux) |
| **FreeIPA** | IAM Linux, RBAC, certificats |
| **OpenSCAP** | Contrôle conformité continu |

---

## Connexions

- [[defense-en-profondeur]] — complémentaire, pas antagoniste
- [[hardening-linux]] — couche hôte du ZTA
- [[hardening-windows]] — couche hôte Windows du ZTA
- [[devsecops]] — ZTA appliqué au pipeline CI/CD
- [[nist]] — SP 800-207 (référence de définition)
- [[anssi]] — doctrine française sur le ZTA
- [[playbooks-securises]] — automatisation des contrôles ZTA

---
*Dernière mise à jour : 2026-06-21 | Sources : NIST SP 800-207, ANSSI, NSA CSI Zero Trust*
