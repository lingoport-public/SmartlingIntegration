#!/bin/bash
./test/bats/bin/bats ./test/test_send_to_smartling.bats -o test/log --print-output-on-failure --show-output-of-passing-tests  "$@"
./test/bats/bin/bats ./test/test_retrieve_from_smartling.bats -o test/log --print-output-on-failure --show-output-of-passing-tests  "$@"
