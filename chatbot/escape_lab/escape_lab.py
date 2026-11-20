#!/usr/bin/env python3
"""
Escape the Lab: a Telegram bot mini-game (complete solution).

The player is locked in the Smart IoT lab and must clear three rooms:

    Room 1 - The keypad   -> inline keyboards, callback queries, editing messages
    Room 2 - The quiz     -> Telegram quiz polls and poll answers
    Room 3 - The bomb     -> JobQueue (scheduled jobs) and the dice emoji

Run it with:
    python chatbot/escape_lab/escape_lab.py

Requirements:
    pip install "python-telegram-bot[job-queue]" python-dotenv
"""
import asyncio
import logging
import os
import time

from dotenv import load_dotenv
from telegram import (
    BotCommand,
    InlineKeyboardButton,
    InlineKeyboardMarkup,
    Poll,
    Update,
)
from telegram.constants import ParseMode
from telegram.ext import (
    Application,
    CallbackQueryHandler,
    CommandHandler,
    ContextTypes,
    MessageHandler,
    PollAnswerHandler,
    filters,
)

# --- Configuration -----------------------------------------------------------
# The bot token lives in siotd.conf, created by setup.sh.
# Set SIOTD_CONF to use another file.
CONFIG_FILE = os.environ.get(
    "SIOTD_CONF", os.path.expanduser("~/Desktop/SIoTD-Projects/siotd.conf")
)
load_dotenv(CONFIG_FILE)
TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
if not TOKEN:
    raise ValueError(f"TELEGRAM_BOT_TOKEN not set (expected in {CONFIG_FILE})")

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)
logging.getLogger("httpx").setLevel(logging.WARNING)  # hide one log line per request
logger = logging.getLogger(__name__)

# --- Game content ------------------------------------------------------------
STORY = (
    "🔒 <b>Escape the Lab</b>\n\n"
    "It's late. You stayed in the Smart IoT lab to finish your project and... "
    "<i>click</i>. The door locked behind you.\n\n"
    "Three rooms stand between you and the exit. Good luck!"
)

KEYPAD_RIDDLE = (
    "🔢 <b>Room 1: The keypad</b>\n\n"
    "The door is locked by a 4-digit code.\n"
    "<i>Hint: it's the default port our Mosquitto MQTT broker listens on.</i>"
)
KEYPAD_CODE = "1883"

# "correct" is the index of the right option (0-based).
QUIZ = [
    {
        "question": "Which protocol does our weather station use to publish sensor readings?",
        "options": ["HTTP", "MQTT", "FTP", "SMTP"],
        "correct": 1,
        "explanation": "MQTT: lightweight publish/subscribe over a broker.",
    },
    {
        "question": "What does the DHT11 sensor measure?",
        "options": ["Temperature and humidity", "Light and sound", "Distance", "Air pressure"],
        "correct": 0,
    },
    {
        "question": "With gpiozero Button(pin, pull_up=False), what does the pin read when the button is pressed?",
        "options": ["LOW (0 V)", "It floats", "HIGH (3.3 V)", "5 V"],
        "correct": 2,
        "explanation": "The button connects the pin to 3.3 V, pulling it HIGH.",
    },
    {
        "question": "Which format do we export YOLO to for fast inference on the Raspberry Pi?",
        "options": ["ONNX", "CoreML", "TensorFlow.js", "NCNN"],
        "correct": 3,
    },
]

BOMB_SECONDS = 30          # time to defuse the bomb
BOMB_TICK = 3              # seconds between countdown updates (Telegram rate-limits edits)
DICE_ANIMATION_SECONDS = 4  # wait for the dice animation before revealing the result


# --- Lobby -------------------------------------------------------------------
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """/start: tell the story and show the 'Enter the lab' button."""
    stop_bomb(update.effective_chat.id, context)
    context.user_data.clear()
    keyboard = InlineKeyboardMarkup(
        [[InlineKeyboardButton("🚪 Enter the lab", callback_data="enter")]]
    )
    await update.message.reply_text(STORY, parse_mode=ParseMode.HTML, reply_markup=keyboard)


async def enter(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """'Enter the lab' button: start the timer and show the keypad."""
    query = update.callback_query
    await query.answer()
    context.user_data.update(room="keypad", code="", start_time=time.monotonic())
    await query.edit_message_text(
        keypad_text(""), parse_mode=ParseMode.HTML, reply_markup=keypad_markup()
    )


# --- Room 1: the keypad ------------------------------------------------------
def keypad_text(code: str) -> str:
    """Riddle plus the digits typed so far, e.g. '1 8 _ _'."""
    display = " ".join(code.ljust(len(KEYPAD_CODE), "_"))
    return f"{KEYPAD_RIDDLE}\n\n<code>[ {display} ]</code>"


def keypad_markup() -> InlineKeyboardMarkup:
    """A phone-style keypad: 1-9, then ⌫ 0 ✅."""
    rows = [
        [InlineKeyboardButton(str(d), callback_data=f"key:{d}") for d in range(first, first + 3)]
        for first in (1, 4, 7)
    ]
    rows.append([
        InlineKeyboardButton("⌫", callback_data="key:del"),
        InlineKeyboardButton("0", callback_data="key:0"),
        InlineKeyboardButton("✅", callback_data="key:ok"),
    ])
    return InlineKeyboardMarkup(rows)


async def keypad_press(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """A keypad button was pressed: update the code shown in the same message."""
    query = update.callback_query
    if context.user_data.get("room") != "keypad":
        await query.answer("This door is already open. Send /start to play again.")
        return

    key = query.data.split(":")[1]
    code = context.user_data["code"]

    if key == "ok":
        if code == KEYPAD_CODE:
            await query.answer("🔓 Click!")
            await query.edit_message_text(
                "🔓 <b>Room 1 cleared!</b> The door opens with a creak...",
                parse_mode=ParseMode.HTML,
            )
            await start_quiz(query.message.chat_id, context)
            return
        await query.answer("❌ Wrong code! The display resets.", show_alert=True)
        new_code = ""
    elif key == "del":
        new_code = code[:-1]
        await query.answer()
    else:
        new_code = (code + key)[: len(KEYPAD_CODE)]
        await query.answer()

    # Telegram rejects an edit that doesn't change the message, so skip it.
    if new_code != code:
        context.user_data["code"] = new_code
        await query.edit_message_text(
            keypad_text(new_code), parse_mode=ParseMode.HTML, reply_markup=keypad_markup()
        )


# --- Room 2: the quiz --------------------------------------------------------
async def start_quiz(chat_id: int, context: ContextTypes.DEFAULT_TYPE) -> None:
    context.user_data.update(room="quiz", quiz_index=0, chat_id=chat_id)
    await context.bot.send_message(
        chat_id,
        "🎓 <b>Room 2: The professor's quiz</b>\n\n"
        f"The professor blocks the corridor. Answer {len(QUIZ)} questions to pass.",
        parse_mode=ParseMode.HTML,
    )
    await send_question(chat_id, context)


async def send_question(chat_id: int, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Send the current question as a Telegram quiz poll."""
    q = QUIZ[context.user_data["quiz_index"]]
    message = await context.bot.send_poll(
        chat_id,
        q["question"],
        q["options"],
        type=Poll.QUIZ,
        correct_option_id=q["correct"],
        explanation=q.get("explanation"),
        is_anonymous=False,  # otherwise Telegram doesn't tell the bot who answered
    )
    # Remember which poll we're waiting for.
    context.user_data["poll_id"] = message.poll.id


async def quiz_answer(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """The player answered a quiz poll."""
    answer = update.poll_answer
    if context.user_data.get("room") != "quiz" or answer.poll_id != context.user_data.get("poll_id"):
        return  # an old poll, or the player isn't in this room

    chat_id = context.user_data["chat_id"]
    q = QUIZ[context.user_data["quiz_index"]]

    if answer.option_ids != [q["correct"]]:
        await context.bot.send_message(chat_id, "❌ Wrong! The professor sighs. Try again.")
        await send_question(chat_id, context)
        return

    context.user_data["quiz_index"] += 1
    if context.user_data["quiz_index"] < len(QUIZ):
        await send_question(chat_id, context)
    else:
        await context.bot.send_message(
            chat_id, "✅ <b>Room 2 cleared!</b> The professor nods.", parse_mode=ParseMode.HTML
        )
        await start_bomb(chat_id, answer.user.id, context)


# --- Room 3: the bomb --------------------------------------------------------
def bomb_text(remaining: int) -> str:
    bar = "🟥" * round(10 * remaining / BOMB_SECONDS)
    return (
        "💣 <b>Room 3: The bomb</b>\n\n"
        "The exit is rigged! Send a 🎲 and roll a <b>6</b> to cut the right wire.\n\n"
        f"⏱ <b>{remaining}s</b> {bar}"
    )


async def start_bomb(chat_id: int, user_id: int, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Show the countdown and schedule a job that updates it every BOMB_TICK seconds."""
    context.user_data["room"] = "bomb"
    message = await context.bot.send_message(
        chat_id, bomb_text(BOMB_SECONDS), parse_mode=ParseMode.HTML
    )
    context.job_queue.run_repeating(
        bomb_tick,
        interval=BOMB_TICK,
        first=BOMB_TICK,
        chat_id=chat_id,
        user_id=user_id,  # gives the job access to context.user_data
        name=f"bomb-{chat_id}",
        data={"message_id": message.message_id, "remaining": BOMB_SECONDS},
    )


async def bomb_tick(context: ContextTypes.DEFAULT_TYPE) -> None:
    """Runs every BOMB_TICK seconds: update the countdown or explode."""
    job = context.job
    job.data["remaining"] -= BOMB_TICK

    if job.data["remaining"] <= 0:
        job.schedule_removal()
        context.user_data["room"] = None
        await context.bot.edit_message_text(
            "💥 <b>BOOM!</b> Too slow. Send /start to try again.",
            chat_id=job.chat_id,
            message_id=job.data["message_id"],
            parse_mode=ParseMode.HTML,
        )
        return

    await context.bot.edit_message_text(
        bomb_text(job.data["remaining"]),
        chat_id=job.chat_id,
        message_id=job.data["message_id"],
        parse_mode=ParseMode.HTML,
    )


def stop_bomb(chat_id: int, context: ContextTypes.DEFAULT_TYPE) -> None:
    for job in context.job_queue.get_jobs_by_name(f"bomb-{chat_id}"):
        job.schedule_removal()


async def roll(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """The player sent a 🎲. Telegram picks the value; we just read it."""
    if context.user_data.get("room") != "bomb":
        await update.message.reply_text("🎲 Nice roll, but there's no bomb here... yet.")
        return

    value = update.message.dice.value
    # Don't spoil the result before the animation ends. This works because
    # the application handles updates concurrently (see main()).
    await asyncio.sleep(DICE_ANIMATION_SECONDS)
    if context.user_data.get("room") != "bomb":
        return  # the bomb exploded while the dice was rolling

    if value != 6:
        await update.message.reply_text(f"✂️ You rolled {value}. Wrong wire! Roll again!")
        return

    stop_bomb(update.effective_chat.id, context)
    context.user_data["room"] = "escaped"
    elapsed = time.monotonic() - context.user_data["start_time"]
    await update.message.reply_text(
        f"🎉 <b>You cut the right wire and ESCAPED in {elapsed:.0f} seconds!</b>\n\n"
        "Challenge your classmates to beat your time. /start to play again.",
        parse_mode=ParseMode.HTML,
    )


# --- Main ----------------------------------------------------------------------
async def post_init(application: Application) -> None:
    """Fill the command menu shown next to the chat's text box."""
    await application.bot.set_my_commands([BotCommand("start", "Start (or restart) the escape")])


def main() -> None:
    application = (
        Application.builder()
        .token(TOKEN)
        .post_init(post_init)
        .concurrent_updates(True)  # one player's dice roll doesn't block the others
        .build()
    )
    if application.job_queue is None:
        raise RuntimeError('JobQueue missing: pip install "python-telegram-bot[job-queue]"')

    application.add_handler(CommandHandler("start", start))
    application.add_handler(CallbackQueryHandler(enter, pattern="^enter$"))
    application.add_handler(CallbackQueryHandler(keypad_press, pattern="^key:"))
    application.add_handler(PollAnswerHandler(quiz_answer))
    application.add_handler(MessageHandler(filters.Dice.DICE, roll))

    logger.info("Escape the Lab is running. Press Ctrl+C to stop.")
    # Poll answers are only delivered if we ask for every update type.
    application.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
