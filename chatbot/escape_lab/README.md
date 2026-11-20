# Escape the Lab 🔒

A 60-minute lab: build a Telegram mini-game where the player escapes the Smart IoT lab
through three rooms. Each room teaches one Telegram bot feature.

| Room | What happens | Telegram feature |
|---|---|---|
| Lobby | `/start` tells the story, a button opens the lab | Commands, HTML formatting, inline buttons |
| 1. The keypad | Type the door code on an inline keypad; the same message updates as you type | Callback queries, editing messages |
| 2. The quiz | Answer course questions as Telegram quiz polls | `send_poll`, poll answers |
| 3. The bomb | A live countdown; send 🎲 and roll a 6 before it hits zero | JobQueue (scheduled jobs), dice |

## Files

- `escape_lab_starter.py`: the skeleton you complete. Content, helpers and `main()` are ready; fill in TODO 1 to TODO 9.
- `escape_lab.py`: the complete solution.

## Before you start

1. Create your own bot with [@BotFather](https://t.me/BotFather) (`/newbot`) and copy the token.
2. Put it in `~/Desktop/SIoTD-Projects/siotd.conf`:
   ```bash
   export TELEGRAM_BOT_TOKEN="123456:ABC..."
   ```
3. Install the dependencies (the `job-queue` extra is needed for the bomb timer):
   ```bash
   pip install "python-telegram-bot[job-queue]" python-dotenv
   ```
4. Run the starter, then open your bot in Telegram:
   ```bash
   python chatbot/escape_lab/escape_lab_starter.py
   ```
   Restart it (Ctrl+C, then run again) after each TODO.

## Suggested timing

| Minutes | TODOs | Check in Telegram |
|---|---|---|
| 0-10 | 1, 2 | `/start` shows the story; the button replaces it with the riddle |
| 10-25 | 3, 4 | The keypad appears, digits show up as you tap, `1883` + ✅ opens the door |
| 25-40 | 5, 6 | The quiz polls arrive one after another; a wrong answer repeats the question |
| 40-55 | 7, 8, 9 | The countdown ticks; rolling a 6 wins, waiting too long explodes |
| 55-60 | | Play against your classmates: who escapes fastest? |

## Bonus rooms (if you finish early)

- **Leaderboard:** store each player's best time in `context.bot_data` and add a `/leaderboard` command.
- **The compass:** add a room with a reply keyboard button `KeyboardButton("📍 Share location", request_location=True)`; unlock it only if the player is within 1 km of the university.
- **The photo:** send a picture with `send_photo` hiding a word in it; the player must type the word.
