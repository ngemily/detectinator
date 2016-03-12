#! /usr/bin/zsh

# Generate 256 random RGB colors.
#
# Usage:
#   ./color.sh

for i in {0..255}; do
    R=$[${RANDOM}%255]
    G=$[${RANDOM}%255]
    B=$[${RANDOM}%255]

    printf "%02x%02x%02x\n" $R $G $B
done
