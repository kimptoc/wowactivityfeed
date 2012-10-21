
module.exports = function(nt, obj) {
  var proxy = nt.tools.proxy;
  var samples = nt.tools.samples;
  var info = nt.tools.info;

  return; // needs rethinking

  proxy.after(obj, ['connect', 'createConnection'], function(obj, args, ret) {
    proxy.before(ret, 'write', function(obj, args) {
      if(nt.paused) return;

      if(args.length < 1) return;
  
      info.metric('Sockets', 'Data sent per minute', size(args[0]), 'KB', 'sum');
    });
  
    proxy.before(ret, 'on', function(obj, args) {
      if(args.length < 2 || args[0] !== 'data') return;
  
      proxy.callback(args, -1, function(obj, args) {  
        if(nt.paused) return;

        info.metric('Sockets', 'Data received per minute', size(args[0]), 'KB', 'sum');
      });
    });
  });
};

var size = function(data) {
  var bytes = 0;
  
  if(Buffer.isBuffer(data)) {
    bytes = data.length;
  }
  else if(typeof data === 'string') {
    bytes = data.length; // yes I know, this is wrong!!!
  }

  return (bytes / 1000);
};
