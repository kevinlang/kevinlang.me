Mix.install([:phoenix_live_view, :nimble_publisher])

defmodule Components do
  use Phoenix.Component
  import Phoenix.HTML

  def layout(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">

        <link rel="stylesheet" href="/my.css">
        <link rel="stylesheet" href="/gfm.css">
        <link rel="stylesheet" href="/highlight-atom-one-light.css">
        <script src="/highlight.min.js"></script>
        <script src="/highlight-elixir.js"></script>
        <script>hljs.highlightAll();</script>
      </head>
    </html>
    <body class="markdown-body">
      <header>
        <div class="container">
          <div class="site-title">Kevin Lang</div>
          <nav>
            <a href="/">home</a> /
            <a href="/blog/">blog</a> /
            <a href="/til/">til</a>
          </nav>
        </div>
      </header>
      <main>
        <%= @inner_content %>
      </main>
    </body>
    """
  end

  def home(assigns) do
    ~H"""
    <h1>hello <%= @name %> </h1>
    """
  end

  def post(assigns) do
    ~H"""
    <article>
      <div>
        <h1><%= @title %></h1>
        <p class="date"><small><%= Calendar.strftime(@date, "%B %d, %Y") %></small></p>
      </div>
      <div>
        <%= raw @body %>
      </div>
    </article>
    """
  end
end

defmodule Posts do
  defmodule Post do
    @enforce_keys [:title, :body, :slug, :date, :description]
    defstruct [:title, :body, :slug, :date, :description]

    def build(filename, attrs, body) do
      [year, month, day, slug] =
        filename
        |> Path.basename(".md")
        |> String.split("-", parts: 4)

      date = Date.from_iso8601!("#{year}-#{month}-#{day}")
      struct!(__MODULE__, [slug: slug, date: date, body: body] ++ Map.to_list(attrs))
    end
  end

  use NimblePublisher,
    build: Post,
    from: "posts/*.md",
    as: :posts

  def all(), do: @posts
end

defmodule Helpers do
  def render(component, assigns) do
    # could also just call component and send result to Phoenix.HTML.Safe.to_iodata() directly
    inner_content = Phoenix.Template.render(Components, component, "html", assigns)
    layout_assigns = Map.put(assigns, :inner_content, inner_content)
    Phoenix.Template.render_to_iodata(Components, "layout", "html", layout_assigns)
  end
end

File.cp_r("public", "_site")

Enum.each(Posts.all(), fn post ->
  html = Helpers.render("post", %{body: post.body, title: post.title, date: post.date})
  File.mkdir_p!("_site/#{post.slug}")
  File.write!("_site/#{post.slug}/index.html", html)
end)
