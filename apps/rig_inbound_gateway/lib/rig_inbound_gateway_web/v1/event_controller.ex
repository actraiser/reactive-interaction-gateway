defmodule RigInboundGatewayWeb.V1.EventController do
  @moduledoc """
  Publish a CloudEvent.
  """
  require Logger
  use Rig.Config, [:cors]

  use RigInboundGatewayWeb, :controller

  alias Rig.CloudEvent
  alias Rig.EventHub
  alias RigAuth.AuthorizationCheck.Submission

  @doc false
  def handle_preflight(%{method: "OPTIONS"} = conn, _params) do
    conn
    |> with_allow_origin()
    |> put_resp_header("access-control-allow-methods", "POST")
    |> put_resp_header("access-control-allow-headers", "content-type")
    |> send_resp(:no_content, "")
  end

  defp with_allow_origin(conn) do
    %{cors: origins} = config()
    put_resp_header(conn, "access-control-allow-origin", origins)
  end

  @doc "Plug action to send a CloudEvent to subscribers."
  def publish(%{method: "POST"} = conn, _params) do
    conn = with_allow_origin(conn)

    with {:ok, cloud_event} <- CloudEvent.parse(conn.body_params),
         :ok <- Submission.check_authorization(conn, cloud_event) do
      EventHub.publish(cloud_event)

      conn
      |> put_status(:accepted)
      |> json(cloud_event |> CloudEvent.to_json_map())
    else
      {:error, :not_authorized} ->
        conn |> put_status(:forbidden) |> text("Submission denied.")

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> text("Failed to parse request body: #{inspect(reason)}")
    end
  end
end
