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

    {:ok, event_to_send} = eval_submission(payload) |> Jason.encode()
    AMQP.Basic.publish(state.channel, "evaluated-submissions-topic", "", event_to_send)

    {:noreply, state}
  end

  def eval_submission(%{code: code, cases: cases, submission_id: submission_id}) do
    dir = "#{System.tmp_dir!()}\\submissions\\#{submission_id}"
    File.mkdir_p!(dir)
    code_file = "#{dir}\\code.cpp"
    exe_file = "#{dir}\\code.exe"
    File.write!(code_file, code)
    System.cmd("g++", [code_file, "-o", exe_file]) # TODO - Compilation errors

    test_results = cases
    |> Enum.with_index
    |> Enum.map(fn ({test_case, id}) -> run_test(
      exe_file,
      test_case,
      "#{dir}\\test-#{id}}"
    ) end)

    SubmissionEvaluated.new(submission_id, test_results)
  end

  defp run_test(
    exe_file,
    test_case,
    input_file
  ) do
    File.write!(input_file, test_case.input)
    # TODO - TL
    res = :os.cmd(:"type #{input_file} | #{exe_file}") |> List.to_string()
    actual = String.replace(res, ~r/(\r|\n)/, "")
    expected = String.replace(test_case.output, ~r/(\r|\n)/, "")
    if actual == expected do
      "OK"
    else
      "WA"
    end
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
