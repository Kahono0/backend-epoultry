defmodule SmartFarm.Vaccinations do
  use SmartFarm.Context

  # NOTE: we need to add authorization logic here. Only the farmer/farm manager
  @spec complete_batch_vaccination(Ecto.UUID.t(), actor: User.t() | nil) ::
          {:ok, BatchVaccination.t()} | {:error, :unauthenticated | :unauthorized}
  def complete_batch_vaccination(vaccination_id, actor: %User{} = user) do
    case get_batch_vaccination(vaccination_id, actor: user) do
      {:ok, %{date_completed: nil} = vaccination} ->
        vaccination
        |> BatchVaccination.changeset(%{
          date_completed: DateTime.utc_now() |> DateTime.truncate(:second),
          completer_id: user.id
        })
        |> Repo.update()

      {:ok, _vaccination} ->
        {:error, :vaccination_already_completed}

      other ->
        other
    end
  end

  def list_batch_vaccinations(filter, actor: %User{} = user) do
    base =
      from v in BatchVaccination,
        join: b in assoc(v, :batch),
        join: f in assoc(b, :farm),
        left_join: fm in assoc(f, :managers),
        where: fm.id == ^user.id or f.owner_id == ^user.id,
        distinct: true,
        order_by: [asc: v.date_scheduled]

    Enum.reduce(filter, base, fn
      {:status, :completed}, query ->
        from v in query, where: not is_nil(v.date_completed)

      {:status, :pending}, query ->
        from v in query, where: is_nil(v.date_completed)

      _other, query ->
        query
    end)
    |> Repo.all()
  end

  def get_batch_vaccination(vaccination_id, actor: %User{}) do
    Repo.fetch(BatchVaccination, vaccination_id)
  end

  def get_vaccination_status(vaccination) do
    case vaccination do
      %{date_completed: nil} ->
        :pending

      %{date_completed: %DateTime{}} ->
        :completed
    end
  end
end