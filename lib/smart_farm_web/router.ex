defmodule SmartFarmWeb.Router do
  use SmartFarmWeb, :router
  import SmartFarmWeb.Auth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SmartFarmWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_authenticated do
    plug SmartFarmWeb.APIAuth
  end

  pipeline :graphql do
    plug :accepts, ["json"]
    plug SmartFarmWeb.Context
  end

  scope "/api/graphql" do
    pipe_through :graphql

    forward "/auth", SmartFarmWeb.AbsinthePlug, schema: SmartFarmWeb.AuthSchema
    forward "/", Absinthe.Plug, schema: SmartFarmWeb.Schema
  end

  forward "/graphiql/auth", SmartFarmWeb.AbsinthePlug.GraphiQL, schema: SmartFarmWeb.AuthSchema
  forward "/graphiql", Absinthe.Plug.GraphiQL, schema: SmartFarmWeb.Schema

  scope "/api", SmartFarmWeb.API do
    pipe_through [:api, :api_authenticated]

    post "/users/avatar", FileController, :create_avatar
    post "/extension_services/medical_visit", ExtensionServiceController, :create_medical_visit
  end

  scope "/", SmartFarmWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/", DashboardLive.Index, :index
    live "/users/farmers", UserLive.Index, :farmer_index
    live "/users/farm_managers", UserLive.Index, :farm_manager_index
    live "/users/extension_officers", UserLive.Index, :extension_officer_index
    live "/users/vet_officers", UserLive.Index, :vet_officer_index
    live "/users/:id", UserLive.Show, :show
    live "/farms/reports", ReportLive.Index, :index
    live "/farms/:farm_id/report/:date", ReportLive.Index, :show
    live "/quotations/clusters", ClusterLive.Index, :index
    live "/quotations/clusters/new", ClusterLive.Index, :new
    live "/quotations/clusters/:id/edit", ClusterLive.Index, :edit
    live "/quotations/requests", QuotationRequestLive.Index, :index

    live "/quotations/requests/:requested_item_id/quotation",
         QuotationRequestLive.Index,
         :show_quotation

    live "/quotations/requests/:requested_item_id/quotation/new",
         QuotationRequestLive.Index,
         :new_quotation

    live "/vaccinations/", VaccinationLive.Index, :index
    live "/vaccinations/schedule", VaccinationLive.Index, :schedule
    live "/vaccinations/new", VaccinationLive.Index, :new
    live "/vaccinations/:id", VaccinationLive.Show, :show
    live "/vaccinations/:id/edit", VaccinationLive.Show, :edit
    live "/vaccinations/:id/create_schedule", VaccinationLive.Show, :new_schedule
  end

  scope "/", SmartFarmWeb do
    pipe_through :browser
    get "/login", SessionController, :new
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: SmartFarmWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
