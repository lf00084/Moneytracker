#!/usr/bin/env bash
set -e

echo "=== Running database migrations ==="
npx tsx scripts/migrate.ts

echo "=== Building project ==="
npm run build

echo "=== All updates applied successfully ==="
