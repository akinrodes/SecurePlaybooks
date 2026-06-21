# Playbooks Sécurisés — Guide de rédaction Ansible

*Comment écrire des playbooks Ansible qui respectent les principes de sécurité et sont conformes aux référentiels ANSSI, NIST, STIGs.*

---

## Principes fondamentaux (à vérifier dans chaque playbook)

| Principe | Contrôle concret |
|----------|-----------------|
| **Moindre privilège** | `become: yes` uniquement quand nécessaire, jamais par défaut |
| **Idempotence** | Tout playbook doit pouvoir tourner N fois avec le même résultat |
| **Traçabilité** | Logs Ansible conservés et protégés (voir section logging) |
| **Intégrité** | Vérification des checksums des fichiers téléchargés |
| **Gestion des secrets** | Ansible Vault ou HashiCorp Vault — jamais en clair |
| **Validation** | `ansible-lint` + `--check` + `--diff` avant tout déploiement prod |
| **Source de vérité** | Galaxy roles depuis des sources vérifiées, ou roles internes signés |

---

## Structure d'un playbook sécurisé

```
project/
├── ansible.cfg                  ← Configuration sécurisée
├── inventory/
│   ├── production/
│   │   ├── hosts.yml            ← Inventaire chiffré si sensible
│   │   └── group_vars/
│   │       ├── all.yml          ← Variables communes (non-sensibles)
│   │       └── all/
│   │           └── vault.yml    ← Variables sensibles (chiffrées Vault)
│   └── staging/
├── roles/
│   └── nom-du-role/
│       ├── tasks/main.yml
│       ├── handlers/main.yml
│       ├── defaults/main.yml    ← Valeurs par défaut sécurisées
│       ├── vars/main.yml
│       ├── templates/           ← Templates Jinja2
│       ├── files/
│       └── meta/main.yml       ← Dépendances, galaxy_info
├── playbooks/
│   └── hardening.yml
├── requirements.yml             ← Rôles Galaxy avec versions figées
└── .ansible-lint                ← Configuration ansible-lint
```

---

## ansible.cfg — Configuration sécurisée

```ini
[defaults]
# Inventaire
inventory = ./inventory/production

# Journalisation
log_path = /var/log/ansible/ansible.log

# Sécurité
host_key_checking = True          # Ne jamais mettre False en prod
become_ask_pass = False           # Utiliser SSH keys, pas les mots de passe
private_key_file = ~/.ssh/ansible_ed25519

# Performances et timeouts
timeout = 30
forks = 10

# Pas de facts si inutiles (performance + surface d'attaque réduite)
gather_facts = smart
gather_subset = min

# Affichage
display_skipped_hosts = False
stdout_callback = yaml

[privilege_escalation]
become = False                    # Pas de become par défaut
become_method = sudo
become_user = root

[ssh_connection]
# Sécurité SSH
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=yes -o UserKnownHostsFile=~/.ssh/known_hosts
pipelining = True                 # Performance + sécurité (réduit les fichiers temporaires)
```

---

## Gestion des secrets — Ansible Vault

### Chiffrement d'un fichier de variables
```bash
# Chiffrer un fichier
ansible-vault encrypt inventory/production/group_vars/all/vault.yml

# Éditer en place
ansible-vault edit inventory/production/group_vars/all/vault.yml

# Déchiffrer (uniquement en dev, jamais en prod)
ansible-vault decrypt --output /dev/stdout vault.yml
```

### Format du fichier vault.yml
```yaml
# inventory/production/group_vars/all/vault.yml
# Ce fichier est chiffré avec Ansible Vault
vault_db_password: "{{ lookup('hashi_vault', 'secret=prod/db:password') }}"
vault_api_key: "AjKd...chiffré..."
vault_ldap_bind_password: "..."
```

### Intégration HashiCorp Vault (recommandé pour la prod)
```yaml
# Utilisation du lookup plugin vault
- name: Récupérer le secret depuis Vault
  set_fact:
    db_password: "{{ lookup('hashi_vault', 'secret=secret/data/prod/db token={{ vault_token }} url=https://vault.example.com') }}"
  no_log: true   # ← OBLIGATOIRE pour les tâches manipulant des secrets
```

**Règle :** toute tâche qui affiche, utilise ou manipule un secret DOIT avoir `no_log: true`.

---

## Modèle de tâche sécurisée

```yaml
---
# roles/hardening-ssh/tasks/main.yml
# Description : Durcissement du service SSH selon ANSSI BP-028 et CIS RHEL 9

- name: "[SSH-01] Vérifier la version OpenSSH installée"
  command: ssh -V
  register: ssh_version
  changed_when: false
  check_mode: false

- name: "[SSH-02] Déployer la configuration SSH durcie"
  template:
    src: sshd_config.j2
    dest: /etc/ssh/sshd_config
    owner: root
    group: root
    mode: '0600'              # ← Permissions strictes
    validate: '/usr/sbin/sshd -t -f %s'  # ← Validation AVANT déploiement
    backup: true              # ← Sauvegarde de l'ancienne config
  notify: Restart sshd
  become: true               # ← become UNIQUEMENT sur cette tâche
  tags:
    - hardening
    - ssh
    - anssi-bp028

- name: "[SSH-03] Vérifier l'intégrité du fichier déployé"
  stat:
    path: /etc/ssh/sshd_config
    checksum_algorithm: sha256
  register: sshd_config_stat
  changed_when: false

- name: "[SSH-04] Asserter que les permissions sont correctes"
  assert:
    that:
      - sshd_config_stat.stat.mode == '0600'
      - sshd_config_stat.stat.pw_name == 'root'
    fail_msg: "SECURITY: /etc/ssh/sshd_config a des permissions incorrectes"
    success_msg: "OK: permissions /etc/ssh/sshd_config conformes"
```

---

## Template sshd_config.j2 (extrait ANSSI)

```jinja2
# /etc/ssh/sshd_config — Configuration durcie ANSSI BP-028
# Généré par Ansible — NE PAS MODIFIER MANUELLEMENT

Protocol 2
Port {{ ssh_port | default(22) }}

# Authentification
PermitRootLogin no                    # ANSSI R67
PasswordAuthentication no             # ANSSI R67 — clés uniquement
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
MaxAuthTries 3                        # CIS 5.2.7
MaxSessions 4

# Chiffrement — algorithmes recommandés ANSSI / RFC 9325
KexAlgorithms curve25519-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# Restrictions
AllowAgentForwarding no               # Évite le rebond
AllowTcpForwarding no
X11Forwarding no
PrintMotd no
TCPKeepAlive no
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 60

# Journalisation
SyslogFacility AUTH
LogLevel VERBOSE                      # Log les fingerprints de clés

# Bannière légale (obligatoire en défense)
Banner /etc/issue.net
```

---

## Vérification et audit du playbook

### Avant tout déploiement en production
```bash
# 1. Lint complet
ansible-lint playbooks/hardening.yml

# 2. Syntaxe check
ansible-playbook --syntax-check playbooks/hardening.yml

# 3. Dry-run avec diff
ansible-playbook --check --diff -i inventory/staging playbooks/hardening.yml

# 4. Test sur environnement de staging
ansible-playbook -i inventory/staging playbooks/hardening.yml

# 5. Déploiement prod avec journalisation
ansible-playbook -i inventory/production playbooks/hardening.yml \
  --vault-password-file ~/.vault_pass \
  2>&1 | tee /var/log/ansible/deploy-$(date +%Y%m%d-%H%M%S).log
```

### Intégration CI/CD (GitLab CI exemple)
```yaml
# .gitlab-ci.yml
stages:
  - lint
  - test
  - deploy

ansible-lint:
  stage: lint
  image: python:3.11
  script:
    - pip install ansible ansible-lint
    - ansible-lint playbooks/
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

molecule-test:
  stage: test
  script:
    - molecule test
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

deploy-staging:
  stage: deploy
  script:
    - ansible-playbook -i inventory/staging playbooks/hardening.yml
      --vault-password-file $VAULT_PASSWORD_FILE
  environment: staging
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"
```

---

## Checklist de sécurité — avant tout commit

- [ ] Aucun secret en clair (grep `password\|secret\|key\|token` dans le diff)
- [ ] `no_log: true` sur toutes les tâches manipulant des secrets
- [ ] `become: true` uniquement sur les tâches qui le nécessitent vraiment
- [ ] Permissions de fichiers explicites (`mode: '0600'` ou `'0644'` selon le cas)
- [ ] Validation (`validate:`) sur les fichiers de configuration critiques
- [ ] Backup (`backup: true`) sur les fichiers de config avant modification
- [ ] `ansible-lint` passe sans erreur
- [ ] `--check --diff` testé sur staging
- [ ] Tags (`hardening`, référentiel, numéro de règle) présents
- [ ] Handlers définis pour les restart de services
- [ ] Pas de `ignore_errors: true` non justifié

---

## Références

- ANSSI — Guide de configuration SSH
- ANSSI BP-028 — Configuration GNU/Linux
- CIS Benchmark (section SSH)
- DISA STIG Ansible (V1R1)
- NIST SP 800-53 — CM-6 (Configuration Settings), CM-7 (Least Functionality)

---

## Connexions

- [[devsecops]] — playbooks dans le pipeline CI/CD
- [[hardening-linux]] — contenu des playbooks de durcissement Linux
- [[hardening-windows]] — contenu des playbooks de durcissement Windows
- [[anssi]] — référentiels à respecter
- [[nist]] — contrôles CM et SI à implémenter
- [[referentiels-securite]] — STIGs Ansible, CIS Ansible Benchmark
- [[defense-en-profondeur]] — les playbooks implémentent les couches 4 et 5

---
*Dernière mise à jour : 2026-06-21 | Sources : ANSSI, CIS, DISA STIG Ansible, NIST SP 800-53*
