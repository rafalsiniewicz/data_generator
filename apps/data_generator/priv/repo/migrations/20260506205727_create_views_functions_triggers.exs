defmodule DataGenerator.Repo.Migrations.CreateViewsFunctionsTriggers do
  use Ecto.Migration

  def up do
    # ============================================
    # VIEWS (quoted to preserve case)
    # ============================================

    execute """
    CREATE OR REPLACE VIEW "VW_EnumDetails" AS
    SELECT e.id AS enum_id, e.name AS enum_name, ev.value
    FROM enums e
    JOIN enum_values ev ON e.id = ev.enum_id;
    """

    execute """
    CREATE OR REPLACE VIEW "VW_Templates_Details" AS
    SELECT t.id, t.name AS template_name, t.number_of_rows, t.description,
           p.name AS project_name, u.login AS created_by
    FROM templates t
    LEFT JOIN projects p ON t.project_id = p.id
    JOIN users u ON t.user_id = u.id;
    """

    execute """
    CREATE OR REPLACE VIEW "VW_TemplateColumns" AS
    SELECT t.id AS template_id, t.name AS template_name, t.number_of_rows,
           c.id AS column_id, c.name AS column_name, ty.name AS type_name,
           c.config, e.name AS enum_name
    FROM templates t
    JOIN columns c ON c.template_id = t.id
    JOIN types ty ON ty.id = c.type_id
    LEFT JOIN enums e ON e.id = c.enum_id;
    """

    execute """
    CREATE OR REPLACE VIEW "VW_UserProjects" AS
    SELECT pm.user_id, p.id AS project_id, p.name AS project_name, pm.is_owner
    FROM project_members pm
    JOIN projects p ON p.id = pm.project_id;
    """

    # ============================================
    # FUNCTIONS (quoted to preserve uppercase naming)
    # ============================================

    execute """
    CREATE OR REPLACE FUNCTION "SP_AddUserToProject"(project_id_param INT, user_id_param INT)
    RETURNS VOID AS $$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM users WHERE id = user_id_param) THEN
            RAISE EXCEPTION 'User does not exist.';
        END IF;
        INSERT INTO project_members(project_id, user_id, is_owner)
        VALUES (project_id_param, user_id_param, FALSE);
    END;
    $$ LANGUAGE plpgsql;
    """

    execute """
    CREATE OR REPLACE FUNCTION "SP_CreateProject"(project_name_param VARCHAR(100), user_id_param INT)
    RETURNS VOID AS $$
    DECLARE new_project_id INT;
    BEGIN
        INSERT INTO projects(name) VALUES (project_name_param) RETURNING id INTO new_project_id;
        INSERT INTO project_members(project_id, user_id, is_owner)
        VALUES (new_project_id, user_id_param, TRUE);
    END;
    $$ LANGUAGE plpgsql;
    """

    # ============================================
    # TRIGGER
    # ============================================

    execute """
    CREATE OR REPLACE FUNCTION prevent_delete_types()
    RETURNS TRIGGER AS $$
    BEGIN
        RAISE EXCEPTION 'Deleting data types is not allowed.';
    END;
    $$ LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER "TRG_PreventDeleteTypes"
    BEFORE DELETE ON types
    FOR EACH ROW EXECUTE FUNCTION prevent_delete_types();
    """
  end

  def down do
    execute "DROP TRIGGER IF EXISTS \"TRG_PreventDeleteTypes\" ON types;"
    execute "DROP FUNCTION IF EXISTS prevent_delete_types();"
    execute "DROP FUNCTION IF EXISTS \"SP_CreateProject\"(VARCHAR, INT);"
    execute "DROP FUNCTION IF EXISTS \"SP_AddUserToProject\"(INT, INT);"
    execute "DROP VIEW IF EXISTS \"VW_UserProjects\";"
    execute "DROP VIEW IF EXISTS \"VW_TemplateColumns\";"
    execute "DROP VIEW IF EXISTS \"VW_Templates_Details\";"
    execute "DROP VIEW IF EXISTS \"VW_EnumDetails\";"
  end
end
