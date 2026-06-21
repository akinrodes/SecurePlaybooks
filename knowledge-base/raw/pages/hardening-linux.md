# Durcissement Linux — Hardening GNU/Linux

*Guide de durcissement des systèmes Linux pour environnement défense. Référentiels : ANSSI BP-028, CIS Benchmark RHEL/Ubuntu, DISA STIG RHEL 9.*

---

## Référentiels applicables

| Référentiel | Cible | Lien |
|-------------|-------|------|
| ANSSI BP-028 | GNU/Linux générique | https://www.ssi.gouv.fr |
| CIS RHEL 9 Benchmark | Red Hat Enterprise Linux 9 | cisecurity.org |
| CIS Ubuntu 22.04 LTS | Ubuntu LTS | cisecurity.org |
| DISA STIG RHEL 9 | RHEL 9 (contexte DoD/OTAN) | public.cyber.mil |
| ANSSI-PA-065 | Linux embarqué | https://www.ssi.gouv.fr |

---

## 1. Accès et authentification

### Comptes et mots de passe
```yaml
# Playbook Ansible — Politique de mots de passe (ANSSI R30)
- name: "[AUTH-01] Configurer la politique de mots de passe PAM"
  template:
    src: pwquality.conf.j2
    dest: /etc/security/pwquality.conf
    mode: '0644'
  become: true
  tags: [hardening, auth, anssi-r30]
```

```ini
# /etc/security/pwquality.conf — ANSSI R30 / CIS 5.4.1
minlen = 12           # Longueur minimale (ANSSI recommande 12+)
minclass = 4          # Au moins 4 types de caractères
maxrepeat = 3         # Maximum 3 caractères répétés
dcredit = -1          # Au moins 1 chiffre
ucredit = -1          # Au moins 1 majuscule
lcredit = -1          # Au moins 1 minuscule
ocredit = -1          # Au moins 1 caractère spécial
```

```ini
# /etc/login.defs — Politique de durée de validité
PASS_MAX_DAYS   90    # Expiration tous les 90 jours (CIS 5.4.1.1)
PASS_MIN_DAYS   1     # Minimum 1 jour entre changements
PASS_WARN_AGE   7     # Avertissement 7 jours avant expiration
```

### Comptes privilegiés
```bash
# Lister les comptes avec UID 0 (ne doit retourner que root)
awk -F: '($3 == 0) {print}' /etc/passwd

# Verrouiller les comptes systèmes inutilisés
passwd -l daemon
passwd -l bin
passwd -l lp

# Vérifier les comptes sans mot de passe
awk -F: '($2 == "") {print}' /etc/shadow
```

### SSH (voir [[playbooks-securises]] pour le template complet)
- `PermitRootLogin no` — ANSSI R67
- `PasswordAuthentication no` — clés uniquement
- Algorithmes : `curve25519-sha256`, `aes256-gcm@openssh.com`
- Port non-standard si applicable
- Bannière légale obligatoire

---

## 2. Système de fichiers et permissions

### Partitionnement recommandé (ANSSI / CIS)
```
/              → partition séparée
/boot          → partition séparée, read-only si possible
/home          → partition séparée, noexec, nosuid, nodev
/tmp           → partition séparée, noexec, nosuid, nodev (CIS 1.1.2)
/var           → partition séparée
/var/log       → partition séparée (évite remplissage de /)
/var/log/audit → partition séparée (intégrité des logs)
swap           → chiffré (ANSSI)
```

### Options de montage sécurisées
```ini
# /etc/fstab (extraits)
/dev/sda3  /tmp      ext4  defaults,noexec,nosuid,nodev  0 2
/dev/sda4  /home     ext4  defaults,noexec,nosuid,nodev  0 2
/dev/sda5  /var/tmp  ext4  defaults,noexec,nosuid,nodev  0 2
tmpfs      /dev/shm  tmpfs defaults,noexec,nosuid,nodev  0 0
```

### Permissions critiques
```bash
# Fichiers world-writable (ne doit rien retourner)
find / -xdev -type f -perm -002 -ls 2>/dev/null

# Fichiers SUID/SGID (auditer et restreindre)
find / -xdev \( -perm -4000 -o -perm -2000 \) -type f -ls 2>/dev/null

# Permissions sur fichiers sensibles
chmod 600 /etc/shadow
chmod 644 /etc/passwd
chmod 600 /etc/ssh/sshd_config
chmod 700 /root
```

---

## 3. Noyau Linux — Paramètres sysctl sécurisés

```ini
# /etc/sysctl.d/99-hardening.conf — ANSSI BP-028 / CIS

# Protection réseau — IPv4
net.ipv4.ip_forward = 0                    # Pas de routage (sauf routeur dédié)
net.ipv4.conf.all.send_redirects = 0       # CIS 3.2.3
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0     # CIS 3.3.2
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.accept_source_route = 0  # CIS 3.3.1
net.ipv4.conf.all.log_martians = 1         # CIS 3.3.11
net.ipv4.conf.all.rp_filter = 1            # Reverse path filtering
net.ipv4.icmp_echo_ignore_broadcasts = 1   # CIS 3.3.6
net.ipv4.tcp_syncookies = 1                # Protection SYN flood
net.ipv4.tcp_timestamps = 0               # ANSSI — évite fingerprinting

# Protection réseau — IPv6
net.ipv6.conf.all.disable_ipv6 = 1        # Si IPv6 non utilisé
net.ipv6.conf.all.accept_redirects = 0

# Mémoire et noyau
kernel.dmesg_restrict = 1                  # ANSSI — restreindre accès dmesg
kernel.kptr_restrict = 2                   # Masquer pointeurs noyau
kernel.perf_event_paranoid = 3             # Restreindre perf events
kernel.randomize_va_space = 2              # ASLR actif (CIS)
kernel.yama.ptrace_scope = 1               # Restreindre ptrace
fs.suid_dumpable = 0                       # Pas de core dump SUID
fs.protected_hardlinks = 1                 # Protection hardlinks
fs.protected_symlinks = 1                  # Protection symlinks
```

---

## 4. Journalisation et audit

### auditd — Configuration ANSSI / CIS
```bash
# Installation
dnf install audit auditd -y

# Règles auditd critiques (/etc/audit/rules.d/hardening.rules)

# Modifications des comptes utilisateurs
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/sudoers -p wa -k privilege_escalation
-w /etc/sudoers.d/ -p wa -k privilege_escalation

# Appels système privilégiés
-a always,exit -F arch=b64 -S execve -F euid=0 -k root_commands
-a always,exit -F arch=b64 -S open,openat -F exit=-EACCES -k access_denied
-a always,exit -F arch=b64 -S chmod,fchmod,fchmodat -k perm_mod
-a always,exit -F arch=b64 -S chown,fchown,lchown,fchownat -k perm_mod

# Connexions réseau
-a always,exit -F arch=b64 -S connect -k network_connect
-a always,exit -F arch=b64 -S bind -k network_bind

# Modules noyau
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-a always,exit -F arch=b64 -S init_module,finit_module -k module_load

# Immutabilité des règles (à mettre en dernier)
-e 2
```

### rsyslog — Envoi vers SIEM centralisé
```conf
# /etc/rsyslog.d/99-siem.conf
# Envoi sécurisé vers SIEM via TLS
*.* action(type="omfwd"
    target="siem.example.mil"
    port="6514"
    protocol="tcp"
    StreamDriver="gtls"
    StreamDriverMode="1"
    StreamDriverAuthMode="x509/name"
    StreamDriverPermittedPeers="siem.example.mil")
```

---

## 5. Pare-feu hôte (firewalld / nftables)

```yaml
# Ansible — Configuration firewalld — principe whitelist
- name: "[FW-01] Supprimer tous les services par défaut"
  firewalld:
    service: "{{ item }}"
    zone: public
    state: disabled
    permanent: true
  loop:
    - dhcpv6-client
    - cockpit
    - mdns
  become: true

- name: "[FW-02] Autoriser uniquement SSH et les services nécessaires"
  firewalld:
    service: ssh
    zone: public
    state: enabled
    permanent: true
  become: true

- name: "[FW-03] Politique par défaut = DROP"
  firewalld:
    zone: public
    target: DROP
    permanent: true
    state: present
  become: true
```

---

## 6. Services et applications

### Désactivation des services inutiles
```bash
# Services à désactiver systématiquement (ANSSI / CIS)
systemctl disable --now avahi-daemon
systemctl disable --now cups
systemctl disable --now rpcbind
systemctl disable --now nfs-server
systemctl disable --now xinetd
systemctl disable --now telnet.socket
systemctl disable --now rsh.socket
systemctl disable --now rlogin.socket

# Vérification des services actifs
systemctl list-units --type=service --state=running
```

### Sudo — Configuration sécurisée
```ini
# /etc/sudoers.d/hardening (via visudo)
# ANSSI R61 — Pas de NOPASSWD en production
Defaults    requiretty            # Empêche sudo sans TTY
Defaults    logfile=/var/log/sudo.log
Defaults    log_input, log_output  # Log des commandes sudo complètes
Defaults    !visiblepw
Defaults    always_set_home
Defaults    env_reset
Defaults    secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Accès sudo nominatif (jamais de groupe générique)
%wheel ALL=(ALL) ALL
```

---

## 7. Contrôle d'intégrité

```bash
# AIDE — Advanced Intrusion Detection Environment
dnf install aide -y

# Initialisation de la base de référence
aide --init
mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

# Vérification quotidienne (cron)
# /etc/cron.daily/aide-check
aide --check | mail -s "AIDE Report $(hostname)" soc@example.mil
```

---

## Audit de conformité rapide

```bash
# OpenSCAP — Audit contre le profil ANSSI/CIS
oscap xccdf eval \
  --profile xccdf_org.ssgproject.content_profile_cis_server_l2 \
  --results /tmp/scan-$(date +%Y%m%d).xml \
  --report /tmp/scan-$(date +%Y%m%d).html \
  /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml

# Score de conformité
grep "score" /tmp/scan-*.xml
```

---

## Connexions

- [[playbooks-securises]] — automatisation de ce durcissement en Ansible
- [[anssi]] — BP-028, référentiel source
- [[nist]] — SP 800-53 (CM-6, CM-7, SI-2, AU-2)
- [[referentiels-securite]] — DISA STIG RHEL 9, CIS RHEL 9
- [[defense-en-profondeur]] — couche 5 (hôtes)
- [[devsecops]] — intégration du durcissement dans le pipeline
- [[hardening-windows]] — équivalent Windows

---
*Dernière mise à jour : 2026-06-21 | Sources : ANSSI BP-028, CIS RHEL 9 v2.0, DISA STIG RHEL 9 V1R3*
