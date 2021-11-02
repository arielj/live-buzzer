defmodule Buzzer.Presence do
  use Phoenix.Presence, otp_app: :buzzer,
                        pubsub_server: Buzzer.PubSub
end
