defmodule Amqp.Dto.SubmissionEvaluated do
  @derive Jason.Encoder
  defstruct [:case_results, :submission_id]
  alias Amqp.Dto.SubmissionEvaluated

  def new(
    submission_id,
    case_results
  ) when is_integer(submission_id) and is_list(case_results) do
    %SubmissionEvaluated{
      case_results: case_results,
      submission_id: submission_id,
    }
  end
end
