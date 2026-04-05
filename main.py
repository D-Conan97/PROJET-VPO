import face_recognition
import cv2
import numpy as np
import os
import time
from config import *
import supabase_utils

# --- INITIALISATION IA ---
connaissances_encodages = []
connaissances_noms = []

def charger_visages():
    if not os.path.exists(D_CONNUS): os.makedirs(D_CONNUS)
    for file in os.listdir(D_CONNUS):
        if file.endswith(('.jpg', '.png')):
            img = face_recognition.load_image_file(f"{D_CONNUS}/{file}")
            enc = face_recognition.face_encodings(img)
            if enc:
                connaissances_encodages.append(enc[0])
                connaissances_noms.append(os.path.splitext(file)[0])
    print(f"✅ IA prête : {len(connaissances_noms)} visages connus.")

def main():
    charger_visages()
    cap = cv2.VideoCapture(0)
    
    id_en_attente = None
    dernier_envoi = 0
    check_timer = 0
    scene_deja_traitee = False

    while True:
        ret, frame = cap.read()
        if not ret: break
        
        frame = cv2.flip(frame, 1)
        

        maintenant = time.time()
        
        # --- PARTIE 1 : IA AUTOMATIQUE ---
        small_frame = cv2.resize(frame, (0,0), fx=0.25, fy=0.25)
        rgb_small = cv2.cvtColor(small_frame, cv2.COLOR_BGR2RGB)
        
        locs = face_recognition.face_locations(rgb_small)
        encs = face_recognition.face_encodings(rgb_small, locs)

        if len(encs) == 0:
            scene_deja_traitee = False

        # Analyse de tous les visages présents
        noms_detectes = []
        for enc in encs:
            nom = "Inconnu"
            if connaissances_encodages:
                matches = face_recognition.compare_faces(connaissances_encodages, enc, TOLERANCE)
                if True in matches:
                    idx = np.argmin(face_recognition.face_distance(connaissances_encodages, enc))
                    nom = connaissances_noms[idx]
            noms_detectes.append(nom)

        # --- PARTIE 2 : LOGIQUE DE DÉCISION DU GROUPE ---
        if noms_detectes and not scene_deja_traitee and (maintenant - dernier_envoi > COOLDOWN_NOTIF):
            
            # SCÉNARIO A : Il y a au moins un INCONNU
            if "Inconnu" in noms_detectes:
                print("⚠️ Groupe mixte ou inconnu détecté. Accès bloqué.")
                print("📸 Envoi de la photo pour décision du propriétaire...")
                res_upload = supabase_utils.uploader_et_enregistrer(frame, nom="Inconnu")
                if res_upload:
                    id_en_attente = res_upload["id"]
                dernier_envoi = maintenant
                scene_deja_traitee = True

            # SCÉNARIO B : Tout le monde est connu (VÉRIFICATION BLACKLIST)
            else:
                personne_blacklistee = False
                noms_interdits = []
                
                # Vérification de chaque visage dans la table blacklist
                # On utilise set() pour ne vérifier chaque nom qu'une seule fois
                for nom in set(noms_detectes):
                    try:
                        reponse_bl = supabase_utils.supabase.table('blacklist').select('*').eq('nom_du_visiteur', nom).execute()
                        if len(reponse_bl.data) > 0:
                            personne_blacklistee = True
                            noms_interdits.append(nom)
                    except Exception as e:
                        print(f"⚠️ Erreur lors de la vérification de la blacklist pour {nom} : {e}")

                # Prise de décision finale
                if personne_blacklistee:
                    liste_interdits = ", ".join(noms_interdits)
                    print(f"🚫 ACCÈS REFUSÉ : {liste_interdits} est sur liste noire !")
                    # Envoi direct à Supabase avec le statut "Refuser"
                    supabase_utils.uploader_et_enregistrer(frame, nom=liste_interdits, status="Refuser")
                else:
                    liste_noms = ", ".join(noms_detectes)
                    print(f"🔓 ACCÈS VIRTUEL AUTORISÉ pour : {liste_noms}")
                    supabase_utils.uploader_et_enregistrer(frame, nom=liste_noms, status="Accepter")
                
                dernier_envoi = maintenant
                scene_deja_traitee = True

        # --- PARTIE 3 : VÉRIFICATION DÉCISION MANUELLE ---
        if id_en_attente and (maintenant - check_timer > 2):
            check_timer = maintenant
            statut = supabase_utils.verifier_decision(id_en_attente)
            
            if statut == "Accepter":
                print("✅ PROPRIÉTAIRE : ACCÈS VIRTUEL ACCORDÉ")
                # Clôture du dossier dans Supabase
                supabase_utils.supabase.table(TABLE_VISITEURS).update({"status": "Terminé"}).eq("id", id_en_attente).execute()
                id_en_attente = None
            
            elif statut == "Refuser":
                print("❌ PROPRIÉTAIRE : ACCÈS REFUSÉ")
                id_en_attente = None

        cv2.imshow("VPO Surveillance", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'): break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
    