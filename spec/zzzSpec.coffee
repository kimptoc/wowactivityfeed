require "./commonSpec"

describe "Is this run last?", ->
  it "finalise...", ->
    wf.mongo_db?.close()
    wf.info "Should be last test, Goodbye"