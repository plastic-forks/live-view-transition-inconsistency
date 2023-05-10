#
# SETUP
#

Application.put_env(:sample, SamplePhoenix.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 5001],
  server: true,
  live_view: [signing_salt: "aaaaaaaa"],
  secret_key_base: String.duplicate("a", 64)
)

Mix.install([
  {:plug_cowboy, "~> 2.5"},
  {:jason, "~> 1.0"},
  {:phoenix, "1.7.2"},
  {:phoenix_live_view, "0.18.18"}
])

defmodule SamplePhoenix.ErrorView do
  def render(template, _), do: Phoenix.Controller.status_message_from_template(template)
end

#
# =======================
#      The LiveView
# =======================
#
# Visit https://github.com/phoenixframework/phoenix_live_view/issues/2484 for
# an explanation of the bug that this LiveView demonstrates.
#

defmodule SamplePhoenix.SampleLive do
  use Phoenix.LiveView, layout: {__MODULE__, :live}

  alias Phoenix.LiveView.JS

  def render("live.html", assigns) do
    ~H"""
    <script src="https://cdn.jsdelivr.net/npm/phoenix@1.7.2/priv/static/phoenix.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/phoenix_live_view@0.18.18/priv/static/phoenix_live_view.min.js"></script>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
      let liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket)
      liveSocket.connect()
    </script>
    <%= @inner_content %>
    """
  end

  @time 1000

  def mount(_params, _session, socket) do
    transition = "transition-opacity duration-#{@time}"
    show_transition = {transition, "opacity-20", "opacity-100"}
    hide_transition = {transition, "opacity-100", "opacity-20"}

    socket =
      assign(
        socket,
        time: @time,
        show_transition: show_transition,
        hide_transition: hide_transition,
        show_opts: [transition: show_transition, time: @time],
        hide_opts: [transition: hide_transition, time: @time]
      )

    {:ok, socket}
  end

  @doc """
  Renders a sequence of squares, each of which demonstrates how a different
  `JS` function behaves when the `transition` option is given.

  ### Consistent `transition` Options

  We consistently use the same `transition` tuples for each example, in order
  to demonstrate that the LiveView JavaScript library is not behaving
  consistently between the different `JS` functions.

  ### The `opacity` CSS Property

  We use the `opacity` CSS property to make it easy to visualize whether a
  transition is occurring or not. Every instance where the opacity does not
  change gradually is an instance where the `JS` function is waiting until the
  end of the transition to apply the `end` classes, rather than immediately
  after the beginning of the transition.

  Rather than using opacity-0, we use opacity-20 so that the DOM elements are
  still slightly visible before/after the transition.

  ### Hidden DOM Elements

  For `JS` functions that concern a DOM element that is already hidden
  (`style="display: none"`), we render a button that can be clicked
  to display the hidden element.

  For all other `JS` functions, the button _is_ the DOM element that will be
  affected by the transition.

  """
  def render(assigns) do
    ~H"""
    <div class="flex flex-wrap">
      <div class="inline-block">
        <div id="toggle" style="display: none" class="bg-fuchsia-500 w-32 h-32" />

        <button phx-click={JS.toggle([to: "#toggle", in: @show_transition, out: @hide_transition, time: @time])} class="w-32 h-32 bg-gray-100">
          JS.toggle
        </button>
      </div>

      <div class="inline-block">
        <div id="show" style="display: none" class="bg-blue-500 w-32 h-32" />

        <button phx-click={JS.show(@show_opts ++ [to: "#show"])} class="w-32 h-32 bg-gray-100">
          JS.show
        </button>
      </div>

      <button phx-click={JS.hide(@hide_opts)} class="w-32 h-32 bg-orange-500">
        JS.hide
      </button>

      <button phx-click={JS.add_class("border-4", @hide_opts)} class="bg-purple-500 border-black w-32 h-32">
        JS.add_class
        <br>
        ("border-4")
        <br>
        [to opacity-20]
      </button>

      <button phx-click={JS.remove_class("border-4", @hide_opts)} class="bg-pink-500 border-4 border-black shadow-lg w-32 h-32">
        JS.remove_class
        <br>
        ("border-4")
        <br>
        [to opacity-20]
      </button>

      <div class="inline-block">
        <div id="transition-show" class="bg-blue-500 w-32 h-32 opacity-20" />

        <button
          phx-click={JS.transition(@show_transition, time: @time, to: "#transition-show")}
          class="bg-gray-100 w-32 h-32"
        >
          JS.transition [to opacity-100]
        </button>
      </div>

      <button phx-click={JS.transition(@hide_transition, time: @time)} class="bg-rose-500 w-32 h-32">
        JS.transition [to opacity-20]
      </button>
    </div>
    """
  end
end

#
# MORE SETUP
#

defmodule Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  scope "/", SamplePhoenix do
    pipe_through(:browser)

    live("/", SampleLive, :index)
  end
end

defmodule SamplePhoenix.Endpoint do
  use Phoenix.Endpoint, otp_app: :sample
  socket("/live", Phoenix.LiveView.Socket)
  plug(Router)
end

{:ok, _} = Supervisor.start_link([SamplePhoenix.Endpoint], strategy: :one_for_one)
Process.sleep(:infinity)
