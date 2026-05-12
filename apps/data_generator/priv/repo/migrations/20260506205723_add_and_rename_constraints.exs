defmodule DataGenerator.Repo.Migrations.AddAndRenameConstraints do
  use Ecto.Migration

  def up do
    # ============================================
    # RENAME INDEXES to match SQL Server naming convention (lowercase for PostgreSQL)
    # ============================================

    execute "ALTER INDEX IF EXISTS columns_template_id_name_index RENAME TO uq_columns_template_name;"
    execute "ALTER INDEX IF EXISTS columns_template_id_index RENAME TO ix_columns_templateid;"

    execute "ALTER INDEX IF EXISTS enums_user_id_name_index RENAME TO uq_enums_user_name;"
    execute "ALTER INDEX IF EXISTS enums_user_id_index RENAME TO ix_enums_userid;"

    execute "ALTER INDEX IF EXISTS enum_values_enum_id_value_index RENAME TO uq_enumvalues_enum_value;"

    execute "ALTER INDEX IF EXISTS project_members_project_id_user_id_index RENAME TO uq_projectmembers_project_user;"

    execute "ALTER INDEX IF EXISTS project_members_one_owner_per_project RENAME TO ix_projectmembers_oneowner;"

    execute "ALTER INDEX IF EXISTS project_members_user_id_index RENAME TO ix_projectmembers_userid;"

    execute "ALTER INDEX IF EXISTS templates_user_id_name_index RENAME TO uq_templates_user_name;"
    execute "ALTER INDEX IF EXISTS templates_project_id_index RENAME TO ix_templates_projectid;"

    execute "ALTER INDEX IF EXISTS types_name_index RENAME TO uq_types_name;"

    execute "ALTER INDEX IF EXISTS users_email_index RENAME TO uq_email;"
    execute "ALTER INDEX IF EXISTS users_login_index RENAME TO uq_login;"

    # ============================================
    # ADD CHECK CONSTRAINTS
    # ============================================

    # CK_Users_Email
    execute """
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'ck_users_email' AND conrelid = 'users'::regclass
      ) THEN
        ALTER TABLE users ADD CONSTRAINT ck_users_email
        CHECK (email LIKE '%_@_%._%');
      END IF;
    END
    $$;
    """
  end

  def down do
    # Drop CHECK constraint
    execute "ALTER TABLE users DROP CONSTRAINT IF EXISTS ck_users_email;"

    # Rename indexes back to original Ecto-generated names
    execute "ALTER INDEX IF EXISTS uq_login RENAME TO users_login_index;"
    execute "ALTER INDEX IF EXISTS uq_email RENAME TO users_email_index;"
    execute "ALTER INDEX IF EXISTS uq_types_name RENAME TO types_name_index;"
    execute "ALTER INDEX IF EXISTS ix_templates_projectid RENAME TO templates_project_id_index;"
    execute "ALTER INDEX IF EXISTS uq_templates_user_name RENAME TO templates_user_id_name_index;"

    execute "ALTER INDEX IF EXISTS ix_projectmembers_userid RENAME TO project_members_user_id_index;"

    execute "ALTER INDEX IF EXISTS ix_projectmembers_oneowner RENAME TO project_members_one_owner_per_project;"

    execute "ALTER INDEX IF EXISTS uq_projectmembers_project_user RENAME TO project_members_project_id_user_id_index;"

    execute "ALTER INDEX IF EXISTS uq_enumvalues_enum_value RENAME TO enum_values_enum_id_value_index;"

    execute "ALTER INDEX IF EXISTS ix_enums_userid RENAME TO enums_user_id_index;"
    execute "ALTER INDEX IF EXISTS uq_enums_user_name RENAME TO enums_user_id_name_index;"
    execute "ALTER INDEX IF EXISTS ix_columns_templateid RENAME TO columns_template_id_index;"

    execute "ALTER INDEX IF EXISTS uq_columns_template_name RENAME TO columns_template_id_name_index;"
  end
end
