Mix.install([:phoenix_live_view, :earmark, :phoenix_html])

defmodule Components do
  use Phoenix.Component
  import Phoenix.HTML

  defp current_url(slug), do: "https://kevinlang.me#{slug}"

  defp title(nil), do: "Kevin Lang"
  defp title(title), do: "#{title} | Kevin Lang"

  def layout(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">

        <title><%= title(@title) %></title>
        <meta name="author" content="Kevin Lang">
        <meta name="description" content={@description} />

        <meta property="og:site_name" content="Kevin Lang">
        <meta property="og:locale" content="en_US">
        <meta property="og:title" content={title(@title)}>
        <meta property="og:url" content={current_url(@slug)}>
        <meta property="og:image" content="https://kevinlang.me/apple-touch-icon.png">
        <meta property="og:description" content={@description} />
        <meta property="og:type" content="article" />
        <meta property="article:published_time" content={@date} />

        <meta name="twitter:title" content={title(@title)} />
        <meta name="twitter:description" content={@description} />
        <meta name="twitter:url" content={current_url(@slug)} />
        <meta name="twitter:image" content="https://kevinlang.me/apple-touch-icon.png" />
        <meta name="twitter:image:src" content="https://kevinlang.me/apple-touch-icon.png" />

        <link rel="canonical" href={current_url(@slug)} />

        <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png">
        <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">
        <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png">

        <link rel="stylesheet" href="/my.css">
        <link rel="stylesheet" href="/gfm.css">
        <link rel="stylesheet" href="/highlight-atom-one-light.css">
        <script src="/highlight.min.js"></script>
        <script src="/highlight-elixir.js"></script>
        <script>hljs.highlightAll();</script>
      </head>
    </html>
    <body>
      <header>
        <div class="container">
          <a class="site-title" href="/">Kevin Lang</a>
        </div>
      </header>
      <main>
        <%= @inner_content %>
      </main>
    </body>
    """
  end

  def index(assigns) do
    ~H"""
    <h1>Blog posts</h1>
    <%= for post <- @posts do %>
    <p>
      <b><a href={post.slug}><%= post.title %></a></b> <small>- <%= Calendar.strftime(post.date, "%B %d, %Y") %></small>
    </p>
    <%end%>
    """
  end

  def post(assigns) do
    ~H"""
    <article>
      <div>
        <h1><%= @title %></h1>
        <p class="date"><small><%= Calendar.strftime(@date, "%B %d, %Y") %></small></p>
      </div>
      <div class="markdown-body">
        <%= raw @body %>
      </div>
    </article>
    """
  end
end

defmodule Helpers do
  def render(component, assigns) do
    assigns
    |> Map.put(:inner_content, component.(assigns))
    |> Components.layout()
    |> Phoenix.HTML.Safe.to_iodata()
  end
end

### Parse markdown

posts =
  Path.wildcard("posts/*.md")
  |> Enum.map(fn path ->
    [year, month, day, slug] =
      path
      |> Path.basename(".md")
      |> String.split("-", parts: 4)

    date = Date.from_iso8601!("#{year}-#{month}-#{day}")

    contents = File.read!(path)
    [attrs_code, markdown] = String.split(contents, "---", parts: 2)
    body = Earmark.as_html!(markdown)
    {attrs, _bindings} = Code.eval_string(attrs_code)

    Map.merge(attrs, %{date: date, slug: "/#{slug}/", body: body})
  end)

### Generate HTML

File.cp_r("public", "_site")

html =
  Helpers.render(&Components.index/1, %{
    posts: posts,
    title: nil,
    description: "Kevin Lang's technical blog",
    slug: "/",
    date: Enum.map(posts, & &1.date) |> Enum.sort(:desc) |> List.first()
  })

File.write!("_site/index.html", html)

Enum.each(posts, fn post ->
  html = Helpers.render(&Components.post/1, post)

  File.mkdir_p!("_site/#{post.slug}")
  File.write!("_site/#{post.slug}/index.html", html)
end)
