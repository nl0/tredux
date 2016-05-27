T = require 'tcomb-kefir'
K = require 'kefir'
R = require 'ramda'
{select, Selector, SelectableObs} = require './select'


Action = T.struct {}, 'Action'

Reducer = T.func [T.Any, Action], T.Any, 'Reducer'


Cases = T.refinement T.list(T.Any), (cases) ->
  types = [T.Type, Reducer]
  cases.every (c, i) -> types[i % 2].is c

_mkReducer = T.func [T.func([], T.Any), Cases], Reducer, '_mkReducer'
.of (init, cases) ->
  cases = R.splitEvery 2, cases

  (state, action) ->
    state ?= init()

    for [type, reducer] in cases
      if type.is action
        return reducer state, action

    state

mkReducer = (init, matchers...) -> _mkReducer init, matchers


combineReducers = T.func [T.dict(T.String, Reducer)], Reducer, 'combineReducers'
.of (reducers) -> (state, action) ->
  R.mapObjIndexed (reducer, key) ->
    reducer state?[key], action
  , reducers


composeReducers = T.func [T.list(Reducer)], Reducer, 'composeReducers'
.of (reducers) -> (state, action) ->
  R.reduce (state, reducer) ->
    reducer state, action
  , state, reducers



IStore = T.interface
  state: T.prop T.Any
  dispatch: T.func Action, IStore, 'IStore::dispatch'
  plug: T.func T.obs(Action), IStore, 'IStore::plug'
  select: T.func Selector, SelectableObs, 'IStore::select'
, 'IStore'

InitAction = Action.extend {}, 'InitAction'

Store = T.func [Reducer, T.Any], IStore, 'Store'
.of (reducer, initialState) ->
  actions = K.pool()
  @state = actions.scan reducer, initialState ? null

  actions.plug K.constant InitAction {}

  dispatch: (action) =>
    #TODO: handle thunks?
    actions.plug K.constant action
    @

  plug: (obs) =>
    actions.plug obs
    @

  select: select @state


module.exports = {
  Action
  mkReducer
  combineReducers
  composeReducers
  Store
}
