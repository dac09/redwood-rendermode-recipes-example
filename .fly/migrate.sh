#!/bin/sh

set -ex

# This command pushes us over 256MB of RAM at release time
# yarn rw prisma migrate deploy

# ⚠️ Demo Only: seed the database for demo, do NOT copy this line
npx prisma db seed
################

# This alternative command uses less memory
npx prisma migrate deploy --schema /app/api/db/schema.prisma
