##[ 
  Nim wrapper for [WebUI](https://github.com/webui-dev/webui)

  :Author: Jasmine
  :WebUI Version: 2.4.0

  See: https://neroist.github.io/webui-docs/
]##

from webui/bindings import nil

type
  Window* = distinct int

  Event* = ref object
    ## When you use `bind()`, your application will receive an event every time 
    ## the user clicks on the specified HTML element. The event comes with the 
    ## `element`, which is The HTML ID of the clicked element, for example,
    ## `MyButton`, `MyInput`, etc. The event also comes with the element ID
    ## & the unique window ID.
  
    internalImpl*: ptr bindings.Event

# vars

var 
  cbs: array[bindings.WEBUI_MAX_IDS, array[bindings.WEBUI_MAX_IDS, proc (e: Event)]]
    ## array of binded callbacks.
    ## Needed for `bind`
  currHandler: proc (filename: string): string
    ## Most recent file handler set by `fileHandler=`.
    ## Meeded for `fileHandler=`.

proc wait*() =
  ## Wait until all opened windows get closed.

  bindings.wait()

proc exit*() = 
  ## Close all opened windows. `wait()` will break.

  bindings.exit()

proc setTimeout*(timeout: int) = 
  ## Set the maximum time in seconds to wait for browser to start
  ## 
  ## Set `timeout` to `0` to wait forever.
  ## 
  ## :timeout: The maximum time in seconds to wait for browser to start.
  ##           Set to `0` to wait forever.
  
  bindings.setTimeout(csize_t timeout)

proc encode*(str: string): string = 
  ## Base64 encoding. Use this to safely send text based data to the UI.
  ## If it fails it will return an empty string.
  ## 
  ## :str: The string to encode.

  var cstr = bindings.encode(cstring str)
  result = $cstr

  bindings.free(addr cstr)

proc decode*(str: string): string = 
  ## Base64 decoding. Use this to safely decode received Base64 text from the UI.
  ## If it fails it will return an empty string.
  ## 
  ## :str: The string to decode.

  var cstr = bindings.decode(cstring str)
  result = $cstr
  
  bindings.free(addr cstr)

proc setDefaultRootFolder*(path: string): bool {.discardable.} = 
  ## Set the web-server root folder path for all windows. 
  ## 
  ## .. note:: Should be used before `webui_show()`.
  ## 
  ## :path: The path to the root folder.

  bindings.setDefaultRootFolder(cstring path)

proc clean*() =
  ## Free all memory resources. Should be called only at the end.
  
  bindings.clean()

proc deleteAllProfiles*() = 
  ## Delete all local web-browser profiles folder. It should be called at the end.
  
  bindings.deleteAllProfiles()

# ------- Impl funcs --------

# --- Event ---

func impl*(event: Event): ptr bindings.Event = 
  ## Returns the internal implementation of `e`

  event.internalImpl

func `impl=`*(event: Event, be: ptr bindings.Event) = 
  ## Sets the internal implementation of `e`

  event.internalImpl = be

# -------- Event --------

proc element*(event: Event): string =
  $ event.impl.element

proc window*(event: Event): Window =
  result = Window(int event.impl.window)

proc data*(event: Event): string =
  $ event.impl.data

proc eventNumber*(event: Event): int =
  int event.impl.eventNumber

proc size*(event: Event): int =
  int event.impl.size

proc eventType*(event: Event): bindings.Events =
  bindings.Events(int event.impl.eventType)

# --- 

proc getInt*(event: Event): int =
  ## Parse event as a integer.
  ## 
  ## :event: The event to parse as an integer

  int bindings.getInt(event.internalImpl)

proc getString*(event: Event): string =
  ## Parse event as a string.
  ## 
  ## :event: The event to parse as an string
  
  $ bindings.getString(event.internalImpl)

proc getBool*(event: Event): bool =
  ## Parse event as a boolean.
  ## 
  ## :event: The event to parse as an boolean

  bindings.getBool(event.internalImpl)

proc returnInt*(event: Event; integer: int) = 
  ## Return the response to JavaScript as a integer.
  ## 
  ## :event: The event to set the response for
  ## :integer: The int to return back to Javascript.

  bindings.returnInt(event.internalImpl, clonglong integer)

proc returnString*(event: Event; str: string) =
  ## Return the response to JavaScript as a string.
  ## 
  ## :event: The event to set the response for
  ## :str: The string to return back to Javascript.

  bindings.returnString(event.internalImpl, cstring str)

proc returnBool*(event: Event; b: bool) =
  ## Return the response to JavaScript as a boolean.
  ## 
  ## :event: The event to set the response for
  ## :b: The bool to return back to Javascript.

  bindings.returnBool(event.internalImpl, b)

# -------- Window --------

proc newWindow*(): Window =
  ## Create a new WebUI window object.

  result = Window(bindings.newWindow())

proc newWindow*(windowNumber: int): Window = 
  ## Create a new webui window object using a specified window ID.
  ## 
  ## :windowNumber: The window ID  (should be > 0, and < WEBUI_MAX_IDS)
  
  bindings.newWindowId(csize_t windowNumber)
  result = Window(windowNumber)

proc getNewWindowId*(): int = 
  ## Get new window ID. To be used in conjuction with
  ## [newWindow()](#newWindow,int).
  ## 
  ## Returns the first available free window number. Starting from 1.
  
  int bindings.getNewWindowId()

proc childProcessId*(window: Window): int =
  int bindings.getChildProcessId(csize_t window)

proc parentProcessId*(window: Window): int =
  int bindings.getParentProcessId(csize_t window)

{.push discardable.}

proc show*(window: Window; content: string): bool = 
  ## Show a window using embedded HTML, or a file. If the window is already
  ## open, it will be refreshed. 
  ## 
  ## :window: The window to show `content` in. If the window is already
  ##          shown, the UI will get refreshed in the same window.
  ## :content: The content to show in `window`. Can be a file name, or a
  ##           static HTML script.
  ## 
  ## Returns `true` if showing the window is a success.

  bindings.show(csize_t window, cstring content)

proc show*(window: Window; content: string; browser: bindings.Browsers): bool =
  ## Same as `show() <#show,Window,string>`_, but with a specific web browser.
  ## 
  ## :window: The window to show `content` in. If the window is already
  ##          shown, the UI will get refreshed in the same window.
  ## :content: The content to show in `window`. Can be a file name, or a
  ##           static HTML script.
  ## :browser: The browser to open the window in.
  ## 
  ## Returns `true` if showing the window is a success.

  bindings.showBrowser(csize_t window, cstring content, csize_t ord(browser))

{.pop.}

proc `icon=`*(window: Window; icon, `type`: string) = 
  ## Set the default embedded HTML favicon.
  ## 
  ## :window: The window to set the icon for.
  ## :icon: The icon as string: `<svg>...</svg>`
  ## :type: The MIME type of the icon

  bindings.setIcon(csize_t window, cstring icon, cstring type)

proc `multiAccess=`*(window: Window; status: bool) = 
  ## Allow the window URL to be re-used in normal web browsers.
  ## 
  ## :window: The window to enable or disable multi access (whether or not
  ##          to allow the window URL to be re-used).
  ## :status: Whether or not to enable multi access mode. `true` to enable, `false`
  ##          to disable.

  bindings.setMultiAccess(csize_t window, status)

proc `kiosk=`*(window: Window; status: bool) = 
  ## Set the window in Kiosk mode (full screen).
  ## 
  ## :window: The window to enable or disable kiosk mode in.
  ## :status: Whether or not to enable kiosk mode. `true` to enable, `false`
  ##          to disable.
  
  bindings.setKiosk(csize_t window, status)

proc `runtime=`*(window: Window; runtime: bindings.Runtime) = 
  ## Chose a runtime for .js and .ts files.
  ## 
  ## :window: The window to set the runtime for.
  ## :runtime: The runtime to set.
  
  bindings.setRuntime(csize_t window, csize_t ord(runtime))

proc `rootFolder=`*(window: Window; path: string): bool {.discardable.} = 
  ## Set the web-server root folder path.
  ##
  ## :window: The window to set the root folder for.
  ## :path: The path to the root folder.

  bindings.setRootFolder(csize_t window, cstring path)

proc `hidden=`*(window: Window; status: bool) = 
  ## Run the window in hidden mode
  ## 
  ## :window: The window to hide or show.
  ## :status: Whether or not to hide the window. `true` to hide, `false`
  ##          to show.
  
  bindings.setHide(csize_t window, status)

proc `size=`*(window: Window; size: tuple[width, height: int]) = 
  bindings.setSize(csize_t window, cuint size.width, cuint size.height)

proc `pos=`*(window: Window; pos: tuple[x, y: int]) = 
  bindings.setPosition(csize_t window, cuint pos.x, cuint pos.y)

proc setSize*(window: Window; width, height: int) = 
  bindings.setSize(csize_t window, cuint width, cuint height)

proc setPos*(window: Window; x, y: int) = 
  bindings.setPosition(csize_t window, cuint x, cuint y)

proc close*(window: Window) = 
  ## Close a specific window only. The window object will still exist.
  ## 
  ## :window: The window to close.
  
  bindings.close(csize_t window)

proc destroy*(window: Window) =
  ## Close a specific window and free all memory resources.
  ## 
  ## :window: The window to destroy.
  
  bindings.destroy(csize_t window)

proc shown*(window: Window): bool = 
  ## Return if window `window` is still running
  ## 
  ## :window: The window to return `true` if still running.

  bindings.isShown(csize_t window)

proc script*(window: Window; script: string; timeout: int = 0, bufferLen: static[int] = 1024 * 8): tuple[data: string; error: bool] =
  ## Run Javascript code `script` and return the result
  ## 
  ## Returns a tuple containing the response (`data`) and whether or not
  ## there was an error (`error`, true if an error occured, false otherwise).
  ## If an error occured, the error message will be held in `data`.
  ## 
  ## :window: The window to run the Javascript code in.
  ## :script: The Javascript code to execute.
  ## :timeout: How long to wait, at most, for a response.
  ## :bufferLen: How large to make the buffer for the response. Default is
  ##             8 kibibytes. (For larger responses make `bufferLen` larger)
  
  var buffer: array[bufferLen, char]

  let 
    error = bindings.script(csize_t window, cstring script, csize_t timeout, cast[cstring](addr buffer[0]), csize_t bufferLen)

    data = $(cast[cstring](addr buffer[0])) # remove trailing null chars

  result.data = data
  result.error = not error

proc run*(window: Window; script: string) =
  ## Run JavaScript quickly without waiting for the response.
  ## 
  ## :window: The window to run the Javascript code in.
  ## :script: The Javascript code to execute.

  bindings.run(csize_t window, cstring script)
  
#proc interfaceHandler(window: csize_t; eventType: csize_t; element: cstring; data: cstring; eventNumber: csize_t) {.cdecl.} =
#  var event = bindings.Event()
#
#  event.element = element
#  event.window = window
#  event.data = data
#  event.eventType = eventType
#  event.eventNumber = eventNumber
#
#  var e = Event(
#    internalImpl: addr event
#  )
#
#  cbs[bindings.interfaceGetWindowId(window)][bindings.interfaceGetBindId(window, element)](e)

proc bindHandler(e: ptr bindings.Event) {.cdecl.} = 
  var event = Event(internalImpl: e)

  cbs[bindings.interfaceGetWindowId(e.window)][bindings.interfaceGetBindId(e.window, e.element)](event)

proc `bind`*(window: Window; element: string; `func`: proc (e: Event)) =
  ## Bind a specific html element click event with a function. Empty element means all events.
  ## 
  ## Each element can have only one function bound to it.
  ## 
  ## :window: The window to bind the function onto.
  ## :element: The element to bind the function `func` to. `func` will be
  ##           called on click events. An empty element means `func` will
  ##           be bound to all events.
  ## :func: The function to bind to `element`. 

  let bid = int bindings.bind(csize_t window, cstring element, bindHandler)
  let wid = int bindings.interfaceGetWindowId(csize_t window)
  
  cbs[wid][bid] = `func`

proc `bind`*(window: Window; element: string; `func`: proc (e: Event): string) =
  window.bind(
    element, 
    proc (e: Event) =
      let res = `func`(e)
      e.returnString(res)
  )

proc `bind`*(window: Window; element: string; `func`: proc (e: Event): int) =
  window.bind(
    element, 
    proc (e: Event) =
      let res = `func`(e)
      e.returnInt(res)
  )

proc `bind`*(window: Window; element: string; `func`: proc (e: Event): bool) =  
  ## Bind `func` to element `element` and automatically pass return value of `func` to Javascript.
  ## 
  ## :window: The window to bind the function onto.
  ## :element: The element to bind the function `func` to. `func` will be
  ##           called on click events. An empty element means `func` will
  ##           be called on all events.
  ## :func: The function to bind to `element`.

  window.bind(
    element, 
    proc (e: Event) =
      let res = `func`(e)
      e.returnBool(res)
  )

proc fileHandlerImpl(filename: cstring, length: ptr cint): pointer {.cdecl.} =
  let content = currHandler($filename)

  if content.len == 0:
    return nil

  # Always set length for memory safety, especially binarys with '\0' inside
  length[] = cint content.len

  # Use webui_malloc to ensure memory safety
  let mem = bindings.malloc(csize_t content.len)
  copyMem(mem, cstring content, content.len)

  return mem

proc `fileHandler=`*(window: Window; handler: proc (filename: string): string) = 
  ## Set a custom handler to serve files.
  ## 
  ## :window: The window to set the file handler.
  ## :runtime: The file handler callback/proc.

  currHandler = handler

  bindings.setFileHandler(csize_t window, fileHandlerImpl)

# mainly for use with `do` notation
proc setFileHandler*(window: Window; handler: proc (filename: string): string) = 
  window.fileHandler = handler

proc `runtime=`*(window: Window; runtime: bindings.Runtime) = 
  ## Chose a runtime for .js and .ts files.
  ## 
  ## :window: The window to set the runtime for.
  ## :runtime: The runtime to set.
  
  bindings.setRuntime(csize_t window, csize_t ord(runtime))

proc `rootFolder=`*(window: Window; path: string): bool {.discardable.} = 
  ## Set the web-server root folder path for a specific window.
  ##
  ## :window: The window to set the root folder for.
  ## :path: The path to the root folder.

  bindings.setRootFolder(csize_t window, cstring path)

proc sendRaw*(window: Window; function: string; raw: pointer; size: uint) = 
  ## Safely send raw data to the UI.
  ## 
  ## :window: The window to send the raw data to.
  ## :function: The JavaScript function to receive raw data: `function myFunc(myData){}`
  ## :raw: The raw data buffer.
  ## :size: The size of the raw data in bytes.
  
  bindings.sendRaw(csize_t window, cstring function, raw, csize_t size)

proc `hidden=`*(window: Window; status: bool) = 
  ## Run the window in hidden mode. Should be called before `webui_show()`.
  ## 
  ## :window: The window to hide or show.
  ## :status: Whether or not to hide the window. `true` to hide, `false`
  ##          to show.
  
  bindings.setHide(csize_t window, status)

proc setSize*(window: Window; width, height: int) =
  ## Set window size
  ## 
  ## :window: The window to set the size for.
  ## :width: What to set the window's width to.
  ## :height: What to set the window's height to.
  
  bindings.setSize(csize_t window, cuint width, cuint height)

proc setPosition*(window: Window; x, y: int) =
  ## Set window position
  ## 
  ## :window: The window to set the size for.
  ## :x: What to set the window's X to.
  ## :y: What to set the window's Y to.

  bindings.setPosition(csize_t window, cuint x, cuint y)

proc setProfile*(window: Window; name, path: string) = 
  ## Set the web browser profile to use. An empty `name` and `path` means
  ## the default user profile. 
  ## 
  ## .. note:: Needs to be called before `webui_show()`.
  ## 
  ## :window: The window to set the browser profile for.
  ## :name: The web browser profile name.
  ## :path: The web browser profile full path.
  
  runnableExamples:
    window.setProfile("Bar", "/Home/Foo/Bar")
    window.setProfile("", "")

  bindings.setProfile(csize_t window, cstring name, cstring path)
  
proc url*(window: Window): string =
  ## Get the full current URL
  ## 
  ## :window: The window to get the URL from
  
  $ bindings.getUrl(csize_t window)
  
proc navigate*(window: Window, url: string) =
  ## Navigate to a specific URL
  ## 
  ## :window: The window to navigate on
  ## :url: The URL to navigate to
  
  bindings.navigate(csize_t window, cstring url)

proc deleteProfile*(window: Window) = 
  ## Delete a specific window web-browser local folder profile.
  ##
  ## :window: The window whose profile will be deleted

  bindings.deleteProfile(csize_t window)

export 
  bindings.Events, 
  bindings.Browsers, 
  bindings.Runtime, 
  bindings.WEBUI_VERSION,
  bindings.WEBUI_MAX_IDS
