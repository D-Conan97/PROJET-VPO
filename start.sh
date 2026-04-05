#!/bin/bash

echo "🤖 Lancement du cerveau Python (en arrière-plan)..."
python3 main.py &

echo "📱 Lancement de l'application Flutter..."
# Assure-toi que ce chemin correspond bien à ton dossier Flutter
cd SecureHomeApp 
flutter run -d chrome

# Quand tu fermeras l'application Flutter, cette commande arrêtera aussi Python
kill %1 