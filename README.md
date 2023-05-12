# Wtal 
> Discord and Transformice bot for the tribe **We talk a Lot**

### Developing

First clone this repository to your machine
```bash
git clone https://github.com/We-Talk-a-Lot/wtal-bot
```

Then set up the following environment variables in `.env`
```env
USERNAME=TRANSFORMICE_NICKNAME_OF_BOT
PASSWORD=TRANSFORMICE_PASSWORD_OF_BOT
DISCORD=DISCORD_TOKEN
```
Replace `TRANSFORMICE_NICKNAME_OF_BOT`, `TRANSFORMICE_PASSWORD_OF_BOT` and `DISCORD_TOKEN` with your secret values

If you have docker installed in your machine follow the following steps to run the bot. Otherwise jump [here](#running-without-docker)

#### Running with Docker
```bash
sudo docker pull senirup/wtal-bot
sudo docker-compose up
```

### Running without Docker

First install the dependencies
```bash
python -m pip install -r requirements.txt
```

Then run
```bash
./script.bash
#or
python src/main.py
```
