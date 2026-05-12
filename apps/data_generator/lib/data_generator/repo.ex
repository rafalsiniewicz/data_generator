defmodule DataGenerator.Repo do
  use Ecto.Repo,
    otp_app: :data_generator,
    adapter: Ecto.Adapters.Postgres
end
