#!/bin/bash
set -e

echo "Stoping java process."
echo "Stoping java process." > /proc/1/fd/1
kill `pidof java` 2> /dev/null || true