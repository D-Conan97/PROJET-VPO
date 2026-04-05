@echo off
echo ==========================================
echo    Lancement de SecureHome AI (Windows)
echo ==========================================

:: 1. Lancer Python dans une nouvelle fenetre avec l'environnement virtuel
echo [1/2] Lancement de la camera et de l'IA...
start cmd /k "env\Scripts\activate && python main.py"

:: 2. Lancer Flutter dans cette fenetre
echo [2/2] Lancement de l'application Flutter...
cd SecureHomeApp
flutter run -d web-server