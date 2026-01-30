# AWS S3 Setup for Arrow CRM

This document describes how to configure AWS S3 for ActiveStorage in production.

## Environment Variables

Add these to your production environment (e.g., Render, Heroku, Railway):

```bash
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here
AWS_REGION=us-east-1
AWS_BUCKET=arrow-crm-documents-production
```

## S3 Bucket Setup

### 1. Create the Bucket

1. Go to AWS S3 Console
2. Click "Create bucket"
3. Name: `arrow-crm-documents-production` (or your preferred name)
4. Region: Choose your preferred region (e.g., `us-east-1`)
5. **Block Public Access**: Keep ALL settings ENABLED (bucket should be private)
6. Click "Create bucket"

### 2. Configure CORS

CORS configuration is required for the frontend to preview/download files via signed URLs.

Go to the bucket → Permissions → CORS configuration → Edit:

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "HEAD", "PUT", "POST"],
    "AllowedOrigins": [
      "https://arrow-crm-frontend.vercel.app",
      "http://localhost:3000",
      "http://localhost:3001"
    ],
    "ExposeHeaders": [
      "Content-Type",
      "Content-Disposition",
      "Content-Length",
      "ETag"
    ],
    "MaxAgeSeconds": 3600
  }
]
```

**Important**: Replace `https://arrow-crm-frontend.vercel.app` with your actual production frontend domain.

### 3. Create IAM User/Policy

Create an IAM user with programmatic access and attach this policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::arrow-crm-documents-production",
        "arn:aws:s3:::arrow-crm-documents-production/*"
      ]
    }
  ]
}
```

## ActiveStorage Configuration

The Rails app is already configured. Key files:

- `config/storage.yml` - Defines the S3 service configuration
- `config/environments/production.rb` - Sets `config.active_storage.service = :amazon`

### Signed URL Expiration

Signed URLs expire after **1 hour** by default (configured in `production.rb`):
```ruby
config.active_storage.service_urls_expire_in = 1.hour
```

## Verification Checklist

After deployment, verify:

- [ ] `AWS_ACCESS_KEY_ID` env var is set
- [ ] `AWS_SECRET_ACCESS_KEY` env var is set
- [ ] `AWS_REGION` env var is set (defaults to us-east-1)
- [ ] `AWS_BUCKET` env var is set
- [ ] S3 bucket exists and is accessible
- [ ] CORS is configured on the bucket
- [ ] Files upload successfully
- [ ] Files download via signed URLs
- [ ] PDF/image previews work in browser

## Testing Upload Flow

1. Navigate to Documents page in the app
2. Upload a PDF or image file
3. Refresh the page - document should persist
4. Click preview - should open in browser
5. Click download - should download the file

## Troubleshooting

### Upload fails with 403 Forbidden
- Check IAM credentials have correct permissions
- Verify bucket name matches `AWS_BUCKET` env var

### Preview shows "Access Denied"
- Check CORS configuration on S3 bucket
- Verify `AllowedOrigins` includes your frontend domain

### Files not persisting after refresh
- Check database connection
- Verify the `active_storage_blobs` table exists
- Run `rails active_storage:install` if needed

### Signed URL expired
- URLs are valid for 1 hour by default
- Refresh the page to get new signed URLs
