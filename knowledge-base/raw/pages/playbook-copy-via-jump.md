---
# =============================================================================
# copy_via_jump.yml — Copie sécurisée d'un fichier A → C via bastion B
# =============================================================================
# Référentiels : ANSSI BP-028 (SSH), NIST SP 800-53 SC-8 (transit), CM-3
#
# UTILISATION :
#   ansible-playbook playbooks/copy_via_jump.yml \
#     -e "src_file=/chemin/local/fichier.txt" \
#     -e "dest_file=/chemin/distant/fichier.txt" \
#     -e "jump_host_ip=10.0.1.10" \
#     -e "jump_host_user=bastionuser" \
#     -e "dest_host_ip=10.0.2.20" \
#     -e "dest_host_user=serveruser" \
#     -e "dest_host_port=22" \
#     --private-key ~/.ssh/ansible_ed25519
#
# VARIABLES OBLIGATOIRES :
#   src_file        : chemin absolu du fichier SOURCE sur le controller (A)
#   dest_file       : chemin absolu de destination sur le serveur (C)
#   jump_host_ip    : IP du bastion (B)
#   jump_host_user  : utilisateur SSH sur le bastion (B)
#   dest_host_ip    : IP du serveur destination (C)
#   dest_host_user  : utilisateur SSH sur le serveur destination (C)
#
# VARIABLES OPTIONNELLES (avec valeurs par défaut) :
#   dest_host_port  : port SSH de C (défaut : 22)
#   jump_host_port  : port SSH de B (défaut : 22)
#   ssh_key_file    : chemin de la clé privée (défaut : ~/.ssh/id_ed25519)
#   dest_file_owner : propriétaire du fichier sur C (défaut : dest_host_user)
#   dest_file_mode  : permissions du fichier sur C (défaut : '0640')
#   dest_file_group : groupe du fichier sur C (défaut : dest_host_user)
#   backup_existing : sauvegarder le fichier existant sur C si présent (défaut : true)
# =============================================================================

- name: "Validation des prérequis — variables et fichier source"
  hosts: localhost
  connection: local
  gather_facts: false

  vars:
    # Valeurs par défaut (surchargeable par -e)
    dest_host_port: "{{ dest_host_port | default('22') }}"
    jump_host_port: "{{ jump_host_port | default('22') }}"
    ssh_key_file: "{{ ssh_key_file | default('~/.ssh/id_ed25519') }}"
    dest_file_owner: "{{ dest_file_owner | default(dest_host_user) }}"
    dest_file_group: "{{ dest_file_group | default(dest_host_user) }}"
    dest_file_mode: "{{ dest_file_mode | default('0640') }}"
    backup_existing: "{{ backup_existing | default(true) }}"

  tasks:
    - name: "[PRE-01] Vérifier que toutes les variables obligatoires sont définies"
      assert:
        that:
          - src_file is defined and src_file | length > 0
          - dest_file is defined and dest_file | length > 0
          - jump_host_ip is defined and jump_host_ip | length > 0
          - jump_host_user is defined and jump_host_user | length > 0
          - dest_host_ip is defined and dest_host_ip | length > 0
          - dest_host_user is defined and dest_host_user | length > 0
        fail_msg: |
          ❌ Variable(s) manquante(s). Vérifiez que vous avez passé :
             -e "src_file=..."
             -e "dest_file=..."
             -e "jump_host_ip=..."
             -e "jump_host_user=..."
             -e "dest_host_ip=..."
             -e "dest_host_user=..."
        success_msg: "✅ Toutes les variables obligatoires sont présentes"
      tags: [always, preflight]

    - name: "[PRE-02] Vérifier que le fichier source existe sur le controller"
      stat:
        path: "{{ src_file }}"
        checksum_algorithm: sha256
        get_checksum: true
      register: src_stat
      tags: [always, preflight]

    - name: "[PRE-03] Échec si le fichier source est introuvable"
      assert:
        that:
          - src_stat.stat.exists
          - src_stat.stat.isreg
        fail_msg: "❌ Le fichier source '{{ src_file }}' n'existe pas ou n'est pas un fichier régulier"
        success_msg: "✅ Fichier source trouvé : {{ src_file }} ({{ src_stat.stat.size }} octets)"
      tags: [always, preflight]

    - name: "[PRE-04] Calculer et afficher le checksum SHA256 du fichier source"
      debug:
        msg: |
          📁 Fichier source    : {{ src_file }}
          📏 Taille            : {{ src_stat.stat.size }} octets
          🔐 SHA256 source     : {{ src_stat.stat.checksum }}
          🖥️  Bastion (B)       : {{ jump_host_user }}@{{ jump_host_ip }}:{{ jump_host_port }}
          🖥️  Destination (C)   : {{ dest_host_user }}@{{ dest_host_ip }}:{{ dest_host_port }}
          📂 Chemin destination : {{ dest_file }}
      tags: [always, preflight]

    - name: "[PRE-05] Stocker le checksum source pour vérification ultérieure"
      set_fact:
        src_checksum_sha256: "{{ src_stat.stat.checksum }}"
        src_file_size: "{{ src_stat.stat.size }}"
      tags: [always, preflight]

    # -------------------------------------------------------------------------
    # Ajout dynamique de l'hôte C dans l'inventaire Ansible
    # avec ProxyJump configuré pour passer par B
    # Sécurité SSH : ANSSI BP-028 / recommandations OpenSSH
    # - ForwardAgent no : pas de forwarding d'agent (évite pivot depuis B)
    # - StrictHostKeyChecking yes : vérifie les fingerprints
    # - ServerAliveInterval : évite les sessions mortes silencieuses
    # -------------------------------------------------------------------------
    - name: "[PRE-06] Enregistrer l'hôte destination (C) dans l'inventaire dynamique"
      add_host:
        name: "dest_server_c"
        ansible_host: "{{ dest_host_ip }}"
        ansible_port: "{{ dest_host_port }}"
        ansible_user: "{{ dest_host_user }}"
        ansible_private_key_file: "{{ ssh_key_file }}"
        ansible_ssh_common_args: >-
          -o ProxyJump={{ jump_host_user }}@{{ jump_host_ip }}:{{ jump_host_port }}
          -o StrictHostKeyChecking=yes
          -o UserKnownHostsFile=~/.ssh/known_hosts
          -o ForwardAgent=no
          -o ServerAliveInterval=30
          -o ServerAliveCountMax=3
          -o ConnectTimeout=15
          -o Ciphers=chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
          -o MACs=hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
          -o KexAlgorithms=curve25519-sha256,diffie-hellman-group16-sha512
        # Variables de contexte à transmettre au prochain play
        src_file_to_copy: "{{ src_file }}"
        dest_file_path: "{{ dest_file }}"
        expected_checksum: "{{ src_stat.stat.checksum }}"
        file_owner: "{{ dest_file_owner }}"
        file_group: "{{ dest_file_group }}"
        file_mode: "{{ dest_file_mode }}"
        do_backup: "{{ backup_existing }}"
        src_size: "{{ src_stat.stat.size }}"
      tags: [always, preflight]

# =============================================================================
# PLAY 2 — Copie effective du fichier vers C (via B transparent par ProxyJump)
# =============================================================================
- name: "Copie sécurisée du fichier vers le serveur destination (C) via bastion (B)"
  hosts: dest_server_c
  gather_facts: false   # Minimise la surface d'exposition — on ne collecte que ce dont on a besoin

  tasks:
    - name: "[COPY-01] Vérifier la connectivité SSH vers C (via B)"
      wait_for_connection:
        timeout: 30
        sleep: 2
      tags: [copy, connectivity]

    - name: "[COPY-02] Collecter les infos minimales sur C (OS, espace disque)"
      setup:
        gather_subset:
          - '!all'
          - 'hardware'
          - 'distribution'
      tags: [copy, facts]

    - name: "[COPY-03] Vérifier que l'espace disque est suffisant sur C"
      assert:
        that:
          - ansible_mounts | selectattr('mount', 'equalto', '/') | map(attribute='size_available') | first > (src_size | int * 2)
        fail_msg: "❌ Espace disque insuffisant sur {{ inventory_hostname }} pour copier {{ src_size }} octets"
        success_msg: "✅ Espace disque suffisant"
      vars:
        src_size: "{{ hostvars['dest_server_c']['src_size'] }}"
      tags: [copy, preflight]

    - name: "[COPY-04] Vérifier si le répertoire destination existe, le créer si nécessaire"
      file:
        path: "{{ dest_file_path | dirname }}"
        state: directory
        owner: "{{ file_owner }}"
        group: "{{ file_group }}"
        mode: '0750'
      become: true
      vars:
        dest_file_path: "{{ hostvars['dest_server_c']['dest_file_path'] }}"
        file_owner: "{{ hostvars['dest_server_c']['file_owner'] }}"
        file_group: "{{ hostvars['dest_server_c']['file_group'] }}"
      tags: [copy, filesystem]

    - name: "[COPY-05] Copier le fichier de A vers C (transit chiffré via ProxyJump B)"
      copy:
        src: "{{ hostvars['dest_server_c']['src_file_to_copy'] }}"
        dest: "{{ hostvars['dest_server_c']['dest_file_path'] }}"
        owner: "{{ hostvars['dest_server_c']['file_owner'] }}"
        group: "{{ hostvars['dest_server_c']['file_group'] }}"
        mode: "{{ hostvars['dest_server_c']['file_mode'] }}"
        backup: "{{ hostvars['dest_server_c']['do_backup'] | bool }}"
        checksum: "{{ hostvars['dest_server_c']['expected_checksum'] }}"
        # Ansible vérifie automatiquement le checksum avant de copier (idempotence)
      become: true
      register: copy_result
      tags: [copy, transfer]

    - name: "[COPY-06] Vérifier l'intégrité du fichier sur C (SHA256 post-copie)"
      stat:
        path: "{{ hostvars['dest_server_c']['dest_file_path'] }}"
        checksum_algorithm: sha256
        get_checksum: true
      register: dest_stat
      become: true
      tags: [copy, integrity]

    - name: "[COPY-07] Asserter que le checksum destination == checksum source"
      assert:
        that:
          - dest_stat.stat.checksum == hostvars['dest_server_c']['expected_checksum']
          - dest_stat.stat.mode == hostvars['dest_server_c']['file_mode']
          - dest_stat.stat.pw_name == hostvars['dest_server_c']['file_owner']
        fail_msg: |
          ❌ INTEGRITY FAILURE — Le fichier copié ne correspond pas au fichier source !
             SHA256 attendu  : {{ hostvars['dest_server_c']['expected_checksum'] }}
             SHA256 reçu     : {{ dest_stat.stat.checksum }}
          ⚠️  Incident de sécurité potentiel — vérifiez le bastion B.
        success_msg: |
          ✅ Intégrité vérifiée :
             SHA256 : {{ dest_stat.stat.checksum }}
             Mode   : {{ dest_stat.stat.mode }}
             Owner  : {{ dest_stat.stat.pw_name }}
      tags: [copy, integrity]

    - name: "[COPY-08] Rapport final de la copie"
      debug:
        msg: |
          ============================================================
          ✅ COPIE RÉUSSIE
          ============================================================
          Source      : {{ hostvars['dest_server_c']['src_file_to_copy'] }} (sur A/controller)
          Bastion     : {{ hostvars['dest_server_c']['ansible_host'] }} (B — ProxyJump)
          Destination : {{ hostvars['dest_server_c']['dest_file_path'] }} (sur C)
          SHA256      : {{ dest_stat.stat.checksum }}
          Taille      : {{ dest_stat.stat.size }} octets
          Modifié     : {{ copy_result.changed }}
          Backup      : {{ copy_result.backup_file | default('aucun') }}
          ============================================================
      tags: [copy, report]
