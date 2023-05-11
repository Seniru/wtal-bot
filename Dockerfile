FROM python:3.11

WORKDIR /wtal-bot
COPY . .

RUN pip install --no-cache-dir -r requirements.txt

CMD ["./script.bash"]
