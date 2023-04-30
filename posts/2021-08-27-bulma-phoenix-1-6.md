%{
  title: "Adding Bulma to Phoenix 1.6",
  description: "It is now possible to add Bulma to Phoenix 1.6 without needing to involve Node, NPM, or Webpack.",
  # reddit: "https://old.reddit.com/r/elixir/comments/pd0qfe/adding_bulma_to_phoenix_16/",
  # elixirforum: "https://elixirforum.com/t/tutorial-adding-bulma-to-phoenix-1-6/41960"
}
---

Phoenix 1.6 is almost here, with the first release candidate being [announced on the Phoenix blog earlier today](https://www.phoenixframework.org/blog/phoenix-1.6-released). 

One of the main changes in Phoenix 1.6 is a complete overhaul of the asset pipeline. Starting with Phoenix 1.6, new Phoenix applications generated via `mix phx.new` will not include Node, NPM, or Webpack. Instead, the app will be generated with a minimal JS/CSS bundling pipeline using [esbuild](https://esbuild.github.io), and will include no built-in support for Sass processing. The reason for this is to reduce maintenance burden for the Phoenix maintainers, who previously spent a large amount of time trying to ensure that the NPM/Node/Webpack trifecta remained stable for new apps.

In this tutorial I'll go over how to set up Sass processing for your Phoenix 1.6 app, how to install Bulma using Mix, and then how to import Bulma into your main SCSS file for you to use and customize. For those who just want to see the code, you can check the [phoenix-bulma](https://github.com/kevinlang/phoenix-bulma) repository that contains the final code from this tutorial.

## Generating a new Phoenix app

Let's start out by generating a new Phoenix app. First we install the latest `phx.new` generator:  

```bash
$ mix archive.install hex phx_new 1.6.0-rc.0
```

Once that is done, we can generate our app:

```bash
$ mix phx.new phoenix-bulma --module MyApp --app my_app
```

Once that command finishes, we can ensure everything is functioning correctly by starting the server, before we get into modifying the base generated installation.

```bash
$ cd phoenix-bulma
$ mix deps.get
$ mix deps.compile
$ mix ecto.create
$ mix phx.server
```

You should then be able to see the app running at `http://localhost:4000`.

![Phoenix app homepage](phoenix-bulma-1.png)

## Installing DartSass

[DartSass](https://github.com/CargoSense/dart_sass) is an Elixir library that works similar to the `Esbuild` library that comes installed with Phoenix. It is a convenient wrapper for the [`dart-sass`](https://github.com/sass/dart-sass) which does the actual Sass processing.

To install it, add the following to your `mix.exs` file's `dep()` section:

```elixir
{:dart_sass, "~> 0.1", runtime: Mix.env() == :dev}
```

Then we need to configure which version of `dart-sass` to use. Add the following to your `config/config.exs` file.

```elixir
config :dart_sass,
  version: "1.36.0",
  default: [
    args: ~w(css:../priv/static/assets),
    cd: Path.expand("../assets", __DIR__)
  ]
```

We also want to rename the existing `assets/css/app.css` to `assets/css/app.scss` in our repository, to reflect that the file will be processed by Sass.

If you look in `assets/js/app.js` you will see this at the top:

```js
// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
import "../css/app.css"
```

Since we are indeed adding our own CSS pipeline, we will want to comment that line out, as instructed.

```js
// import "../css/app.css"
```

For development, we want to enable watch mode. So find the watchers configuration for your `MyApp.Endpoint` in your `config/dev.exs` and change it to:

```elixir
watchers: [
  # Start the esbuild watcher by calling Esbuild.install_and_run(:default, args)
  esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
  sass: {
    DartSass,
    :install_and_run,
    [:default, ~w(--embed-source-map --source-map-urls=absolute --watch)]
  }
]
```

And finally, we want to make sure our Sass pipeline runs when we are preparing our app for production. Go to your `mix.exs` file and change the `assets.deploy` alias to the following:

```elixir
"assets.deploy": ["sass default --no-source-map --style=compressed", "esbuild default --minify", "phx.digest"]
```

To verify everything is working, let's change the text of the "Welcome to Phoenix!" title to the Phoenix orange. Start up your server with `mix phx.server` and go to `assets/css/app.scss` and add the following to the top:

```scss
/* This file is for your main application CSS */
@import "./phoenix.css";

// our new sassy style
$phoenix-orange: #f05423;
.phx-hero {
  h1 {
    color: $phoenix-orange;
  }
}
```

With that done, you should see the home page of your app update with our "new sassy style".

![Phoenix app after Sass](phoenix-bulma-2.png)

## Installing Bulma

There are effectively three different ways to install Bulma. 

The first way to install Bulma is to just include the `bulma.min.css` file from a CDN like [JSDeliver](https://www.jsdelivr.com/package/npm/bulma). With this approach, you would not be able to customize Bulma at all, however. The main power of Sass is being to override some of the Bulma variables when building the final CSS, so we will not be going with this approach.

The second way is to install `node` and `npm` create a `package.json` and add `bulma` to it. Then the Bulma Sass files would be installed to our `node_modules/` folder. From there, we would need to tell `dart-sass` where those Sass files were installed to so that they could be included in our Sass build. However, this makes our app depend on `node` again, which is a pain. 

The third way, which we will be doing in this tutorial, is to install the [`bulma`](https://github.com/kevinlang/bulma-elixir) Hex package. This package includes all of the Bulma Sass files in a convenient package that can easily be added to your Mix project. This approach is similar to the `node` approach above, but without using `node` at all! This approach is also similar to how the various Phoenix JS libraries get included in your Phoenix application.

Go to your `mix.exs` file and add it:

```elixir
{:bulma, "0.9.3"}
```

Then update your `dart-sass` config to include it as a [load path](https://sass-lang.com/documentation/cli/dart-sass#load-path):

```elixir
config :dart_sass,
  version: "1.36.0",
  default: [
    args: ~w(--load-path=../deps/bulma css:../priv/static/assets),
    cd: Path.expand("../assets", __DIR__)
  ]
```

Lastly, you will need to import Bulma into your root style sheet, `assets/css/app.scss`:

```scss
/* This file is for your main application CSS */
@import "./phoenix.css";
 
@import "bulma";
```

If you start your server again, you will see the home page change slightly due to the Bulma styles mixing in with the default styles included in the initial generated Phoenix application.

![Homepage after adding Bulma](phoenix-bulma-3.png)

## Using Bulma and CSS Cleanup

Now that we have Bulma installed, we can do some minimal changes to the generated app to show it in action, along with cleaning up our initial generated CSS. First, let's get rid of the `assets/css/phoenix.css` file and then replace the content of the `assets/css/app.scss` file with the following:

```scss
// override bulma variables before import to customize
$phoenix-orange: #f05423;
$primary: $phoenix-orange;

@import "bulma";

// add our own styles after the Bulma import
```

Here we are overriding the `$primary` variable outlined in the [Bulma docs](https://bulma.io/documentation/customize/variables/) to our `$phoenix-orange` color. We can override any of the variables listed in that doc page before we import, to customize to our needs. Generally, our own styles can go after the import, as noted in the comment.

Now let's update some of our HTML files so we can show Bulma in action. First, remove the header in `root.html.heex`:

```diff
   <body>
-    <header>
-      <section class="container">
-        <nav>
-          <ul>
-            <li><a href="https://hexdocs.pm/phoenix/overview.html">Get Started</a></li>
-            <%= if function_exported?(Routes, :live_dashboard_path, 2) do %>
-              <li><%= link "LiveDashboard", to: Routes.live_dashboard_path(@conn, :home) %></li>
-            <% end %>
-          </ul>
-        </nav>
-        <a href="https://phoenixframework.org/" class="phx-logo">
-          <img src={Routes.static_path(@conn, "/images/phoenix.png")} alt="Phoenix Framework Logo"/>
-        </a>
-      </section>
-    </header>
     <%= @inner_content %>
   </body>
```

Then let's remove the `container` class from our `app.html.heex` layout:

```diff
-<main class="container">
+<main class="">
```

Lastly, let's make a nice big Bulma hero section on our main `index.html` page

```html
<section class="hero is-primary is-fullheight">
  <div class="hero-body">
    <div class="container has-text-centered">
      <p class="title">
        Phoenix
      </p>
      <p class="subtitle">
        With Bulma!
      </p>
    </div>
  </div>
</section>
```

With that done, we can load up our Phoenix server and see our new home page.

![Phoenix homepage with Bulma](phoenix-bulma-4.png)

That's it! All the code in this tutorial is published at the [phoenix-bulma](https://github.com/kevinlang/phoenix-bulma) repository for you to reference. If you encounter any difficulties, feel free to open an issue there. Cheers!
