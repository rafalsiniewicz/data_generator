defmodule DataGeneratorWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: DataGeneratorWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="fixed top-4 right-4 z-50"
      {@rest}
    >
      <div class={[
        "w-80 sm:w-96 rounded-lg p-4 shadow-lg ring-1 flex items-start gap-3",
        @kind == :info && "bg-blue-50 text-blue-900 ring-blue-200",
        @kind == :error && "bg-red-50 text-red-900 ring-red-200"
      ]}>
        <.icon
          :if={@kind == :info}
          name="hero-information-circle"
          class={["size-5 shrink-0 mt-0.5", "text-blue-500"]}
        />
        <.icon
          :if={@kind == :error}
          name="hero-exclamation-circle"
          class={["size-5 shrink-0 mt-0.5", "text-red-500"]}
        />
        <div class="flex-1 min-w-0">
          <p :if={@title} class="text-sm font-semibold">{@title}</p>
          <p class="text-sm">{msg}</p>
        </div>
        <button
          type="button"
          class="group shrink-0 cursor-pointer -m-1 p-1 rounded-md hover:bg-black/5 transition-colors"
          aria-label={gettext("close")}
        >
          <.icon name="hero-x-mark" class="size-4 opacity-50 group-hover:opacity-80" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :any
  attr :variant, :string, values: ~w(primary)
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    variants = %{
      "primary" => "bg-blue-500 text-white hover:bg-blue-600 active:bg-blue-700 shadow-sm",
      nil => "bg-blue-50 text-blue-700 hover:bg-blue-100 active:bg-blue-200 ring-1 ring-blue-200"
    }

    assigns =
      assign_new(assigns, :class, fn ->
        [
          "inline-flex items-center justify-center gap-2 rounded-lg px-4 py-2.5",
          "text-sm font-semibold transition-all duration-150 cursor-pointer",
          "disabled:opacity-50 disabled:cursor-not-allowed",
          "phx-submit-loading:opacity-70 phx-click-loading:opacity-70",
          Map.fetch!(variants, assigns[:variant])
        ]
      end)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as radio, are best
  written directly in your templates.

  ## Examples

  ```heex
  <.input field={@form[:email]} type="email" />
  <.input name="my-input" errors={["oh no!"]} />
  ```

  ## Select type

  When using `type="select"`, you must pass the `options` and optionally
  a `value` to mark which option should be preselected.

  ```heex
  <.input field={@form[:user_type]} type="select" options={["Admin": "admin", "User": "user"]} />
  ```

  For more information on what kind of data can be passed to `options` see
  [`options_for_select`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#options_for_select/2).
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :any, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div phx-feedback-for={@name} class="mb-2">
      <label for={@id} class="flex items-center gap-2 cursor-pointer select-none">
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class={
            @class ||
              [
                "size-4 rounded border-gray-300 text-blue-500",
                "focus:ring-2 focus:ring-blue-500/20 focus:ring-offset-0",
                "transition-colors cursor-pointer"
              ]
          }
          {@rest}
        />
        <span class="text-sm font-medium text-gray-700">{@label}</span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="mb-2">
      <label for={@id} class="block">
        <span :if={@label} class="block text-sm font-medium text-gray-700 mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[
            @class ||
              [
                "w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm",
                "shadow-sm transition-colors",
                "focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 focus:outline-none"
              ],
            @errors != [] &&
              (@error_class || "border-red-400 focus:border-red-500 focus:ring-red-500/20")
          ]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="mb-2">
      <label for={@id} class="block">
        <span :if={@label} class="block text-sm font-medium text-gray-700 mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class ||
              [
                "w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm",
                "shadow-sm transition-colors",
                "focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 focus:outline-none"
              ],
            @errors != [] &&
              (@error_class || "border-red-400 focus:border-red-500 focus:ring-red-500/20")
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="mb-2">
      <label for={@id} class="block">
        <span :if={@label} class="block text-sm font-medium text-gray-700 mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class ||
              [
                "w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm",
                "shadow-sm transition-colors",
                "focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 focus:outline-none"
              ],
            @errors != [] &&
              (@error_class || "border-red-400 focus:border-red-500 focus:ring-red-500/20")
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex items-center gap-1.5 text-sm text-red-600">
      <.icon name="hero-exclamation-circle" class="size-4 shrink-0" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-gray-900">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-gray-500">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-x-auto rounded-lg border border-gray-200">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th
              :for={col <- @col}
              class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500"
            >
              {col[:label]}
            </th>
            <th :if={@action != []} class="px-4 py-3">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}
          class="divide-y divide-gray-100 bg-white"
        >
          <tr
            :for={row <- @rows}
            id={@row_id && @row_id.(row)}
            class="hover:bg-gray-50 transition-colors"
          >
            <td
              :for={col <- @col}
              phx-click={@row_click && @row_click.(row)}
              class={["px-4 py-3 text-sm text-gray-700", @row_click && "hover:cursor-pointer"]}
            >
              {render_slot(col, @row_item.(row))}
            </td>
            <td :if={@action != []} class="w-0 px-4 py-3 text-sm font-semibold">
              <div class="flex gap-4">
                <%= for action <- @action do %>
                  {render_slot(action, @row_item.(row))}
                <% end %>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="divide-y divide-gray-100 rounded-lg border border-gray-200 bg-white">
      <li :for={item <- @item} class="px-4 py-3">
        <div>
          <div class="text-sm font-semibold text-gray-900">{item.title}</div>
          <div class="mt-0.5 text-sm text-gray-600">{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  @doc """
  Renders type-specific configuration inputs for a column.
  Accepts assigns: :column (map with keys :id, :type_name, :config), :enums (list).
  This component is used by both the Generate and Templates pages so their
  configuration UI stays consistent.
  """
  attr :column, :map, required: true
  attr :enums, :list, default: []

  def type_config(assigns) do
    assigns = assign_new(assigns, :enums, fn -> [] end)

    ~H"""
    <%= case @column.type_name do %>
      <% "integer" -> %>
        <label class="block text-xs font-medium text-gray-700 mb-1">Range</label>
        <div class="flex items-center gap-2">
          <form phx-change="update_column_config" phx-value-id={@column.id} phx-value-key="min">
            <input
              type="number"
              name="value"
              value={@column.config["min"] || 0}
              class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
              placeholder="Min"
            />
          </form>
          <span class="text-gray-400">-</span>
          <form phx-change="update_column_config" phx-value-id={@column.id} phx-value-key="max">
            <input
              type="number"
              name="value"
              value={@column.config["max"] || 1000}
              class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
              placeholder="Max"
            />
          </form>
        </div>
      <% "float" -> %>
        <label class="block text-xs font-medium text-gray-700 mb-1">Range</label>
        <div class="flex items-center gap-2">
          <form phx-change="update_column_config" phx-value-id={@column.id} phx-value-key="min">
            <input
              type="number"
              name="value"
              value={@column.config["min"] || 0}
              step="any"
              class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
              placeholder="Min"
            />
          </form>
          <span class="text-gray-400">-</span>
          <form phx-change="update_column_config" phx-value-id={@column.id} phx-value-key="max">
            <input
              type="number"
              name="value"
              value={@column.config["max"] || 100}
              step="any"
              class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
              placeholder="Max"
            />
          </form>
        </div>
        <div class="mt-2">
          <label class="block text-xs font-medium text-gray-700 mb-1">
            Precision (decimal places)
          </label>
          <form phx-change="update_column_config" phx-value-id={@column.id} phx-value-key="precision">
            <input
              type="number"
              name="value"
              value={@column.config["precision"] || 2}
              min="0"
              max="10"
              class="block w-24 rounded-lg border border-gray-300 px-3 py-2 text-sm"
              placeholder="2"
            />
          </form>
        </div>
      <% "price" -> %>
        <label class="block text-xs font-medium text-gray-700 mb-1">Currency</label>
        <form phx-change="update_column_config" phx-value-id={@column.id} phx-value-key="currency">
          <input
            type="text"
            name="value"
            value={@column.config["currency"] || ""}
            class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
            placeholder="USD, EUR, $, ..."
          />
        </form>
      <% "date" -> %>
        <label class="block text-xs font-medium text-gray-700 mb-1">Date Range</label>
        <div class="flex items-center gap-2">
          <form phx-change="update_column_config" phx-value-id={@column.id} phx-value-key="from">
            <input
              type="date"
              name="value"
              value={@column.config["from"] || "2020-01-01"}
              class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
            />
          </form>
          <span class="text-gray-400 text-xs">to</span>
          <form phx-change="update_column_config" phx-value-id={@column.id} phx-value-key="to">
            <input
              type="date"
              name="value"
              value={@column.config["to"] || "2025-12-31"}
              class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
            />
          </form>
        </div>
        <div class="mt-2">
          <label class="block text-xs font-medium text-gray-700 mb-1">Timezone</label>
          <form phx-change="update_column_config" phx-value-id={@column.id} phx-value-key="timezone">
            <select
              name="value"
              class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
            >
              <%= for {label, value} <- timezone_options() do %>
                <option value={value} selected={(@column.config["timezone"] || "UTC") == value}>
                  {label}
                </option>
              <% end %>
            </select>
          </form>
        </div>
      <% "datetime" -> %>
        <label class="block text-xs font-medium text-gray-700 mb-1">DateTime Range</label>
        <div class="flex items-center gap-2">
          <form phx-change="update_column_config" phx-value-id={@column.id} phx-value-key="from">
            <input
              type="datetime-local"
              name="value"
              value={@column.config["from"] || "2020-01-01T00:00:00"}
              class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
            />
          </form>
          <span class="text-gray-400 text-xs">to</span>
          <form phx-change="update_column_config" phx-value-id={@column.id} phx-value-key="to">
            <input
              type="datetime-local"
              name="value"
              value={@column.config["to"] || "2025-12-31T23:59:59"}
              class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
            />
          </form>
        </div>
        <div class="mt-2">
          <label class="block text-xs font-medium text-gray-700 mb-1">Timezone</label>
          <form phx-change="update_column_config" phx-value-id={@column.id} phx-value-key="timezone">
            <select
              name="value"
              class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
            >
              <%= for {label, value} <- timezone_options() do %>
                <option value={value} selected={(@column.config["timezone"] || "UTC") == value}>
                  {label}
                </option>
              <% end %>
            </select>
          </form>
        </div>
      <% "string" -> %>
        <label class="block text-xs font-medium text-gray-700 mb-1">Length</label>
        <form phx-change="update_column_config" phx-value-id={@column.id} phx-value-key="length">
          <input
            type="number"
            name="value"
            value={@column.config["length"] || 10}
            min="1"
            class="block w-28 rounded-lg border border-gray-300 px-3 py-2 text-sm"
            placeholder="Length"
          />
        </form>
      <% "regex" -> %>
        <label class="block text-xs font-medium text-gray-700 mb-1">Pattern</label>
        <form phx-change="update_column_config" phx-value-id={@column.id} phx-value-key="pattern">
          <input
            type="text"
            name="value"
            value={@column.config["pattern"] || ""}
            class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm font-mono"
            placeholder="[A-Z]{3}-\\d{4}"
          />
        </form>
      <% "enum" -> %>
        <%= if @enums != [] do %>
          <label class="block text-xs font-medium text-gray-700 mb-1">Enum Source</label>
          <form phx-change="update_column_config" phx-value-id={@column.id} phx-value-key="enum_id">
            <select
              name="value"
              class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
            >
              <option value="">-- Select enum --</option>
              <%= for e <- @enums do %>
                <option
                  value={e.id}
                  selected={to_string(e.id) == to_string(@column.config["enum_id"])}
                >
                  {e.name}
                </option>
              <% end %>
            </select>
          </form>
        <% end %>
        <div class={[if(@enums != [], do: "mt-2")]}>
          <label class="block text-xs font-medium text-gray-700 mb-1">Inline Values</label>
          <form phx-change="update_column_config" phx-value-id={@column.id} phx-value-key="values">
            <input
              type="text"
              name="value"
              value={@column.config["values"] || ""}
              class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
              placeholder="inline values, comma-separated (red,green,blue)"
            />
          </form>
        </div>
      <% _ -> %>
        <p class="text-xs text-gray-400 py-2">No additional configuration needed.</p>
    <% end %>
    """
  end

  defp timezone_options do
    [
      {"UTC", "UTC"},
      {"-12:00 (Baker Island)", "-12:00"},
      {"-11:00 (Samoa)", "-11:00"},
      {"-10:00 (Hawaii)", "-10:00"},
      {"-09:00 (Alaska)", "-09:00"},
      {"-08:00 (PST)", "-08:00"},
      {"-07:00 (MST)", "-07:00"},
      {"-06:00 (CST)", "-06:00"},
      {"-05:00 (EST)", "-05:00"},
      {"-04:00 (AST)", "-04:00"},
      {"-03:00 (BRT)", "-03:00"},
      {"-02:00", "-02:00"},
      {"-01:00 (Azores)", "-01:00"},
      {"+01:00 (CET)", "+01:00"},
      {"+02:00 (EET)", "+02:00"},
      {"+03:00 (MSK)", "+03:00"},
      {"+04:00 (GST)", "+04:00"},
      {"+05:00 (PKT)", "+05:00"},
      {"+05:30 (IST)", "+05:30"},
      {"+06:00 (BST)", "+06:00"},
      {"+07:00 (ICT)", "+07:00"},
      {"+08:00 (CST/HKT)", "+08:00"},
      {"+09:00 (JST)", "+09:00"},
      {"+10:00 (AEST)", "+10:00"},
      {"+11:00 (SBT)", "+11:00"},
      {"+12:00 (NZST)", "+12:00"}
    ]
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(DataGeneratorWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(DataGeneratorWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
