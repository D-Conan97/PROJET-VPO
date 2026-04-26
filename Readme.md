# 🏠 SecureHome AI

Salut l'équipe ! 👋 Bienvenue sur le projet **SecureHome AI**. 
C'est notre système de surveillance intelligent qui utilise la reconnaissance faciale (Python) pour détecter les visages à la caméra, et une application (Flutter) pour gérer les accès et voir l'historique en temps réel.

Ce projet est divisé en deux parties principales :
1. **Le Cerveau (Python) :** Utilise OpenCV et `face_recognition` pour analyser le flux vidéo, détecter les visages, et interagir avec la base de données.
2. **L'Application (Flutter) :** Une interface en temps réel permettant de surveiller la porte, consulter l'historique, gérer la blacklist et ouvrir/fermer l'accès.

Toutes les données sont synchronisées en temps réel grâce à **Supabase**.

---

## 🛠️ Prérequis

Avant de commencer, assurez-vous d'avoir installé sur votre machine :
- [Git](https://git-scm.com/)
- [Python 3.10+](https://www.python.org/downloads/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)

---

## 🚀 Étape 1 : Cloner le projet

Ouvrez votre terminal (ou l'invite de commande) et tapez ces commandes pour télécharger le code :

```bash
git clone [https://github.com/VOTRE_PSEUDO/VOTRE_REPO.git](https://github.com/VOTRE_PSEUDO/VOTRE_REPO.git)
cd VOTRE_REPO

```


##  🔐 Étape 2 : 1 .Ajouter les clés secrètes (IMPORTANT)
Pour des raisons de sécurité, les mots de passe de la base de données ne sont pas sur GitHub. Si vous lancez le code maintenant, l'application ne pourra pas se connecter !

👉 Demandez-moi le fichier config.py (et/ou .env) en message privé et placez-le à la racine du projet, exactement au même niveau que main.py.


## 📁 Étape 2 :2 . Créer le dossier des visages connus
Le script d'intelligence artificielle a besoin d'un dossier spécifique pour lire et stocker les photos des personnes autorisées. Parce qu'il est vide ou qu'il contient des données personnelles, ce dossier n'est pas envoyé sur GitHub.

Allez à la racine du projet (au même niveau que main.py).

Créez un nouveau dossier et nommez-le exactement : visages_connus

(Optionnel : Vous pouvez y glisser quelques photos de vous ou de vos amis au format .jpg  chacune dans un dossier pour que l'IA vous reconnaisse tout de suite ! Le nom du dossier deviendra le nom reconnu, ex: sara).

## 🐍 Étape 3 : Configurer le cerveau Python (L'IA)
Il faut créer un environnement virtuel pour installer les bonnes librairies (OpenCV, face_recognition, etc.) sans polluer votre système.

🍏 Pour Mac / Linux :

```Bash
# 1. Créer l'environnement virtuel
python3 -m venv venv

# 2. Activer l'environnement
source venv/bin/activate

# 3. Installer les dépendances
pip install -r requirements.txt
```

🪟 Pour Windows :

```DOS
# 1. Créer l'environnement virtuel
python -m venv venv

# 2. Activer l'environnement
.\venv\Scripts\activate

# 3. Installer les dépendances
pip install -r requirements.txt
```

## 📱 Étape 4 : Configurer l'application Flutter
Maintenant que l'IA est prête, téléchargeons les packages de l'application. La commande est la même pour tous les systèmes d'exploitation :

```Bash ou cmd
flutter pub get
```

## ▶️ Étape 5 : Lancer le projet !
Pour que le système fonctionne, il faut faire tourner la détection vidéo ET l'interface en même temps.

Option A : Le raccourci tout-en-un (Uniquement Mac / Linux)
Si vous êtes sur Mac ou Linux, vous pouvez tout lancer avec un seul fichier :

```Bash
# Donner les droits d'exécution (la première fois seulement)
chmod +x start.sh

# Lancer le projet
./start.sh
```
   Option B : Lancer manuellement (Pour Windows, ou pour voir les erreurs séparément)
Ouvrez deux terminaux différents et placez-les tous les deux dans le dossier du projet.

Terminal 1 (L'IA de la caméra) :

```DOS
# N'oubliez pas d'activer l'environnement virtuel d'abord !
# (Mac: source venv/bin/activate | Windows: .\venv\Scripts\activate)

python main.py
````

Terminal 2 (L'application Flutter) :

```DOS
flutter run -d chrome

```
(Vous pouvez remplacer chrome par edge, macos, windows ou le nom de votre simulateur mobile).
