import threading
import time
from telegram_bot import start_bot
from camera import start_camera

def main():
    print("🛡️ Starting Smart Door Security System...")

    # 1. Start the Telegram Bot in a background thread
    # daemon=True means this thread will automatically die when you close the camera
    bot_thread = threading.Thread(target=start_bot, daemon=True)
    bot_thread.start()
    
    # Give the bot a second to boot up before opening the camera
    time.sleep(1)

    # 2. Start the Camera in the MAIN thread
    # This will block the main thread and run forever until you press 'q'
    start_camera()

    print("🛑 System shut down successfully.")

if __name__ == "__main__":
    main()