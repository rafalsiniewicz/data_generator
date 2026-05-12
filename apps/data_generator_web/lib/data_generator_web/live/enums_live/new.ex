defmodule DataGeneratorWeb.EnumsLive.New do
  use DataGeneratorWeb, :live_view

  alias DataGenerator.Enums
  alias DataGenerator.Enums.Enum, as: UserEnum

  def mount(_params, _session, socket) do
    changeset =
      Enums.change_enum(%UserEnum{user_id: socket.assigns.current_user.id, enum_values: []})

    {:ok,
     assign(socket,
       page_title: "New Enum",
       form: to_form(changeset, as: :enum),
       values: [%{temp_id: "val-0", value: ""}],
       next_value_id: 1
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6 max-w-xl">
        <div>
          <.link
            navigate={~p"/enums"}
            class="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 transition mb-2"
          >
            <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Enums
          </.link>
          <h1 class="text-2xl font-bold text-gray-900">New Enum</h1>
          <p class="mt-1 text-sm text-gray-600">
            Create a custom value set for use in data generation.
          </p>
        </div>

        <.form for={@form} id="enum-form" phx-change="validate" phx-submit="save" class="space-y-6">
          <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm space-y-4">
            <.input
              field={@form[:name]}
              type="text"
              label="Enum Name"
              required
              placeholder="e.g. colors, statuses, sizes"
            />
          </div>

          <div class="rounded-xl border border-gray-200 bg-white shadow-sm">
            <div class="flex items-center justify-between border-b border-gray-200 px-6 py-4">
              <h2 class="text-lg font-semibold text-gray-900">Values</h2>
              <button
                type="button"
                phx-click="add_value"
                class="inline-flex items-center gap-1.5 rounded-lg bg-blue-50 px-3 py-1.5 text-sm font-medium text-blue-600 hover:bg-blue-100 transition"
              >
                <.icon name="hero-plus" class="w-4 h-4" /> Add Value
              </button>
            </div>

            <div class="divide-y divide-gray-100">
              <%= for val <- @values do %>
                <div class="flex items-center gap-3 px-6 py-3" id={"value-#{val.temp_id}"}>
                  <input
                    type="text"
                    name={"values[#{val.temp_id}]"}
                    value={val.value}
                    class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 focus:outline-none"
                    placeholder="Enter value..."
                  />
                  <button
                    type="button"
                    phx-click="remove_value"
                    phx-value-id={val.temp_id}
                    class={[
                      "shrink-0 rounded-lg p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 transition",
                      length(@values) <= 1 && "opacity-30 pointer-events-none"
                    ]}
                    disabled={length(@values) <= 1}
                  >
                    <.icon name="hero-x-mark" class="w-4 h-4" />
                  </button>
                </div>
              <% end %>
            </div>
          </div>

          <div class="flex items-center justify-end gap-3">
            <.link
              navigate={~p"/enums"}
              class="rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm font-semibold text-gray-700 shadow-sm hover:bg-gray-50 transition"
            >
              Cancel
            </.link>
            <.button
              type="submit"
              phx-disable-with="Saving..."
              class="rounded-lg bg-blue-500 px-6 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-600 transition"
            >
              Create Enum
            </.button>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("validate", %{"enum" => enum_params} = params, socket) do
    values = sync_values_from_params(params, socket.assigns.values)
    changeset = build_changeset(socket, enum_params, values)

    {:noreply,
     assign(socket,
       form: to_form(changeset, as: :enum, action: :validate),
       values: values
     )}
  end

  def handle_event("add_value", _params, socket) do
    id = socket.assigns.next_value_id
    temp_id = "val-#{id}"
    values = socket.assigns.values ++ [%{temp_id: temp_id, value: ""}]
    {:noreply, assign(socket, values: values, next_value_id: id + 1)}
  end

  def handle_event("remove_value", %{"id" => temp_id}, socket) do
    values = Elixir.Enum.reject(socket.assigns.values, &(&1.temp_id == temp_id))
    {:noreply, assign(socket, values: values)}
  end

  def handle_event("save", %{"enum" => enum_params} = params, socket) do
    user = socket.assigns.current_user
    values = sync_values_from_params(params, socket.assigns.values)

    enum_values =
      values
      |> Elixir.Enum.reject(&(&1.value == ""))
      |> Elixir.Enum.map(&%{"value" => &1.value})

    attrs = Map.put(enum_params, "enum_values", enum_values)

    case Enums.create_enum(user.id, attrs) do
      {:ok, _enum} ->
        {:noreply,
         socket
         |> put_flash(:info, "Enum created successfully.")
         |> push_navigate(to: ~p"/enums")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :enum))}
    end
  end

  defp sync_values_from_params(%{"values" => values_params}, current_values) do
    Elixir.Enum.map(current_values, fn val ->
      %{val | value: Map.get(values_params, val.temp_id, val.value)}
    end)
  end

  defp sync_values_from_params(_params, current_values), do: current_values

  defp build_changeset(socket, enum_params, values) do
    enum_values =
      values
      |> Elixir.Enum.reject(&(&1.value == ""))
      |> Elixir.Enum.map(&%{"value" => &1.value})

    attrs = Map.put(enum_params, "enum_values", enum_values)
    user_id = socket.assigns.current_user.id

    Enums.change_enum(%UserEnum{user_id: user_id, enum_values: []}, attrs)
  end
end
