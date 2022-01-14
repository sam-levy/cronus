defmodule Sig.Preloader do
  defmacro __using__([{schema, preloadable_fields}]) do
    quote bind_quoted: [schema: schema, preloadable_fields: preloadable_fields] do
      import Ecto.Query
      import Sig.Preloader

      for field_name <- preloadable_fields do
        def shallow_preload(queryable, unquote(field_name)) do
          if has_named_binding?(queryable, unquote(field_name)) do
            queryable
          else
            queryable
            |> join(:left, [{unquote(schema), s}], field in assoc(s, unquote(field_name)),
              as: unquote(field_name)
            )
            |> preload([{unquote(field_name), field}], [{unquote(field_name), field}])
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
    end
  end
end
