import os
import subprocess

def declencher_alarme():
    print("🚨🚨🚨 ALARME SONORE ACTIVÉE ! 🚨🚨🚨")
    
    # Path to a sound file on your Mac
    sound_file = "/System/Library/Sounds/Glass.aiff" # Default Mac sound
    
    # Check if file exists, then play it using subprocess
    if os.path.exists(sound_file):
        # subprocess.run is safe and won't block your Python script
        subprocess.Popen(["afplay", sound_file])
    else:
        print("Sound file not found.")
        