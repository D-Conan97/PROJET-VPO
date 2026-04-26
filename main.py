import face_recognition
import cv2
import numpy as np
import os
import time
import threading

from config import *
import supabase_utils

# --- INITIALISATION IA ---
connaissances_encodages = []
connaissances_noms = []

# --- THREAD SHARED DATA ---
latest_frame = None
face_results = []
face_locations = []
lock = threading.Lock()
tracked_faces = []

# Variables globales pour la gestion réseau en arrière-plan
id_en_attente = None
is_checking_decision = False

def charger_visages():
    if not os.path.exists(D_CONNUS): 
        os.makedirs(D_CONNUS)
        
    for nom_personne in os.listdir(D_CONNUS):
        chemin_dossier_personne = os.path.join(D_CONNUS, nom_personne)
        
        if os.path.isdir(chemin_dossier_personne):
            for file in os.listdir(chemin_dossier_personne):
                if file.lower().endswith(('.jpg', '.jpeg', '.png')):
                    chemin_image = os.path.join(chemin_dossier_personne, file)
                    
                    try:
                        img = face_recognition.load_image_file(chemin_image)
                        enc = face_recognition.face_encodings(img, num_jitters=10)
                        if enc:
                            connaissances_encodages.append(enc[0])
                            connaissances_noms.append(nom_personne)
                    except Exception as e:
                        print(f"⚠️ Erreur avec {chemin_image} : {e}")
                        
    print(f"✅ IA prête : {len(connaissances_noms)} visages connus.")

# --- THREAD: FACE RECOGNITION ---
def process_frames():
    global latest_frame, face_results, face_locations

    while True:
        # Limit processing rate
        if time.time() % 0.2 > 0.01:
            time.sleep(0.01)
            continue

        if latest_frame is None:
            time.sleep(0.01)
            continue

        with lock:
            frame = latest_frame.copy()

        # AI processing
        small_frame = cv2.resize(frame, (0,0), fx=0.25, fy=0.25)
        rgb_small = cv2.cvtColor(small_frame, cv2.COLOR_BGR2RGB)

        locs = face_recognition.face_locations(rgb_small)
        encs = face_recognition.face_encodings(rgb_small, locs)

        noms_detectes = []

        for enc in encs:
            nom = "Inconnu"

            if connaissances_encodages:
                distances = face_recognition.face_distance(connaissances_encodages, enc)

                if len(distances) > 0:
                    min_dist = np.min(distances)
                    idx = np.argmin(distances)

                    if min_dist < TOLERANCE:
                        nom = connaissances_noms[idx]

            noms_detectes.append(nom)

        with lock:
            face_results = noms_detectes
            face_locations = locs

        time.sleep(0.01)

# --- THREADS RESEAUX (POUR NE PAS BLOQUER LA CAMERA) ---
def upload_inconnu_thread(frame_copy):
    global id_en_attente
    print("☁️ Upload de l'inconnu en cours...")
    res_upload = supabase_utils.uploader_et_enregistrer(frame_copy, nom="Inconnu")
    if res_upload:
        id_en_attente = res_upload["id"]
        print(f"✅ Upload terminé, en attente de décision pour ID: {id_en_attente}")

def upload_connu_thread(frame_copy, liste_noms, status):
    print(f"☁️ Upload de {liste_noms} en cours ({status})...")
    supabase_utils.uploader_et_enregistrer(frame_copy, nom=liste_noms, status=status)

def check_decision_thread():
    global id_en_attente, is_checking_decision
    is_checking_decision = True
    try:
        if id_en_attente:
            statut = supabase_utils.verifier_decision(id_en_attente)
            if statut == "Accepter":
                print("✅ PROPRIÉTAIRE: ACCORDÉ")
                supabase_utils.supabase.table(TABLE_VISITEURS) \
                    .update({"status": "Terminé"}) \
                    .eq("id", id_en_attente) \
                    .execute()
                id_en_attente = None
            elif statut == "Refuser":
                print("❌ PROPRIÉTAIRE: REFUSÉ")
                id_en_attente = None
    finally:
        is_checking_decision = False

def main():
    global latest_frame, face_results, face_locations, id_en_attente, is_checking_decision

    charger_visages()
    cap = cv2.VideoCapture(0)

    # LOAD BLACKLIST ONCE
    blacklist_cache = set()
    try:
        res = supabase_utils.supabase.table('blacklist').select('nom_du_visiteur').execute()
        blacklist_cache = set([x['nom_du_visiteur'] for x in res.data])
        print("✅ Blacklist chargée:", blacklist_cache)
    except:
        print("⚠️ Impossible de charger blacklist")

    # START THREAD IA
    thread = threading.Thread(target=process_frames, daemon=True)
    thread.start()

    dernier_envoi = 0
    check_timer = 0
    scene_deja_traitee = False

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        frame = cv2.flip(frame, 1)
        maintenant = time.time()

        # SEND FRAME TO THREAD
        with lock:
            latest_frame = frame.copy()

        # GET RESULTS FROM THREAD
        with lock:
            noms_detectes = face_results.copy()
            locs = face_locations.copy()

        # --- RESET SCENE ---
        if len(noms_detectes) == 0:
            scene_deja_traitee = False

        # --- DECISION LOGIC ---
        if noms_detectes and not scene_deja_traitee and (maintenant - dernier_envoi > COOLDOWN_NOTIF):

            # SCENARIO A: UNKNOWN
            if "Inconnu" in noms_detectes:
                print("⚠️ Groupe inconnu. Accès bloqué.")
                # Lancement de l'upload en arrière-plan !
                threading.Thread(target=upload_inconnu_thread, args=(frame.copy(),), daemon=True).start()
                
                dernier_envoi = maintenant
                scene_deja_traitee = True

            # SCENARIO B: ALL KNOWN
            else:
                # Vérification instantanée depuis le cache, aucune attente réseau
                noms_interdits = [nom for nom in set(noms_detectes) if nom in blacklist_cache]
                personne_blacklistee = len(noms_interdits) > 0

                if personne_blacklistee:
                    liste = ", ".join(noms_interdits)
                    print(f"🚫 REFUSÉ: {liste}")
                    # Upload en arrière-plan
                    threading.Thread(target=upload_connu_thread, args=(frame.copy(), liste, "Refuser"), daemon=True).start()
                else:
                    liste = ", ".join(set(noms_detectes))
                    print(f"🔓 AUTORISÉ: {liste}")
                    # Upload en arrière-plan
                    threading.Thread(target=upload_connu_thread, args=(frame.copy(), liste, "Accepter"), daemon=True).start()

                dernier_envoi = maintenant
                scene_deja_traitee = True

        # --- CHECK MANUAL DECISION ---
        if id_en_attente and not is_checking_decision and (maintenant - check_timer > 2):
            check_timer = maintenant
            # Vérification réseau en arrière-plan
            threading.Thread(target=check_decision_thread, daemon=True).start()

        # ===============================
        # 🎯 TRACKING + DRAWING
        # ===============================
        cv2.putText(frame, "TEST DRAW", (50, 50),
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
        
        for (top, right, bottom, left), nom in zip(locs, noms_detectes):
            
            # Scale back
            top *= 4
            right *= 4
            bottom *= 4
            left *= 4

            # Color logic
            if nom == "Inconnu":
                color = (0, 0, 255)
                label = "Inconnu"
            elif nom in blacklist_cache:
                color = (0, 0, 255)
                label = f"{nom} (REFUSÉ)"
            else:
                color = (0, 255, 0)
                label = nom

            # Draw box
            cv2.rectangle(frame, (left, top), (right, bottom), color, 2)
            cv2.rectangle(frame, (left, bottom - 35), (right, bottom), color, cv2.FILLED)
            cv2.putText(frame, label, (left + 6, bottom - 6),
                        cv2.FONT_HERSHEY_DUPLEX, 0.8, (255, 255, 255), 1)

        cv2.imshow("Surveillance", frame)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()