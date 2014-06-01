path = require "path"


module.exports =
  run: (venver) ->
    envName = path.basename(process.cwd())
    [
      venver.addEnvVar "PS1", "(#{envName})$PS1"
      venver.mkdir "node_modules"
      venver.addToPath "node_modules/.bin"
      venver.addFunction "r", "npm start"
      venver.addFunction "s", "node"
      venver.addFunction "t", "npm test"
    ]
