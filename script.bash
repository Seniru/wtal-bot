#!/bin/bash

function run() {
    python -u src/main.py || run
}

run