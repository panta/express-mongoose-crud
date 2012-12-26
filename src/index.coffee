mongoose = require('mongoose')

Schema   = mongoose.Schema
ObjectId = Schema.ObjectId

is_callable = (f) ->
  (typeof f is 'function')

# Extend a source object with the properties of another object (shallow copy).
extend = (dst, src) ->
  for key, val of src
    dst[key] = val
  dst

defaults = (dst, src) ->
  for key, val of src
    if not (key of dst)
      dst[key] = val
  dst

trim = (str) ->
  String(str).replace(/^\s+|\s+$/g, '')

ltrim = (str) ->
  String(str).replace(/^\s*/g, "")

rtrim = (str) ->
  String(str).replace(/\s*$/g, "")

startsWith = (str, prefix) ->
  str.indexOf(prefix) isnt -1

endsWith = (str, suffix) ->
  str.indexOf(suffix, str.length - suffix.length) isnt -1

strip = (str, subs) ->
  if startsWith(str, subs)
    return str.substr(subs.length)
  if endsWith(str, subs)
    return str.substr(0, str.length - subs.length)
  str

urlJoinV = (pieces) ->
  _pieces = (strip(s, '/') for s in pieces)
  if pieces[0] is '/'
    _pieces[0] = pieces[0]
  else if startsWith(pieces[0], '/')
    _pieces[0] = rtrim(pieces[0])
  pieces.join('/')

urlJoin = (args...) ->
  urlJoinV(args)

bind = (func, context) ->
  bound = undefined
  args = undefined
  args = Array::slice.call(arguments, 2)
  bound = ->
    return func.apply(context, args.concat(Array::slice.call(arguments)))  unless this instanceof bound
    ctor:: = func::
    self = new ctor
    result = func.apply(self, args.concat(Array::slice.call(arguments)))
    return result  if Object(result) is result
    self

# -- Resource ---------------------------------------------------------

class Resource
  _DEFAULT_OPTIONS:
    name: null
    plural: null
    model: null
    fields: []
    exclude: []
    getters: true
    middleware: []
    urlPrefix: '/api/v1'
    idParam: null
    formats: ['json', 'html']
    defaultFormat: 'json'
    actions: {}
    addLinks: true
    trace: false
  _DEFAULT_OPTION_ACTIONS:
    index: {}
    create: {}
    delete_all: {}
    show: {}
    update: {}
    'delete': {}
    transition: {}
    'new': {}
    edit: {}
  _DEFAULT_ACTION_OPTS:
    url: null
    middleware: null
    callback: null
    template: null
    enabled: true

  constructor: (@options) ->
    defaults(@options, @_DEFAULT_OPTIONS)
    defaults(@options.actions, @_DEFAULT_OPTION_ACTIONS)
    for action of @options.actions
      defaults(@options.actions[action], @_DEFAULT_ACTION_OPTS)

    @_trace = @options.trace or false
    @model = @options.model or null
    @schema = @model.schema

    @name = @options.name or @model.modelName
    @plural = @options.plural or (@name + 's')
    @urlPrefix = @options.urlPrefix or ''

    @idParam = @options.idParam or (@name + 'Id')

    if @name is '/'
      @_prefix = @urlPrefix
    else
      @_prefix = urlJoin(@urlPrefix, @plural)

    @_mount_info =
      app: null
      on: null
      on_resource: false
      options: null
      url_prefix: null

  toString: ->
    "<Resource '#{@name}'>"

  instance2json: (item) ->
    obj = item.toObject(getters: @options.getters)
    if @options.addLinks
      obj['href'] = @_mount_info.url_prefix + "/#{item.id}"
    for field in @options.exclude
      if field of obj
        delete obj[field]
    obj

  instances2json: (items) ->
    objs = items.map (item) => @instance2json(item)
    objs

  action_index: (req, res) ->
    format = req.format or @options.defaultFormat
    @traceAction(req, 'index', "#{@_mount_info.url_prefix} format:#{format}")
    q = @_build_query(req)
    q.exec (err, items) =>
      return res.send(500, { error: "#{err}" })  if err
      objs = @instances2json(items)
      res.json(objs)

  action_show: (req, res) ->
    format = req.format or @options.defaultFormat
    @traceAction(req, 'show', "#{@_mount_info.url_prefix}:#{@idParam} format:#{format}")
    id = req.params[@idParam]
    @findOne req, id, (err, item) =>
      # console.log("find returned err:", err, "  item:", item)
      return res.send(500, { error: "#{err}", id: id })  if err
      # return res.json(500, { error: "#{err}", id: id })  if err
      if item is null
        return res.send(404, { error: "Resource not found", id: id })
        # return res.json(404, { error: "Resource not found", id: id })
      obj = @instance2json(item)
      res.json(obj)

  action_update: (req, res) ->
    format = req.format or @options.defaultFormat
    @traceAction(req, 'update', "#{@_mount_info.url_prefix}:#{@idParam} format:#{format}")
    id = req.params[@idParam]
    @findOne req, id, (err, item) =>
      # console.log("find returned err:", err, "  item:", item)
      return res.send(500, { error: "#{err}", id: id })  if err
      # return res.json(500, { error: "#{err}", id: id })  if err
      if item is null
        return res.send(404, { error: "Resource not found", id: id })
        # return res.json(404, { error: "Resource not found", id: id })
      @_update_instance_from_body_values(req, item)
      item.save (err) =>
        return res.send(500, { error: "#{err}" })  if err
        #console.log("created #{@name} with id:#{item.id}")
        if (req.body._format? and req.body._format == 'html') or (format == 'html')
          return res.redirect @_mount_info.url_prefix + "/#{item.id}" + ".html"
        else
          obj = @instance2json(item)
          return res.json(obj)

  action_create: (req, res) ->
    format = req.format or @options.defaultFormat
    @traceAction(req, 'create', "#{@_mount_info.url_prefix} format:#{format}")
    # #console.log(req.body)
    # console.log("REQUEST files:")
    # console.log(req.files)
    # instanceValues = @get_body_instance_values(req)
    # instance = new @model(instanceValues)
    item = new @model()
    @_update_instance_from_body_values(req, item)
    if @_mount_info.on_resource
      related = @_mount_info.on
      related_id = req.params[related.idParam]
      relation = @_mount_info.options.relation or related.name

      @trace("we have a related model field: '#{relation}' req field: '#{related.idParam}'")
      @trace("req.params.#{related.idParam} = #{related_id}")
      if related_id
        if (not related.idParam of item) or (not item[related.idParam])
          item[related.idParam] = related_id
    item.save (err) =>
      return res.send(500, { error: "#{err}" })  if err
      #console.log("created #{@name} with id:#{item.id}")
      if (req.body._format? and req.body._format == 'html') or (format == 'html')
        return res.redirect @_mount_info.url_prefix + "/#{item.id}" + ".html"
      else
        obj = @instance2json(item)
        return res.json(obj)

  action_delete: (req, res) ->
    format = req.format or @options.defaultFormat
    @traceAction(req, 'delete', "#{@_mount_info.url_prefix}:#{@idParam} format:#{format}")
    id = req.params[@idParam]
    @findOne req, id, (err, item) =>
      #console.log("find returned err:", err, "  item:", item)
      return res.send(500, { error: "#{err}", id: id })  if err
      if item is null
        return res.send(404, { error: "Resource not found", id: id })
        # return res.json(404, { error: "Resource not found", id: id })
      return item.remove (err) =>
        return res.send(500, { error: "#{err}", id: id })  if err
        #console.log("removed #{@name} with id:#{id}")
        return res.json(200, { message: 'Ok' })

  findOne: (req, id, cb) ->
    q = @_build_query(req)
    q.where('_id', id).findOne cb

  _build_query: (req) ->
    q = @model.find().select @_build_select()
    if @_mount_info.on_resource
      # find the related object before
      related = @_mount_info.on
      related_id = req.params[related.idParam]
      filter = {}
      relation = @_mount_info.options.relation or related.name
      filter[relation] = related_id
      q = q.find(filter)
    q

  _build_select: ->
    selectObj = {}
    for field in @options.fields
      selectObj[field] = 1
    for field in @options.exclude
      selectObj[field] = 0
    selectObj

  mount: (app_or_resource, options={}) ->
    if app_or_resource instanceof Resource
      return @_mount_over_resource(app_or_resource, options)
    @_mount_over_app(app_or_resource, options)

  _mount_over_app: (app, options) ->
    @_mount_info =
      app: app
      on: app
      on_resource: false
      options: options
      url_prefix: @_prefix
    @_mount_info.url_prefix = @_get_prefix()
    @_mount_actions()

  _mount_over_resource: (resource, options) ->
    @_mount_info =
      app: resource._mount_info.app
      on: resource
      on_resource: true
      options: options
      url_prefix: @_prefix
    @_mount_info.url_prefix = @_get_prefix()
    @_mount_actions()

  _mount_actions: ->
    # create the routes:
    #
    #   GET     /PLURAL           -> index      (get all resources)
    #   POST    /PLURAL           -> create     (create a new resource)
    #   DELETE  /PLURAL           -> delete_all (delete all resources)
    #   GET     /PLURAL/:NAMEID   -> show       (get the given resource)
    #   PUT     /PLURAL/:NAMEID   -> update     (update the given resource)
    #   DELETE  /PLURAL/:NAMEID   -> delete     (delete the given resource)
    #   POST    /PLURAL/:NAMEID   -> transition (perform a state change on resource)
    #
    # In addition, the following non-REST routes are created:
    #
    #   GET     /PLURAL/new           -> new    (edit new resource (not yet saved to db))
    #   GET     /PLURAL/:NAMEID/edit  -> edit   (edit the given resource)
    #

    app = @_mount_info.app

    middleware = @options.middleware?.index or []
    app.get @_mount_info.url_prefix + ".:format?", middleware, bind(@action_index, @)

    middleware = @options.middleware?.create or []
    app.post @_mount_info.url_prefix + ".:format?", middleware, bind(@action_create, @)

    middleware = @options.middleware?.show or []
    app.get @_mount_info.url_prefix + "/:#{@idParam}.:format?", middleware, bind(@action_show, @)

    middleware = @options.middleware?.update or []
    app.put @_mount_info.url_prefix + "/:#{@idParam}.:format?", middleware, bind(@action_update, @)

    middleware = @options.middleware?.delete or []
    app.delete @_mount_info.url_prefix + "/:#{@idParam}", middleware, bind(@action_delete, @)
    @

  _get_prefix: ->
    if @_mount_info.on_resource
      resource = @_mount_info.on
      r_prefix = resource._prefix + "/:#{resource.idParam}"
      prefix = urlJoin(r_prefix, @plural)
    else
      prefix = @_prefix
    prefix

  _update_instance_from_body_values: (req, instance) ->
    @model.schema.eachPath (pathname) =>
      path = @model.schema.path(pathname)
      # TODO: handle compound pathnames (like 'aaa.bbb')
      if pathname of req.body
        instance.set(pathname, req.body[pathname])
      else if req.files? and (pathname of req.files)
        rf = req.files[pathname]
        @trace("getting file name:#{rf.name} length:#{rf.length} filename:#{rf.filename} mime:#{rf.mime}")
        # the following expects the field to be defined through the `mongoose-file` plugin
        instance.set("#{pathname}.file", req.files[pathname])
    instance

  # -- helper methods -------------------------------------------------

  # trace
  trace: (args...) ->
    if @_trace
      args = args or []
      args.unshift("[#{@name}] ")
      console?.log?(args...)
    @

  traceAction: (req, actionName, url) ->
    if @_trace
      msg = "[#{@name}/#{actionName}] #{req.method} #{url}"
      if req.params? and (@idParam of req.params)
        id = req.params[@idParam]
        if id
          msg = msg + " id:#{id}"
      console?.log?(msg)
    @

# -- exports ----------------------------------------------------------

module.exports =
  Resource: Resource
