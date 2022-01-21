defmodule Sig.Query do
  @callback filter_by(
              queryable :: Ecto.Queryable.t(),
              filter_key :: atom(),
              filter_value :: any()
            ) :: Ecto.Queryable.t()

  defmacro __using__([{:schema, schema}, {:as, named_binding}]) do
    quote bind_quoted: [schema: schema, named_binding: named_binding] do
      @behaviour Sig.Query

      import Ecto.Query
      import Sig.Query

      def init_query do
        from(s in unquote(schema), as: unquote(named_binding))
      end

      for association <- schema.__schema__(:associations) do
        def shallow_preload(queryable, unquote(association)) do
          if has_named_binding?(queryable, unquote(association)) do
            queryable
          else
            queryable
            |> join(:left, [{unquote(named_binding), s}], field in assoc(s, unquote(association)),
              as: unquote(association)
            )
            |> preload([{unquote(association), field}], [{unquote(association), field}])
          end
        end
      end

      def shallow_preload(queryable, []), do: queryable

      def shallow_preload(queryable, [{key, _} | _] = opts) when is_atom(key) do
        case Keyword.get(opts, :preload, []) do
          [] -> queryable
          field_or_fields -> shallow_preload(queryable, field_or_fields)
        end
      end

      def shallow_preload(queryable, fields) when is_list(fields) do
        Enum.reduce(fields, queryable, &shallow_preload(&2, &1))
      end

      def filter_by(queryable, filter_key, %MapSet{} = filter_values)
          when filter_key in unquote(schema.__schema__(:fields)) do
        filter_by(queryable, filter_key, MapSet.to_list(filter_values))
      end

      def filter_by(queryable, filter_key, filter_values)
          when filter_key in unquote(schema.__schema__(:fields)) and is_list(filter_values) do
        where(
          queryable,
          [{unquote(named_binding), named_binding}],
          field(named_binding, ^filter_key) in ^filter_values
        )
      end

      def filter_by(queryable, filter_key, filter_value)
          when filter_key in unquote(schema.__schema__(:fields)) do
        where(
          queryable,
          [{unquote(named_binding), named_binding}],
          field(named_binding, ^filter_key) == ^filter_value
        )
      end

      def filter_by(queryable, [{key, _} | _] = opts) when is_atom(key) do
        case Keyword.take(opts, [:filter_by]) do
          [] ->
            queryable

          filter_bys ->
            Enum.reduce(filter_bys, queryable, fn {_, filters}, acc ->
              Enum.reduce(filters, acc, fn {filter_key, filter_value}, acc ->
                filter_by(acc, filter_key, filter_value)
              end)
            end)
        end
      end

      def filter_by(queryable, []), do: queryable
    end
  end
end
