
module.exports = function(nt, obj) {
  var proxy = nt.tools.proxy;
  var samples = nt.tools.samples;

  function probe(obj) {
    if(obj.__probeInstalled__) return;
    obj.__probeInstalled__ = true;

    // Callback API
    proxy.before(obj, 'query', function(obj, args, ret) {
      var client = obj;
      var trace = samples.stackTrace();
      var command = args.length > 0 ? args[0] : undefined;
      var params = args.length > 1 && Array.isArray(args[1]) ? args[1] : undefined;
      var time = samples.time("PostgreSQL", "query");

      proxy.callback(args, -1, function(obj, args) {
        if(!time.done(proxy.hasError(args))) return;
        if(nt.paused) return;

        var error = proxy.getErrorMessage(args);
        var obj = {'Type': 'PostgreSQL',
            'Connection': {host: client.host, port: client.port, user: client.user, database: client.database ? client.database : undefined}, 
            'Command': samples.truncate(command), 
            'Arguments': samples.truncate(params),
            'Stack trace': trace,
            'Error': error};

        samples.add(time, obj, 'PostgreSQL: ' + obj['Command']);
      });
    });


    // Evented API
    proxy.after(obj, 'query', function(obj, args, ret) {
      // If has a callback, ignore
      if(args.length > 0 && typeof args[args.length - 1] === 'function') return;

      var client = obj;
      var trace = samples.stackTrace();
      var command = args.length > 0 ? args[0] : undefined;
      var params = args.length > 1 && Array.isArray(args[1]) ? args[1] : undefined;
      var time = samples.time("PostgreSQL", "query");

      proxy.before(ret, 'on', function(obj, args) {
        var event = args[0];
        if(event !== 'end' && event !== 'error') return;

        proxy.callback(args, -1, function(obj, args) {
          if(!time.done(proxy.hasError(args))) return;
          if(nt.paused) return;

          var error = proxy.getErrorMessage(args);
          var obj = {'Type': 'PostgreSQL',
              'Connection': {host: client.host, port: client.port, user: client.user, database: client.database ? client.database : undefined}, 
              'Command': samples.truncate(command), 
              'Params': samples.truncate(params),
              'Stack trace': trace,
              'Error': error};

          samples.add(time, obj, 'PostgreSQL: ' + obj['Command']);
        });
      });
    });
  }


  // Native, reinitialize probe 
  proxy.getter(obj, 'native', function(obj, ret) {
    proxy.after(ret, 'Client', function(obj, args, ret) {
      probe(ret.__proto__); 
    });
  });

  probe(obj.Client.prototype);
};

