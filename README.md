# PROJET-VPO
a Computer Vision project for lock open when the face is detected  

# 🛡️ SecureHome AI (VPO Surveillance)

SecureHome AI est un système de sécurité intelligent et hybride combinant la **reconnaissance faciale en temps réel** (via Python) et un **tableau de bord de contrôle mobile/web** (via Flutter). Le tout est synchronisé instantanément grâce à **Supabase**.

## ✨ Fonctionnalités Principales

* **🤖 Reconnaissance Faciale (Edge Computing) :** Détecte et identifie les visages en temps réel via la webcam.
* **✅ Accès Automatique :** Autorise l'accès si la personne est reconnue (présente dans le dossier `visages_connues`).
* **🚫 Liste Noire (Blacklist) :** Bloque automatiquement l'accès aux personnes enregistrées sur la liste noire, même si leur visage est connu du système.
* **⚠️ Gestion des Inconnus :** Lorsqu'un visage inconnu est détecté, une photo est prise et envoyée sur l'application avec le statut `pending` (en attente).
* **📱 Tableau de Bord Flutter :** Permet au propriétaire de recevoir des alertes, de voir la photo de l'inconnu, et de décider manuellement de l'accepter ou de le refuser.
* **📊 Historique :** Garde une trace complète des passages avec l'heure, le nom, le statut et le type de vérification (IA ou Manuel).

## 🛠️ Technologies Utilisées

* **Intelligence Artificielle (Python) :** `OpenCV`, `face_recognition`, `numpy`
* **Application Client (Flutter) :** `Dart`, `Riverpod` (State Management)
* **Backend & Base de données :** `Supabase` (PostgreSQL, Storage, Realtime)

## 🗄️ Structure de la Base de Données (Supabase)

Le projet nécessite deux tables principales dans PostgreSQL :

1.  **Table `visiteurs` :**
    * `id` (int, primary key)
    * `nom_du_visiteur` (text)
    * `status` (text) -> Peut être : "Accepter", "Refuser", "pending", "Terminé".
    * `image_url` (text) -> Lien vers le bucket Storage.
    * `created_at` (timestamp)

2.  **Table `blacklist` :**
    * `id` (int, primary key)
    * `nom_du_visiteur` (text, UNIQUE)

## 🚀 Installation et Lancement

### 1. Prérequis
* Avoir Python 3.9+ installé.
* Avoir Flutter SDK installé.
* Avoir un projet Supabase configuré avec les tables ci-dessus et un bucket de stockage pour les images.

### 2. Configuration Python (IA)
\`\`\`bash
# Cloner le dépôt (si applicable)
git clone <ton-repo>

# Installer les dépendances
pip install -r requirements.txt

# Ajouter les photos des personnes autorisées dans le dossier
# /visages_connues/ (ex: sara.jpg, jean.png)
\`\`\`
*N'oubliez pas de configurer vos clés d'API Supabase dans le fichier `config.py` ou `.env`.*

### 3. Lancement du système
Pour lancer à la fois le cerveau Python et l'application Flutter, exécutez le script de démarrage :
\`\`\`bash
./start.sh
\`\`\`



### ETAPES DE CREATION DU SCRIPT POUR L'ÉXECUTION DE TOUS  

Étape 1 : Crée un fichier de lancement
Dans le dossier principal de ton projet (au même endroit que main.py), crée un nouveau fichier texte et nomme-le start.sh


Étape 2 : Colle ce code dedans
#!/bin/bash

echo "🤖 Lancement du cerveau Python (en arrière-plan)..."
python3 main.py &

echo "📱 Lancement de l'application Flutter..."
# Assure-toi que ce chemin correspond bien à ton dossier Flutter
cd SecureHomeApp 
flutter run -d chrome

# Quand tu fermeras l'application Flutter, cette commande arrêtera aussi Python
kill %1

Étape 3 : Donner le droit d'exécution (À faire une seule fois)
Ouvre ton terminal Mac, place-toi dans le dossier de ton projet, et tape cette commande pour autoriser ton Mac à exécuter ce fichier :

# chmod +x start.sh

Étape 4 : La nouvelle commande magique !
Maintenant, à chaque fois que tu veux lancer ton projet complet (Python + Flutter), tu n'as plus qu'à taper cette unique commande dans ton terminal :

# ./start.sh




###### 👨‍💻 Auteur
Créé par [SARA DOMTI/ TALHI FATIMA EZZAHRA / OUELD AADOU KAWTAR].
