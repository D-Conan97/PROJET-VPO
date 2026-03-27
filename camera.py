import cv2
import mediapipe as mp
import time
import math
import os
import face_recognition
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
# Import your other files!
from alarme import declencher_alarme
from door_controller import open_door
from telegram_bot import send_visitor_alert

# --- 1. FACE RECOGNITION SETUP ---
KNOWN_FACES_DIR = "visages_connus"
known_face_encodings = []

def load_known_faces():
    """Scans the visages_connus folder to learn allowed faces."""
    print("Loading known faces...")
    # Make sure the folder exists so it doesn't crash
    if not os.path.exists(KNOWN_FACES_DIR):
        os.makedirs(KNOWN_FACES_DIR)
        
    for filename in os.listdir(KNOWN_FACES_DIR):
        if filename.endswith(".jpg") or filename.endswith(".png"):
            filepath = os.path.join(KNOWN_FACES_DIR, filename)
            image = face_recognition.load_image_file(filepath)
            encodings = face_recognition.face_encodings(image)
            if encodings:
                known_face_encodings.append(encodings[0])
    print(f"Loaded {len(known_face_encodings)} known faces.")

# Run this immediately when the file is imported
load_known_faces()


# --- 2. VIOLENCE DETECTION SETUP ---
prev_wrist_x, prev_wrist_y = 0, 0
prev_time = time.time()
VELOCITY_THRESHOLD = 0.5 

def check_for_violence(detection_result):
    """Calculates wrist speed using the new MediaPipe Tasks API."""
    global prev_wrist_x, prev_wrist_y, prev_time
    
    # Grab the skeleton of the first person detected [0]
    landmarks = detection_result.pose_landmarks[0] 
    right_wrist = landmarks[16] # Landmark 16 = Right Wrist
    
    curr_wrist_x, curr_wrist_y = right_wrist.x, right_wrist.y
    curr_time = time.time()
    
    delta_t = curr_time - prev_time
    if delta_t > 0:
        distance = math.sqrt((curr_wrist_x - prev_wrist_x)**2 + (curr_wrist_y - prev_wrist_y)**2)
        velocity = distance / delta_t
        
        if velocity > VELOCITY_THRESHOLD:
            print(f"⚠️ VIOLENCE DETECTED! Velocity: {velocity:.2f}")
            declencher_alarme()
            
    prev_wrist_x, prev_wrist_y = curr_wrist_x, curr_wrist_y
    prev_time = curr_time


# --- 3. MAIN CAMERA LOOP ---
def start_camera():
    # NEW MEDIAPIPE SETUP: Load your .task file
    base_options = python.BaseOptions(model_asset_path='pose_landmarker_heavy.task')
    options = vision.PoseLandmarkerOptions(
        base_options=base_options,
        output_segmentation_masks=False)
    detector = vision.PoseLandmarker.create_from_options(options)
    
    cap = cv2.VideoCapture(0)
    print("Starting camera feed...")

    # Cooldown timers
    last_alert_time = 0
    last_door_open_time = 0
    ALERT_COOLDOWN = 30  
    DOOR_COOLDOWN = 10   
    frame_counter = 0

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        frame = cv2.flip(frame, 1)    
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        current_time = time.time()
        frame_counter += 1

        # --- A. FACE RECOGNITION (Runs every 5 frames) ---
        if frame_counter % 5 == 0:
            face_locations = face_recognition.face_locations(rgb_frame)
            face_encodings = face_recognition.face_encodings(rgb_frame, face_locations)

            for face_encoding in face_encodings:
                matches = face_recognition.compare_faces(known_face_encodings, face_encoding)
                
                if True in matches:
                    if current_time - last_door_open_time > DOOR_COOLDOWN:
                        print("✅ Known face detected! Opening door...")
                        open_door()
                        last_door_open_time = current_time
                else:
                    if current_time - last_alert_time > ALERT_COOLDOWN:
                        print("⚠️ Unknown face! Saving photo and sending to Telegram...")
                        cv2.imwrite("alerte.jpg", frame) 
                        send_visitor_alert("alerte.jpg") 
                        last_alert_time = current_time

        # --- B. VIOLENCE DETECTION (NEW MEDIAPIPE API) ---
        # Convert the frame into a MediaPipe Image object
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
        
        # Detect poses
        detection_result = detector.detect(mp_image)
        
        # If at least one person's skeleton is found, run the math
        if detection_result.pose_landmarks:
            check_for_violence(detection_result)

        # Show the video feed
        cv2.imshow("Security Camera", frame)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()