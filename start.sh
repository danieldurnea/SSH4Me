#!/bin/bash

# Start the SSH daemon in the background
/usr/sbin/sshd

# Persistent tunnel with connection logging
while true; do
  echo "=== Establishing Tunnel ==="
  ssh -o ExitOnForwardFailure=yes \
      -o ServerAliveInterval=60 \
      -o StrictHostKeyChecking=no \
      -R 80:localhost:22 \
      danieldurnearoot@localhost.run

  # Sleep before reconnecting
  echo "=== Tunnel Disconnected - Retrying in 10s ==="
  sleep 10
done
