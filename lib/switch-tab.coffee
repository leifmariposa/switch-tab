
module.exports =
  activate: (state) ->
    atom.commands.add 'atom-workspace',
      'switch-tab:toggle-switch-tab': =>
        @createSwitchTabView().toggle()
      'switch-tab:close': =>
        @createSwitchTabView().closeCurrent()

  deactivate: ->
    if @SwitchTabView?
      @SwitchTabView.destroy()
      @SwitchTabView = null
    @projectPaths = null
    @fileIconsDisposable?.dispose()

  createSwitchTabView: ->
    unless @SwitchTabView?
      SwitchTabView = require './switch-tab-view'
      @SwitchTabView = new SwitchTabView()
    @SwitchTabView
