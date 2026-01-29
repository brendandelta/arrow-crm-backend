class CreateSecurityAuditLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :security_audit_logs do |t|
      t.references :actor_user, null: false, foreign_key: { to_table: :users }

      t.string :action, null: false

      # Polymorphic auditable (InternalEntity, BankAccount, Document, etc.)
      t.string :auditable_type, null: false
      t.bigint :auditable_id, null: false

      t.jsonb :metadata, default: {}

      t.datetime :created_at, null: false
    end

    # Index on action for filtering
    add_index :security_audit_logs, :action

    # Index for polymorphic lookups
    add_index :security_audit_logs, [:auditable_type, :auditable_id],
              name: 'idx_security_audit_logs_auditable'

    # Note: actor_user_id index is already created by t.references above

    # Index on created_at for time-based queries
    add_index :security_audit_logs, :created_at

    # Composite index for common queries
    add_index :security_audit_logs, [:actor_user_id, :action, :created_at],
              name: 'idx_security_audit_logs_actor_action_time'
  end
end
