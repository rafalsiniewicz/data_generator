defmodule DataGenerator.Accounts.TokenCleanupWorker do
  @moduledoc """
  GenServer that periodically cleans up expired refresh tokens.

  Runs every hour and deletes tokens that expired more than 30 days ago.
  """

  use GenServer

  alias DataGenerator.Repo
  alias DataGenerator.Accounts.RefreshToken

  @cleanup_interval_ms :timer.hours(1)
  @retention_days 30

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_cleanup()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_expired_tokens()
    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval_ms)
  end

  defp cleanup_expired_tokens do
    import Ecto.Query

    cutoff =
      DateTime.utc_now()
      |> DateTime.add(-@retention_days * 24 * 3600, :second)
      |> DateTime.truncate(:second)

    from(rt in RefreshToken,
      where: rt.expires_at < ^cutoff
    )
    |> Repo.delete_all()
  end
end
