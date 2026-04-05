import cv2
import time
from supabase import create_client, Client
from config import URL, KEY, BUCKET_PHOTOS, TABLE_VISITEURS

supabase: Client = create_client(URL, KEY)


def uploader_et_enregistrer(frame, nom="Inconnu", status="pending"):
    try:
        img_name = f"visit_{int(time.time())}.jpg"

        ok, buffer = cv2.imencode(
            ".jpg", frame, [int(cv2.IMWRITE_JPEG_QUALITY), 70]
        )
        if not ok:
            return None

        storage_path = f"public/{img_name}"
        supabase.storage.from_(BUCKET_PHOTOS).upload(storage_path, buffer.tobytes())

        img_url = supabase.storage.from_(BUCKET_PHOTOS).get_public_url(storage_path)

        data = {
            "nom_du_visiteur": nom,
            "status": status,
            "image_url": img_url,
            "situation": "Detecte par camera",
        }

        res = supabase.table(TABLE_VISITEURS).insert(data).execute()

        if res.data:
            return {
                "id": res.data[0]["id"],
                "image_url": img_url,
            }

        return None

    except Exception as e:
        print(f"Erreur Supabase Utils: {e}")
        return None


def verifier_decision(id_ligne):
    try:
        res = supabase.table(TABLE_VISITEURS).select("status").eq("id", id_ligne).execute()
        if res.data:
            return res.data[0]["status"]
        return "pending"
    except Exception:
        return "pending"
