import telebot
import os
from dotenv import load_dotenv
from telebot.types import InlineKeyboardMarkup, InlineKeyboardButton
from door_controller import open_door

# Load the variables from the .env file
load_dotenv()

# These must match your .env file EXACTLY:
BOT_TOKEN = os.getenv("TELEGRAM_TOKEN") 
CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")

# Initialize the bot
bot = telebot.TeleBot(BOT_TOKEN)

def send_visitor_alert(image_path="alerte.jpg"):
    """Sends the saved image to Telegram with Open/Ignore buttons."""
    markup = InlineKeyboardMarkup()
    btn_open = InlineKeyboardButton("🔓 Open Door", callback_data="open_door")
    btn_ignore = InlineKeyboardButton("🚫 Ignore", callback_data="ignore")
    markup.add(btn_open, btn_ignore)

    try:
        with open(image_path, 'rb') as photo:
            bot.send_photo(CHAT_ID, photo=photo, 
                           caption="⚠️ Unknown visitor detected! What should I do?", 
                           reply_markup=markup)
        print("Telegram alert sent successfully.")
    except Exception as e:
        print(f"Error sending Telegram alert: {e}")

@bot.callback_query_handler(func=lambda call: True)
def handle_query(call):
    """Handles the button presses."""
    if call.data == "open_door":
        open_door() # Triggers the door!
        bot.answer_callback_query(call.id, "Opening door...")
        bot.edit_message_caption(caption="✅ You chose to OPEN the door.", 
                                 chat_id=call.message.chat.id, 
                                 message_id=call.message.message_id)
    elif call.data == "ignore":
        bot.answer_callback_query(call.id, "Ignored.")
        bot.edit_message_caption(caption="🚫 You IGNORED the visitor.", 
                                 chat_id=call.message.chat.id, 
                                 message_id=call.message.message_id)

# Start the bot listening for button presses in the background
def start_bot():
    print("Telegram bot is listening...")
    bot.infinity_polling()

if __name__ == "__main__":
    start_bot()