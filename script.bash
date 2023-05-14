#!/bin/bash

sh /wait-for-it.sh "db:3306" --timeout=60

function run() {
    python -u src/main.py || run
}

run