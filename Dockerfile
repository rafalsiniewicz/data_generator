# Find eligible files for COPY
ARG ELIXIR_VERSION=1.19.5
ARG OTP_VERSION=27.3.1
ARG DEBIAN_VERSION=bookworm-20260406-slim
ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

# ── Stage 1: deps ─────────────────────────────────────────────
FROM ${BUILDER_IMAGE} AS deps

RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV="prod"

# Copy umbrella root mix files
COPY mix.exs mix.lock ./

# Copy child app mix files
COPY apps/data_generator/mix.exs apps/data_generator/mix.exs
COPY apps/data_generator_web/mix.exs apps/data_generator_web/mix.exs

# Fetch dependencies
RUN mix deps.get --only $MIX_ENV

# ── Stage 2: compile ─────────────────────────────────────────
FROM deps AS compile

ENV MIX_ENV="prod"

# Copy dependency config
RUN mkdir config
COPY config/config.exs config/
COPY config/prod.exs config/
COPY config/runtime.exs config/

# Compile dependencies
RUN mix deps.compile

# Copy all application source code
COPY apps apps

# Compile the project
RUN mix compile --warnings-as-errors

# ── Stage 3: assets ──────────────────────────────────────────
FROM compile AS assets

ENV MIX_ENV="prod"

WORKDIR /app

# Install Node.js for asset compilation (tailwind + esbuild are managed by mix)
RUN mix assets.deploy

# ── Stage 4: release ─────────────────────────────────────────
FROM assets AS release

ENV MIX_ENV="prod"

WORKDIR /app

RUN mix release

# ── Stage 5: runtime (minimal image) ─────────────────────────
FROM ${RUNNER_IMAGE} AS runtime

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app

# Create a non-root user
RUN groupadd --system app && useradd --system --gid app app

# Copy the release from the build stage
COPY --from=release --chown=app:app /app/_build/prod/rel/data_generator ./

USER app

# Set runtime environment variables
ENV MIX_ENV="prod"
ENV PHX_SERVER=true
ENV PORT=4000

EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:4000/ || exit 1

CMD bin/data_generator eval "DataGenerator.Release.seed()" && bin/data_generator start
