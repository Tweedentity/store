#!/usr/bin/env bash

contracts=(
"TweedentityStore"
"TweedentityManager"
"TweedentityVerifier"
)

for c in "${contracts[@]}"
do
  truffle-flattener "contracts/$c.sol" > "flattened/$c-flattened.sol"
done
