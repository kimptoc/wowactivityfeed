
var commands = [
  'get',
  'count',
  'set',
  'remove',
  'truncate',
  'use',
  'addKeySpace',
  'dropKeySpace'
];

module.exports = function(nt, obj) {
  // not tested, skip
  return;

  var proxy = nt.tools.proxy;
  var samples = nt.tools.samples;

  commands.forEach(function(command) {
    proxy.before(obj.ColumnFamily.prototype, command, function(obj, args) {
      var cf = obj;
      var trace = samples.stackTrace();
      var params = args.length > 1 && Array.isArray(args[1]) ? args[1] : undefined;
      var time = samples.time("Cassandra", command);

      proxy.callback(args, -1, function(obj, args) {
        if(!time.done(proxy.hasError(args)))) return;
        if(nt.paused) return;

        var error = proxy.getErrorMessage(args);
        var obj = {'Type': 'Cassandra',
            'Connection': {host: cf.client_.host, port: cf.client_.port, keyspace: cf.client_.keyspace, columnFamily: cf.name}, 
            'Command': command, 
            'Arguments': samples.truncate(params),
            'Stack trace': trace,
            'Error': error};

        samples.add(time, obj, 'Cassandra: ' + obj['Command']);
      });
    });
  });
};

