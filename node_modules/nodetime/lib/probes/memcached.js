
var commands = [
  'get',
  'gets',
  'getMulti',
  'set',
  'replace',
  'add',
  'cas',
  'append',
  'prepend',
  'increment',
  'decrement',
  'incr',
  'decr',
  'del',
  'delete',
  'version',
  'flush',
  'samples',
  'slabs',
  'items',
  'flushAll',
  'samplesSettings',
  'samplesSlabs',
  'samplesItems',
  'cachedump'
];


module.exports = function(nt, obj) {
  var proxy = nt.tools.proxy;
  var samples = nt.tools.samples;

  commands.forEach(function(command) {
    proxy.before(obj.prototype, command, function(obj, args) {
      // ignore, getMulti will be called
      if(command === 'get' && Array.isArray(args[0])) return;

      var client = obj;
      var trace = samples.stackTrace();
      var params = args;
      var time = samples.time("Memcached", command);

      proxy.callback(args, -1, function(obj, args) {
        if(!time.done(proxy.hasError(args))) return;
        if(nt.paused) return;

        var error = proxy.getErrorMessage(args);
        var obj = {'Type': 'Memcached',
            'Servers': client.servers, 
            'Command': command, 
            'Arguments': samples.truncate(params),
            'Stack trace': trace,
            'Error': error};

        samples.add(time, obj, 'Memcached: ' + obj['Command']);
      });
    });
  });
};

