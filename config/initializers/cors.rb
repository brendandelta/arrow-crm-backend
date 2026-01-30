# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Default allowed origins for local development
DEFAULT_ORIGINS = [
  "http://localhost:3000",
  "http://localhost:3001",
  "http://localhost:5173"
].freeze

# Production origins (can be extended via CORS_ALLOWED_ORIGINS env var)
PRODUCTION_ORIGINS = [
  "https://arrow-crm-frontend.vercel.app"
].freeze

# Build final origins list
# Additional origins can be added via comma-separated CORS_ALLOWED_ORIGINS env var
ALLOWED_ORIGINS = (DEFAULT_ORIGINS + PRODUCTION_ORIGINS + ENV.fetch("CORS_ALLOWED_ORIGINS", "").split(",").map(&:strip).reject(&:empty?)).uniq.freeze

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins *ALLOWED_ORIGINS

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ["Content-Disposition", "Content-Type"]
  end
end

# NOTE: For S3 direct file access (previews/downloads), the S3 bucket must also have
# CORS configured. Example S3 CORS configuration (apply in AWS Console or via Terraform):
#
# [
#   {
#     "AllowedHeaders": ["*"],
#     "AllowedMethods": ["GET", "HEAD"],
#     "AllowedOrigins": ["https://arrow-crm-frontend.vercel.app"],
#     "ExposeHeaders": ["Content-Type", "Content-Disposition", "Content-Length"],
#     "MaxAgeSeconds": 3600
#   }
# ]
