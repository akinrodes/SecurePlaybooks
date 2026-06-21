FROM ubuntu:22.04

# Éviter les prompts interactifs apt
ENV DEBIAN_FRONTEND=noninteractive

# Installer OpenSSH Server, Sudo et Python3 (requis par Ansible)
RUN apt-get update && \
    apt-get install -y openssh-server sudo python3 && \
    mkdir /var/run/sshd && \
    # Nettoyage
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Argument pour le nom d'utilisateur (défaut: testuser)
ARG USERNAME=testuser

# Créer l'utilisateur, l'ajouter au groupe sudo, et permettre le sudo sans mot de passe pour les tests
RUN useradd -rm -d /home/$USERNAME -s /bin/bash -g root -G sudo -u 1000 $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Préparer le dossier .ssh pour l'injection de clé publique
RUN mkdir -p /home/$USERNAME/.ssh && \
    chmod 700 /home/$USERNAME/.ssh && \
    chown $USERNAME:root /home/$USERNAME/.ssh

# Configurer sshd (optionnel, pour forcer les bonnes pratiques si besoin)
RUN echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
