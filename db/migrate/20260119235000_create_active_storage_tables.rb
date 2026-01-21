# This migration creates the tables needed by ActiveStorage
# ActiveStorage is Rails' built-in file upload system
class CreateActiveStorageTables < ActiveRecord::Migration[7.2]
  def change
    # This table stores metadata about each uploaded file
    # (filename, content type, size, checksum for integrity)
    create_table :active_storage_blobs do |t|
      t.string   :key,          null: false  # Unique identifier for the file
      t.string   :filename,     null: false  # Original filename
      t.string   :content_type              # MIME type (image/jpeg, etc.)
      t.text     :metadata                  # Extra data (dimensions, etc.)
      t.string   :service_name, null: false # Which storage service (local, s3, etc.)
      t.bigint   :byte_size,    null: false # File size in bytes
      t.string   :checksum                  # For verifying file integrity

      t.datetime :created_at, null: false

      t.index [:key], unique: true
    end

    # This table links uploaded files to your models (Person, Organization, etc.)
    # It's a "join table" - connects blobs to records
    create_table :active_storage_attachments do |t|
      t.string     :name,     null: false  # The attachment name (e.g., "avatar")
      t.references :record,   null: false, polymorphic: true, index: false  # Which model
      t.references :blob,     null: false  # Which file

      t.datetime :created_at, null: false

      t.index [:record_type, :record_id, :name, :blob_id],
              name: :index_active_storage_attachments_uniqueness,
              unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end

    # This table tracks variants (resized/transformed versions of images)
    create_table :active_storage_variant_records do |t|
      t.belongs_to :blob, null: false, index: false
      t.string :variation_digest, null: false

      t.index [:blob_id, :variation_digest],
              name: :index_active_storage_variant_records_uniqueness,
              unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
  end
end
