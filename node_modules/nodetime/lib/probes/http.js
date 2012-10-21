
module.exports = function(nt, obj) {
  var proxy = nt.tools.proxy;
  var samples = nt.tools.samples;

  // server probe
  proxy.before(obj.Server.prototype, ['on', 'addListener'], function(obj, args) {
    if(args[0] !== 'request') return;

    proxy.callback(args, -1, function(obj, args) {
      var req = args[0];
      var res = args[1];
      var time = samples.time("HTTP Server", req.url, true);

      proxy.after(res, 'end', function(obj, args) {
        if(!time.done()) return;
        if(nt.paused) return;

        samples.add(time, {'Type': 'HTTP', 
            'Method': req.method, 
            'URL': req.url, 
            'Request headers': req.headers, 
            'Status code': res.statusCode}, 
            samples.truncate(req.url));
      });
    });
  });


  // client error probe
  proxy.after(obj, 'request', function(obj, args, ret) {
    var time = undefined;
    var trace = samples.stackTrace();
    var opts = args[0];
    
    // exclude agent.io communication
    if(opts && opts.headers && opts.headers['agentio-version']) return;

    proxy.before(ret, 'end', function(obj, args) {
      time = opts.__time__ = !opts.__time__ ? samples.time("HTTP Client", opts.method || 'GET') : undefined;
    });

    proxy.before(ret, ['on', 'addListener'], function(obj, args) {
      if(args[0] !== 'error') return;

      proxy.callback(args, -1, function(obj, args) {
        if(!time || !time.done(proxy.hasError(args))) return;
        if(nt.paused) return;

        var error = proxy.getErrorMessage(args);
        var obj = {'Type': 'HTTP', 
            'Method': opts.method, 
            'URL': (opts.hostname || opts.host) + (opts.port ? ':' + opts.port : '') + (opts.path || '/'),
            'Request headers': opts.headers, 
            'Stack trace': trace,
            'Error': error};
        samples.add(time, obj, 'HTTP Client: ' + obj.URL);
      });   
    });
  });


  // client probe
  proxy.before(obj, 'request', function(obj, args) {
    var trace = samples.stackTrace();
    var opts = args[0];
 
    // exclude agent.io communication
    if(opts && opts.headers && opts.headers['agentio-version']) return;

    proxy.callback(args, -1, function(obj, args) {
      var res = args[0];
      proxy.before(res, ['on', 'addListener'], function(obj, args) {
        if(args[0] !== 'end') return;
        
        proxy.callback(args, -1, function(obj, args) {
	        var time = opts.__time__;
          if(!time || !time.done()) return;
          if(nt.paused) return;

          var obj = {'Type': 'HTTP', 
              'Method': opts.method, 
              'URL': (opts.hostname || opts.host) + (opts.port ? ':' + opts.port : '') + (opts.path || '/'),
              'Request headers': opts.headers, 
              'Response headers': res.headers, 
              'Status code': res.statusCode,
              'Stack trace': trace};
          samples.add(time, obj, 'HTTP Client: ' + obj.URL);
        });
      });
    });
  });
};


