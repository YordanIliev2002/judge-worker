defmodule JudgeWorker do
  use GenServer
  require Logger
  alias Amqp.Dto.SubmissionEvaluated

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: :rabbit)
  end

  def handle_info({:basic_deliver, json_payload, _meta} = event, state) do
    Logger.debug("Received event: #{inspect(event)}")
    {:ok, payload} = Jason.decode(json_payload, keys: :atoms)

    {:ok, event_to_send} = eval_submission(payload)
      |> Jason.encode()
    AMQP.Basic.publish(state.channel, "evaluated-submissions-topic", "", event_to_send)

    {:noreply, state}
  end

  def eval_submission(%{code: _code, cases: cases, submission_id: submission_id}) do
    # TODO - actual logic
    results = cases
    |> Enum.map(fn x -> "OK" end)

    SubmissionEvaluated.new(submission_id, results)
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
