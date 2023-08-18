defmodule JudgeWorker do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: :rabbit)
  end

  def handle_info({:basic_deliver, payload, _meta}, state) do
    Logger.info(payload)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warn("Received unknown msg #{inspect(msg)}")
    {:noreply, state}
  end

  def init(:ok) do
    config = Application.get_env(:judge_worker, Rabbit)
    {:ok, connection} = AMQP.Connection.open(
      username: config[:username],
      password: config[:password]
    )
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Basic.consume(channel, "new-submissions-queue", nil, no_ack: true)
    {:ok, %{channel: channel, connection: connection}}
  end

  def terminate(_, state) do
    AMQP.Connection.close(state.connection)
  end
end
