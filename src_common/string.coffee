if (typeof window == "undefined")
  ns = global
else
  ns = window
ns.wf ?= {}

class wf.String
  @capitalise: (str) ->
    # /* First letter of each word as uppercase, rest lower */ 
    str = str.trim()
    outstr = ""
    found_space = true
    # str = str.substring(0,1).toUpperCase() + str.substring(1,str.length).toLowerCase()
    for i in [0..str.length]
      # wf.debug str.substring(i,i+1)
      if found_space
        outstr += str.substring(i,i+1).toUpperCase()
      else
        outstr += str.substring(i,i+1).toLowerCase()
      found_space = (str.substring(i,i+1) == " ")
    return outstr
