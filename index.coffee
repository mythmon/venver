fs = require "fs-promise"
path = require "path"

{Promise} = require "es6-promise"

{Venver} = require "./venver"

venver = new Venver()

main = () ->

  fs.exists ".venv"
  .then checkExists
  .then loadTemplate
  .then makeVenvFile
  .catch uhoh


checkExists = (exists) ->
  if exists
    console.error "There is already a .venv file here, bailing."
    process.exit 1

loadTemplate = () ->
  hookName = process.argv[2]
  if hookName == undefined
    console.error "Usage: #{process.argv[1]} ENVTYPE"
    process.exit 2
  try
    hook = require "./templates/#{hookName}"
  catch e
    console.error "Error: Couldn't find environment type #{hookName}"
    process.exit 3
  Promise.all [Promise.resolve p for p in hook.run(venver)]

makeVenvFile = () ->
  fs.writeFile ".venv", venver.generate()

uhoh = (err) ->
  console.log "Error: #{err.stack || err}"

main()
