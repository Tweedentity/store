#!/usr/bin/env bash

rm flattened/*

contracts=(
"TweedentityStore"
"TweedentityManager"
"TweedentityClaimer"
)

for c in "${contracts[@]}"
do
  truffle-flattener "contracts/$c.sol" > "flattened/$c-flattened.sol"
done
