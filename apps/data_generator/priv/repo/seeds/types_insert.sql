-- SQL insert statements for generator types (Postgres)
-- Run with: psql -d YOUR_DB -f priv/repo/seeds/types_insert.sql

BEGIN;

INSERT INTO types (name, inserted_at, updated_at) VALUES
  ('integer', now(), now()),
  ('float', now(), now()),
  ('string', now(), now()),
  ('boolean', now(), now()),
  ('date', now(), now()),
  ('datetime', now(), now()),
  ('uuid', now(), now()),
  ('first_name', now(), now()),
  ('last_name', now(), now()),
  ('email', now(), now()),
  ('phone', now(), now()),
  ('city', now(), now()),
  ('country', now(), now()),
  ('street', now(), now()),
  ('zip_code', now(), now()),
  ('url', now(), now()),
  ('ip_address', now(), now()),
  ('domain', now(), now()),
  ('price', now(), now()),
  ('product_name', now(), now()),
  ('company', now(), now()),
  ('regex', now(), now()),
  ('enum', now(), now())
ON CONFLICT (name) DO NOTHING;

COMMIT;
