module.exports =
  run: (venver) ->
    [
      venver.addExtraPrelude "source $DIR/bin/activate"
      venver.addFunction "r", "echo nope"
      venver.addFunction "s", "python"
      venver.addFunction "t", "echo nope"
      venver.run "virtualenv2 --distribute ."
      venver.addExtraDeactivate "deactivate"
    ]
