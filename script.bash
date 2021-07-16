cd discordslashcommands
pip install -r requirements.txt
python setup.py install
cd ..

function run() {
    python src/main.py || run
}

run