
module.exports = function(nt, obj) {
  var proxy = nt.tools.proxy;
  var samples = nt.tools.samples;

  proxy.after(obj, 'createClient', function(obj, args, ret) {
    var client = ret;

    proxy.before(client, 'query', function(obj, args) {
      var trace = samples.stackTrace();
      var command = args.length > 0 ? args[0] : undefined;
      var params = args.length > 1 && Array.isArray(args[1]) ? args[1] : undefined;
      var time = samples.time("MySQL", "query");

      proxy.callback(args, -1, function(obj, args) {
        if(!time.done(proxy.hasError(args))) return;
        if(nt.paused) return;

        var error = proxy.getErrorMessage(args);
        var obj = {'Type': 'MySQL',
            'Connection': {host: client.host, port: client.port, user: client.user, database: client.database !== '' ? client.database : undefined}, 
            'Command': samples.truncate(command), 
            'Arguments': samples.truncate(params),
            'Stack trace': trace,
            'Error': error};

        samples.add(time, obj, 'MySQL: ' + obj['Command']);
      });
    });
  });
};

