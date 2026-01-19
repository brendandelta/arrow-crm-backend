# Arrow CRM - Backend

Rails 7.2 JSON API backend.

## Requirements

- Ruby 3.3+
- PostgreSQL 14+

## Quick Setup

```bash
bin/setup
```

This single command will:
1. Install Ruby dependencies
2. Create PostgreSQL role `crm2_user`
3. Create databases `crm2_development` and `crm2_test`
4. Run migrations

## Manual Role Creation

If `bin/setup` fails with permission errors creating the PostgreSQL role, run these commands manually:

```bash
psql postgres
```

Then in psql:

```sql
CREATE ROLE crm2_user WITH LOGIN PASSWORD 'crm2_password' CREATEDB;
\q
```

Then re-run:

```bash
bin/setup
```

## Run

```bash
bin/rails server
```

The API will be available at http://localhost:5050.

## Verify Database Connection

```bash
bin/rails runner "puts ActiveRecord::Base.connection.current_database"
```

Expected output: `crm2_development`

## Database Configuration

Uses app-specific environment variables (won't conflict with other apps):

| Variable | Default |
|----------|---------|
| `CRM2_DB_HOST` | localhost |
| `CRM2_DB_PORT` | 5432 |
| `CRM2_DB_NAME` | crm2_development |
| `CRM2_DB_TEST_NAME` | crm2_test |
| `CRM2_DB_USER` | crm2_user |
| `CRM2_DB_PASSWORD` | crm2_password |

See `.env.example` for reference.

## API Endpoints

All API routes are namespaced under `/api/v1`.

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/v1/health | Health check |
