defmodule DataGeneratorWeb.GenerateDataLive do
  use DataGeneratorWeb, :live_view

  alias DataGenerator.Generator
  alias DataGenerator.Export

  @type_options [
    {"-- Select Type --", ""},
    {"Personal", :disabled},
    {"First Name", "first_name"},
    {"Last Name", "last_name"},
    {"Email", "email"},
    {"Phone", "phone"},
    {"Address", :disabled},
    {"City", "city"},
    {"Country", "country"},
    {"Street", "street"},
    {"Zip Code", "zip_code"},
    {"Internet", :disabled},
    {"URL", "url"},
    {"IP Address", "ip_address"},
    {"Domain", "domain"},
    {"Commerce", :disabled},
    {"Price", "price"},
    {"Product Name", "product_name"},
    {"Company", "company"},
    {"Primitives", :disabled},
    {"Integer", "integer"},
    {"Float", "float"},
    {"String", "string"},
    {"Boolean", "boolean"},
    {"Date", "date"},
    {"Datetime", "datetime"},
    {"UUID", "uuid"},
    {"Advanced", :disabled},
    {"Regex Pattern", "regex"},
    {"Custom Enum", "enum"}
  ]

  @max_rows_unauthenticated 100
  @max_rows_authenticated 1_000_000

  def mount(_params, _session, socket) do
    columns = [default_column(0)]

    max_rows =
      if socket.assigns[:current_user],
        do: @max_rows_authenticated,
        else: @max_rows_unauthenticated

    {:ok,
     assign(socket,
       page_title: "Generate Data",
       columns: columns,
       next_id: 1,
       row_count: 10,
       max_rows: max_rows,
       generated_data: nil,
       generating: false,
       preview_columns: [],
       type_options: @type_options
     )}
  end

  defp default_column(id) do
    %{
      id: id,
      name: "column_#{id}",
      type_name: "",
      config: %{}
    }
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-8">
        <%!-- Header --%>
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Generate Data</h1>
          <p class="mt-1 text-sm text-gray-600">
            Define your columns, choose data types, and generate realistic mock data instantly.
            <%= if !@current_user do %>
              <.link navigate={~p"/register"} class="text-blue-500 hover:text-blue-600 font-semibold">
                Sign up
              </.link>
              to generate up to 1M rows and export data.
            <% end %>
          </p>
        </div>

        <%!-- Column Builder --%>
        <div class="rounded-xl border border-gray-200 bg-white shadow-sm">
          <div class="flex items-center justify-between border-b border-gray-200 px-6 py-4">
            <h2 class="text-lg font-semibold text-gray-900">Column Definitions</h2>
            <button
              phx-click="add_column"
              type="button"
              class="inline-flex items-center gap-1.5 rounded-lg bg-blue-50 px-3 py-1.5 text-sm font-medium text-blue-600 hover:bg-blue-100 transition"
            >
              <.icon name="hero-plus" class="w-4 h-4" /> Add Column
            </button>
          </div>

          <div class="divide-y divide-gray-100">
            <%= for column <- @columns do %>
              <div class="px-6 py-4" id={"column-#{column.id}"}>
                <div class="flex items-start gap-4">
                  <%!-- Column Name --%>
                  <div class="flex-1 min-w-0">
                    <label class="block text-xs font-medium text-gray-700 mb-1">Column Name</label>
                    <input
                      type="text"
                      value={column.name}
                      phx-blur="update_column_name"
                      phx-value-id={column.id}
                      class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500 transition"
                      placeholder="column_name"
                    />
                  </div>

                  <%!-- Type Selector --%>
                  <div class="flex-1 min-w-0">
                    <label class="block text-xs font-medium text-gray-700 mb-1">Data Type</label>
                    <select
                      phx-blur="update_column_type"
                      phx-value-id={column.id}
                      class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500 transition"
                    >
                      <%= for {label, value} <- @type_options do %>
                        <%= if value == :disabled do %>
                          <option disabled class="font-semibold text-gray-400">{label}</option>
                        <% else %>
                          <option value={value} selected={column.type_name == value}>{label}</option>
                        <% end %>
                      <% end %>
                    </select>
                  </div>

                  <%!-- Config (type-specific) --%>
                  <div class="flex-1 min-w-0">
                    <.type_config column={column} />
                  </div>

                  <%!-- Remove Button --%>
                  <div class="pt-6">
                    <button
                      phx-click="remove_column"
                      phx-value-id={column.id}
                      type="button"
                      class={[
                        "rounded-lg p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 transition",
                        length(@columns) <= 1 && "opacity-30 pointer-events-none"
                      ]}
                      disabled={length(@columns) <= 1}
                    >
                      <.icon name="hero-trash" class="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <%!-- Generation Controls --%>
        <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
          <div class="flex flex-wrap items-end gap-6">
            <div class="flex-1 min-w-48">
              <label class="block text-sm font-medium text-gray-700 mb-1">Number of Rows</label>
              <input
                type="number"
                value={@row_count}
                phx-blur="update_row_count"
                min="1"
                max={@max_rows}
                class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500 transition"
              />
              <p class="mt-1 text-xs text-gray-500">Max: {Integer.to_string(@max_rows)} rows</p>
            </div>
            <div>
              <button
                phx-click="generate"
                disabled={@generating}
                class={[
                  "inline-flex items-center gap-2 rounded-lg px-6 py-2.5 text-sm font-semibold text-white shadow-sm transition",
                  if(@generating,
                    do: "bg-gray-400 cursor-not-allowed",
                    else: "bg-blue-500 hover:bg-blue-600"
                  )
                ]}
              >
                <%= if @generating do %>
                  <.icon name="hero-arrow-path" class="w-4 h-4 animate-spin" /> Generating...
                <% else %>
                  <.icon name="hero-bolt" class="w-4 h-4" /> Generate Data
                <% end %>
              </button>
            </div>
          </div>
        </div>

        <%!-- Results --%>
        <%= if @generated_data do %>
          <div
            id="data-results"
            phx-hook="Download"
            class="rounded-xl border border-gray-200 bg-white shadow-sm"
          >
            <div class="flex items-center justify-between border-b border-gray-200 px-6 py-4">
              <h2 class="text-lg font-semibold text-gray-900">
                Preview
                <span class="text-sm font-normal text-gray-500">
                  (showing {min(length(@generated_data), 50)} of {length(@generated_data)} rows)
                </span>
              </h2>
              <%= if @current_user do %>
                <div class="flex items-center gap-2">
                  <button
                    phx-click="export"
                    phx-value-format="csv"
                    class="inline-flex items-center gap-1.5 rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 transition"
                  >
                    <.icon name="hero-arrow-down-tray" class="w-4 h-4" /> CSV
                  </button>
                  <button
                    phx-click="export"
                    phx-value-format="json"
                    class="inline-flex items-center gap-1.5 rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 transition"
                  >
                    <.icon name="hero-arrow-down-tray" class="w-4 h-4" /> JSON
                  </button>
                  <button
                    phx-click="export"
                    phx-value-format="sql"
                    class="inline-flex items-center gap-1.5 rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 transition"
                  >
                    <.icon name="hero-arrow-down-tray" class="w-4 h-4" /> SQL
                  </button>
                </div>
              <% else %>
                <p class="text-sm text-gray-500">
                  <.link
                    navigate={~p"/register"}
                    class="text-blue-500 hover:text-blue-600 font-semibold"
                  >
                    Sign up
                  </.link>
                  to export data
                </p>
              <% end %>
            </div>

            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                      #
                    </th>
                    <%= for col_name <- @preview_columns do %>
                      <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                        {col_name}
                      </th>
                    <% end %>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 bg-white">
                  <%= for {row, index} <- @generated_data |> Elixir.Enum.take(50) |> Elixir.Enum.with_index(1) do %>
                    <tr class="hover:bg-gray-50 transition">
                      <td class="whitespace-nowrap px-4 py-2.5 text-xs text-gray-400 font-mono">
                        {index}
                      </td>
                      <%= for col_name <- @preview_columns do %>
                        <td class="whitespace-nowrap px-4 py-2.5 text-sm text-gray-900 font-mono">
                          {format_cell(row[col_name])}
                        </td>
                      <% end %>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  # Type-specific config inputs
  defp type_config(%{column: %{type_name: "integer"}} = assigns) do
    ~H"""
    <label class="block text-xs font-medium text-gray-700 mb-1">Range</label>
    <div class="flex items-center gap-2">
      <input
        type="number"
        value={@column.config["min"] || 0}
        phx-blur="update_column_config"
        phx-value-id={@column.id}
        phx-value-key="min"
        class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
        placeholder="Min"
      />
      <span class="text-gray-400">-</span>
      <input
        type="number"
        value={@column.config["max"] || 1000}
        phx-blur="update_column_config"
        phx-value-id={@column.id}
        phx-value-key="max"
        class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
        placeholder="Max"
      />
    </div>
    """
  end

  defp type_config(%{column: %{type_name: "float"}} = assigns) do
    ~H"""
    <label class="block text-xs font-medium text-gray-700 mb-1">Range & Precision</label>
    <div class="flex items-center gap-2">
      <input
        type="number"
        value={@column.config["min"] || 0}
        phx-blur="update_column_config"
        phx-value-id={@column.id}
        phx-value-key="min"
        step="any"
        class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
        placeholder="Min"
      />
      <span class="text-gray-400">-</span>
      <input
        type="number"
        value={@column.config["max"] || 100}
        phx-blur="update_column_config"
        phx-value-id={@column.id}
        phx-value-key="max"
        step="any"
        class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
        placeholder="Max"
      />
    </div>
    """
  end

  defp type_config(%{column: %{type_name: "string"}} = assigns) do
    ~H"""
    <label class="block text-xs font-medium text-gray-700 mb-1">Length</label>
    <input
      type="number"
      value={@column.config["length"] || 10}
      phx-blur="update_column_config"
      phx-value-id={@column.id}
      phx-value-key="length"
      min="1"
      max="1000"
      class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
      placeholder="Length"
    />
    """
  end

  defp type_config(%{column: %{type_name: "regex"}} = assigns) do
    ~H"""
    <label class="block text-xs font-medium text-gray-700 mb-1">Pattern</label>
    <input
      type="text"
      value={@column.config["pattern"] || ""}
      phx-blur="update_column_config"
      phx-value-id={@column.id}
      phx-value-key="pattern"
      class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm font-mono shadow-sm focus:border-blue-500 focus:ring-blue-500"
      placeholder="[A-Z]{3}-\\d{4}"
    />
    """
  end

  defp type_config(%{column: %{type_name: "enum"}} = assigns) do
    ~H"""
    <label class="block text-xs font-medium text-gray-700 mb-1">Values (comma-separated)</label>
    <input
      type="text"
      value={@column.config["values"] || ""}
      phx-blur="update_column_config"
      phx-value-id={@column.id}
      phx-value-key="values"
      class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
      placeholder="red, green, blue"
    />
    """
  end

  defp type_config(assigns) do
    ~H"""
    <label class="block text-xs font-medium text-gray-700 mb-1">Config</label>
    <p class="text-xs text-gray-400 py-2">No additional configuration needed.</p>
    """
  end

  # Event handlers

  def handle_event("add_column", _params, socket) do
    id = socket.assigns.next_id
    columns = socket.assigns.columns ++ [default_column(id)]
    {:noreply, assign(socket, columns: columns, next_id: id + 1)}
  end

  def handle_event("remove_column", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    columns = Elixir.Enum.reject(socket.assigns.columns, &(&1.id == id))
    {:noreply, assign(socket, columns: columns)}
  end

  def handle_event("update_column_name", %{"id" => id_str, "value" => name}, socket) do
    id = String.to_integer(id_str)

    columns =
      Elixir.Enum.map(socket.assigns.columns, fn col ->
        if col.id == id, do: %{col | name: sanitize_column_name(name)}, else: col
      end)

    {:noreply, assign(socket, columns: columns)}
  end

  def handle_event("update_column_type", %{"id" => id_str, "value" => type_name}, socket) do
    id = String.to_integer(id_str)

    columns =
      Elixir.Enum.map(socket.assigns.columns, fn col ->
        if col.id == id,
          do: %{col | type_name: type_name, config: default_config(type_name)},
          else: col
      end)

    {:noreply, assign(socket, columns: columns)}
  end

  def handle_event(
        "update_column_config",
        %{"id" => id_str, "key" => key, "value" => value},
        socket
      ) do
    id = String.to_integer(id_str)

    columns =
      Elixir.Enum.map(socket.assigns.columns, fn col ->
        if col.id == id do
          %{col | config: Map.put(col.config, key, maybe_parse_number(value))}
        else
          col
        end
      end)

    {:noreply, assign(socket, columns: columns)}
  end

  def handle_event("update_row_count", %{"value" => value}, socket) do
    row_count =
      case Integer.parse(value) do
        {n, _} -> min(max(n, 1), socket.assigns.max_rows)
        :error -> 10
      end

    {:noreply, assign(socket, row_count: row_count)}
  end

  def handle_event("generate", _params, socket) do
    columns = socket.assigns.columns
    row_count = socket.assigns.row_count

    # Validate all columns have types
    invalid = Elixir.Enum.any?(columns, &(&1.type_name == ""))

    if invalid do
      {:noreply, put_flash(socket, :error, "All columns must have a data type selected.")}
    else
      socket = assign(socket, generating: true)

      # Build column specs for the engine, converting enum values from string to list
      column_specs =
        Elixir.Enum.map(columns, fn col ->
          config = prepare_config(col.type_name, col.config)

          %{
            "name" => col.name,
            "type_name" => col.type_name,
            "config" => config
          }
        end)

      case Generator.generate_data(column_specs, row_count) do
        {:ok, data} ->
          preview_columns = Elixir.Enum.map(columns, & &1.name)

          {:noreply,
           assign(socket,
             generated_data: data,
             preview_columns: preview_columns,
             generating: false
           )}

        {:error, reason} ->
          {:noreply,
           socket
           |> put_flash(:error, "Generation failed: #{reason}")
           |> assign(generating: false)}
      end
    end
  end

  def handle_event("export", %{"format" => format}, socket) do
    if socket.assigns.current_user do
      data = socket.assigns.generated_data

      case Export.export(data, format, table_name: "generated_data") do
        {:ok, content} ->
          filename = "generated_data.#{format}"

          {:noreply,
           push_event(socket, "download", %{
             content: content,
             filename: filename,
             content_type: content_type(format)
           })}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Export failed: #{reason}")}
      end
    else
      {:noreply, put_flash(socket, :error, "Please sign up to export data.")}
    end
  end

  # Helpers

  defp sanitize_column_name(name) do
    name
    |> String.trim()
    |> String.replace(~r/[^a-zA-Z0-9_]/, "_")
    |> case do
      "" -> "column"
      sanitized -> sanitized
    end
  end

  defp default_config("integer"), do: %{"min" => 0, "max" => 1000}
  defp default_config("float"), do: %{"min" => 0, "max" => 100}
  defp default_config("string"), do: %{"length" => 10}
  defp default_config("regex"), do: %{"pattern" => ""}
  defp default_config("enum"), do: %{"values" => ""}
  defp default_config(_), do: %{}

  defp prepare_config("enum", config) do
    values =
      case Map.get(config, "values") do
        v when is_binary(v) ->
          v
          |> String.split(",")
          |> Elixir.Enum.map(&String.trim/1)
          |> Elixir.Enum.reject(&(&1 == ""))

        v when is_list(v) ->
          v

        _ ->
          []
      end

    Map.put(config, "values", values)
  end

  defp prepare_config(_type, config), do: config

  defp maybe_parse_number(value) when is_binary(value) do
    case Integer.parse(value) do
      {n, ""} ->
        n

      _ ->
        case Float.parse(value) do
          {f, ""} -> f
          _ -> value
        end
    end
  end

  defp maybe_parse_number(value), do: value

  defp format_cell(nil), do: ""
  defp format_cell(value) when is_binary(value), do: value
  defp format_cell(value), do: inspect(value)

  defp content_type("csv"), do: "text/csv"
  defp content_type("json"), do: "application/json"
  defp content_type("sql"), do: "text/plain"
  defp content_type(_), do: "text/plain"
end
