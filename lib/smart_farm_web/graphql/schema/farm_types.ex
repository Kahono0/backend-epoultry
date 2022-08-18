defmodule SmartFarmWeb.Schema.FarmTypes do
  use SmartFarmWeb, :schema

  object :farm do
    field :id, :uuid
    field :name, :string

    field :bird_count, :integer do
      resolve(&Resolvers.Farm.bird_count/3)
    end

    field :egg_count, :integer do
      resolve(&Resolvers.Farm.egg_count/3)
    end

    field :owner, :user do
      resolve(dataloader(Repo))
    end

    field :batches, list_of(:batch) do
      resolve(dataloader(Repo))
    end
  end

  object :invite do
    field :invite_code, :string
    field :expiry, :datetime
  end

  object :farm_queries do
  end

  object :farm_mutations do
    field :join_farm, non_null(:farm) do
      arg(:invite_code, non_null(:string))

      resolve(&Resolvers.Farm.join_farm/2)
    end

    field :create_invite, non_null(:invite) do
      arg(:farm_id, non_null(:uuid))

      resolve(&Resolvers.Farm.create_invite/2)
    end
  end
end
