defmodule DataGenerator.VaultTest do
  use DataGenerator.DataCase, async: true

  alias DataGenerator.Vault

  describe "encrypt/decrypt roundtrip" do
    test "encrypts and decrypts a string successfully" do
      plaintext = "hello world secret data"

      {:ok, ciphertext} = Vault.encrypt(plaintext)
      assert is_binary(ciphertext)
      assert ciphertext != plaintext

      {:ok, decrypted} = Vault.decrypt(ciphertext)
      assert decrypted == plaintext
    end

    test "encrypts and decrypts binary data" do
      plaintext = :crypto.strong_rand_bytes(64)

      {:ok, ciphertext} = Vault.encrypt(plaintext)
      {:ok, decrypted} = Vault.decrypt(ciphertext)

      assert decrypted == plaintext
    end

    test "different plaintexts produce different ciphertexts" do
      {:ok, ct1} = Vault.encrypt("secret_one")
      {:ok, ct2} = Vault.encrypt("secret_two")

      assert ct1 != ct2
    end

    test "same plaintext encrypted twice produces different ciphertexts (nonce)" do
      plaintext = "same value"

      {:ok, ct1} = Vault.encrypt(plaintext)
      {:ok, ct2} = Vault.encrypt(plaintext)

      # AES-GCM uses random nonces, so same plaintext should produce different ciphertexts
      assert ct1 != ct2
    end

    test "encrypt! and decrypt! work without wrapping" do
      plaintext = "bang version test"

      ciphertext = Vault.encrypt!(plaintext)
      assert is_binary(ciphertext)

      decrypted = Vault.decrypt!(ciphertext)
      assert decrypted == plaintext
    end
  end
end
