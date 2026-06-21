# Durcissement Windows — Hardening Windows Server & Poste

*Guide de durcissement des systèmes Windows pour environnement défense. Référentiels : ANSSI PA-046, CIS Windows Server 2022, DISA STIG Windows Server 2022, Microsoft Security Baseline.*

---

## Référentiels applicables

| Référentiel | Cible | Lien |
|-------------|-------|------|
| ANSSI PA-046 | Active Directory | https://www.ssi.gouv.fr |
| ANSSI — Config Windows | Windows 10/11, Server | https://www.ssi.gouv.fr |
| CIS Windows Server 2022 | Windows Server 2022 | cisecurity.org |
| CIS Windows 11 | Postes Windows 11 | cisecurity.org |
| DISA STIG WS2022 | Windows Server 2022 (DoD) | public.cyber.mil |
| DISA STIG Win11 | Windows 11 (DoD) | public.cyber.mil |
| Microsoft Security Baseline | Windows (via LGPO/GPO) | microsoft.com/en-us/download |

---

## 1. Active Directory — Sécurisation (ANSSI PA-046)

### Niveaux de privilèges (Tier Model / Red Forest)

```
Tier 0 — Administration de domaine (DC, AD)
  └── Comptes : Domain Admins, Enterprise Admins
  └── Workstations dédiées (PAW — Privileged Access Workstations)
  └── JAMAIS de connexion internet, JAMAIS utilisé pour des tâches courantes

Tier 1 — Administration des serveurs
  └── Comptes : Server Admins (par zone)
  └── Jump servers dédiés par zone de sensibilité
  └── Séparation des rôles (un admin = un scope)

Tier 2 — Administration des postes utilisateurs
  └── Comptes : Helpdesk, desktop admins
  └── Droits locaux uniquement, pas d'accès aux Tier 0/1
```

**Règle ANSSI :** les comptes Tier 0 ne doivent **jamais** se connecter sur des machines Tier 1 ou Tier 2. Un keylogger sur un poste Tier 2 ne doit pas compromettre le Tier 0.

### Comptes à supprimer ou désactiver
```powershell
# Désactiver le compte Administrateur local intégré (nom renommé + désactivé)
Disable-LocalUser -Name "Administrateur"
Rename-LocalUser -Name "Administrateur" -NewName "ADM_DESACTIVE"

# Désactiver le compte Invité
Disable-LocalUser -Name "Invité"

# Utiliser LAPS (Local Administrator Password Solution) pour les admins locaux
# LAPS v2 intégré dans Windows Server 2022 / Windows 11
```

### Politique de mots de passe (via GPO)
```
Computer Configuration → Windows Settings → Security Settings → Account Policies

Mot de passe :
  Longueur minimale : 14 caractères (ANSSI recommande 15+ pour comptes admin)
  Complexité : Activée
  Âge maximum : 90 jours (Tier 2), 60 jours (Tier 1), 0 (Tier 0 = certificats)
  Historique : 24 derniers mots de passe

Verrouillage :
  Seuil : 5 tentatives
  Durée : 30 minutes
  Réinitialisation du compteur : 30 minutes
```

---

## 2. GPO — Group Policy Objects de durcissement

### Structure recommandée des GPO

```
GPO de durcissement (liées par OU, pas à la racine du domaine) :
├── GPO_SEC_Baseline_Servers      ← Tous les serveurs
├── GPO_SEC_Baseline_Workstations ← Tous les postes
├── GPO_SEC_DomainControllers     ← DC uniquement
├── GPO_SEC_Tier0_PAW             ← PAW Tier 0
└── GPO_SEC_Internet_Facing       ← Serveurs exposés (IIS, Exchange...)
```

### Paramètres de sécurité clés (Computer Configuration)

```
Security Settings → Local Policies → Security Options :

Comptes :
  Accès réseau : ne pas autoriser l'énumération anonyme des comptes SAM → Activé
  Accès réseau : ne pas autoriser l'énumération anonyme des comptes et partages SAM → Activé
  Accès réseau : autoriser les autorisations anonymes pour Everyone → Désactivé
  Compte Administrateur : statut → Désactivé

Authentification :
  Niveau d'authentification LAN Manager → NTLMv2 uniquement, refuser LM et NTLM
  Sécurité réseau : ne pas stocker hash LAN Manager → Activé
  Authentification interactive : ne pas afficher le dernier nom d'utilisateur → Activé
  Authentification interactive : message pour les utilisateurs → [Bannière légale]
  Authentification interactive : nécessite Windows Hello for Business / MFA → Activé

Audit :
  (Voir section Journalisation)
```

### Désactivation des protocoles obsolètes
```powershell
# Désactiver SMBv1 (vecteur WannaCry, NotPetya) — CRITIQUE
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart

# Désactiver LLMNR (vecteur Responder)
# Via GPO : Computer Config → Admin Templates → Network → DNS Client → Turn off multicast name resolution → Enabled

# Désactiver NetBIOS over TCP/IP
# Via DHCP option 43, ou script WMI sur chaque interface

# Désactiver NTLMv1 (Registry)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" `
  -Name "LmCompatibilityLevel" -Value 5 -Type DWord
```

---

## 3. Windows Defender & Protection avancée

```powershell
# Activer Windows Defender ATP / Microsoft Defender for Endpoint
# Vérifier l'état
Get-MpComputerStatus | Select-Object AMRunningMode, RealTimeProtectionEnabled, IoavProtectionEnabled

# Activer la protection contre les exploits (Exploit Guard)
Set-ProcessMitigation -System -Enable DEP, SEHOP, ASLR, HighEntropy

# Activer Credential Guard (protège les hashs LSASS — anti-mimikatz)
# Via GPO : Computer Config → Admin Templates → System → Device Guard
# → Turn on Virtualization Based Security → Enabled + Secure Boot + DMA Protection

# Activer LSA Protection (RunAsPPL)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" `
  -Name "RunAsPPL" -Value 1 -Type DWord
# Vérifie : LSASS ne peut plus être ouvert en lecture par des processus non-protégés
```

---

## 4. Journalisation et audit Windows

### Politique d'audit avancée (Advanced Audit Policy)

| Catégorie | Succès | Échec | Justification |
|-----------|--------|-------|---------------|
| Account Logon — Credential Validation | ✅ | ✅ | Détection bruteforce |
| Account Management — User Account | ✅ | ✅ | Création/suppression comptes |
| Account Management — Security Group | ✅ | ✅ | Modifications groupes AD |
| Logon/Logoff — Logon | ✅ | ✅ | Connexions |
| Logon/Logoff — Special Logon | ✅ | — | Admin logon |
| Object Access — File System | — | ✅ | Accès refusés |
| Privilege Use — Sensitive Privilege Use | ✅ | ✅ | SeDebugPrivilege etc. |
| System — Security System Extension | ✅ | ✅ | Chargement de drivers |
| DS Access — Directory Service Changes | ✅ | — | Modifications AD |
| Policy Change — Audit Policy Change | ✅ | ✅ | Modification de la politique d'audit |

```powershell
# Taille des journaux d'événements (à augmenter impérativement)
Limit-EventLog -LogName Security -MaximumSize 1GB
Limit-EventLog -LogName System -MaximumSize 512MB
Limit-EventLog -LogName Application -MaximumSize 512MB

# Rétention = overwrite when full (les logs sont collectés par le SIEM)
```

### Collecte centralisée (WEF/WEC)
```powershell
# Windows Event Forwarding — configuration du collecteur WEC
winrm quickconfig -q
wecutil qc /q

# Sur les machines sources (via GPO) :
# Computer Config → Admin Templates → Windows Components → Event Forwarding
# → Configure target Subscription Manager → Server=http://wec.example.mil:5985/wsman/SubscriptionManager/WEC
```

### Events critiques à monitorer (SIEM rules)

| Event ID | Description | Criticité |
|----------|-------------|-----------|
| 4624 | Successful logon | Medium |
| 4625 | Failed logon | High (>5) |
| 4648 | Explicit credentials used | High |
| 4672 | Admin privileges assigned | High |
| 4698 | Scheduled task created | High |
| 4719 | Audit policy changed | Critical |
| 4728/4732/4756 | Member added to security group | High |
| 4740 | Account locked out | Medium |
| 4771 | Kerberos pre-auth failed | High |
| 7045 | New service installed | Critical |
| 1102 | Audit log cleared | Critical |

---

## 5. Chiffrement des disques (BitLocker)

```powershell
# Activer BitLocker sur le volume système avec TPM + PIN
Enable-BitLocker -MountPoint "C:" `
  -EncryptionMethod XtsAes256 `
  -TpmAndPinProtector `
  -Pin (ConvertTo-SecureString "PIN_FORT" -AsPlainText -Force)

# Sauvegarder la clé de récupération dans AD DS (obligatoire en entreprise)
Backup-BitLockerKeyProtector -MountPoint "C:" `
  -KeyProtectorId (Get-BitLockerVolume -MountPoint "C:").KeyProtector[0].KeyProtectorId

# Vérification
Get-BitLockerVolume -MountPoint "C:" | Select-Object MountPoint, EncryptionMethod, VolumeStatus, ProtectionStatus
```

---

## 6. Playbook Ansible pour Windows

```yaml
# playbooks/hardening-windows.yml
---
- name: Durcissement Windows Server 2022 — ANSSI / CIS
  hosts: windows_servers
  gather_facts: true
  vars_files:
    - "{{ inventory_dir }}/group_vars/windows/vault.yml"

  tasks:
    - name: "[WIN-01] Désactiver SMBv1"
      win_feature:
        name: FS-SMB1
        state: absent
      tags: [hardening, smb, cis-18.3.3]

    - name: "[WIN-02] Désactiver LM et NTLMv1"
      win_regedit:
        path: HKLM:\SYSTEM\CurrentControlSet\Control\Lsa
        name: LmCompatibilityLevel
        data: 5
        type: dword
      tags: [hardening, auth, cis-2.3.11.8]

    - name: "[WIN-03] Activer LSA Protection (RunAsPPL)"
      win_regedit:
        path: HKLM:\SYSTEM\CurrentControlSet\Control\Lsa
        name: RunAsPPL
        data: 1
        type: dword
      tags: [hardening, credential-protection, anssi]

    - name: "[WIN-04] Configurer la taille du journal Sécurité"
      win_eventlog:
        name: Security
        maximum_size_kb: 1048576   # 1 GB
        overflow_action: DoNotOverwrite
      tags: [hardening, logging, cis-17.x]

    - name: "[WIN-05] Activer le pare-feu Windows sur tous les profils"
      win_firewall:
        profiles:
          - Domain
          - Private
          - Public
        state: enabled
        inbound_action: block
        outbound_action: allow
      tags: [hardening, firewall]
```

---

## Audit de conformité Windows

```powershell
# Utiliser Microsoft Security Compliance Toolkit (SCT) + LGPO
# Télécharger les baselines Microsoft : https://www.microsoft.com/en-us/download/details.aspx?id=55319

# LGPO pour appliquer/auditer des GPO localement
.\LGPO.exe /parse /m MachinePolicy\registry.pol > lgpo_output.txt

# CIS-CAT Pro (outil CIS) — audit automatisé contre CIS Benchmark
.\CIS-CAT.bat -b benchmarks\CIS_Microsoft_Windows_Server_2022_Benchmark_v3.0.0-xccdf.xml `
  -p "Level 2 - Member Server"
```

---

## Connexions

- [[playbooks-securises]] — automatisation du durcissement en Ansible/WinRM
- [[anssi]] — PA-046 (Active Directory), guide Windows
- [[nist]] — SP 800-53 (IA, AC, AU, CM, SI)
- [[referentiels-securite]] — DISA STIG WS2022, CIS Windows Server 2022
- [[defense-en-profondeur]] — couche 5 (hôtes) Windows
- [[hardening-linux]] — équivalent Linux
- [[devsecops]] — intégration CI/CD pour Windows (Ansible + WinRM)

---
*Dernière mise à jour : 2026-06-21 | Sources : ANSSI PA-046, CIS WS2022 v3.0, DISA STIG WS2022 V2R2*
