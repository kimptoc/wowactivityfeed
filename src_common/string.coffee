if (typeof window == "undefined")
  ns = global
else
  ns = window
ns.wf ?= {}

class wf.String
  @capitalise: (str) ->
    # /* First letter as uppercase, rest lower */ 
    str = str.substring(0,1).toUpperCase() + str.substring(1,str.length).toLowerCase()
