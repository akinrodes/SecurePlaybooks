#!/bin/bash
set -e

# Se placer dans le bon répertoire
cd "$(dirname "$0")"

echo "========================================================="
echo "🚀 PRÉPARATION DU TESTBED DEVSECOPS"
echo "========================================================="

# 1. Générer une paire de clés SSH dédiée aux tests si elle n'existe pas
if [ ! -f "test_key" ]; then
    echo "🔑 Création de la paire de clés SSH de test (ED25519)..."
    ssh-keygen -t ed25519 -f test_key -N "" -C "ansible_test_key"
    chmod 600 test_key
else
    echo "🔑 Clé SSH de test déjà existante."
fi

# 2. Démarrer les conteneurs (B = Bastion, C = Target)
echo "🐳 Démarrage des conteneurs via Docker Compose..."
docker compose up -d --build

# 3. Attendre que SSH soit prêt
echo "⏳ Attente (5s) pour s'assurer que les serveurs SSH sont démarrés..."
sleep 5

# Récupérer l'IP du conteneur cible (C) sur le réseau Docker
TARGET_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' test_target)
echo "📡 IP de la cible (C) détectée : $TARGET_IP"

# 4. Créer un fichier de test (A)
TEST_FILE="/tmp/test_secret_file.txt"
echo "Contenu super secret $(date)" > $TEST_FILE
echo "📄 Fichier de test créé sur l'hôte local (A) : $TEST_FILE"

echo "========================================================="
echo "🏃 EXÉCUTION DU PLAYBOOK ANSIBLE"
echo "========================================================="

# On définit le répertoire où se trouve le playbook
PLAYBOOK_DIR="../../outputs"
PLAYBOOK="$PLAYBOOK_DIR/copy_via_jump_multiplatform.yml"

# Chemin absolu vers la clé (copiée dans /tmp pour éviter les problèmes d'espaces dans le chemin ProxyCommand d'Ansible)
cp test_key /tmp/ansible_test_key
chmod 600 /tmp/ansible_test_key
KEY_PATH="/tmp/ansible_test_key"

# On exécute Ansible avec le Bastion publié sur le port 2222 de localhost
# L'hôte A est notre machine physique (localhost)
# Le Bastion B est accessible via localhost:2222
# La cible C est accessible via son IP Docker ($TARGET_IP:22) DEPUIS le bastion B.
#
# Note: Dans un environnement réel, on utilise le DNS ou les IPs réelles.
ansible-playbook "$PLAYBOOK" \
  -e "src_file=$TEST_FILE" \
  -e "dest_file=/tmp/fichier_recu.txt" \
  -e "dest_os=linux" \
  -e "jump_host_ip=127.0.0.1" \
  -e "jump_host_user=bastionuser" \
  -e "jump_host_port=2222" \
  -e "dest_host_ip=$TARGET_IP" \
  -e "dest_host_user=serveruser" \
  -e "ssh_key_file=$KEY_PATH"

echo "========================================================="
echo "✅ VÉRIFICATION FINALE (DANS LE CONTENEUR CIBLE)"
echo "========================================================="
docker exec test_target cat /tmp/fichier_recu.txt

echo "========================================================="
echo "🧹 NETTOYAGE (OPTIONNEL)"
echo "Pour détruire l'environnement de test, lancez :"
echo "cd knowledge-base/tests/docker-testbed && docker compose down"
echo "========================================================="
