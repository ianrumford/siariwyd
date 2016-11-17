# README

A module for sharing and reusing callback functions.

The most obvious use case is the callback functions of
\`GenServer\` i.e. \`handle\_code/3\`, \`handle\_cast/2\` and
\`handle\_info/2\`.

Callback function *sources* have to be compiled together in the
callback module to enable multiple implementations of the same
callback to be found by pattern matching.

Although targetting \`GenServer\` callbacks, \`Siariwyd\` can be used to
share any function's implementations (callback or otherwise) that
must be compiled together.

\`Siariwyd\` enables one or more implementations of a function to be
*register*-ed in one or more **donor** modules and selectively
*include*-d into a **recipient** (e.g. callback) module at
compilation time.

See full [documentation](<https://hexdocs.pm/siariwyd/readme.html>) for details.

See my
[blog post](<http://ianrumford.github.io//elixir/siariwyd/callback/function/share/reuse/2016/11/17/siariwyd.html>) for
some background.

## Installation

Add **siariwyd** to your list of dependencies in <span class="underline">mix.exs</span>:

    def deps do
      [{:siariwyd, "~> 0.1.0"}]
    end

## Examples

See the examples in the API documentation and also the
[blog post](<http://ianrumford.github.io//elixir/siariwyd/callback/function/share/reuse/2016/11/17/siariwyd.html>)