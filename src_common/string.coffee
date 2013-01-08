if (typeof window == "undefined")
  root = global
else
  root = window
root.wf ?= {}

class wf.String
  @capitalise: (str) ->
    # /* First letter as uppercase, rest lower */ 
    str = str.substring(0,1).toUpperCase() + str.substring(1,str.length).toLowerCase()
