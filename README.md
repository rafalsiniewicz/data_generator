<div align="center">
  <img src="apps/data_generator_web/priv/static/images/logo.svg" alt="Data Generator Logo" width="100" height="auto">
  <h1 align="center">Data Generator</h1>
  <p align="center">
    A powerful web-based mock data generation tool built with Elixir &amp; Phoenix LiveView
  </p>
  <p align="center">
    Generate realistic test data — CSV, JSON, or SQL — with a rich set of data types,
    reusable templates, team collaboration, and parallel generation engine.
  </p>
  <p align="center">

[![Elixir](https://img.shields.io/badge/Elixir-1.19-4B275F?logo=elixir&logoColor=white)](https://elixir-lang.org)
[![Phoenix](https://img.shields.io/badge/Phoenix-1.8-FD4F00?logo=phoenix&logoColor=white)](https://phoenixframework.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql&logoColor=white)](https://postgresql.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![CI](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)](.github/workflows/ci.yml)

  </p>
</div>

---

## Features

<details open>
<summary><strong>Core Generation</strong></summary>

- **20+ data types** — integer, float, string, boolean, date, datetime, UUID, email, phone, first/last name, city, country, street, ZIP code, URL, IP address, domain, price, product name, company, regex, and custom enums
- **Parallel engine** — columns are generated concurrently using `Task.Supervisor.async_stream_nolink` for maximum throughput
- **Chunked processing** — large datasets (>10K rows) are processed in chunks of 1,000 to keep memory low
- **Up to 1M rows** — generate up to one million rows of data in a single request
- **Custom enums** — define reusable enum value lists and use them across multiple columns
- **Regex-based generation** — generate strings matching custom regex patterns
</details>

<details>
<summary><strong>Export Formats</strong></summary>

| Format | Extension | Description |
|--------|-----------|-------------|
| **CSV** | `.csv` | Comma-separated values (uses `NimbleCSV`) |
| **JSON** | `.json` | Array of objects format |
| **SQL** | `.sql` | `INSERT INTO` statements ready for your database |
</details>

<details>
<summary><strong>Templates & Collaboration</strong></summary>

- **Reusable templates** — save column definitions as templates for quick reuse
- **Project sharing** — share templates and custom enums within team projects
- **Member management** — add/remove project members with ease
- **User accounts** — registration, login, email verification, password reset
</details>

<details>
<summary><strong>Developer Experience</strong></summary>

- **LiveView UI** — responsive, real-time interface with no page refreshes
- **Property-based tests** — generators verified with StreamData
- **Docker support** — consistent dev environment with Docker Compose
- **CI pipeline** — format checking, Credo linting, and full test suite
</details>

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Language** | [Elixir](https://elixir-lang.org) ~> 1.15 |
| **Runtime** | [Erlang/OTP](https://www.erlang.org) 28+ |
| **Web Framework** | [Phoenix](https://www.phoenixframework.org) 1.8.5 |
| **Interactive UI** | [LiveView](https://github.com/phoenixframework/phoenix_live_view) 1.1.27 |
| **HTTP Server** | [Bandit](https://github.com/mtrudel/bandit) 1.10 |
| **Database** | PostgreSQL 16 via [Ecto](https://github.com/elixir-ecto/ecto_sql) 3.13 |
| **CSS** | [Tailwind CSS](https://tailwindcss.com) 4.12 |
| **JS Bundler** | [esbuild](https://esbuild.github.io) 0.25 |
| **Mailer** | [Swoosh](https://github.com/swoosh/swoosh) 1.16 |
| **Password Hashing** | [bcrypt_elixir](https://github.com/riverrun/bcrypt_elixir) 3.1 |
| **Fake Data** | [Faker](https://github.com/elixirs/faker) 0.18 |
| **Testing** | ExUnit, [StreamData](https://github.com/whatyouhide/stream_data) (property-based), [ExMachina](https://github.com/thoughtbot/ex_machina) (factories) |
| **Linting** | [Credo](https://github.com/rrrene/credo) 1.7 |
| **Static Analysis** | [Dialyzer](https://github.com/jeremyjh/dialyxir) via dialyxir |

---

## Screenshots

> Screenshots coming soon. Run the app locally to see it in action!

| Page | Description |
|------|-------------|
| **Home** | Landing page with quick-start data generation |
| **Generate** | Interactive column builder with 20+ data types |
| **Dashboard** | Overview of your templates, projects, and enums |
| **Templates** | Save, edit, and reuse column definitions |
| **Projects** | Share templates and enums with team members |
| **Enums** | Define custom enum value lists |

---

## Getting Started

### Prerequisites

- [Elixir](https://elixir-lang.org/install.html) ~> 1.15 (with Erlang/OTP 28+)
- [PostgreSQL](https://www.postgresql.org/download/) 16+
- Git

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/your-org/data_generator.git
cd data_generator

# 2. Install dependencies
mix deps.get

# 3. Set up the database (creates, migrates, and seeds)
mix setup

# 4. Start the Phoenix server
mix phx.server
```

Now visit **[http://localhost:4000](http://localhost:4000)** in your browser.

> The `mix setup` alias runs `deps.get`, `ecto.create`, `ecto.migrate`, and runs the `seeds.exs` file to populate the supported data types.

### Docker (alternative)

```bash
docker compose up --build
```

This starts both the application and a PostgreSQL instance. Access the app at `http://localhost:4000`.

---

## Configuration

The project uses [Phoenix configuration](https://hexdocs.pm/phoenix/config.html) across four environments:

| File | Purpose |
|------|---------|
| `config/config.exs` | Shared defaults (database, mailer, endpoint) |
| `config/dev.exs` | Local development (localhost DB, live reload, watchers) |
| `config/prod.exs` | Production (SSL, cache manifest, Swoosh API client) |
| `config/runtime.exs` | Runtime secrets via environment variables |

### Key Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | — | PostgreSQL connection string |
| `SECRET_KEY_BASE` | — | Phoenix signing/encryption secret |
| `PHX_HOST` | `localhost` | Application hostname |
| `PORT` | `4000` | HTTP server port |

---

## Usage

### Ad-hoc Data Generation

1. Go to **Generate** (no login required)
2. Add columns with names and pick data types
3. Configure each type (e.g., integer range, date format, enum values)
4. Set the number of rows (up to 1,000,000)
5. Choose export format — CSV, JSON, or SQL
6. Click **Generate** and download your file

### Templates (requires login)

1. Register an account and log in
2. Go to **Templates → New Template**
3. Define columns with their types and settings
4. Save — reuse the template anytime from the **Generate** page

### Projects (requires login)

1. Go to **Projects → New Project**
2. Add members by their email address
3. Share templates and custom enums within the project

### Enums (requires login)

1. Go to **Enums → New Enum**
2. Add values (e.g., `urgent`, `high`, `medium`, `low`)
3. Use the enum as a data type in any column

---

## Data Types Reference

| Type | Configuration | Example Output |
|------|---------------|----------------|
| `integer` | Min, max | `42` |
| `float` | Min, max, decimals | `3.14` |
| `string` | Length range, charset | `aB3xY` |
| `boolean` | — | `true` |
| `date` | Format, range | `2024-03-15` |
| `datetime` | Format, range | `2024-03-15T10:30:00Z` |
| `uuid` | — | `550e8400-e29b-41d4-a716-446655440000` |
| `first_name` | — | `Alice` |
| `last_name` | — | `Johnson` |
| `email` | Domain (optional) | `alice.johnson@example.com` |
| `phone` | Format | `+1 (555) 123-4567` |
| `city` | — | `Springfield` |
| `country` | — | `United States` |
| `street` | — | `123 Main St` |
| `zip_code` | — | `90210` |
| `url` | — | `https://example.com/page` |
| `ip_address` | Version (v4/v6) | `192.168.1.1` |
| `domain` | — | `example.com` |
| `price` | Currency, min, max | `$29.99` |
| `product_name` | — | `Ergonomic Keyboard` |
| `company` | — | `Acme Corp` |
| `regex` | Pattern | (user-defined) |
| `enum` | Enum list | (user-defined) |

---

## Project Structure

```
data_generator/                  # Umbrella root
├── apps/
│   ├── data_generator/          # Core business logic (OTP app)
│   │   ├── lib/data_generator/
│   │   │   ├── accounts/        # User auth, email verification
│   │   │   ├── enums/           # Custom enum management
│   │   │   ├── export/          # CSV, JSON, SQL exporters
│   │   │   ├── generator/       # Data generation engine & types
│   │   │   │   ├── engine.ex    # Parallel, chunked generator
│   │   │   │   └── types/       # 17+ individual type generators
│   │   │   ├── projects/        # Team project collaboration
│   │   │   └── templates/       # Reusable column templates
│   │   └── priv/repo/
│   │       ├── migrations/      # Database schema migrations
│   │       └── seeds/           # Type seed data (SQL)
│   │
│   └── data_generator_web/      # Phoenix web interface
│       ├── assets/              # CSS (Tailwind), JS (esbuild)
│       ├── lib/data_generator_web/
│       │   ├── components/      # Reusable UI components
│       │   ├── controllers/     # Page & session controllers
│       │   ├── live/            # LiveView modules (pages)
│       │   │   ├── templates_live/  # Template CRUD
│       │   │   ├── projects_live/   # Project CRUD & members
│       │   │   └── enums_live/      # Enum CRUD
│       │   └── plugs/           # Auth plug
│       └── priv/static/         # Static assets (logo, favicon)
│
├── config/                      # Environment configuration
├── .github/workflows/           # CI pipeline
├── Dockerfile                   # Production Docker image
└── docker-compose.yml           # Local PostgreSQL + app
```

---

## Architecture

The app is an **Elixir umbrella project** with two OTP applications:

### Data Flow

```
User defines columns & settings  →  GenerateData LiveView
                                       │
                                       ▼
                              Generator.Engine
                              (Task.Supervisor.async_stream_nolink)
                              ┌──────────────────┐
                              │  Column 1 gen     │  ← parallel
                              │  Column 2 gen     │  ← parallel
                              │  Column 3 gen     │  ← parallel
                              │  ...              │
                              └──────────────────┘
                                       │
                                       ▼
                              Export module
                              (CSV / JSON / SQL)
                                       │
                                       ▼
                              File download
```

### Supervision Tree

```
DataGenerator.Application
├── DataGenerator.Repo                  (Ecto repo)
├── DNSCluster                          (DNS clustering)
├── Phoenix.PubSub                      (PubSub bus)
├── DataGenerator.TaskSupervisor        (parallel generation)
└── DataGenerator.DynamicSupervisor     (generation jobs)

DataGeneratorWeb.Application
├── DataGeneratorWeb.Telemetry          (metrics)
└── DataGeneratorWeb.Endpoint           (Phoenix endpoint)
```

---

## Testing

The project has a comprehensive test suite covering both unit and integration tests:

```bash
# Run the full test suite
mix test

# Run tests with coverage
mix test --cover

# Run property-based tests (StreamData) multiple times
mix test --seed 0 --max-failures 1

# Run Credo linting
mix credo --strict

# Run full CI check (format, compile warnings, credo, test)
mix precommit
```

### Test Structure

| Directory | Type | Tools |
|-----------|------|-------|
| `test/data_generator/` | Unit & context tests | ExUnit |
| `test/data_generator/generator/types/` | Type generator tests | ExUnit |
| `test/data_generator/generator/` | Property-based engine tests | StreamData |
| `test/data_generator/export/` | Property-based export tests | StreamData |
| `test/data_generator_web/live/` | LiveView integration tests | ExUnit + Phoenix.ConnCase |

---

## CI Pipeline

The [GitHub Actions workflow](.github/workflows/ci.yml) runs on every push/PR to `main`:

1. **Setup** — Elixir 1.19.5 / OTP 28, PostgreSQL 16
2. **Dependencies** — `mix deps.get`
3. **Compile** — `mix compile --warnings-as-errors`
4. **Format** — `mix format --check-formatted`
5. **Lint** — `mix credo --strict`
6. **Test** — `mix test`

---

## API Routes

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/` | — | Home / landing page |
| `GET` | `/generate` | — | Data generation page |
| `GET` | `/login` | — | User login |
| `GET` | `/register` | — | User registration |
| `GET` | `/dashboard` | ✓ | User dashboard |
| `GET` | `/templates` | ✓ | Template list |
| `GET` | `/templates/new` | ✓ | Create template |
| `GET` | `/templates/:id/edit` | ✓ | Edit template |
| `GET` | `/projects` | ✓ | Project list |
| `GET` | `/projects/new` | ✓ | Create project |
| `GET` | `/projects/:id` | ✓ | Project details |
| `GET` | `/projects/:id/members` | ✓ | Manage members |
| `GET` | `/enums` | ✓ | Enum list |
| `GET` | `/enums/new` | ✓ | Create enum |
| `GET` | `/enums/:id/edit` | ✓ | Edit enum |
| `GET` | `/settings` | ✓ | User settings |
| `GET` | `/dev/dashboard` | dev | Phoenix LiveDashboard |
| `GET` | `/dev/mailbox` | dev | Swoosh mailbox preview |

---

## License

Distributed under the MIT License. See `LICENSE` for more information.

---

## Acknowledgments

- [Phoenix Framework](https://phoenixframework.org) — the web framework powering this app
- [Faker](https://github.com/elixirs/faker) — realistic fake data generation
- [NimbleCSV](https://github.com/dashbitco/nimble_csv) — CSV export
- [Tailwind CSS](https://tailwindcss.com) — utility-first CSS framework
- [Heroicons](https://heroicons.com) — SVG icons used throughout the UI
