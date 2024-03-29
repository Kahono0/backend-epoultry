defmodule SmartFarm.Farms.FarmAuthorizer do
  import Ecto.Query, only: [from: 2]
  alias SmartFarm.Accounts.User
  alias SmartFarm.Farms.{Farm, FarmFeed, FarmInvite, FarmManager}
  alias SmartFarm.Repo

  @spec authorize(%User{}, :create, %FarmInvite{}) :: :ok | {:error, :unauthorized}
  def authorize(%User{id: user_id}, :create, %FarmInvite{farm_id: farm_id}) do
    query = from f in Farm, where: f.id == ^farm_id and f.owner_id == ^user_id

    if Repo.exists?(query) do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  @spec authorize(%User{}, :create, %FarmFeed{}) :: :ok | {:error, :unauthorized}
  def authorize(%User{id: user_id}, :create, %FarmFeed{farm_id: farm_id}) do
    query1 = from f in Farm, where: f.id == ^farm_id and f.owner_id == ^user_id
    query2 = from f in FarmManager, where: f.farm_id == ^farm_id and f.user_id == ^user_id

    if Repo.exists?(query2) or Repo.exists?(query1) do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  @spec authorize(%User{}, :get, %Farm{}) :: :ok | {:error, :unauthorized}
  def authorize(%User{id: user_id}, :get, %Farm{id: farm_id, owner_id: owner_id}) do
    query = from f in FarmManager, where: f.farm_id == ^farm_id and f.user_id == ^user_id

    if user_id == owner_id or Repo.exists?(query) do
      :ok
    else
      {:error, :unauthorized}
    end
  end
end
