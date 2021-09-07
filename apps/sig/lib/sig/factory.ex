defmodule Sig.Factory do
  use Sig.Factories.EntityFactory
  use Sig.Factories.IndividualFactory

  def build(factory_name, attributes \\ []) do
    factory_name |> factory(attributes) |> struct(attributes)
  end

  def insert(factory_name, attributes \\ []) do
    factory_name |> build(attributes) |> Sig.Repo.insert!()
  end

  def build_list(amount, factory_name, attributes \\ []) do
    Stream.repeatedly(fn -> build(factory_name, attributes) end) |> Enum.take(amount)
  end

  def insert_list(amount, factory_name, attributes \\ []) do
    Stream.repeatedly(fn -> insert(factory_name, attributes) end) |> Enum.take(amount)
  end

  def factory(factory_name, _attributes), do: factory(factory_name)

  def random_enum_value(enum) do
    enum.__valid_values__()
    |> Enum.filter(&is_binary/1)
    |> Enum.random()
  end

  defp sequence(fun) when is_function(fun, 1) do
    fun.(System.unique_integer([:positive, :monotonic]))
  end
end
