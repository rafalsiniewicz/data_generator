# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     DataGenerator.Repo.insert!(%DataGenerator.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias DataGenerator.Repo
alias DataGenerator.Generator.Type

types =
  ~w(integer float string boolean date datetime uuid first_name last_name email phone city country street zip_code url ip_address domain price product_name company regex enum)

for name <- types do
  Repo.insert!(%Type{name: name}, on_conflict: :nothing, conflict_target: :name)
end
