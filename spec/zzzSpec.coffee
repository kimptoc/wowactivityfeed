require "./commonSpec"

describe "Is this run last?", ->
  it "finalise...", (done)->
    wf.info "========================================================="
    wf.info "==============       TESTS END          ================="
    wf.info "========================================================="
    done()