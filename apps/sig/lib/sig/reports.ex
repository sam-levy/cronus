defmodule Sig.Reports do
  alias Sig.Reports.HR

  defdelegate employee_count_per_assigned_company(org), to: HR
end
