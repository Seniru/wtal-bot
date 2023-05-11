#!/bin/bash

function run() {
    python src/main.py || run
}

run