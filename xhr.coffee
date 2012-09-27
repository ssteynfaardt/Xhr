class Xhr
  #class methods
  @readyState =  0
  @status = null
  #jsonp callback function

  _parseUrl = (->
    a = document.createElement("a")
    (url) ->
      a.href = url
      host: a.host
      hostname: a.hostname
      pathname: a.pathname
      port: a.port
      protocol: a.protocol
      search: a.search
      hash: a.hash
  )()

  _isObject = (obj) ->
    (obj.ownerDocument not instanceof Object) and (obj not instanceof Date) and (obj not instanceof RegExp) and (obj not instanceof Function) and (obj not instanceof String) and (obj not instanceof Boolean) and (obj not instanceof Number) and obj instanceof Object

  _doJsonP = (url) ->
    script = document.createElement("script")
    script.type = 'text/javascript';
    script.src = url
    document.body.appendChild script

  jpcb: ->
  #public methods
  constructor: () ->
    
    _callbackFunctions = {}
    _setCallbackFor = (callbackFor, callbackFunction) ->
      if(typeof callbackFor is 'string' and typeof callbackFunction is 'function')
        _callbackFunctions[callbackFor] = callbackFunction

    _doCallbackFor = (callbackFor) ->
      if(typeof _callbackFunctions[callbackFor] is 'function')
        _callbackFunctions[callbackFor](arguments[1],arguments[2],arguments[3])
    #Instance varialbes, to access it @_.cors
    @_ =
      xhr: null
      cors:  null
      xhrType: 'form'
      doCallbackFor: _doCallbackFor
      setCallbackFor: _setCallbackFor



  createXhrObject: ->
    _validStatus = [200,201,204,304]
    @_.cors = false
    if window.XDomainRequest
      @_.xhr = new XDomainRequest()
      @_.cors = true
    else if window.XMLHttpRequest
      @_.xhr = new XMLHttpRequest()
      @_.cors = true  if "withCredentials" of @_.xhr
    else if window.ActiveXObject
      try
        @_.xhr = new ActiveXObject("MSXML2.XMLHTTP.3.0")
      catch error
        @_.xhr = null
        throw Error(error);

    _this = @
    @_.xhr.onreadystatechange = ->
      _this.readyState = _this._.xhr.readyState
      _this._.doCallbackFor('readystatechange',_this._.xhr)
      switch _this._.xhr.readyState
        when 0, 1
          _this._.doCallbackFor('loadstart',_this._.xhr)
        when 2
          _this._.doCallbackFor('progress',_this._.xhr)
        when 3
          _this._.doCallbackFor('onload',_this._.xhr)
        when 4
          try
            if _this._.xhr.status in _validStatus
              _this._.doCallbackFor('success',_this._.xhr.responseText,_this._.xhr.status,_this._.xhr)
            else
              _this._.doCallbackFor('error',_this._.xhr.responseText,_this._.xhr.status,_this._.xhr)
          catch error
            throw Error(error)

          _this._.doCallbackFor('loadend',_this._.xhr.responseText, _this._.xhr.status,_this._.xhr)
          _this._.xhr = null
        else
          throw Error("Unsupported readystate (#{_this._.xhr.readyState}) received.")

    @_.xhr.ontimeout = ->
      _this._.doCallbackFor('timeout',_this._.xhr)
    @_.xhr.onabort = ->
      _this._.doCallbackFor('abort',_this._.xhr)  

    @_.xhr

  _doAjaxCall: (url,method = "GET",data = null)->
    if (url is undefined)
      throw Error("URL required");
    currentUrl = window.location

    urlObj = _parseUrl(url);
    xhrObj = @createXhrObject()

    getContentType = (type = "form") ->
      contentType = 'application/x-www-form-urlencoded'
      switch type.toLowerCase()
        when 'html'
          contentType = 'text/html'
        when 'json'
          contentType = 'application/json'
        when 'jsonp'
          contentType = 'application/javascript'
        when 'xml'
          contentType = 'application/xml'
        else
          contentType = 'application/x-www-form-urlencoded'
      contentType
    
    #check if we are making a CORS call
    if (urlObj.host is currentUrl.host and urlObj.protocol is currentUrl.protocol and urlObj.port is currentUrl.port) then crossDomain = false else crossDomain = true
    if crossDomain is false or @_.cors is true
      xhrObj.open(method,url,true)
      if(@_.cors)
        xhrObj.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
      if (data)
        if(typeof data is 'string' and window.JSON)
          try
            data = JSON.parse(data)
            @setType('json');            
          catch e
          

        if(@_.xhrType is 'json' and typeof data is "object" and window.JSON)
          data = JSON.stringify(data)
          @setType('json');
        else if(typeof data != "string")
          xhrObj.setRequestHeader('Content-Type', getContentType('form'))
          data = @serialize(data)
          @setType('form');
      xhrObj.setRequestHeader('Content-Type', getContentType(@_.xhrType))
      xhrObj.send(data)
    else
      data = @serialize(data)
      _doJsonP("#{data}&callback=")
      throw Error "crossDomain Error"

  serialize: (obj, keyed, prefix = '') ->
    return prefix + encodeURIComponent(obj)  unless _isObject(obj)
    result = ""
    temp = ""
    for index of obj
      continue  unless obj.hasOwnProperty(index)
      temp = (if keyed then keyed + "[" + encodeURIComponent(index) + "]" else encodeURIComponent(index))
      result += @serialize(obj[index], temp, "&" + temp + "=")
    result.substring(1)

  setType: (type)->
    _validTypes = ['form','html','json','jsonp','xml']
    type = type.toLowerCase()
    throw Error("Unsupported type (#{type})") if type not in _validTypes
    @_.xhrType = type


  cors: ->
    if @_.cors is null
      @createXhrObject()
    @_.cors

  abort: ->
    try
      @_.xhr.abort();
      @_.xhr.onreadystatechange = ->
      @readyState = 0
    catch error
      #throw Error(error)
    @ononabort()
    @

  call: (url,method,data) ->
    @_doAjaxCall(url,method,data)
    @
  head:(url) ->
    @_doAjaxCall(url,"HEAD")
    @
  options:(url) ->
    @_doAjaxCall(url,"OPTIONS")
    @
  get:(url) ->
    @_doAjaxCall(url,"GET")
    @
  put: ( url, data) ->
    @_doAjaxCall(url,"PUT",data)
    @
  post: ( url, data) ->
    @_doAjaxCall(url,"POST",data)
    @
  delete: (url) ->
    @_doAjaxCall(url,"DELETE")
    @
  jsonp:(url) ->
    _doJsonP(url)
    @

  onreadystatechange: (callback) ->
    @_.setCallbackFor('readystatechange',callback)
    @
  onloadstart: (callback) ->
    @_.setCallbackFor('loadstart',callback)
    @
  onprogress: (callback) ->
    @_.setCallbackFor('progress',callback)
    @
  onload: (callback) ->
    @_.setCallbackFor('load',callback)
    @
  onerror: (callback) ->
    @_.setCallbackFor('error',callback)
    @
  onsuccess: (callback) ->
    @_.setCallbackFor('success',callback)
    @
  onloadend: (callback) ->
    @_.setCallbackFor('loadend',callback)
    @
  ontimeout: (callback) ->
    @_.setCallbackFor('timeout',callback)
    @
  onabort: (callback) ->
    @_.setCallbackFor('abort',callback)
    @
#Set some variables that will be available in the to use
window.Xhr = Xhr