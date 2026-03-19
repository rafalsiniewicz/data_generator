# Data Generator — Phoenix Umbrella App Implementation Plan

## Overview

Build "Data Generator", an Elixir/Phoenix umbrella application with PostgreSQL, Phoenix LiveView frontend, JWT access + refresh token auth (refresh token rotation, encrypted at rest via Cloak/AES-256-GCM, stored in PG), OTP supervisors for data generation processes, Google SMTP for transactional emails, Docker Compose for deployment, and GitHub Actions for CI. The app lets users define data templates, manage projects/enums, generate millions of mock rows, and export to CSV/JSON/SQL. Unregistered users get limited ad-hoc generation (max 100 rows); registered users get full access.

---

## Step 1 — Scaffold the Umbrella Project

Create a Phoenix umbrella app with three child applications:
- `data_generator` — core business logic domain (Ecto schemas, contexts, data generation engine). No web dependency.
- `data_generator_web` — Phoenix endpoint, LiveView, router, auth plugs, channels.
- `data_generator_mailer` — email delivery (Swoosh + Google SMTP adapter).

```
mix phx.new data_generator --umbrella --live --database postgres
```

Then add the `data_generator_mailer` app manually under `apps/`.

---

## Step 2 — PostgreSQL Database Schema (Ecto Migrations)

Adapt the MSSQL schema to PostgreSQL via Ecto migrations. Key differences: `IDENTITY` → `bigserial`, `bit` → `boolean`, `nvarchar` → `text`/`varchar`, `ISJSON` → custom Ecto changeset validation, remove `dbo` schema prefix.

**Migration order** (respecting FK dependencies):

1. **`create_users`** — `id` (bigserial PK), `email` (varchar(255), unique, CHECK email format), `login` (varchar(100), unique), `password_hash` (varchar(255)). Add unique indexes `UQ_Email`, `UQ_Login`.

2. **`create_types`** — `id` (bigserial PK), `name` (varchar(20), unique). Seed with initial types: `integer`, `float`, `string`, `boolean`, `date`, `datetime`, `uuid`, `first_name`, `last_name`, `email`, `phone`, `city`, `country`, `street`, `zip_code`, `url`, `ip_address`, `domain`, `price`, `product_name`, `company`, `regex`, `enum`. Add a PostgreSQL rule or trigger to prevent deletion.

3. **`create_projects`** — `id` (bigserial PK), `name` (varchar(100)).

4. **`create_project_members`** — `id` (bigserial PK), `project_id` (FK → projects), `user_id` (FK → users), `is_owner` (boolean, NOT NULL). Unique constraint on `(project_id, user_id)`. Partial unique index `IX_ProjectMembers_OneOwner` on `project_id WHERE is_owner = true`. Index on `user_id`.

5. **`create_enums`** — `id` (bigserial PK), `name` (varchar(100)), `user_id` (FK → users). Unique on `(user_id, name)`. Index on `user_id`.

6. **`create_enum_values`** — `id` (bigserial PK), `enum_id` (FK → enums, ON DELETE CASCADE), `value` (varchar(50)). Unique on `(enum_id, value)`.

7. **`create_templates`** — `id` (bigserial PK), `name` (varchar(100)), `number_of_rows` (integer, CHECK > 0), `user_id` (FK → users, nullable), `description` (varchar(255), nullable), `project_id` (FK → projects, nullable). Unique on `(user_id, name)`. Index on `project_id`.

8. **`create_columns`** — `id` (bigserial PK), `name` (varchar(100)), `type_id` (FK → types), `config` (jsonb, NOT NULL), `enum_id` (FK → enums, nullable), `template_id` (FK → templates, ON DELETE CASCADE), `description` (varchar(255), nullable). Unique on `(template_id, name)`. Index on `template_id`. Check that `config` is not empty `{}` or `[]` (via changeset + DB constraint).

9. **`create_refresh_tokens`** — `id` (bigserial PK), `user_id` (FK → users, ON DELETE CASCADE), `token_hash` (varchar(255), unique — SHA-256 hash for lookups), `encrypted_token` (binary — AES-256-GCM encrypted raw token via Cloak), `expires_at` (utc_datetime), `revoked_at` (utc_datetime, nullable), `replaced_by_id` (FK → self, nullable), `inserted_at` (utc_datetime). Index on `user_id`, index on `token_hash`.

10. **`create_email_verification_tokens`** — `id` (bigserial PK), `user_id` (FK → users, ON DELETE CASCADE), `token_hash` (varchar(255), unique), `expires_at` (utc_datetime), `confirmed_at` (utc_datetime, nullable), `inserted_at`. For registration confirmation and password reset flows.

---

## Step 3 — Ecto Schemas & Contexts (`data_generator` app)

Organize into contexts following Phoenix conventions:

- **`DataGenerator.Accounts`** — context for `User`, `RefreshToken`, `EmailVerificationToken`
  - `User` schema: virtual `password` field, `password_hash` stored via `Bcrypt`
  - Functions: `register_user/1`, `authenticate_user/2`, `get_user_by_email_or_login/1`, `change_password/2`, `request_password_reset/1`, `reset_password/2`, `confirm_email/1`, `generate_email_token/2`

- **`DataGenerator.Accounts.Auth`** — token management
  - Functions: `create_token_pair/1` (returns {access_jwt, refresh_token}), `rotate_refresh_token/1` (revokes old, creates new — rotation), `revoke_all_user_tokens/1`, `verify_access_token/1`
  - Access token: short-lived JWT (15 min), signed with app secret
  - Refresh token: long-lived (7 days), stored as SHA-256 hash in `refresh_tokens` table for lookups, **encrypted at rest** via Cloak (AES-256-GCM) in the `encrypted_token` column

- **`DataGenerator.Vault`** — Cloak vault module for encryption
  - Configures AES-256-GCM cipher with key from environment variable (`CLOAK_KEY`)
  - Defines `DataGenerator.Encrypted.Binary` Cloak.Ecto type for use in schemas
  - Supports key rotation: old keys kept in config for decryption, new key used for encryption

- **`DataGenerator.Generator`** — context for data generation engine
  - `Types` schema
  - Functions: `generate_data/2` (accepts column definitions + row count, returns list of maps), individual generators per type (delegated to submodules)

- **`DataGenerator.Generator.Engine`** — GenServer/Task-based data generation
  - Uses `Task.Supervisor` for parallel column generation
  - For large row counts (>10k), generate in chunks to avoid memory spikes
  - Returns stream or chunked results

- **`DataGenerator.Generator.Types.*`** — one module per data type family, all using the `Faker` library:
  - `IntegerGen` — `:rand.uniform/1` within config range
  - `FloatGen` — `:rand.uniform/0` scaled to config range + precision
  - `StringGen` — `Faker.Lorem` for random text, or config-based length/prefix
  - `BooleanGen` — weighted random based on `true_ratio`
  - `DateGen` — random date within range via `Faker.Date`
  - `DateTimeGen` — random datetime within range via `Faker.DateTime`
  - `UUIDGen` — `Ecto.UUID.generate/0`
  - `PersonalGen` — `Faker.Person.first_name/0`, `Faker.Person.last_name/0`, `Faker.Internet.email/0`, `Faker.Phone.EnUs.phone/0`
  - `AddressGen` — `Faker.Address.city/0`, `Faker.Address.country/0`, `Faker.Address.street_address/0`, `Faker.Address.zip_code/0`
  - `InternetGen` — `Faker.Internet.url/0`, `Faker.Internet.ip_v4_address/0`, `Faker.Internet.domain_name/0`
  - `CommerceGen` — `Faker.Commerce.price/0`, `Faker.Commerce.product_name/0`, `Faker.Company.name/0`
  - `RegexGen` — using `Randex` or custom regex-to-string generator
  - `EnumGen` — picks random value from provided enum values list via `Enum.random/1`

- **`DataGenerator.Templates`** — context for `Template`, `Column`
  - Functions: `list_user_templates/1`, `get_template/1`, `create_template/2`, `update_template/2`, `delete_template/1`, `get_template_with_columns/1`

- **`DataGenerator.Projects`** — context for `Project`, `ProjectMember`
  - Functions: `list_user_projects/1`, `create_project/2` (wraps project creation + owner assignment in a transaction, equivalent to `SP_CreateProject`), `add_member/2` (equivalent to `SP_AddUserToProject`), `remove_member/2`, `set_co_owner/2`, `get_project_with_members/1`, `assign_template_to_project/2`, `remove_template_from_project/2`

- **`DataGenerator.Enums`** — context for `Enum`, `EnumValue`
  - Functions: `list_user_enums/1`, `create_enum/2`, `update_enum/2`, `delete_enum/1`, `get_enum_with_values/1`

- **`DataGenerator.Export`** — data export module
  - `Export.CSV` — generates CSV string/stream
  - `Export.JSON` — generates JSON array
  - `Export.SQL` — generates `INSERT INTO` statements with configurable table name

---

## Step 4 — Database Views as Ecto Queries

Instead of SQL views, implement equivalent composable Ecto queries in each context (idiomatic Elixir). Optionally also create the PostgreSQL views via migration for direct DB access:

- `VW_EnumDetails` → `DataGenerator.Enums.enum_details_query/1`
- `VW_Templates_Details` → `DataGenerator.Templates.template_details_query/1`
- `VW_TemplateColumns` → `DataGenerator.Templates.template_columns_query/1`
- `VW_UserProjects` → `DataGenerator.Projects.user_projects_query/1`

---

## Step 5 — Authentication & Authorization (`data_generator_web` app)

### Auth Flow

1. **Registration**: POST credentials → validate → create user (unconfirmed) → send verification email via Google SMTP → user clicks link → confirm email → user can now log in
2. **Login**: POST email/login + password → verify bcrypt → generate access token (JWT, 15 min) + refresh token (random 256-bit, hashed for lookup + encrypted at rest via Cloak, 7 days) → return both
3. **Token Refresh**: POST refresh token → compute SHA-256 hash → look up in DB → verify not revoked/expired → revoke old token → create new pair (rotation) → return new tokens. If a revoked token is reused, revoke the entire token family (security).
4. **Password Reset**: POST email → send reset link with signed token → user submits new password with token → validate → update password → revoke all refresh tokens
5. **Logout**: revoke the current refresh token

### Implementation

- `DataGeneratorWeb.Plugs.AuthPipeline` — plug that extracts JWT from `Authorization: Bearer <token>` header, verifies, and assigns `current_user` to conn/socket
- `DataGeneratorWeb.Plugs.RequireAuth` — halts with 401 if no `current_user`
- `DataGeneratorWeb.Plugs.OptionalAuth` — sets `current_user` if token present, nil otherwise
- For LiveView: authenticate on `mount/3` via token passed from session, store user in socket assigns
- Library: `joken` for JWT creation/verification, `bcrypt_elixir` for password hashing, `cloak` + `cloak_ecto` for refresh token encryption

---

## Step 6 — OTP Supervision Tree

```
DataGenerator (umbrella)
├── DataGenerator.Application
│   ├── DataGenerator.Repo (Ecto)
│   ├── DataGenerator.Vault (Cloak vault for encryption)
│   ├── DataGenerator.Generator.TaskSupervisor (Task.Supervisor)
│   │   └── spawns tasks for parallel column data generation
│   ├── DataGenerator.Generator.JobSupervisor (DynamicSupervisor)
│   │   └── manages long-running generation jobs (>10k rows)
│   └── DataGenerator.Auth.TokenCleanupWorker (GenServer)
│       └── periodically purges expired/revoked refresh tokens
├── DataGeneratorWeb.Application
│   ├── DataGeneratorWeb.Endpoint
│   └── DataGeneratorWeb.Telemetry
└── DataGeneratorMailer.Application
    └── DataGeneratorMailer.Swoosh.Mailer
```

- **`Vault`** — Cloak vault, must start before Repo so encrypted fields can be read on boot
- **`TaskSupervisor`** — supervises short-lived tasks for generating each column's data in parallel
- **`JobSupervisor`** — `DynamicSupervisor` that manages long-running generation GenServers (chunked generation for large datasets, can report progress to LiveView via PubSub)
- **`TokenCleanupWorker`** — runs every hour, deletes tokens expired > 30 days ago

---

## Step 7 — Phoenix LiveView Pages (`data_generator_web` app)

### Router Structure

```elixir
# Public (no auth)
live "/", HomeLive                          # Landing page
live "/login", LoginLive                    # Login form
live "/register", RegisterLive              # Registration form
live "/forgot-password", ForgotPasswordLive
live "/reset-password/:token", ResetPasswordLive
live "/confirm-email/:token", ConfirmEmailLive

# Public or authenticated (optional auth)
live "/generate", GenerateDataLive          # Ad-hoc generation

# Authenticated only
live "/dashboard", DashboardLive
live "/templates", TemplatesLive.Index
live "/templates/new", TemplatesLive.New
live "/templates/:id/edit", TemplatesLive.Edit
live "/projects", ProjectsLive.Index
live "/projects/new", ProjectsLive.New
live "/projects/:id", ProjectsLive.Show
live "/projects/:id/members", ProjectsLive.Members
live "/enums", EnumsLive.Index
live "/enums/new", EnumsLive.New
live "/enums/:id/edit", EnumsLive.Edit
live "/settings", SettingsLive
```

### Page-by-Page Implementation

1. **`HomeLive`** — Landing page matching the mockup. UI title: "Data Generator". "Get Started for Free" → `/register`. "Generate Ad-Hoc Data" → `/generate`.

2. **`LoginLive`** — Form with email/login + password. On success, store tokens in browser (access in memory, refresh in httpOnly cookie). "Forgot password?" link.

3. **`RegisterLive`** — Form with username, email, password. On submit, create unconfirmed user + send verification email. Show "check your email" message.

4. **`DashboardLive`** — Stats cards (generated data count, projects, templates, enums). Recent projects list. Quick action buttons.

5. **`GenerateDataLive`** — Schema configuration: dynamic form with add/remove column rows. Each row: column name input, data type dropdown, options/config input (context-sensitive based on type). Dropdown to select template or "Ad-Hoc". Generation settings sidebar: row count (enforce max 100 for unauthenticated). "Generate Now" button → triggers generation via `DataGenerator.Generator` → shows preview table (first 10 rows, expandable by 10). Export buttons (CSV/JSON/SQL) for authenticated users. Use LiveView hooks for dynamic form interactions.

6. **`TemplatesLive.Index`** — Search bar + table of templates (name, project, column count, default rows, last updated). "Create Template" button + per-row edit/delete.

7. **`TemplatesLive.New / Edit`** — Form: template name, description, number_of_rows. Dynamic column sub-forms (add/remove). Each column: name, type dropdown, config (changes based on type — range inputs for numbers, pattern for regex, enum picker for enum type). Enum picker shows user's saved enums + "create new enum" option.

8. **`ProjectsLive.Index`** — Card grid of projects (name, role badge, member count, template count). "+ New Project" button.

9. **`ProjectsLive.Show`** — Project detail: list of assigned templates (clickable → generate or remove). "Assign Template" button (shows modal with user's templates). "Manage Members" link (owner only).

10. **`ProjectsLive.Members`** — List of members with roles. Add member by login/email. Remove member or grant co-owner (owner only).

11. **`EnumsLive.Index`** — Table of enums (name, values preview). Search bar. "+ Create Enum" button.

12. **`EnumsLive.New / Edit`** — Form: enum name + dynamic list of values (add/remove value inputs).

13. **`SettingsLive`** — Change password form (current password + new password).

---

## Step 8 — Data Generation Engine Detail

The generation engine in `DataGenerator.Generator`, using `Faker` as the primary data generation library:

1. Accept a list of column definitions (type + config + optional enum_id) and row count
2. For each column, resolve the generator module from `type_id`
3. Use `Task.Supervisor` to generate each column's data in parallel: each task produces a list of N values
4. Zip columns together into a list of row maps
5. For large row counts (>10,000), use `Stream` and process in chunks of 1,000
6. For very large jobs, spawn under `JobSupervisor` as a GenServer that:
   - Reports progress via `Phoenix.PubSub` (LiveView subscribes for real-time progress bar)
   - Stores result temporarily in ETS (TTL: 30 min) for download
7. Config parsing per type:
   - `integer`: `{"min": 0, "max": 100}` → `:rand.uniform/1`
   - `float`: `{"min": 0.0, "max": 1.0, "precision": 2}`
   - `string`: `{"length": 10}` or `{"prefix": "user_"}` → `Faker.Lorem`
   - `boolean`: `{"true_ratio": 0.5}`
   - `date`: `{"from": "2020-01-01", "to": "2025-12-31"}` → `Faker.Date.between/2`
   - `datetime`: `{"from": ..., "to": ...}` → `Faker.DateTime.between/2`
   - `uuid`: `{}` → `Ecto.UUID.generate/0`
   - `first_name`: `{}` → `Faker.Person.first_name/0`
   - `last_name`: `{}` → `Faker.Person.last_name/0`
   - `email`: `{"domain": "example.com"}` → `Faker.Internet.email/0`
   - `phone`: `{}` → `Faker.Phone.EnUs.phone/0`
   - `city`: `{}` → `Faker.Address.city/0`
   - `country`: `{}` → `Faker.Address.country/0`
   - `street`: `{}` → `Faker.Address.street_address/0`
   - `zip_code`: `{}` → `Faker.Address.zip_code/0`
   - `url`: `{}` → `Faker.Internet.url/0`
   - `ip_address`: `{}` → `Faker.Internet.ip_v4_address/0`
   - `domain`: `{}` → `Faker.Internet.domain_name/0`
   - `price`: `{"min": 1.0, "max": 999.99}` → `Faker.Commerce.price/0`
   - `product_name`: `{}` → `Faker.Commerce.product_name/0`
   - `company`: `{}` → `Faker.Company.name/0`
   - `enum`: resolved from `enum_id` → fetches values from DB → `Enum.random/1`
   - `regex`: `{"pattern": "[A-Z]{3}-\\d{4}"}` → `Randex.stream/1`

---

## Step 9 — Export Module

`DataGenerator.Export` receives generated data (list of maps) + format:

- **CSV**: Use `NimbleCSV` or built-in — header row from column names, data rows. Return as downloadable file via `send_download/3`.
- **JSON**: `Jason.encode!/1` the list of maps. Pretty-printed.
- **SQL INSERT**: Accept table name parameter (default: `"generated_data"`). Generate `INSERT INTO table_name (col1, col2, ...) VALUES (v1, v2, ...);` statements. Properly escape strings, handle NULL, quote identifiers.

In LiveView, after generation, show export buttons. On click, trigger a `handle_event` that calls the export module and sends the file download.

---

## Step 10 — Email (Swoosh + Google SMTP)

In `data_generator_mailer` app:

- Configure Swoosh with `Swoosh.Adapters.SMTP` adapter pointing to `smtp.gmail.com:587` with TLS
- Store credentials in runtime config (`releases.exs`) via environment variables
- Email templates:
  - `VerificationEmail` — contains link: `{base_url}/confirm-email/{signed_token}`
  - `PasswordResetEmail` — contains link: `{base_url}/reset-password/{signed_token}`
- Tokens are signed with `Phoenix.Token` (expiry: 24h for verification, 1h for password reset)

---

## Step 11 — Tailwind CSS & UI Components

- Use Phoenix default Tailwind CSS setup
- Build a component library in `DataGeneratorWeb.Components`:
  - `Sidebar` — navigation component (Dashboard, Generate Data, Projects, Templates, Enums, Settings, Logout)
  - `StatsCard` — for dashboard stat boxes
  - `DataTable` — reusable table with search/sort
  - `Modal` — for confirmations, member management
  - `DynamicForm` — for add/remove column rows in template/generate pages
  - `Badge` — for roles (Owner/Member), project tags
  - `Button`, `Input`, `Select`, `Dropdown` — styled form primitives
- Color scheme: blue primary (#3B82F6), light gray backgrounds, white cards (matching mockups)
- UI branding: "Data Generator" throughout (header, login, register, etc.)

---

## Step 12 — Testing Strategy

Full test coverage using ExUnit, StreamData (property-based), Phoenix.LiveViewTest, and ExMachina for factories.

### 12.1 — Test Infrastructure

- **`DataGenerator.Factory`** (ExMachina) — factories for: `user`, `template`, `column`, `project`, `project_member`, `enum_definition`, `enum_value`, `refresh_token`, `type`
- **`DataGenerator.DataCase`** — shared test case with Ecto.Sandbox, imports factories
- **`DataGeneratorWeb.ConnCase`** — shared test case for controller/plug tests, includes auth helpers (`log_in_user/2`, `create_authenticated_conn/1`)
- **`DataGeneratorWeb.LiveCase`** — shared test case for LiveView tests with authenticated socket setup
- **Test config**: `config/test.exs` — use `Swoosh.Adapters.Test`, `Ecto.Adapters.SQL.Sandbox`, `Bcrypt.no_log_rounds()`

### 12.2 — Unit Tests (`data_generator` app)

**`DataGenerator.AccountsTest`**
- `register_user/1`: valid attrs creates user; duplicate email/login fails; invalid email format fails; short password fails
- `authenticate_user/2`: correct login+password succeeds; wrong password fails; nonexistent user fails
- `get_user_by_email_or_login/1`: finds by email; finds by login; returns nil for unknown
- `change_password/2`: valid current + new password succeeds; wrong current password fails
- `request_password_reset/1`: creates email token for existing user; no-ops for unknown email (timing-safe)
- `reset_password/2`: valid token resets password and revokes all refresh tokens; expired token fails; already-used token fails
- `confirm_email/1`: valid token confirms; expired token fails; double-confirm fails

**`DataGenerator.Accounts.AuthTest`**
- `create_token_pair/1`: returns valid JWT + refresh token; refresh token is stored encrypted in DB; token_hash is SHA-256 of raw token
- `rotate_refresh_token/1`: revokes old token, creates new pair; old token has `replaced_by_id` set; reusing revoked token revokes entire family
- `revoke_all_user_tokens/1`: marks all user tokens as revoked
- `verify_access_token/1`: valid JWT returns user_id; expired JWT fails; tampered JWT fails

**`DataGenerator.VaultTest`**
- Encrypt and decrypt round-trip succeeds
- Different plaintexts produce different ciphertexts
- Key rotation: old key can still decrypt, new key used for encrypt

**`DataGenerator.TemplatesTest`**
- `create_template/2`: valid attrs with columns succeeds; missing name fails; `number_of_rows <= 0` fails; duplicate `(user_id, name)` fails
- `update_template/2`: can change name, rows, description, columns; uniqueness still enforced
- `delete_template/1`: deletes template and cascades to columns
- `list_user_templates/1`: returns only templates owned by user
- `get_template_with_columns/1`: preloads columns with types

**`DataGenerator.ProjectsTest`**
- `create_project/2`: creates project + assigns user as owner in transaction; rollback on failure
- `add_member/2`: adds user; fails for nonexistent user; fails if already member
- `remove_member/2`: removes member; cannot remove owner
- `set_co_owner/2`: grants ownership; partial unique index prevents multiple owners via DB constraint
- `assign_template_to_project/2`: links template; `remove_template_from_project/2`: unlinks
- `list_user_projects/1`: returns projects with role info

**`DataGenerator.EnumsTest`**
- `create_enum/2`: valid name + values succeeds; duplicate `(user_id, name)` fails; empty values list fails
- `update_enum/2`: can add/remove values, rename; duplicate value in same enum fails
- `delete_enum/1`: cascades to enum_values
- `list_user_enums/1`: returns only user's enums with value previews

**`DataGenerator.Generator.Types.*Test`** (one test module per generator)
- `IntegerGenTest`: generates integers within `[min, max]`; min > max fails
- `FloatGenTest`: generates floats within range with correct precision
- `StringGenTest`: generates strings of correct length; respects prefix config
- `BooleanGenTest`: generates only true/false; ratio roughly correct over many samples
- `DateGenTest`: generates dates within `[from, to]` range
- `DateTimeGenTest`: generates datetimes within range
- `UUIDGenTest`: generates valid UUID v4 format
- `PersonalGenTest`: `first_name` returns non-empty string; `email` contains `@`; `phone` matches digit pattern
- `AddressGenTest`: `city`, `country`, `street`, `zip_code` return non-empty strings
- `InternetGenTest`: `url` starts with `http`; `ip_address` matches IP pattern; `domain` contains `.`
- `CommerceGenTest`: `price` is positive number; `product_name` and `company` are non-empty
- `RegexGenTest`: generated string matches the source pattern
- `EnumGenTest`: picks only from provided values; empty values list fails

**`DataGenerator.GeneratorTest`** (integration of engine)
- `generate_data/2`: mixed column types produce correct number of rows; each row has all column keys; values match expected types
- Large generation (10k+ rows): completes without error, results have correct count
- Empty column list returns empty rows

**`DataGenerator.ExportTest`**
- `Export.CSV`: correct header row; correct number of data rows; special characters escaped; empty data returns header only
- `Export.JSON`: output is valid JSON array; each element has correct keys; handles unicode
- `Export.SQL`: generates valid INSERT syntax; strings are single-quote escaped; NULL handling; custom table name works

### 12.3 — Property-Based Tests (StreamData)

**`DataGenerator.Generator.PropertyTest`**
- For each generator type, use `StreamData` to generate random valid configs and verify:
  - `IntegerGen`: `∀ min, max where min ≤ max: generated value ∈ [min, max]`
  - `FloatGen`: `∀ min, max, precision: generated value ∈ [min, max] ∧ decimal_places ≤ precision`
  - `StringGen`: `∀ length > 0: String.length(generated) == length`
  - `BooleanGen`: `∀ ratio ∈ [0,1]: generated ∈ [true, false]`
  - `DateGen`: `∀ from ≤ to: from ≤ generated ≤ to`
  - `EnumGen`: `∀ values (non-empty list): generated ∈ values`
  - `RegexGen`: `∀ simple_pattern: Regex.match?(pattern, generated)`

**`DataGenerator.Export.PropertyTest`**
- CSV: `∀ data (list of maps with same keys): CSV has length(data) + 1 lines` (header + rows)
- JSON: `∀ data: Jason.decode!(Export.JSON.generate(data)) == data`
- SQL: `∀ data, table_name: each line starts with "INSERT INTO #{table_name}"`

### 12.4 — Integration / LiveView Tests (`data_generator_web` app)

**`DataGeneratorWeb.AuthFlowTest`** (full integration)
- Register → receive email → confirm → login → get tokens → refresh token → logout
- Register with duplicate email shows error
- Login with wrong password shows error
- Forgot password → receive email → reset → old password no longer works
- Access protected page without token → redirect to login
- Access protected page with expired JWT → 401

**`DataGeneratorWeb.HomeLiveTest`**
- Renders landing page with "Data Generator" branding
- "Get Started for Free" navigates to `/register`
- "Generate Ad-Hoc Data" navigates to `/generate`
- Unauthenticated: shows login/register links
- Authenticated: redirects to `/dashboard`

**`DataGeneratorWeb.LoginLiveTest`**
- Renders login form
- Valid credentials → redirects to dashboard
- Invalid credentials → shows error message
- "Forgot password?" link present and navigable
- "Sign up" link present

**`DataGeneratorWeb.RegisterLiveTest`**
- Renders registration form
- Valid input → shows "check your email" message
- Duplicate email → shows error
- Duplicate login → shows error
- Invalid email format → shows validation error

**`DataGeneratorWeb.DashboardLiveTest`**
- Requires authentication (redirect if not logged in)
- Shows correct stats for logged-in user
- Recent projects listed
- Quick action buttons navigate correctly

**`DataGeneratorWeb.GenerateDataLiveTest`**
- Renders generation form for both authenticated and unauthenticated users
- Add column → new row appears
- Remove column → row disappears
- Select data type → config options update accordingly
- Select "enum" type → shows enum picker (authenticated only)
- Set rows > 100 as guest → shows error, blocks generation
- Generate → shows preview table with first 10 rows
- Expand preview → shows additional rows
- Export buttons visible only for authenticated users
- Export CSV/JSON/SQL → triggers file download

**`DataGeneratorWeb.TemplatesLiveTest`**
- Requires authentication
- `Index`: lists user templates; search filters results; "Create Template" navigates
- `New`: creating template with columns succeeds; validation errors shown
- `Edit`: loads existing template config; saves changes; column add/remove works
- Delete template → removed from list

**`DataGeneratorWeb.ProjectsLiveTest`**
- Requires authentication
- `Index`: shows project cards with correct role badges; "New Project" works
- `New`: create project → user becomes owner
- `Show`: lists assigned templates; "Assign Template" modal works; generate from template works; remove template works
- `Members` (owner only): add member by email/login; remove member; grant co-owner; non-owner cannot access

**`DataGeneratorWeb.EnumsLiveTest`**
- Requires authentication
- `Index`: lists enums with value previews; search works
- `New`: create enum with values; validation errors shown for empty name/values
- `Edit`: modify name; add/remove values; save succeeds
- Delete enum → removed from list

**`DataGeneratorWeb.SettingsLiveTest`**
- Requires authentication
- Change password with correct current password succeeds
- Wrong current password shows error

### 12.5 — Plug / Pipeline Tests

**`DataGeneratorWeb.Plugs.AuthPipelineTest`**
- Valid JWT in header → assigns `current_user`
- Missing header → no `current_user` assigned
- Expired JWT → no `current_user` assigned
- Malformed token → no `current_user` assigned

**`DataGeneratorWeb.Plugs.RequireAuthTest`**
- With `current_user` → passes through
- Without `current_user` → halts with 401/redirect

### 12.6 — Test Coverage Target

- Contexts (`data_generator` app): >90% line coverage
- LiveView pages (`data_generator_web` app): >85% line coverage
- Overall umbrella: >85% line coverage
- All property-based tests pass with default StreamData iterations (100)

---

## Step 13 — Docker & Docker Compose

- `Dockerfile`: Multi-stage build (deps → compile → release → runtime with minimal Alpine image)
- `docker-compose.yml`:
  - `app` service: Phoenix release, ports 4000
  - `db` service: PostgreSQL 16, volume for persistence
  - `mailhog` service (dev only): for testing emails locally
- Environment variables: `DATABASE_URL`, `SECRET_KEY_BASE`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `PHX_HOST`, `CLOAK_KEY`

---

## Step 14 — GitHub Actions CI

- `.github/workflows/ci.yml`:
  - Trigger on push/PR to main
  - Services: PostgreSQL
  - Steps: checkout → setup Elixir/OTP → deps cache → `mix deps.get` → `mix compile --warnings-as-errors` → `mix format --check-formatted` → `mix credo --strict` → `mix test`
  - Optional: Dialyzer step (cached PLTs)

---

## Step 15 — Implementation Order (Milestones)

| # | Milestone | Key Deliverables |
|---|-----------|-----------------|
| 1 | Project scaffold | Umbrella structure, deps, config, Docker Compose, DB connection |
| 2 | Database & schemas | All migrations, Ecto schemas, seed Types table, Cloak vault setup |
| 3 | Auth system | Registration, login, JWT, refresh token rotation + encryption, email verification, password reset |
| 4 | Core UI shell | Layout, sidebar, navigation, Tailwind setup, auth-aware LiveView mounting |
| 5 | Enums CRUD | Enums context + LiveView pages (list, create, edit, delete) + tests |
| 6 | Templates CRUD | Templates + Columns contexts + LiveView pages with dynamic column forms + tests |
| 7 | Data generation engine | All Faker-based type generators, TaskSupervisor, chunked generation, preview display + property tests |
| 8 | Ad-hoc generation page | GenerateDataLive with full column config UI, row limit enforcement, preview table + LiveView tests |
| 9 | Projects CRUD | Projects + Members contexts + LiveView pages, assign templates + tests |
| 10 | Dashboard | Stats aggregation queries, recent projects, quick actions + tests |
| 11 | Export | CSV, JSON, SQL export with file download + export tests |
| 12 | Full test suite | Property-based tests, E2E auth flow tests, remaining LiveView tests, coverage check |
| 13 | Deployment | Docker production build, environment config, CI pipeline, documentation |

---

## Verification Checklist

- [ ] `mix test` across the umbrella — all unit, integration, LiveView, and property-based tests pass
- [ ] Test coverage: contexts >90%, LiveView >85%, overall >85%
- [ ] `mix credo --strict` and `mix dialyzer` — no warnings
- [ ] Docker Compose `docker compose up` starts app + DB, accessible at `localhost:4000`
- [ ] Manual walkthrough: register → confirm email → login → create enum → create template with columns → generate data → preview → export CSV/JSON/SQL → create project → add member → assign template → generate from project template → logout → ad-hoc generate as guest (max 100 rows enforced)
- [ ] Refresh tokens are encrypted at rest in DB (verify via `psql` — `encrypted_token` column is binary, not plaintext)
- [ ] GitHub Actions CI passes on push

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| PostgreSQL instead of MSSQL | Idiomatic for Elixir/Ecto ecosystem; original SQL scripts adapted |
| Umbrella with 3 apps (`data_generator`, `data_generator_web`, `data_generator_mailer`) | Clean separation of concerns |
| Refresh token rotation with family revocation on reuse | Prevents token theft replay attacks |
| Refresh token encrypted at rest via Cloak (AES-256-GCM) | Defense in depth — protects tokens if DB is compromised; supports key rotation |
| `Faker` library for realistic data generation | Mature Elixir library with broad locale/type support |
| LiveView-only frontend (no SPA) | Simpler deployment, real-time capabilities, stays in Elixir |
| JSON config validation in Ecto changesets (not DB-level `ISJSON`) | More expressive error messages |
| `Task.Supervisor` + `DynamicSupervisor` for generation | Leverages OTP supervision for parallel & long-running jobs |
| `Joken` for JWT + `bcrypt_elixir` for passwords | Battle-tested Elixir libraries |
| Google SMTP via Swoosh | User-requested; simple config, reliable delivery |
| StreamData for property-based tests | Finds edge cases in generators that example-based tests miss |
| UI name "Data Generator" (full name everywhere) | Consistent branding per user requirement |

---

## Dependencies (mix.exs)

```elixir
# data_generator
{:ecto_sql, "~> 3.11"},
{:postgrex, "~> 0.18"},
{:bcrypt_elixir, "~> 3.1"},
{:joken, "~> 2.6"},
{:jason, "~> 1.4"},
{:faker, "~> 0.18"},
{:nimble_csv, "~> 1.2"},
{:randex, "~> 0.4"},           # regex-based string generation
{:cloak, "~> 1.1"},            # encryption vault
{:cloak_ecto, "~> 1.3"},       # Ecto types for encrypted fields

# data_generator_web
{:phoenix, "~> 1.7"},
{:phoenix_live_view, "~> 0.20"},
{:phoenix_html, "~> 4.1"},
{:phoenix_live_dashboard, "~> 0.8"},
{:tailwind, "~> 0.2"},
{:heroicons, "~> 0.5"}

# data_generator_mailer
{:swoosh, "~> 1.16"},
{:gen_smtp, "~> 1.2"}          # SMTP adapter for Swoosh

# dev/test
{:credo, "~> 1.7", only: [:dev, :test]},
{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
{:ex_machina, "~> 2.7", only: :test},
{:stream_data, "~> 1.1", only: :test}  # property-based testing
```
