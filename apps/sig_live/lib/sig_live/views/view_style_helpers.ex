defmodule SigLive.ViewStyleHelpers do
  def payslip_type_text_color(:regular), do: ~w(text-blue-400)
  def payslip_type_text_color(:vacation), do: ~w(text-purple-400)
  def payslip_type_text_color(:first_13), do: ~w(text-indigo-400)
  def payslip_type_text_color(:second_13), do: ~w(text-indigo-400)
  def payslip_type_text_color(:extra), do: ~w(text-yellow-400)
  def payslip_type_text_color(_type), do: ~w(text-gray-400)
end
