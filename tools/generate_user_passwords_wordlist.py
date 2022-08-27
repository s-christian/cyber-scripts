#!/usr/bin/env python3

username = "hkochi"
prefix = "cE{"

passwords_file = open("./passwords.txt", "r")
wordlist_file = open(f"./brute_{username}.txt", "w")

for password in passwords_file.readlines():
    wordlist_file.write(f"{prefix}{password.strip()}\n")
