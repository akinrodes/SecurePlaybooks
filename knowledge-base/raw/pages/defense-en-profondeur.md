# Défense en Profondeur

*Principe architectural fondamental : multiplier les couches de sécurité indépendantes pour qu'aucune défaillance unique ne compromette l'ensemble du système.*
*Doctrine ANSSI, OTAN, DoD.*

---

## Concept

La défense en profondeur (DiD — Defense in Depth) est issue de la stratégie militaire : si une ligne est percée, la suivante arrête l'adversaire. En cybersécurité, cela se traduit par des contrôles redondants et indépendants à chaque couche du SI.

**Principe clé :** un attaquant doit contourner N contrôles indépendants pour atteindre son objectif. Le coût de l'attaque augmente exponentiellement avec N.

---

## Les couches de défense (modèle 7 couches)

```
┌─────────────────────────────────────────┐
│  7. Données          (chiffrement, DLP) │
├─────────────────────────────────────────┤
│  6. Applications     (WAF, DAST, pentest)│
├─────────────────────────────────────────┤
│  5. Hôtes            (durcissement, EDR) │
├─────────────────────────────────────────┤
│  4. Réseau interne   (VLAN, IPS, firewall)│
├─────────────────────────────────────────┤
│  3. Périmètre        (FW, DMZ, proxy)   │
├─────────────────────────────────────────┤
│  2. Physique         (badges, cages, HSM)│
├─────────────────────────────────────────┤
│  1. Humain/Process   (formation, procédures)│
└─────────────────────────────────────────┘
```

---

## Application par couche — contexte défense

### Couche 1 — Humain et Processus
- Habilitation du personnel (TS, CD, DR selon IGI 1300)
- Formation à la sécurité (sensibilisation, ingénierie sociale)
- Procédures d'exploitation sécurisée (PES)
- Gestion des incidents documentée

### Couche 2 — Physique
- Zones sécurisées (ZP, ZS) selon la classification
- Contrôle d'accès biométrique/badge
- Destruction des supports (DIN 66399, HDD degaussing)
- Protection EM (cage de Faraday pour SI très sensibles)

### Couche 3 — Périmètre réseau
- Firewall stateful (inspection L4) + NextGen FW (inspection L7)
- DMZ pour services exposés (reverse proxy, bastion)
- Passerelle d'interconnexion homologuée (diode réseau pour flux unidirectionnels)
- Filtrage DNS (RPZ), proxy HTTPS avec inspection TLS

### Couche 4 — Réseau interne
- Segmentation VLAN par zone de sensibilité (DR / NCD / administration)
- Micro-segmentation (SDN, pare-feu hôte)
- 802.1X — authentification des équipements réseau
- IPS/IDS — détection d'intrusion
- NAC (Network Access Control) — contrôle de conformité des postes

### Couche 5 — Hôtes (endpoints & serveurs)
- Durcissement OS (voir [[hardening-linux]], [[hardening-windows]])
- EDR (Endpoint Detection & Response)
- Gestion des correctifs (patch management < 30 jours CVE critiques)
- Contrôle d'intégrité (AIDE, Tripwire, IMA/EVM sous Linux)
- Journalisation locale + export vers SIEM

### Couche 6 — Applications
- Développement sécurisé (OWASP Top 10, SAST, DAST)
- WAF (Web Application Firewall)
- Tests d'intrusion (PASSI qualifié ANSSI)
- Gestion des secrets (Vault, pas de credentials en clair)
- Authentification forte (MFA, certificats)

### Couche 7 — Données
- Chiffrement au repos (LUKS, BitLocker, TDE)
- Chiffrement en transit (TLS 1.2+, recommandation ANSSI : TLS 1.3)
- Classification et étiquetage des données
- DLP (Data Loss Prevention)
- Sauvegardes chiffrées et testées (règle 3-2-1)

---

## Règles d'implémentation

| Règle | Description |
|-------|-------------|
| **Indépendance** | Deux couches consécutives ne doivent pas partager le même composant ou vecteur de défaillance |
| **Diversité** | Utiliser des technologies différentes (évite qu'une CVE unique casse toutes les couches) |
| **Proportion** | Le niveau de protection doit être proportionnel à la sensibilité des données protégées |
| **Visibilité** | Chaque couche doit générer des logs utilisables par le SOC |
| **Testabilité** | Chaque couche doit pouvoir être auditée indépendamment |

---

## Pièges classiques à éviter

- **Sécurité par l'obscurité** — ne pas compter uniquement sur la complexité cachée
- **Single point of failure** — une seule couche de contrôle = pas de DiD
- **Couches redondantes mais identiques** — deux firewalls du même vendeur ne sont pas de la DiD
- **Oublier la couche humaine** — la meilleure architecture technique échoue sans formation

---

## Références

- ANSSI — Recommandations relatives à la défense en profondeur
- NIST SP 800-53 — Programme de contrôles (approche par couches implicite)
- DoD 8500.01 — Defense in Depth as DoD cybersecurity principle
- NSA/CISA — Defense-in-depth guidance

---

## Connexions

- [[zero-trust]] — évolution du DiD : "ne jamais faire confiance, toujours vérifier"
- [[hardening-linux]] — couche 5 (hôtes) pour Linux
- [[hardening-windows]] — couche 5 (hôtes) pour Windows
- [[devsecops]] — sécurité intégrée dans la couche 6 (applications)
- [[anssi]] — doctrine française sur le sujet
- [[nist]] — SP 800-53 comme catalogue de contrôles par couche
- [[playbooks-securises]] — automatiser l'implémentation des couches 4 et 5

---
*Dernière mise à jour : 2026-06-21 | Sources : ANSSI, NIST SP 800-53, DoD 8500.01*
