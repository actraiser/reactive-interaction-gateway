defmodule RigInboundGateway.Events do
  @moduledoc """
  Utility functions used in more than one controller.
  """
  alias UUID

  alias Rig.Connection
  alias Rig.Subscription
  alias RigCloudEvents.CloudEvent

  @spec welcome_event(pid | nil) :: CloudEvent.t()
  def welcome_event(pid \\ self()) do
    connection_token = Connection.Codec.serialize(pid)

    rig_event(
      "rig.connection.create",
      %{connection_token: connection_token}
    )
  end

  @spec subscriptions_set([Subscription.t()]) :: CloudEvent.t()
  def subscriptions_set(subscriptions) do
    rig_event(
      "rig.subscriptions_set",
      Enum.map(subscriptions, fn %Subscription{event_type: event_type, constraints: constraints} ->
        %{"eventType" => event_type, "oneOf" => constraints}
      end)
    )
  end

  defp rig_event(type, data) do
    CloudEvent.parse!(%{
      specversion: "0.2",
      type: type,
      source: "rig",
      id: UUID.uuid4(),
      time: Timex.now() |> Timex.format!("{RFC3339}"),
      data: data
    })
  end
end
