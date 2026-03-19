defmodule DataGenerator.Encrypted.Binary do
  use Cloak.Ecto.Binary, vault: DataGenerator.Vault
end
