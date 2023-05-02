%{
  title: "Phoenix LiveView Navigation Regressions",
  description: "Phoenix LiveView has multiple regressions in simple navigation scenarios.",
}
---

[Phoenix LiveView]() has been out for a while now, though still not yet 1.0.
Within the Phoenix community, it has been pushed enthusiastically, with many in the community claiming it should be used all cases over normal views as it only offers a "net positive".
There are claims that there is no downside from either the user's or developer's perspective.

In practice this is untrue.
LiveView, as it exists today, contains regressions with respect to simple website navigation in a browser.
These result in a degraded browsing experience for any websites that use LiveView.

## Browsers and navigation

The original intent of HTML was to facilitate the sharing of [hypertext](https://en.wikipedia.org/wiki/Hypertext) documents.
I'd argue that the primary purpose of the web, to this day, is to share hypertext documents.
Web browsers, as their name indicate, are meant for _browsing_ those documents.

Of course, that original scope has expanded greatly.
Nowadays there are fully featured applications that use HTML to represent application widgets more than any proper document.
However, my focus for this article will be on the document browsing aspect of HTML and web browsers.

In my opinion the two key aspects of browser navigation is scroll position maintenance and the restoration of cached HTML.

### Scroll position maintenance

If you click on a link within an HTML page and navigate elsewhere, you can go back to the previous HTML page by clicking the back button.
When you do so, your previous scroll position will be maintained.
This is great when browsing Wikipedia articles, as we'll show shortly.

### Cached HTML restoration

When you navigate backwards, the browser will give you the cached HTML instead of re-requesting the resource.
This means any changes you did to the document that changed the HTML of that document will be maintained when you click the back button.
This is quite useful for infinite scrolling pages, as the HTML appended to the end of the page will be restored.
Combined with scroll position restoration, this means you can be quite deep into an infinite scroll, navigate to a link, and easily navigate back and retain your position.
A good example of this is this demo of [infinite scrolling Wikipedia articles](https://wikiscroll.blankenship.io/).

![cached html restoration](cached-html-restoration.gif)

## LiveView realities

I've created a basic Phoenix Application then added a new `/articles` LiveView to it.
It renders a list of random Wikipedia article links.
More links can be appended by clicking a "load more" button.

You can see the code for it at on Github at [kevinlang/liveview_navigation_demo](https://github.com/kevinlang/liveview_navigation_demo).

### Scroll position lost

If I scroll down slightly, click on a link, then click back, my initial scroll state will not be restored.
Instead, I'll be scrolled back to the top of the page.

![scroll position lost](scroll-position-lost.gif)

### Cached HTML state erased

Likewise, if I click the "load more" once, click on a link, then click back, my HTML state will not be restored.
This, combined with the lack of scroll position maintenance, means that my previous navigation state is entirely wiped.

![cached html state erased](cached-html-state-erased.gif)

## Mitigation

These two issues can be partly mitigated by the developer by writing some extra code.
However, the crux of my criticism lie not in whether these regressions can be fixed or workaround, but the need to do it.

Remember, the basic browser functionality of HTML restoration and scroll position work out of the box with no JavaScript and no custom code or annotations needed by the developer of a basic HTML website.
That is the bar we should aim for, under the understanding that many developers will not notice this regression, and thus will not make the needed changes to mitigate it.
In short, these behaviors can be considered _broken_ by default, and require manual intervention to get working again.

### Pushstate and params

When one clicks the back button in a LiveView app, the HTML cached state _is_ restored.
However, when the socket reconnects and gets the authoritative HTML from the server once more, that client HTML is overwritten.

Typically the solution to this is to update the parameters of the URL to save the current "page" we are within the infinite list.
This way when we navigate back to the page, those params can then be read by the server to render HTML that matches the cached client state.

However, this mitigation is often not done.
For example, the two top tutorials for adding infinite scroll to a Phoenix web app, [one by fly.io](https://fly.io/phoenix-files/infinitely-scroll-images-in-liveview/) and [another by PhoenixCasts](https://elixircasts.io/infinite-scroll-with-liveview), do not cover this workaround at all.

### Scroll position hook?

For scroll position, there is an [open issue](https://github.com/phoenixframework/phoenix_live_view/issues/2326) for not losing it on reconnect or refresh.
I assume this, if fixed, may fix the issue that we saw around navigation.

I believe the only current workaround would be to write a hook that detects any navigation event and stores the current scroll position, then to scroll back when navigated to.
However, that may not play nice with the automatic scroll-to-top the live socket already does for you.

## JavaScript and progressive enhancement

My website design philosophy is that of [progressive enhancement](https://developer.mozilla.org/en-US/docs/Glossary/Progressive_Enhancement).
Namely, the HTML served should work just fine without JavaScript.
The JavaScript should aim to elevate the browsing experience, but **should not** degrade it.

Many websites that leverage SPA frameworks fail this basic principle.
In fact, an SPA that does not have server-side rendering will display _nothing_ without JavaScript enabled.

However my focus is not on whether or not JavaScript is required to browse a website.
Instead, it is on whether the website maintains the same basic navigation feature set that basic HTML does.
That is, even if a website _requires_ JavaScript to function at all, it should still at the very least emulate or retain the basic functionality we get with a bare bones HTML site.

In this sense, I think LiveView fails to "progressively enhance" a website in its current form.

## Conclusion

LiveView can be a good alternative to SPAs.
Unfortunately, the comparison of LiveView to SPAs is quite apt: they result in an inferior user experience out of the box that can only be mitigated by attentive development.

LiveView excels for complex UI logic, or things like live updates.
For back-office applications it is hard to be beat.
In other words, proper applications that would've otherwise needed an SPA to implement.
But for basic blogs or documentation sites, I recommend instead to continue to use normal views.
