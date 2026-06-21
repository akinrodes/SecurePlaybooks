# ANSSI — Agence Nationale de la Sécurité des Systèmes d'Information

*Autorité nationale française en matière de cybersécurité. Tutelle : SGDSN / Premier Ministre.*
*Site officiel : https://www.ssi.gouv.fr*

---

## Rôle et statut

L'ANSSI est l'autorité nationale française de cybersécurité depuis 2009 (décret n°2009-834). Elle remplit deux missions :
1. **Défense** — protéger les SI de l'État et des OIV/OSE
2. **Conseil** — publier des référentiels, guides et recommandations pour élever le niveau global

Dans un contexte défense, les recommandations ANSSI ont valeur de référentiel opposable pour les systèmes traitant des informations sensibles (DRI, DR, CD, SD, TS).

---

## Documents fondamentaux à connaître

### Guides de configuration et durcissement

| Document | Cible | Lien |
|----------|-------|------|
| Guide de configuration GNU/Linux | RHEL/Debian/Ubuntu | https://www.ssi.gouv.fr/guide/configuration-des-equipements-de-securite/ |
| Guide de configuration Windows 10/11 | Postes Windows | https://www.ssi.gouv.fr |
| Guide de configuration Windows Server 2022 | Serveurs Windows | https://www.ssi.gouv.fr |
| Guide NTP | Synchronisation temporelle | https://www.ssi.gouv.fr |
| Guide SSH | Sécurisation du protocole SSH | https://www.ssi.gouv.fr/guide/recommandations-pour-un-usage-securise-dopenssh/ |
| Guide TLS | Protocoles TLS/HTTPS | https://www.ssi.gouv.fr/guide/recommandations-de-securite-relatives-a-tls/ |
| Guide Ansible | Automatisation sécurisée | Voir [[playbooks-securises]] |

### Recommandations thématiques (format R-series)

| Recommandation | Sujet |
|----------------|-------|
| ANSSI-BP-028 | Recommandations de sécurité relatives à un système GNU/Linux |
| ANSSI-PA-046 | Sécurisation d'Active Directory |
| ANSSI-PA-065 | Recommandations pour la sécurisation des systèmes Linux embarqués |
| Rec. mot de passe | Politique de gestion des secrets et mots de passe |
| Guide Cloud | Prestataires cloud et externalisation |
| EBIOS Risk Manager | Méthode d'analyse de risque (remplace EBIOS 2010) |

### Qualification et certification

- **Qualification** — processus ANSSI pour valider un produit/service de sécurité (niveaux : standard, renforcé)
- **Certification Critères Communs (CC)** — évaluation EAL (EAL2 à EAL7) via un CESTI agréé
- **PASSI** — Prestataire d'Audit SSI qualifié par l'ANSSI
- **PAMS** — Prestataire d'Administration et de Maintenance Sécurisé

---

## Référentiel Général de Sécurité (RGS)

Le RGS définit les règles de sécurité applicables aux SI des autorités administratives. Il couvre :
- Authentification (niveaux 1, 2, 3)
- Confidentialité des échanges (chiffrement)
- Intégrité et signature
- Disponibilité des services

Applicable aux téléservices de l'État. Pour la défense, le cadre est complété par les directives DGA/DIRISI.

---

## Cadre spécifique défense

Les SI de défense (SID) relèvent d'une réglementation complémentaire :
- **IGI 1300** — Instruction interministérielle sur la protection du secret de la défense nationale
- **II 901** — Instruction sur les systèmes d'information non classifiés (diffusion restreinte)
- **II 910** — SI traitant d'informations classifiées de défense
- **Homologation** — processus d'autorisation d'exploitation d'un SI, obligatoire pour les SI DR et CD

Pour l'homologation :
1. Analyse de risque EBIOS RM
2. Définition du Dossier de Sécurité du Système (DSS)
3. Mesures de sécurité documentées (MSS)
4. Décision d'homologation par l'Autorité d'Homologation (AH)

---

## Principes ANSSI applicables aux playbooks

Voir [[playbooks-securises]] pour l'implémentation technique. Les principes clés :

1. **Moindre privilège** — aucun compte avec droits excessifs
2. **Défense en profondeur** — voir [[defense-en-profondeur]]
3. **Cloisonnement** — segmentation réseau et applicative
4. **Contrôle des flux** — tout flux non autorisé est interdit (whitelist)
5. **Traçabilité** — logs centralisés, intègres, protégés
6. **Mise à jour** — patch management régulier et contrôlé
7. **Maîtrise des dépendances** — vérification de l'intégrité des sources (supply chain)

---

## Connexions

- [[nist]] — équivalent américain, souvent complémentaire
- [[referentiels-securite]] — tableau comparatif de tous les cadres
- [[hardening-linux]] — implémentation Linux des recommandations ANSSI
- [[hardening-windows]] — implémentation Windows des recommandations ANSSI
- [[playbooks-securises]] — comment traduire les recommandations ANSSI en playbook Ansible
- [[defense-en-profondeur]] — principe architecturel central dans la doctrine ANSSI

---
*Dernière mise à jour : 2026-06-21 | Sources : ANSSI ssi.gouv.fr*
