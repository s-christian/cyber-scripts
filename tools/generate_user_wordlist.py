#!/usr/bin/env python3

username = "ckung"
password = "canulate"

prefixes_file = open("./all_prefixes.txt", "r")
wordlist_file = open(f"./brute_{username}.txt", "w")

for prefix in prefixes_file.readlines():
    wordlist_file.write(f"{prefix.strip()}{password}\n")
