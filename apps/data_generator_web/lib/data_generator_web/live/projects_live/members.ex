defmodule DataGeneratorWeb.ProjectsLive.Members do
  use DataGeneratorWeb, :live_view

  alias DataGenerator.Projects
  alias DataGenerator.Accounts

  def mount(%{"id" => id}, _session, socket) do
    project = Projects.get_project_with_members!(id)
    user = socket.assigns.current_user

    is_owner =
      Elixir.Enum.any?(project.project_members, fn pm ->
        pm.user_id == user.id && pm.is_owner
      end)

    if not is_owner do
      {:ok,
       socket
       |> put_flash(:error, "Only the project owner can manage members.")
       |> push_navigate(to: ~p"/projects/#{project.id}")}
    else
      add_member_form = to_form(%{"email" => ""}, as: :member)

      {:ok,
       socket
       |> assign(
         page_title: "Members - #{project.name}",
         project: project,
         is_owner: is_owner,
         add_member_form: add_member_form
       )
       |> stream(:members, project.project_members)}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6 max-w-2xl">
        <div>
          <.link
            navigate={~p"/projects/#{@project.id}"}
            class="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 transition mb-2"
          >
            <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to {@project.name}
          </.link>
          <h1 class="text-2xl font-bold text-gray-900">Manage Members</h1>
          <p class="mt-1 text-sm text-gray-600">Add or remove members from {@project.name}.</p>
        </div>

        <%!-- Add Member --%>
        <%= if @is_owner do %>
          <div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
            <h2 class="text-lg font-semibold text-gray-900">Add Member</h2>
            <p class="mt-1 text-sm text-gray-600">Invite someone by their email address.</p>
            <.form
              for={@add_member_form}
              id="add-member-form"
              phx-submit="add_member"
              class="mt-4 flex items-end gap-3"
            >
              <div class="flex-1">
                <.input
                  field={@add_member_form[:email]}
                  type="email"
                  label="Email address"
                  required
                  placeholder="user@example.com"
                />
              </div>
              <.button
                type="submit"
                phx-disable-with="Adding..."
                class="rounded-lg bg-blue-500 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-600 transition"
              >
                Add
              </.button>
            </.form>
          </div>
        <% end %>

        <%!-- Members List --%>
        <div class="rounded-xl border border-gray-200 bg-white shadow-sm">
          <div class="border-b border-gray-200 px-6 py-4">
            <h2 class="text-lg font-semibold text-gray-900">Current Members</h2>
          </div>
          <div id="members" phx-update="stream" class="divide-y divide-gray-100">
            <div
              :for={{id, member} <- @streams.members}
              id={id}
              class="flex items-center justify-between px-6 py-4"
            >
              <div class="flex items-center gap-3">
                <div class="flex items-center justify-center w-10 h-10 rounded-full bg-indigo-100 text-sm font-bold text-indigo-600">
                  {String.first(member.user.login)}
                </div>
                <div>
                  <p class="text-sm font-medium text-gray-900">{member.user.login}</p>
                  <p class="text-xs text-gray-500">{member.user.email}</p>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <span class={[
                  "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
                  if(member.is_owner,
                    do: "bg-indigo-100 text-indigo-700",
                    else: "bg-gray-100 text-gray-700"
                  )
                ]}>
                  <%= if member.is_owner do %>
                    Owner
                  <% else %>
                    Member
                  <% end %>
                </span>
                <%= if @is_owner && !member.is_owner do %>
                  <button
                    phx-click="remove_member"
                    phx-value-user-id={member.user_id}
                    data-confirm={"Remove #{member.user.login} from this project?"}
                    class="rounded-lg p-1.5 text-gray-400 hover:text-red-500 hover:bg-red-50 transition"
                  >
                    <.icon name="hero-x-mark" class="w-4 h-4" />
                  </button>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("add_member", %{"member" => %{"email" => email}}, socket) do
    project = socket.assigns.project

    case Accounts.get_user_by_email(email) do
      nil ->
        {:noreply, put_flash(socket, :error, "No user found with that email address.")}

      user ->
        case Projects.add_member(project.id, user.id) do
          {:ok, member} ->
            member = %{member | user: user}

            {:noreply,
             socket
             |> stream_insert(:members, member)
             |> put_flash(:info, "#{user.login} has been added to the project.")
             |> assign(add_member_form: to_form(%{"email" => ""}, as: :member))}

          {:error, _changeset} ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "Could not add member. They may already be in the project."
             )}
        end
    end
  end

  def handle_event("remove_member", %{"user-id" => user_id_str}, socket) do
    project = socket.assigns.project
    user_id = String.to_integer(user_id_str)

    case Projects.remove_member(project.id, user_id) do
      {:ok, removed_member} ->
        {:noreply,
         socket
         |> stream_delete(:members, removed_member)
         |> put_flash(:info, "Member removed from the project.")}

      {:error, :cannot_remove_owner} ->
        {:noreply, put_flash(socket, :error, "Cannot remove the project owner.")}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Member not found.")}
    end
  end
end
