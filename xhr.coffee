((window) ->
  _xhr = null
  _xhrType = 'form'    
  _cors =  null
  _callbackFunctions = {}

  _setCallbackFor = (callbackFor, callbackFunction) ->
    if(typeof callbackFor is 'string' and typeof callbackFunction is 'function')
      _callbackFunctions[callbackFor] = callbackFunction

  _doCallbackFor = (callbackFor) ->
    if(typeof _callbackFunctions[callbackFor] is 'function')
      _callbackFunctions[callbackFor](arguments[1],arguments[2],arguments[3])

  class Xhr
    @readyState =  0
    @status = null

    #constructor: ->
    jpcb = ->
    createXhrObject: ->
      _validStatus = [200,201,204,304]
      _cors = false
      if window.XDomainRequest
        _xhr = new XDomainRequest()
        _cors = true
      else if window.XMLHttpRequest
        _xhr = new XMLHttpRequest()
        _cors = true  if "withCredentials" of _xhr
      else if window.ActiveXObject
        try
          _xhr = new ActiveXObject("MSXML2.XMLHTTP.3.0")
        catch error
          _xhr = null
          throw Error(error);

      _this = @
      _xhr.onreadystatechange = ->
        _this.readyState = _xhr.readyState
        _doCallbackFor('readystatechange',_xhr)
        switch _xhr.readyState
          when 0, 1
            _doCallbackFor('loadstart',_xhr)
          when 2
            _doCallbackFor('progress',_xhr)
          when 3
            _doCallbackFor('onload',_xhr)
          when 4
            try
              if _xhr.status in _validStatus
                _doCallbackFor('success',_xhr.responseText,_xhr.status,_xhr)
              else
                _doCallbackFor('error',_xhr.responseText,_xhr.status,_xhr)
            catch error
              throw Error(error)

            _doCallbackFor('loadend',_xhr.responseText, _xhr.status,_xhr)
            _xhr = null
          else
            throw Error("Unsupported readystate (#{_xhr.readyState}) received.")

      _xhr.ontimeout = ->
        _doCallbackFor('timeout',_xhr)
      _xhr.onabort = ->
        _doCallbackFor('abort',_xhr)  

      _xhr

    _doAjaxCall: (url,method = "GET",data = null)->
      if (url is undefined)
        throw Error("URL required");
      currentUrl = window.location

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
      if crossDomain is false or _cors is true
        xhrObj.open(method,url,true)
        if(_cors)
          xhrObj.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
        if (data)
          if(typeof data is 'string' and window.JSON)
            try
              data = JSON.parse(data)
              @setType('json');            
            catch e
            

          if(_xhrType is 'json' and typeof data is "object" and window.JSON)
            data = JSON.stringify(data)
            @setType('json');
          else if(typeof data != "string")
            xhrObj.setRequestHeader('Content-Type', getContentType('form'))
            data = @serialize(data)
            @setType('form');
        xhrObj.setRequestHeader('Content-Type', getContentType(_xhrType))
        xhrObj.send(data)
      else
        data = @serialize(data)
        _doJsonP("#{data}&callback=")
        throw Error "crossDomain Error"

    _doJsonP: (url) ->
      @setType('jsonp')
      script = document.createElement("script")
      script.type = 'text/javascript';
      script.src = url
      document.body.appendChild script

    serialize: (obj, keyed, prefix = '') ->
      _isObject = (obj) ->
        (obj.ownerDocument not instanceof Object) and (obj not instanceof Date) and (obj not instanceof RegExp) and (obj not instanceof Function) and (obj not instanceof String) and (obj not instanceof Boolean) and (obj not instanceof Number) and obj instanceof Object
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
      _xhrType = type


    cors: ->
      if _cors is null
        @createXhrObject()
      _cors

    abort: ->
      try
        _xhr.abort();
        _xhr.onreadystatechange = ->
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
      @_doJsonP(url)
      @

    onreadystatechange: (callback) ->
      _setCallbackFor('readystatechange',callback)
      @
    onloadstart: (callback) ->
      _setCallbackFor('loadstart',callback)
      @
    onprogress: (callback) ->
      _setCallbackFor('progress',callback)
      @
    onload: (callback) ->
      _setCallbackFor('load',callback)
      @
    onerror: (callback) ->
      _setCallbackFor('error',callback)
      @
    onsuccess: (callback) ->
      _setCallbackFor('success',callback)
      @
    onloadend: (callback) ->
      _setCallbackFor('loadend',callback)
      @
    ontimeout: (callback) ->
      _setCallbackFor('timeout',callback)
      @
    onabort: (callback) ->
      _setCallbackFor('abort',callback)
      @
  #Set some variables that will be available in the to use
  window.Xhr = Xhr


) window