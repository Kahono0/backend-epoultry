defmodule SmartFarm.ExtensionServices.ExtensionServiceRequest do
  use SmartFarm.Schema

  schema "extension_service_requests" do
    field :date_accepted, :utc_datetime
    field :date_cancelled, :utc_datetime
    belongs_to :acceptor, User
    belongs_to :requester, User
    belongs_to :farm, Farm
    has_one :medical_visit, MedicalVisitRequest, foreign_key: :extension_service_id
    has_one :farm_visit, FarmVisitRequest, foreign_key: :extension_service_id
    has_one :farm_visit_report, FarmVisitReport, foreign_key: :extension_service_id

    many_to_many :attachments, Files.File,
      join_through: ExtensionServices.Attachment,
      join_keys: [extension_service_id: :id, file_id: :id]

    timestamps()
  end

  def changeset(request, attrs) do
    request
    |> cast(attrs, [:date_accepted, :date_cancelled, :farm_id, :acceptor_id, :requester_id])
    |> validate_required([:farm_id])
  end
end
