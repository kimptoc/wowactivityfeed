global.wf ?= {}

GoogleAnalytics = require 'ga'

ua = "UA-36352086-1"

wf.ga = new GoogleAnalytics(ua, wf.SITE_URL)

# ga.trackPage('testing/1');
# ga.trackEvent({
#     category: 'Videos',
#     action: 'Video Loading',
#     label: 'Gone With the Wind',
#     value: 42
# });