🪟 Guide d'Installation et d'Exécution (Spécial Windows)
Bienvenue sur le projet SecureHome AI ! Puisque ce projet utilise la reconnaissance faciale, il doit accéder à la webcam de votre ordinateur. Voici les étapes simples pour tout configurer et lancer sur votre machine Windows.

🛠️ 1. Prérequis
Avant de commencer, assurez-vous d'avoir ces trois outils installés sur votre ordinateur :

Git (Pour télécharger le code)
Python 3.9 ou plus (⚠️ Très important : lors de l'installation de Python, cochez bien la case "Add Python to PATH" en bas de la fenêtre !)
Flutter SDK (Pour lancer l'application mobile/web)
📥 2. Récupérer le projet
Ouvrez l'Invite de commandes (tapez cmd dans la barre de recherche Windows).
Choisissez le dossier où vous voulez mettre le projet (par exemple le bureau : cd Desktop).
Téléchargez le projet et entrez dans le dossier avec ces commandes :
``cmd git clone https://github.com/D-Conan97/PROJET-VPO.git cd PROJET-VPO

3. Créer l'environnement et installer les outils
:: 1. Créer l'environnement virtuel (nommé "env") python -m venv env

:: 2. Activer l'environnement virtuel env\Scripts\activate

:: 3. Installer les bibliothèques d'Intelligence Artificielle pip install -r requirements.txt

📸 4. Ajouter vos visages (Configuration)
Avant d'allumer la caméra, l'IA a besoin de savoir qui est autorisé à entrer.

Allez dans le dossier du projet.

Ouvrez le dossier visages_connues.

Glissez-y une photo de vous bien claire (ex: marc.jpg ou sophie.png).

🚀 5. Lancer la magie (Méthode Automatique)
Nous avons créé un script qui lance automatiquement le "cerveau" (Python) et l'interface (Flutter) en même temps.

👉 Pour lancer le projet :

Allez dans le dossier du projet PROJET-VPO.

. Tapez cette commande et appuyez sur Entrée :

.\start.bat