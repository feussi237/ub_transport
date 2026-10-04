#!/bin/sh
set -e

# Config/route caches are safe to build now — all the env vars they read
# (APP_KEY, DB_*, etc.) are already injected by Render at container start.
php artisan config:cache
php artisan route:cache

php artisan migrate --force

# DemoDataSeeder and OctoberTripsSeeder are both idempotent (firstOrCreate
# throughout), so re-running them on every deploy is safe and just fills in
# anything missing rather than duplicating data.
php artisan db:seed --force

exec php artisan serve --host 0.0.0.0 --port "${PORT:-8000}"
