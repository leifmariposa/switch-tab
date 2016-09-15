Path = require 'path'
_ = require 'underscore-plus'
{Point, CompositeDisposable} = require 'atom'
{$, $$, SelectListView} = require 'atom-space-pen-views'
fs = require 'fs-plus'
fuzzaldrin = require 'fuzzaldrin'
#{TextEditorView} = require 'atom-space-pen-views'
home = if process.platform is 'win32' then process.env.USERPROFILE else process.env.HOME

isUnder = (dir, path) ->
  Path.relative(path, dir).startsWith('..')

module.exports =
class SwitchTabView extends SelectListView
  filePaths: null
  projectRelativePaths: null
  subscriptions: null

  initialize: ->
    super
    @addClass('switch-tab')
    @subscriptions = new CompositeDisposable

  toggle: ->
    if @panel?.isVisible()
      @cancel()
    else
      @setItems()
      @show()

  closeCurrent: ->
    item = @getSelectedItem()
    pane = item.pane
    tab = item.tab
    pane.removeItem(tab)
    @setItems()

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'No open editors'
    else
      super

  getFilterKey: ->
    'title'

  cancel: ->
    lastSearch = @getFilterQuery()
    super

    @filterEditorView.setText(lastSearch)
    @filterEditorView.getModel().selectAll()

  destroy: ->
    @cancel()
    @panel?.destroy()
    @subscriptions?.dispose()
    @subscriptions = null

  projectRelativePath = (path) ->
    path = Path.dirname(path)
    [root, relativePath] = atom.project.relativizePath(path)
    if root
      if atom.project.getPaths().length > 1
        relativePath = Path.basename(root) + Path.sep + relativePath
      relativePath
    else if home and isUnder(home, path)
      '~' + Path.sep + Path.relative(home, path)
    else
      path

  viewForItem: ({pane, tab, title}) ->
    isEditor = tab.constructor.name is 'TextEditor'
    #title = tab.getTitle()
    if isEditor
      path = tab.getPath()
      icon = "icon icon-file-text"
      modified = if tab?.isModified() then 'modified'
    else
      icon = "title: #{title}, icon icon-tools"

    dir = if path then projectRelativePath(path) else ''
    filterQuery = @getFilterQuery()
    matches = fuzzaldrin.match(title, filterQuery)

    $$ ->
      highlighter = (path, matches) =>
        lastIndex = 0
        matchedChars = [] # Build up a set of matched chars to be more semantic
        for matchIndex in matches
          unmatched = path.substring(lastIndex, matchIndex)
          if unmatched
            @span matchedChars.join(''), class: 'character-match' if matchedChars.length
            matchedChars = []
            @text unmatched
          matchedChars.push(path[matchIndex])
          lastIndex = matchIndex + 1

        @span matchedChars.join(''), class: 'character-match' if matchedChars.length

        # Remaining characters are plain text
        @text path.substring(lastIndex)

      show = (path) =>
        @text path

      @li class: 'two-lines', =>
        baseOffset = 0
        @div class: "primary-line file #{icon} #{modified}", 'data-name': title, 'data-path': dir, -> highlighter(title, matches)
        @div class: 'secondary-line path no-icon', -> show(dir)

  confirmed: ({pane, tab}={}) ->
    @cancel()
    pane.activateItem(tab)
    pane.activate()

  setItems: ->
    panes = atom.workspace.getPanes()
    objs = panes.map (pane) ->
      tabs = pane.getItems()
      objs = tabs.map (tab) ->
        title = tab.getTitle()
        {pane, tab, title}

      objs

    paths = [].concat.apply([], objs)
    super(paths)

  show: ->
    @storeFocusedElement()
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()

  hide: ->
    @panel?.hide()

  cancelled: ->
    @hide()
