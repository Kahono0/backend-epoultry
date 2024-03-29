defmodule SmartFarmWeb.ClusterLive.FormComponent do
  use SmartFarmWeb, :live_component

  alias SmartFarm.Quotations

  @impl true
  def update(%{cluster: cluster} = assigns, socket) do
    changeset = Quotations.Cluster.changeset(cluster, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"cluster" => cluster_params}, socket) do
    changeset =
      socket.assigns.cluster
      |> Quotations.Cluster.changeset(cluster_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"cluster" => cluster_params}, socket) do
    save_cluster(socket, socket.assigns.action, cluster_params)
  end

  defp save_cluster(socket, :edit, cluster_params) do
    case Quotations.update_cluster(socket.assigns.cluster, cluster_params) do
      {:ok, _cluster} ->
        {:noreply,
         socket
         |> put_flash(:info, "Cluster updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_cluster(socket, :new, cluster_params) do
    case Quotations.create_cluster(cluster_params) do
      {:ok, _cluster} ->
        {:noreply,
         socket
         |> put_flash(:info, "Cluster created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
