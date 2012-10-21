
var internalCommands = [
  '_executeQueryCommand', 
  '_executeInsertCommand', 
  '_executeUpdateCommand', 
  '_executeRemoveCommand'
];

var commandMap = {
  '_executeQueryCommand': 'find', 
  '_executeInsertCommand': 'insert', 
  '_executeUpdateCommand': 'update', 
  '_executeRemoveCommand': 'remove'
};

module.exports = function(nt, obj) {
  var proxy = nt.tools.proxy;                                                                                                                                                                           
  var samples = nt.tools.samples;

  internalCommands.forEach(function(internalCommand) {
    proxy.before(obj.Db.prototype, internalCommand, function(obj, args) {
      var trace = samples.stackTrace();
      var command = (args && args.length > 0) ? args[0] : undefined;
      var time = samples.time("MongoDB", commandMap[internalCommand]);

      proxy.callback(args, -1, function(obj, args) {
        if(!time.done()) return;
        if(nt.paused) return;

        var conn = {};
        if(command.db) {
          var servers = command.db.serverConfig;
          if(servers) {
            if(Array.isArray(servers)) {
              conn.servers = [];
              servers.forEach(function(server) {
                conn.servers.push({host: server.host, port: server.port});
              }); 
            }
            else {
              conn.host = servers.host;
              conn.port = servers.port;
            }
          }
          
          conn.database = command.db.databaseName;
        }

        var commandName = commandMap[internalCommand];
        var query = command.query ? samples.truncate(JSON.stringify(command.query)) : '{}';
        var error = proxy.getErrorMessage(args);
        var obj = {'Type': 'MongoDB', 
          'Connection': conn,
          'Command': {collectionName: command.collectionName, 
              commandName: commandName, 
              query: query, 
              queryOptions: command.queryOptions, 
              numberToSkip: command.numberToSkip,
              numberToReturn: command.numberToReturn},
          'Stack trace': trace,
          'Error': error};

        samples.add(time, obj, 'MongoDB: ' + commandName);
      });
    });
  });
};

