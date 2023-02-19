defmodule Sig.Accounting.Salables.SalableUnitsTest do
  use Sig.DataCase, async: true

  alias Sig.Accounting.Salables.SalableUnits

  describe "valid_salable_unit?" do
    assert SalableUnits.valid_salable_unit?("KG")
    assert SalableUnits.valid_salable_unit?("BISNAGA")

    refute SalableUnits.valid_salable_unit?("INVALID")
  end
end
