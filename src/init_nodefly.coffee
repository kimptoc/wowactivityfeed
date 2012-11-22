# wf.info "Init nodefly, maybe..."
if process.env.NODEFLY_KEY? 
  # wf.info "Yes, nodefly is a go!"
  require('nodefly').profile(
    process.env.NODEFLY_KEY,
    'WoW Activity Feed'
  )

