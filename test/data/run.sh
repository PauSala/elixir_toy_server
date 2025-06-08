#!/bin/bash

if [ -z "$1" ]; then
 echo "Usage: $0 <filename>"
  exit 1
fi

DEFAULT_PREFIX_PATH="./test/data/" 
REQUESTS_FILE="${DEFAULT_PREFIX_PATH}$1" 

if [ ! -f "$REQUESTS_FILE" ]; then
  echo "Error: File '$REQUESTS_FILE' not found or is not a regular file."
  exit 1
fi

echo "Sending request from '$REQUESTS_FILE' to 127.0.0.1:4040..."

(cat "$REQUESTS_FILE"; cat) | telnet 127.0.0.1 4040