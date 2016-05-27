T = require 'tcomb-kefir'
R = require 'ramda'


sameConstructor = (a, b) ->
  a?.constructor == b?.constructor

eq = R.both sameConstructor, R.equals

Selector = T.func [T.Any], T.Any, 'Selector'

SelectableObs = T.declare 'SelectableObs'

SelectableObs.define T.obs(T.Any).extend T.interface
  select: T.func [Selector], SelectableObs, 'SelectableObs::select'
, 'SelectableObs'


select = T.func [T.obs(T.Any), Selector], SelectableObs
.of (obs, selector) ->
  selected = obs.map(selector).skipDuplicates(eq).toProperty()
  # chaining
  selected.select = select selected
  selected
, true # curried


module.exports = {
  select
  Selector
  SelectableObs
}
