# Playbook : Copie sécurisée A → C via bastion B (Multiplateforme)

*Ce playbook permet de copier de manière sécurisée un fichier depuis le contrôleur Ansible (A) vers un serveur cible (C) en passant par un bastion (B), de manière chiffrée de bout en bout et sans utiliser de relais intermédiaire sur B.*
*Support complet pour les cibles Linux et Windows.*

---

## Fichier source
Le code complet est disponible dans : `outputs/copy_via_jump_multiplatform.yml`

## Cas d'usage en Défense
- Transfert de fichiers sur des réseaux segmentés (ex: DMZ, réseau restreint) où l'accès direct est interdit par pare-feu.
- Respect strict de la trace et intégrité : vérification par empreinte SHA256 du fichier avant et après copie.
- Conformité ANSSI (BP-028) : utilisation de ProxyJump (tunnel chiffré direct) sans rebond d'agent SSH (ForwardAgent no).

## Prérequis
- **Contrôleur (A)** : Linux (ou WSL2 sous Windows).
- **Bastion (B)** : Serveur OpenSSH installé (Linux ou Windows).
- **Cible (C)** : Linux ou Windows avec OpenSSH installé et démarré.

## Commande d'exécution

### Si la cible (C) est sous Linux :
```bash
ansible-playbook knowledge-base/outputs/copy_via_jump_multiplatform.yml \
  -e "src_file=/chemin/local/fichier.txt" \
  -e "dest_file=/opt/data/fichier.txt" \
  -e "dest_os=linux" \
  -e "jump_host_ip=10.0.1.10" \
  -e "jump_host_user=bastionuser" \
  -e "dest_host_ip=10.0.2.20" \
  -e "dest_host_user=serveruser" \
  --private-key ~/.ssh/ansible_ed25519
```

### Si la cible (C) est sous Windows :
```powershell
ansible-playbook knowledge-base/outputs/copy_via_jump_multiplatform.yml \
  -e "src_file=/chemin/local/fichier.txt" \
  -e 'dest_file=C:\Data\fichier.txt' \
  -e "dest_os=windows" \
  -e "jump_host_ip=10.0.1.10" \
  -e "jump_host_user=bastionuser" \
  -e "dest_host_ip=10.0.2.20" \
  -e "dest_host_user=DOMAINE\serveruser" \
  --private-key ~/.ssh/ansible_ed25519
```

## Étapes de sécurité implémentées
1. **Preflight :** Vérification de l'existence du fichier source et calcul de son empreinte cryptographique (SHA256).
2. **ProxyJump SSH :** Création d'un tunnel sécurisé `A -> B -> C` sans `ProxyCommand` ni relais en clair.
3. **Ciphers ANSSI :** Forçage des algorithmes `chacha20-poly1305` ou `aes256-gcm`.
4. **Agent-Forwarding désactivé :** (`ForwardAgent=no`) empêche un administrateur du bastion (B) d'usurper l'identité de A.
5. **Post-copie :** Recalcul du SHA256 sur la cible (C) et validation croisée avec la source.

---
*Dernière mise à jour : 2026-06-21 | Type : Playbook Ansible multiplateforme*
