defmodule DataGeneratorWeb.GenerateDataLive do
  use DataGeneratorWeb, :live_view

  alias DataGenerator.Generator
  alias DataGenerator.Export
  alias DataGenerator.Templates
  alias DataGenerator.Enums
  alias DataGenerator.Projects

  # type options are now loaded dynamically from the database via Generator.list_types/0
  @type_options []

  @max_rows_unauthenticated 100
  @max_rows_authenticated 1_000_000

  def mount(_params, _session, socket) do
    columns = [default_column(0)]

    max_rows =
      if socket.assigns[:current_user],
        do: @max_rows_authenticated,
        else: @max_rows_unauthenticated

    user = socket.assigns.current_user
    templates = if user, do: Templates.list_user_templates(user.id), else: []
    types = if user, do: Generator.list_types(), else: Generator.list_types()

    # collect enums: user's enums plus enums owned by members of user's projects
    enums =
      if user do
        user_enums = Enums.list_user_enums(user.id)

        projects = Projects.list_user_projects(user.id)

        project_member_user_ids =
          projects
          |> Enum.flat_map(fn p -> Enum.map(p.project_members || [], & &1.user_id) end)
          |> Enum.uniq()

        other_user_ids = Enum.reject(project_member_user_ids, &(&1 == user.id))

        project_enums =
          other_user_ids
          |> Enum.flat_map(&Enums.list_user_enums/1)

        (user_enums ++ project_enums)
        |> Enum.uniq_by(& &1.id)
      else
        []
      end

    # templates: personal + grouped project templates for projects user is a member of
    user_templates = if user, do: Templates.list_user_templates(user.id), else: []

    project_template_groups =
      if user do
        Projects.list_user_projects(user.id)
        |> Enum.map(fn proj -> {proj, Projects.list_project_templates(proj.id)} end)
      else
        []
      end

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
       type_options: @type_options,
       templates: templates,
       types: types,
       enums: enums,
       user_templates: user_templates,
       project_template_groups: project_template_groups,
       mode: "ad_hoc",
       selected_template_id: nil
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
          </p>
        </div>

        <%!-- Column Builder --%>
        <div class="rounded-xl border border-gray-200 bg-white shadow-sm">
          <div class="flex items-center justify-between border-b border-gray-200 px-6 py-4">
            <h2 class="text-lg font-semibold text-gray-900">Column Definitions</h2>
            <div class="flex items-center gap-3">
              <%= if @current_user do %>
                <div class="text-sm text-gray-600">Mode:</div>
                <form phx-change="change_mode">
                  <select
                    name="value"
                    phx-debounce="0"
                    id="generate-mode"
                    class="rounded-lg border border-gray-300 px-2 py-1 text-sm"
                  >
                    <option value="ad_hoc" selected={@mode == "ad_hoc"}>Ad hoc</option>
                    <option value="template" selected={@mode == "template"}>From template</option>
                  </select>
                </form>
              <% end %>

              <%= if @mode == "template" do %>
                <form phx-change="select_template">
                  <select
                    name="value"
                    id="template-select"
                    class="rounded-lg border border-gray-300 px-2 py-1 text-sm"
                  >
                    <option value="">-- Select template --</option>
                    <%!-- user templates first --%>
                    <%= for t <- @user_templates do %>
                      <option value={t.id} selected={@selected_template_id == t.id}>{t.name}</option>
                    <% end %>

                    <%!-- divider --%>
                    <option disabled class="text-gray-400">-- Projects --</option>

                    <%!-- grouped project templates --%>
                    <%= for {proj, templates} <- @project_template_groups do %>
                      <option disabled class="text-gray-400">-- {proj.name} --</option>
                      <%= for pt <- templates do %>
                        <option value={pt.id} selected={@selected_template_id == pt.id}>
                          &nbsp;&nbsp;{pt.name}
                        </option>
                      <% end %>
                    <% end %>
                  </select>
                </form>
              <% end %>

              <button
                phx-click="add_column"
                type="button"
                class="inline-flex items-center gap-1.5 rounded-lg bg-blue-50 px-3 py-1.5 text-sm font-medium text-blue-600 hover:bg-blue-100 transition"
              >
                <.icon name="hero-plus" class="w-4 h-4" /> Add Column
              </button>
            </div>
          </div>

          <div class="divide-y divide-gray-100">
            <%= for column <- @columns do %>
              <div class="px-6 py-4" id={"column-#{column.id}"}>
                <div class="flex items-start gap-4">
                  <%!-- Column Name --%>
                  <div class="flex-1 min-w-0">
                    <label class="block text-xs font-medium text-gray-700 mb-1">Column Name</label>
                    <form phx-change="update_column_name" phx-value-id={column.id}>
                      <input
                        type="text"
                        name="column_name"
                        value={column.name}
                        class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500 transition"
                        placeholder="column_name"
                      />
                    </form>
                  </div>

                  <%!-- Type Selector --%>
                  <div class="flex-1 min-w-0">
                    <label class="block text-xs font-medium text-gray-700 mb-1">Data Type</label>
                    <form phx-change="update_column_type" phx-value-id={column.id}>
                      <select
                        name="type_name"
                        class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500 transition"
                      >
                        <option value="">-- Select Type --</option>
                        <%= for type <- @types do %>
                          <option value={type.name} selected={column.type_name == type.name}>
                            {type.name}
                          </option>
                        <% end %>
                      </select>
                    </form>
                  </div>

                  <%!-- Config (type-specific) --%>
                  <div class="flex-1 min-w-0">
                    <.type_config column={column} enums={@enums} />
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
              <form phx-change="update_row_count">
                <input
                  type="number"
                  name="row_count"
                  value={@row_count}
                  min="1"
                  max={@max_rows}
                  class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500 transition"
                />
              </form>

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

  # type-specific config is rendered via the shared <.type_config /> component

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

  def handle_event("update_column_name", %{"id" => id_str, "column_name" => name}, socket) do
    id = String.to_integer(id_str)

    columns =
      Elixir.Enum.map(socket.assigns.columns, fn col ->
        if col.id == id, do: %{col | name: sanitize_column_name(name)}, else: col
      end)

    {:noreply, assign(socket, columns: columns)}
  end

  def handle_event("update_column_type", %{"id" => id_str, "type_name" => type_name}, socket) do
    id = String.to_integer(id_str)

    columns =
      Elixir.Enum.map(socket.assigns.columns, fn col ->
        if col.id == id,
          do: %{col | type_name: type_name, config: default_config(type_name)},
          else: col
      end)

    {:noreply, assign(socket, columns: columns)}
  end

  def handle_event("change_mode", %{"value" => mode}, socket) do
    {:noreply, assign(socket, mode: mode)}
  end

  def handle_event("select_template", %{"value" => ""}, socket) do
    {:noreply, assign(socket, selected_template_id: nil)}
  end

  def handle_event("select_template", %{"value" => id_str}, socket) do
    id = String.to_integer(id_str)

    # load template with columns
    template = Templates.get_template_with_columns!(id)

    # convert template columns to local column format
    columns =
      Enum.map(template.columns, fn c ->
        %{
          id: c.id,
          name: c.name,
          type_name: (c.type && c.type.name) || "",
          config: c.config || %{}
        }
      end)

    ids = Enum.map(columns, & &1.id)
    max_id = if ids == [], do: 0, else: Enum.max(ids)
    next_id = max_id + 1

    {:noreply,
     assign(socket,
       columns: columns,
       next_id: next_id,
       row_count: template.number_of_rows || socket.assigns.row_count,
       selected_template_id: id
     )}
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
          %{col | config: Map.put(col.config || %{}, key, maybe_parse_number(value))}
        else
          col
        end
      end)

    {:noreply, assign(socket, columns: columns)}
  end

  def handle_event("update_row_count", params, socket) do
    value = params["row_count"] || params["value"] || "10"

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

  defp default_config("integer"), do: %{"min" => 0, "max" => 1000, "step" => 1, "null_prob" => 0}

  defp default_config("float"),
    do: %{"min" => 0, "max" => 100, "precision" => 2, "null_prob" => 0}

  defp default_config("string"),
    do: %{
      "length" => 10,
      "charset" => "alphanumeric",
      "prefix" => "",
      "suffix" => "",
      "null_prob" => 0
    }

  defp default_config("regex"), do: %{"pattern" => ""}
  defp default_config("enum"), do: %{"values" => []}

  defp default_config("date"),
    do: %{"from" => "2020-01-01", "to" => "2025-12-31", "timezone" => "UTC"}

  defp default_config("datetime"),
    do: %{
      "from" => "2020-01-01T00:00:00",
      "to" => "2025-12-31T23:59:59",
      "timezone" => "UTC"
    }

  defp default_config("price"), do: %{"currency" => ""}
  defp default_config(_), do: %{}

  defp prepare_config("enum", config) do
    # if enum_id present, fetch enum values from DB, otherwise fall back to inline values
    case Map.get(config, "enum_id") do
      id when is_integer(id) and id > 0 ->
        enum = Enums.get_enum!(id)
        values = Enum.map(enum.enum_values || [], & &1.value)
        Map.put(config, "values", values)

      id when is_binary(id) ->
        case Integer.parse(id) do
          {n, _} ->
            enum = Enums.get_enum!(n)
            values = Enum.map(enum.enum_values || [], & &1.value)
            Map.put(config, "values", values)

          _ ->
            # fallback to comma-separated string
            v = Map.get(config, "values") || ""

            values =
              v |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

            Map.put(config, "values", values)
        end

      _ ->
        values =
          case Map.get(config, "values") do
            v when is_binary(v) ->
              v |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

            v when is_list(v) ->
              v

            _ ->
              []
          end

        Map.put(config, "values", values)
    end
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
