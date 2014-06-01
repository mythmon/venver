path = require "path"
childProcess = require "child_process"

fs = require "fs-promise"
shellQuote = require "shell-quote"
{Promise} = require "es6-promise"


class Venver
  constructor: () ->
    @extraPrelude = []
    @paths = []
    @envVars = {}
    @functions = {}
    @extraActivate = []
    @extraDeactivate = []

  mkdir: (path) ->
    return fs.mkdir(path)
    .catch (err) ->
      if err.code == "EEXIST"
        return
      throw err

  run: (command) ->
    return new Promise (resolve, reject) ->
      cli = shellQuote.parse(command, process.env)
      sub = childProcess.spawn cli[0], cli.slice(1)

      stdout = ''
      stderr = ''

      sub.stdout.on 'data', (data) -> stdout += data
      sub.stderr.on 'data', (data) -> stdout += data

      sub.on 'close', (code) ->
        if code == 0
          resolve([stdout, stderr, code])
        else
          reject([stdout, stderr, code])

  addToPath: (path) ->
    @paths.push path

  addFunction: (name, body) ->
    if name in @functions
      throw "Duplicate function defined: #{name}"
    @functions[name] = body.trim()

  addExtraPrelude: (text) ->
    @extraPrelude.push text.trim()

  addEnvVar: (key, val) ->
    if key in @envVars
      throw "Duplicate envvar set: #{key}"
    @envVars[key] = val

  addExtraActivate: (text) ->
    @extraActivate.push text.trim()

  addExtraDeactivate: (text) ->
    @extraDeactivate.push text.trim()

  generate: () ->
    output = new Output()

    # Prelude
    output.append """
      #!/bin/bash
      DIR=$(dirname $0)
      """

    @extraPrelude.forEach (pre) -> output.append pre

    # activate
    output.append "v_activate() {"
    output.indent()

    if @paths.length
      pathString = @paths.join ":"
      @envVars["PATH"] = "#{pathString}:$PATH"

    for key, val of @envVars
      output.append """
        _OLD_#{key}="$#{key}"
        export #{key}="#{val}"
        """

    for name, body of @functions
      output.append "#{name}() {"
      output.indent()
      output.append body
      output.dedent()
      output.append "}"

    output.append @extraActivate.join "\n"

    output.dedent()
    output.append "}"

    # Deactivate
    output.append "v_deactivate() {"
    output.indent()

    if @paths.length
      output.append """
        PATH=$_OLD_PATH
        unset _OLD_PATH
        """

    for name of @envVars
      output.append """
        #{name}=$_OLD_#{name}
        unset _OLD_#{name}
        """

    for name of @functions
      output.append "unfunction #{name}"

    output.append @extraDeactivate.join "\n"

    output.dedent()
    output.append "}"

    # Done
    output.toString()


class Output
  constructor: () ->
    @contents = ""
    @_indent = ""
  append: (text) ->
    text = text.trim()
    if text == ""
      return
    text.trim().split "\n"
    .forEach (line) => @contents += @_indent + line + "\n"
  indent: () ->
    @_indent += "  "
  dedent: () ->
    if @_indent == ""
      throw "Too much dedent!"
    @_indent = @_indent.slice 2
  toString: () ->
    if @_indent != ""
      throw "Didn't finish dedenting!"
    @contents


module.exports = {Venver}
