import asyncio
import telegram

async def main():
  bot = telegram.Bot()
  async with bot:
    print(await bot.get_me(TELEGRAM_BOT_TOKEN))

if __name__ == '__main__':
  asyncio.run(main())
