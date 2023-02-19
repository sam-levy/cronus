defmodule Sig.Accounting.Salables.SalableUnits do
  salable_units_file = Application.app_dir(:sig, "priv/assets/salable-units.json")
  @external_resource salable_units_file

  salable_units =
    salable_units_file
    |> File.read!()
    |> Jason.decode!()

  for %{"popular_code" => popular_code, "rf_code" => rf_code} <-
        salable_units do
    if is_binary(popular_code) do
      popular_code = popular_code |> String.trim() |> String.upcase()

      if popular_code == "" do
        raise CompileError, message: "empty popular_code"
      end

      def valid_salable_unit?(unquote(popular_code)), do: true
    end

    if is_binary(rf_code) do
      rf_code = rf_code |> String.trim() |> String.upcase()

      if rf_code == "" do
        raise CompileError, message: "empty rf_code"
      end

      def valid_salable_unit?(unquote(rf_code)), do: true
    end
  end

  def valid_salable_unit?(_), do: false
end
