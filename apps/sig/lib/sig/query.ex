defmodule Sig.Query do
  @callback filter_by(
              queryable :: Ecto.Queryable.t(),
              field :: atom(),
              value :: any()
            ) :: Ecto.Queryable.t()

  @callback shallow_preload(
              queryable :: Ecto.Queryable.t(),
              preload_name :: atom()
            ) :: Ecto.Queryable.t()

  defmacro __using__([{:schema, schema}, {:as, named_binding}]) do
    quote bind_quoted: [schema: schema, named_binding: named_binding] do
      @behaviour Sig.Query

      import Ecto.Query
      import Sig.Query

      defguard is_field(field) when field in unquote(schema.__schema__(:fields))
      defguard is_assoc(assoc) when assoc in unquote(schema.__schema__(:associations))

      def init_query do
        from(s in unquote(schema), as: unquote(named_binding))
      end

      defoverridable init_query: 0

      for assoc <- schema.__schema__(:associations) do
        defp do_join(queryable, unquote(assoc)) do
          if has_named_binding?(queryable, unquote(assoc)) do
            queryable
          else
            join(
              queryable,
              :left,
              [{unquote(named_binding), s}],
              field in assoc(s, unquote(assoc)),
              as: unquote(assoc)
            )
          end
        end

        defp do_shallow_preload(queryable, unquote(assoc)) do
          preload(queryable, [{unquote(assoc), field}], [{unquote(assoc), field}])
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

      def shallow_preload(queryable, assoc) when is_assoc(assoc) do
        queryable
        |> do_join(assoc)
        |> do_shallow_preload(assoc)
      end

      def reject_nil(queryable, field) when is_field(field) do
        where(
          queryable,
          [{unquote(named_binding), named_binding}],
          not is_nil(field(named_binding, ^field))
        )
      end

      def reject_nil(queryable, [{key, _} | _] = opts) when is_atom(key) do
        case Keyword.take(opts, [:reject_nil]) do
          [] ->
            queryable

          reject_nils ->
            Enum.reduce(reject_nils, queryable, fn {_, fields}, queryable ->
              Enum.reduce(fields, queryable, fn field, queryable ->
                reject_nil(queryable, field)
              end)
            end)
        end
      end

      def reject_nil(queryable, []), do: queryable

      @order_directions [
        :asc,
        :asc_nulls_last,
        :asc_nulls_first,
        :desc,
        :desc_nulls_last,
        :desc_nulls_first
      ]

      defguardp is_order_direction(direction) when direction in @order_directions

      def filter_by(queryable, field, %MapSet{} = values) when is_field(field) do
        filter_by(queryable, field, MapSet.to_list(values))
      end

      def filter_by(queryable, field, values) when is_field(field) and is_list(values) do
        where(
          queryable,
          [{unquote(named_binding), named_binding}],
          field(named_binding, ^field) in ^values
        )
      end

      def filter_by(queryable, field, nil) when is_field(field) do
        where(
          queryable,
          [{unquote(named_binding), named_binding}],
          is_nil(field(named_binding, ^field))
        )
      end

      def filter_by(queryable, field, value) when is_field(field) do
        where(
          queryable,
          [{unquote(named_binding), named_binding}],
          field(named_binding, ^field) == ^value
        )
      end

      def filter_by(queryable, [{key, _} | _] = opts) when is_atom(key) do
        case Keyword.take(opts, [:filter_by]) do
          [] ->
            queryable

          filter_bys ->
            Enum.reduce(filter_bys, queryable, fn {_, filters}, acc ->
              Enum.reduce(filters, acc, fn {field, value}, acc -> filter_by(acc, field, value) end)
            end)
        end
      end

      def filter_by(queryable, []), do: queryable

      def handle_order_by(queryable, field) when is_field(field) do
        do_order(queryable, field)
      end

      def handle_order_by(queryable, opts_or_fields) when is_list(opts_or_fields) do
        case Keyword.take(opts_or_fields, [:order_by]) do
          # is field list
          [] -> do_order(queryable, opts_or_fields)
          # is opts
          order_bys -> handle_order_bys_opts(queryable, order_bys)
        end
      end

      def handle_order_by(queryable, opts, default_fields)
          when is_list(opts) and (is_field(default_fields) or is_list(default_fields)) do
        case Keyword.take(opts, [:order_by]) do
          [] -> do_order(queryable, default_fields)
          order_bys -> handle_order_bys_opts(queryable, order_bys)
        end
      end

      defp handle_order_bys_opts(queryable, [{:order_by, _} | _] = order_bys) do
        Enum.reduce(order_bys, queryable, fn {_, fields}, queryable ->
          do_order(queryable, fields)
        end)
      end

      defp do_order(queryable, fields) when is_list(fields) do
        Enum.reduce(fields, queryable, fn
          # field with custom order direction
          {direction, field}, queryable when is_order_direction(direction) ->
            do_order(queryable, field, direction)

          # is association
          {assoc, assoc_fields}, queryable when is_assoc(assoc) ->
            do_order_by_assoc(queryable, assoc, assoc_fields)

          # field with default order direction
          field, queryable ->
            do_order(queryable, field)
        end)
      end

      defp do_order(queryable, field) when is_field(field) do
        order_by(
          queryable,
          [{unquote(named_binding), named_binding}],
          field(named_binding, ^field)
        )
      end

      defp do_order(queryable, _), do: queryable

      defp do_order(queryable, field, direction)
           when is_field(field) and is_order_direction(direction) do
        order_by(
          queryable,
          [{unquote(named_binding), named_binding}],
          [{^direction, field(named_binding, ^field)}]
        )
      end

      defp do_order(queryable, _, _), do: queryable

      defp do_order_by_assoc(queryable, assoc, assoc_fields)
           when is_assoc(assoc) and is_list(assoc_fields) do
        Enum.reduce(assoc_fields, queryable, fn
          # Association with custom order directio
          {direction, assoc_field}, queryable when is_order_direction(direction) ->
            do_order_by_assoc(queryable, assoc, assoc_field, direction)

          # Association with default order direction
          assoc_field, queryable ->
            do_order_by_assoc(queryable, assoc, assoc_field)
        end)
      end

      defp do_order_by_assoc(queryable, assoc, assoc_field)
           when is_assoc(assoc) and is_atom(assoc_field) do
        queryable
        |> do_join(assoc)
        |> order_by([{^assoc, assoc}], field(assoc, ^assoc_field))
      end

      defp do_order_by_assoc(queryable, assoc, assoc_field, direction)
           when is_assoc(assoc) and is_atom(assoc_field) and is_order_direction(direction) do
        queryable
        |> do_join(assoc)
        |> order_by([{^assoc, assoc}], [{^direction, field(assoc, ^assoc_field)}])
      end
    end
  end
end
