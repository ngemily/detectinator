#! /usr/bin/zsh

# Generate 256 random RGB colors.
#
# Usage:
#   ./color.sh

n=$(echo "2 ^ 16" | bc);
echo $n;
for i in {0..$n}; do
    R=$[${RANDOM}%255]
    G=$[${RANDOM}%255]
    B=$[${RANDOM}%255]

    printf "%02x%02x%02x\n" $R $G $B
done
