import asyncio
import os

import telegram
from dotenv import load_dotenv

# Settings live in siotd.conf, created by setup.sh. Set SIOTD_CONF to use another file.
CONFIG_FILE = os.environ.get(
    "SIOTD_CONF", os.path.expanduser("~/Desktop/SIoTD-Projects/siotd.conf")
)
load_dotenv(CONFIG_FILE)
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
if not TELEGRAM_BOT_TOKEN:
    raise ValueError(f"TELEGRAM_BOT_TOKEN not set (expected in {CONFIG_FILE})")


async def main():
  bot = telegram.Bot(TELEGRAM_BOT_TOKEN)
  async with bot:
    print(await bot.get_me())

if __name__ == '__main__':
  asyncio.run(main())
