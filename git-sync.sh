#!/bin/sh
set -e

REPO_URL="${REPO_URL:-https://github.com/blaaw/trial-webpage}"
DEST="/git-site"

if [ -d "$DEST/.git" ]; then
  echo "Repositorio ya existe, haciendo git pull..."
  git -C "$DEST" pull --ff-only
  echo "Repositorio actualizado."
else
  echo "Clonando repositorio por primera vez..."
  git clone "$REPO_URL" "$DEST"
  echo "Repositorio clonado."
fi

