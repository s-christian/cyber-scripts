#!/usr/bin/env python3

prefixes_file = open("./all_prefixes.txt", "w")

# Printable ASCII characters
prefix_chars = []
for i in range(33, 127):
    prefix_chars.append(chr(i))

for x in prefix_chars:
    for y in prefix_chars:
        for z in prefix_chars:
            prefixes_file.write(f"{x}{y}{z}\n")
