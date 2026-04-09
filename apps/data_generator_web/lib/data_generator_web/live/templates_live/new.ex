defmodule DataGeneratorWeb.TemplatesLive.New do
  use DataGeneratorWeb, :live_view

  alias DataGenerator.Templates
  alias DataGenerator.Templates.Template
  alias DataGenerator.Generator

  def mount(_params, _session, socket) do
    changeset = Templates.change_template(%Template{columns: []})
    types = Generator.list_types()
    user = socket.assigns.current_user
    enums = if user, do: DataGenerator.Enums.list_user_enums(user.id), else: []

    {:ok,
     assign(socket,
       page_title: "New Template",
       form: to_form(changeset, as: :template),
       types: types,
       enums: enums,
       columns: [default_column(0)],
       next_column_id: 1
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6 max-w-3xl">
        <div>
          <.link
            navigate={~p"/templates"}
            class="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 transition mb-2"
          >
            <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Templates
          </.link>
          <h1 class="text-2xl font-bold text-gray-900">New Template</h1>
          <p class="mt-1 text-sm text-gray-600">
            Define your data generation template with columns and types.
          </p>
        </div>

        <.form
          for={@form}
          id="template-form"
          phx-submit="save"
          phx-change="validate"
          class="space-y-6"
        >
          <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm space-y-4">
            <h2 class="text-lg font-semibold text-gray-900">Template Details</h2>
            <.input
              field={@form[:name]}
              type="text"
              label="Template Name"
              required
              phx-debounce="blur"
            />
            <.input
              field={@form[:description]}
              type="textarea"
              label="Description (optional)"
              phx-debounce="blur"
            />
            <.input
              field={@form[:number_of_rows]}
              type="number"
              label="Number of Rows"
              required
              min="1"
              phx-debounce="blur"
            />
          </div>
        </.form>

        <%!-- Columns section outside the form to allow <form> wrappers --%>
        <div class="rounded-xl border border-gray-200 bg-white shadow-sm">
          <div class="flex items-center justify-between border-b border-gray-200 px-6 py-4">
            <h2 class="text-lg font-semibold text-gray-900">Columns</h2>
            <button
              type="button"
              phx-click="add_column"
              class="inline-flex items-center gap-1.5 rounded-lg bg-blue-50 px-3 py-1.5 text-sm font-medium text-blue-600 hover:bg-blue-100 transition"
            >
              <.icon name="hero-plus" class="w-4 h-4" /> Add Column
            </button>
          </div>

          <div class="divide-y divide-gray-100">
            <%= for column <- @columns do %>
              <div class="px-6 py-4" id={"new-col-#{column.id}"}>
                <div class="flex items-start gap-4">
                  <div class="flex-1">
                    <label class="block text-xs font-medium text-gray-700 mb-1">Column Name</label>
                    <form phx-change="update_column" phx-value-id={column.id} phx-value-field="name">
                      <input
                        type="text"
                        name="value"
                        value={column.name}
                        class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
                        placeholder="column_name"
                      />
                    </form>
                  </div>
                  <div class="flex-1 min-w-0">
                    <label class="block text-xs font-medium text-gray-700 mb-1">Type</label>
                    <form phx-change="update_column_type" phx-value-id={column.id}>
                      <select
                        name="value"
                        class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500 transition"
                      >
                        <option value="">Select type...</option>
                        <%= for type <- @types do %>
                          <option value={type.name} selected={column.type_name == type.name}>
                            {type.name}
                          </option>
                        <% end %>
                      </select>
                    </form>
                  </div>

                  <div class="flex-1 min-w-0">
                    <.type_config column={column} enums={@enums} />
                  </div>
                  <div class="pt-6">
                    <button
                      type="button"
                      phx-click="remove_column"
                      phx-value-id={column.id}
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

        <div class="flex items-center justify-end gap-3">
          <.link
            navigate={~p"/templates"}
            class="rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm font-semibold text-gray-700 shadow-sm hover:bg-gray-50 transition"
          >
            Cancel
          </.link>
          <button
            type="submit"
            form="template-form"
            phx-disable-with="Saving..."
            class="rounded-lg bg-blue-500 px-6 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-600 transition"
          >
            Create Template
          </button>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp default_column(id) do
    %{id: id, name: "", type_name: "", type_id: nil, config: %{}}
  end

  def handle_event("validate", %{"template" => template_params}, socket) do
    changeset =
      %Template{columns: []}
      |> Templates.change_template(template_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: :template))}
  end

  def handle_event("add_column", _params, socket) do
    id = socket.assigns.next_column_id
    columns = socket.assigns.columns ++ [default_column(id)]
    {:noreply, assign(socket, columns: columns, next_column_id: id + 1)}
  end

  def handle_event("remove_column", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    columns = Elixir.Enum.reject(socket.assigns.columns, &(&1.id == id))
    {:noreply, assign(socket, columns: columns)}
  end

  def handle_event("update_column", %{"id" => id_str, "field" => field, "value" => value}, socket) do
    id = String.to_integer(id_str)

    columns =
      Elixir.Enum.map(socket.assigns.columns, fn col ->
        if col.id == id, do: Map.put(col, String.to_existing_atom(field), value), else: col
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
      Enum.map(socket.assigns.columns, fn col ->
        if col.id == id do
          parsed_value = parse_config_value(key, value)
          %{col | config: Map.put(col.config || %{}, key, parsed_value)}
        else
          col
        end
      end)

    {:noreply, assign(socket, columns: columns)}
  end

  # def handle_event("update_column_type", %{"id" => id_str} = params, socket) do
  #   IO.inspect(params, label: "params")
  #   id = String.to_integer(id_str)
  #   type_id_str = params["template"]["columns"]["#{id}"]["type_id"] || ""

  #   type_id =
  #     case Integer.parse(type_id_str) do
  #       {n, _} -> n
  #       :error -> nil
  #     end

  #   columns =
  #     Elixir.Enum.map(socket.assigns.columns, fn col ->
  #       if col.id == id, do: %{col | type_id: type_id}, else: col
  #     end)

  #   {:noreply, assign(socket, columns: columns)}
  # end

  def handle_event("update_column_type", %{"id" => id_str, "value" => type_name}, socket) do
    id = String.to_integer(id_str)

    type = Enum.find(socket.assigns.types, fn t -> t.name == type_name end)
    type_id = if type, do: type.id, else: nil

    columns =
      Enum.map(socket.assigns.columns, fn col ->
        if col.id == id do
          default_cfg = if type, do: default_config(type.name), else: %{}

          %{
            col
            | type_id: type_id,
              type_name: (type && type.name) || "",
              config: default_cfg
          }
        else
          col
        end
      end)

    {:noreply, assign(socket, columns: columns)}
  end

  def handle_event("save", %{"template" => template_params}, socket) do
    user = socket.assigns.current_user

    # Build columns from our tracked state
    columns_attrs =
      Elixir.Enum.map(socket.assigns.columns, fn col ->
        %{
          "name" => col.name,
          "type_id" => col.type_id,
          "config" => col.config
        }
      end)
      |> Elixir.Enum.reject(&(&1["name"] == "" || is_nil(&1["type_id"])))

    attrs = Map.put(template_params, "columns", columns_attrs)

    case Templates.create_template(user.id, attrs) do
      {:ok, _template} ->
        {:noreply,
         socket
         |> put_flash(:info, "Template created successfully.")
         |> push_navigate(to: ~p"/templates")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :template))}
    end
  end

  # parse config values to match Generate tab behaviour: numbers become numeric types
  defp parse_config_value("enum_id", value) when is_binary(value) do
    case Integer.parse(value) do
      {n, _} -> n
      :error -> value
    end
  end

  defp parse_config_value(_key, value) when is_binary(value) do
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

  defp parse_config_value(_key, value), do: value

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
end
