# Arrow CRM Production Deployment Checklist

## Environment Variables Required

### Backend (Rails API)

```bash
# Database
CRM2_DB_HOST=your-db-host
CRM2_DB_PORT=5432
CRM2_DB_NAME=crm2_production
CRM2_DB_USER=crm2_user
CRM2_DB_PASSWORD=secure_password_here

# AWS S3 (Required for file storage)
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
AWS_BUCKET=arrow-crm-documents-production

# Optional
RAILS_LOG_LEVEL=info
CORS_ALLOWED_ORIGINS=https://custom-domain.com
```

### Frontend (Next.js)

```bash
NEXT_PUBLIC_API_BASE_URL=https://your-api-domain.com
```

## Pre-Deployment Steps

### 1. Run Database Migrations

```bash
rails db:migrate
```

Key migrations for S3 support:
- `20260130100001_make_document_legacy_fields_nullable.rb` - Makes legacy fields nullable

### 2. Configure S3 Bucket

See `docs/S3_SETUP.md` for detailed instructions:
- Create bucket with private access
- Configure CORS policy
- Create IAM user with appropriate permissions

### 3. Verify ActiveStorage Tables

```bash
rails runner "puts ActiveStorage::Blob.count"
```

If tables don't exist:
```bash
rails active_storage:install
rails db:migrate
```

## Post-Deployment Verification

### Quick Smoke Test

1. **Upload Test**
   - Upload a PDF from Documents page
   - Verify it appears in the list
   - Refresh page - should persist

2. **Preview Test**
   - Click on uploaded PDF
   - Should open inline in browser
   - No CORS or access errors

3. **Download Test**
   - Click download button
   - File should download correctly

4. **Link Test**
   - Upload from Deal sidebar
   - Document should auto-link to Deal
   - Appears in both Documents page and Deal view

### Console Verification

```bash
# Check recent uploads
rails runner "puts Document.order(created_at: :desc).limit(5).pluck(:id, :name)"

# Check ActiveStorage blobs
rails runner "puts ActiveStorage::Blob.order(created_at: :desc).limit(5).pluck(:id, :filename)"

# Check blob service
rails runner "puts ActiveStorage::Blob.service.class"
# Should output: ActiveStorage::Service::S3Service (in production)
```

## Configuration Summary

| Component | File | Setting |
|-----------|------|---------|
| S3 Service | `config/storage.yml` | `amazon` service with ENV vars |
| Production Storage | `config/environments/production.rb` | `config.active_storage.service = :amazon` |
| URL Expiration | `config/environments/production.rb` | `config.active_storage.service_urls_expire_in = 1.hour` |
| CORS | `config/initializers/cors.rb` | Allows specified origins |
| Documents | `app/controllers/api/documents_controller.rb` | Handles file uploads and URL generation |

## Troubleshooting

### "Access Denied" on preview/download
- Check S3 CORS configuration
- Verify IAM permissions include GetObject

### Upload fails silently
- Check browser console for errors
- Verify AWS credentials are set

### Files disappear after refresh
- Check database connection
- Verify `active_storage_blobs` table has records
- Check Rails logs for errors

### Signed URLs expired
- Default expiration is 1 hour
- Refresh page to get new URLs
