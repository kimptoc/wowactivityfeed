if process.env.NODEFLY_KEY? 
  require('nodefly').profile(
    process.env.NODEFLY_KEY,
    'WoW Activity Feed'
  )

