
var commands = [
  'rename',
  'truncate',
  'chown',
  'fchown',
  'lchown',
  'chmod',
  'fchmod',
  'lchmod',
  'stat',
  'lstat',
  'fstat',
  'link',
  'symlink',
  'readlink',
  'realpath',
  'unlink',
  'rmdir',
  'mkdir',
  'readdir',
  'close',
  'open',
  'utimes',
  'futimes',
  'fsync',
  'write',
  'read',
  'readFile',
  'writeFile',
  'appendFile',
  'exists'
];


module.exports = function(nt, obj) {
  var proxy = nt.tools.proxy;
  var samples = nt.tools.samples;

  commands.forEach(function(command) {
    proxy.before(obj, command, function(obj, args) {
      var trace = samples.stackTrace();
      var params = args;
      var time = samples.time("File System", command);

      proxy.callback(args, -1, function(obj, args) {
        if(!time.done(proxy.hasError(args))) return;
        if(nt.paused) return;

        var error = proxy.getErrorMessage(args);
        var context = {'Type': 'File System',
            'Command': command, 
            'Arguments': samples.truncate(params),
            'Stack trace': trace,
            'Error': error};

        samples.add(time, context, 'File System: ' + context['Command']);
      });
    });

 
    var commandSync = command + 'Sync';
    proxy.around(obj, commandSync, function(obj, args, locals) {
      locals.stackTrace = samples.stackTrace();
      locals.params = args;
      locals.time = samples.time("File System", commandSync);

    }, function(obj, args, ret, locals) {
      if(!locals.time.done()) return;
      if(nt.paused) return;

      var context = {'Type': 'File System',
          'Command': commandSync, 
          'Arguments': samples.truncate(locals.params),
          'Stack trace': locals.stackTrace};

      samples.add(locals.time, context, 'File System: ' + context['Command']);
    });
  });
};

