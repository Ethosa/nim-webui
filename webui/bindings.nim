## Nim bindings for [WebUI](https://github.com/webui-dev/webui)

runnableExamples:

  let window = newWindow() # Create a new Window
  window.show("<html>Hello</html>") # Show the window with html content in any browser

  wait() # Wait until the window gets closed


import std/os

const
  currentSourceDir {.used.} = currentSourcePath().parentDir()

  useWebuiStaticLib* = defined(useWebuiStaticLib) or defined(useWebuiStaticLibrary)
  useWebuiDll* = defined(useWebuiDll)

when useWebuiStaticLib:
  const webuiStaticLib* {.strdefine.} = "webui-2-static-x64"

  when defined(vcc):
    {.link: "user32.lib".}
    {.link: "ws2_32.lib".}
    {.link: "Advapi32.lib".}

    {.link: webuiStaticLib & ".lib".}
  else:
    # * Order matters!!

    {.passL: "-L.".} # so gcc/clang can find the library

    {.passL: "-l" & webuiStaticLib.} # link the static library itself

    {.passL: "-luser32".} # link dependencies
    {.passL: "-lws2_32".}
    {.passL: "-lAdvapi32".}

  {.pragma: webui, discardable.}
elif useWebuiDll:
  const webuiDll* {.strdefine.} = when defined(windows):
    "webui-2-x64.dll"
  elif defined(macos):
    "webui-2-x64.dyn"
  else:
    "webui-2-x64.so" # no lib prefix

  {.pragma: webui, dynlib: webuiDll, discardable.}
else:
  # -d:webuiLog
  when defined(webuiLog):
    {.passC: "-DWEBUI_LOG".}

  when defined(vcc):
    {.link: "user32.lib".}
    {.link: "ws2_32.lib".}
    {.link: "Advapi32.lib".}

    {.passC: "/I " & currentSourceDir / "webui" / "include".}

  elif defined(windows):
    {.passL: "-lws2_32".}
    {.passL: "-luser32".}
    {.passL: "-lAdvapi32".}

    {.passC: "-I" & currentSourceDir / "webui" / "include".}

  when defined(linux) or defined(macosx):
    {.passL: "-lpthread".}
    {.passL: "-lm".}

    {.passC: "-I" & currentSourceDir / "webui" / "include".}

  {.pragma: webui, discardable.}
  
  {.passC: "-DNDEBUG -DNO_CACHING -DNO_CGI -DNO_SSL -DUSE_WEBSOCKET -DMUST_IMPLEMENT_CLOCK_GETTIME".}

  {.compile: currentSourceDir / "webui/src/civetweb/civetweb.c".}
  {.compile: currentSourceDir / "webui/src/webui.c".}

const
  WEBUI_VERSION* = "2.4.0 (Beta)"   ## Version
  WEBUI_MAX_IDS* = (512)
  WEBUI_MAX_ARG* = (16)

# -- Types -------------------------

type
  Browsers* {.pure.} = enum
    NoBrowser     ## 0. No web browser
    Any           ## 1. Default recommended web browser
    Chrome        ## 2. Google Chrome
    Firefox       ## 3. Mozilla Firefox
    Edge          ## 4. Microsoft Edge
    Safari        ## 5. Apple Safari
    Chromium      ## 6. The Chromium Project
    Opera         ## 7. Opera Browser
    Brave         ## 8. The Brave Browser
    Vivaldi       ## 9. The Vivaldi Browser
    Epic          ## 10. The Epic Browser
    Yandex        ## 11. The Yandex Browser
    ChromiumBased ## 12. Any Chromium based browser

  Events* = enum
    EventsDisconnected        ## 0. Window disconnection event
    EventsConnected           ## 1. Window connection event
    EventsMouseClick          ## 2. Mouse click event
    EventsNavigation          ## 3. Window navigation event
    EventsCallback            ## 4. Function call event

  Event* {.bycopy.} = object
    window*: csize_t       ## The window object number
    eventType*: csize_t    ## Event type
    element*: cstring      ## HTML element ID
    eventNumber*: csize_t  ## Internal WebUI
    bindId*: csize_t

  Runtime* {.pure.} = enum
    None    ## 0. Prevent WebUI from using any runtime for .js and .ts files
    Deno    ## 1. Use Deno runtime for .js and .ts files
    NodeJS  ## 2. Use Nodejs runtime for .js files

#  -- Definitions ---------------------
proc newWindow*(): csize_t {.cdecl, importc: "webui_new_window".}
  ##  Create a new webui window object.

proc newWindowId*(windowNumber: csize_t) {.cdecl, importc: "webui_new_window_id".}
  ##  Create a new webui window object.

proc getNewWindowId*(): csize_t {.cdecl, importc: "webui_get_new_window_id".}
  ##  Get a free window ID that can be used with `newWindowId()`

proc `bind`*(window: csize_t; element: cstring; `func`: proc (e: ptr Event) {.cdecl.}): csize_t {.
    cdecl, importc: "webui_bind".}
  ##  Bind a specific html element click event with a function. Empty element means all events.
 
proc show*(window: csize_t; content: cstring): bool {.cdecl, importc: "webui_show".}
  ##  Show a window using a embedded HTML, or a file. If the window is already opened then it will be refreshed.

proc showBrowser*(window: csize_t; content: cstring; browser: csize_t): bool {.cdecl,
    importc: "webui_show_browser".}
  ##  Same as webui_show(). But with a specific web browser.

proc setKiosk*(window: csize_t; status: bool) {.cdecl, importc: "webui_set_kiosk".}
  ##  Set the window in Kiosk mode (Full screen)

proc wait*() {.cdecl, importc: "webui_wait".}
  ##  Wait until all opened windows get closed.

proc close*(window: csize_t) {.cdecl, importc: "webui_close".}
  ##  Close a specific window only. The window object will still exist.

proc destroy*(window: csize_t) {.cdecl, importc: "destroy".}
  ##  Close a specific window and free all memory resources.

proc exit*() {.cdecl, importc: "webui_exit".}
  ##  Close all opened windows. webui_wait() will break.

proc setRootFolder*(window: csize_t; path: cstring): bool {.cdecl,
    importc: "webui_set_root_folder".}
  ##  Set the web-server root folder path for a specific window.

proc setDefaultRootFolder*(path: cstring): bool {.cdecl,
    importc: "webui_default_set_root_folder".}
  ##  Set the web-server root folder path for all windows.

proc setFileHandler*(window: csize_t; handler: proc (filename: cstring, length: ptr cint): pointer {.cdecl.}) {.cdecl, importc: "webui_set_file_handler".}
  ##  Set a custom handler to serve files

#  -- Other ---------------------------
proc isShown*(window: csize_t): bool {.cdecl, importc: "webui_is_shown".}
  ##  Check a specific window if it's still running

proc setTimeout*(second: csize_t) {.cdecl, importc: "webui_set_timeout".}
  ##  Set the maximum time in seconds to wait for browser to start

proc setIcon*(window: csize_t; icon: cstring; `type`: cstring) {.cdecl,
    importc: "webui_set_icon".}
  ##  Set the default embedded HTML favicon

#  -- JavaScript ----------------------
proc run*(window: csize_t; script: cstring) {.cdecl, importc: "webui_run".}
  ##  Run JavaScript quickly without waiting for the response.

proc script*(window: csize_t; script: cstring; timeout: csize_t; buffer: cstring;
            bufferLength: csize_t): bool {.cdecl, importc: "webui_script".}
  ##  Run a JavaScript, and get the response back (Make sure your local buffer can hold the response).

proc setRuntime*(window: csize_t; runtime: csize_t) {.cdecl,
    importc: "webui_set_runtime".}
  ##  Chose between Deno and Nodejs runtime for .js and .ts files.

proc getIntAt*(e: ptr Event; index: csize_t): clonglong {.cdecl, importc: "webui_get_int".}
  ##  Get an argument as integer at a specific index.

proc getInt*(e: ptr Event): clonglong {.cdecl, importc: "webui_get_int".}
  ##  Get the first argument as integer.

proc getStringAt*(e: ptr Event; index: csize_t): cstring {.cdecl, importc: "webui_get_string".}
  ##  Get an argument as string at a specific index.

proc getString*(e: ptr Event): cstring {.cdecl, importc: "webui_get_string".}
  ##  Get the first argument as string.

proc getBoolAt*(e: ptr Event; index: csize_t): bool {.cdecl, importc: "webui_get_bool".}
  ##  Get an argument as boolean at a specific index.

proc getBool*(e: ptr Event): bool {.cdecl, importc: "webui_get_bool".}
  ##  Get the first argument as boolean.

proc getSizeAt*(e: ptr Event; index: csize_t): csize_t {.cdecl, importc: "webui_get_bool".}
  ##  Get the size in bytes of an argument at a specific index.

proc getSize*(e: ptr Event): csize_t {.cdecl, importc: "webui_get_bool".}
  ##  Get size in bytes of the first argument.

proc returnInt*(e: ptr Event; n: clonglong) {.cdecl, importc: "webui_return_int".}
  ##  Return the response to JavaScript as integer.

proc returnString*(e: ptr Event; s: cstring) {.cdecl, importc: "webui_return_string".}
  ##  Return the response to JavaScript as string.

proc returnBool*(e: ptr Event; b: bool) {.cdecl, importc: "webui_return_bool".}
  ##  Return the response to JavaScript as boolean.

proc encode*(str: cstring): cstring {.cdecl, importc: "webui_encode".}
  ##  Base64 encoding. Use this to safely send text based data to the UI.
  ##  If it fails it will return `nil`.

proc decode*(str: cstring): cstring {.cdecl, importc: "webui_decode".}
  ##  Base64 decoding. Use this to safely decode received Base64 text from the UI.
  ##  If it fails it will return `nil`.

proc free*(`ptr`: pointer) {.cdecl, importc: "webui_free".}
  ##  Safely free a buffer allocated by WebUI, for example when using 
  ##  `encode()`.

proc malloc*(size: csize_t): pointer {.cdecl, importc: "webui_malloc".}
  ##  Safely allocate memory using the WebUI memory management system.
  ##  It can be safely free using `free()`.

proc sendRaw*(window: csize_t; function: cstring; raw: pointer; size: csize_t) {.cdecl, importc: "webui_send_raw".}
  ##  Safely send raw data to the UI.

proc setHide*(window: csize_t; status: bool) {.cdecl, importc: "webui_set_hide".}
  ##  Run the window in hidden mode

proc getChildProcessId*(window: csize_t): csize_t {.importc: "webui_get_child_process_id".}
  ##  Get child process id 

proc getParentProcessId*(window: csize_t): csize_t {.importc: "webui_get_parent_process_id".}
  ##  Get parent process id 

proc setSize*(window: csize_t; width: cuint; height: cuint) {.cdecl, importc: "webui_set_size".}
  ##  Set window size

proc setPosition*(window: csize_t; x: cuint; y: cuint) {.cdecl, importc: "webui_set_position".}
  ##  Set window position

proc setProfile*(window: csize_t, name: cstring, path: cstring) {.cdecl, importc: "webui_set_profile".}
  ##  Set the web browser profile to use. An empty `name` and `path` means
  ##  the default user profile. Needs to be called before `webui_show()`.

proc getUrl*(window: csize_t): cstring {.cdecl, importc: "webui_get_url".}
  ##  Get the full current URL

proc navigate*(window: csize_t; url: cstring) {.cdecl, importc: "webui_navigate".}
  ##  Navigate to a specific URL

proc clean*() {.cdecl, importc: "webui_clean".}
  ##  Free all memory resources. Should be called only at the end.

proc deleteAllProfiles*() {.cdecl, importc: "webui_delete_all_profiles".}
  ##  Delete all local web-browser profiles folder. It should be called at the end.

proc deleteProfile*(window: csize_t) {.cdecl, importc: "webui_delete_profile".}
  ##  Delete a specific window web-browser local folder profile.

#  -- Interface -----------------------
proc interfaceBind*(window: csize_t; element: cstring; `func`: proc (a1: csize_t;
    a2: csize_t; a3: cstring; a4: csize_t, a5: csize_t) {.cdecl.}): csize_t {.cdecl,
    importc: "webui_interface_bind".}
  ##  Bind a specific html element click event with a function. Empty element means all events. This replace webui_bind(). The func is (Window, EventType, Element, EventNumber, BindID)

proc interfaceSetResponse*(window: csize_t, event_number: csize_t, repsonse: cstring) {.cdecl,
    importc: "webui_interface_set_response".}
  ##  When using `webui_interface_bind()` you need this function to easily set your callback response.

proc interfaceIsAppRunning*(): bool {.cdecl,
                                   importc: "webui_interface_is_app_running".}
  ##  Check if the app still running or not. This replace webui_wait().

proc interfaceGetWindowId*(window: csize_t): csize_t {.cdecl,
    importc: "webui_interface_get_window_id".}
  ##  Get window unique ID

proc interfaceGetStringAt*(window: csize_t, event_number: csize_t, index: csize_t): cstring {.cdecl,
    importc: "webui_interface_get_string_at".}
  ## Get an argument as string at a specific index

proc interfaceGetIntAt*(window: csize_t, event_number: csize_t, index: csize_t): clonglong {.cdecl,
    importc: "webui_interface_get_int_at".}
  ## Get an argument as integer at a specific index

proc interfaceGetBoolAt*(window: csize_t, event_number: csize_t, index: csize_t): bool {.cdecl,
    importc: "webui_interface_get_bool_at".}
  ## Get an argument as boolean at a specific index
