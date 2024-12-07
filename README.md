# Klon

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `klon` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:klon, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/klon>.

## TODO
- [x] set up repo
- [x] data structure that mimics screener -> question & stim -> question_stims
- [ ] tests
- [x] credo
- [x] dialyzer
- [ ] cache plt file
- [ ] ci
- [x] build graph
- [x] traverse graph
- [x] multi
- [ ] optimize for insert_all?
- [x] Ecto mix task to evaluate graph? assocs that go in one direction but not the other?
- [ ] clone "through" associations
- [ ] reset_fields callback?


## Callbacks
`assocs` 
 - should this be a list of child associations or something more like what `preload` accepts?
 - how much would someone need to filter the list when they can do anything they want in the `changeset` function

`changeset` 
  - currently is provided the source and the new parent
  1. should it instead be given a changeset with all the source things applied and then regular changeset functions can be used?
  2. instead of the parent should it be given a contextual mapping `%{parent_assoc_name => parent_struct | nil}`
  3. have `defer` be a valid return value?
    - how many times would we allow deferring to happen to not endlessly defer?
  4. build a dependency tree starting at first record to clone so that we know when we've satisfied the child's pre-conditions for the parents
    - then we don't have to defer
           
`multi`
 - escape hatch
 - provides `{name, changeset}, source, parent_map, changes`

`???` 
- clean API
- add dscout functionality
- then move on to graph/tree stuff
