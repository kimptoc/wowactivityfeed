
var os = require('os');


var nt;
var metrics = {};


exports.init = function(_nt) {
  nt = _nt;

  setInterval(function() {
    try {
      aggregate();
    }
    catch(e) {
      nt.error(e);
    }
  }, 60000);

  //send any initial values
  setTimeout(function() {
    try {
      initial();
    }
    catch(e) {
      nt.error(e);
    }
  }, 1000);
};


exports.add = function(scope, name, value, unit, op) {  
  if(!scope || !name || typeof(value) !== 'number') 
    throw new Error('parameter(s) missing');

  process.nextTick(function() {
    var key = scope + ':' + name;

    // create
    if(!metrics[key]) {
      metrics[key] = {
        scope: scope,
        name: name,
        value: 0,
        _count: 0,
        unit: unit,
        op: op,
        history: nt.history
      };

      if(op === 'hist')
        metrics[key].value = {};
    }


    // update
    var obj = metrics[key];

    if(!op || op === 'avg' || op === 'sum') {
      obj.value += value;
      obj._count++;
    }
    else if(op === 'gauge') {
      obj.value = value;
    }
    else if(op === 'hist') {
      var bin = Math.pow(10, Math.floor(Math.log(value) / Math.LN10) + 1); 
      if(obj.value[bin]) {
        obj.value[bin]++;
      }
      else {
        obj.value[bin] = 1;
      }
    }

    if(!nt.history) {
      obj.history = false;
    }
  });
};


var emit = function(obj) {
  try {
    delete obj._count;
    obj.source = os.hostname() + '[' + process.pid + ']';
    obj._id = nt.nextId++; 
    obj._ns = 'metrics';
    obj._ts = nt.millis();
 
    nt.emit('metric', obj);
  }
  catch(err) {
    nt.error(err);
  }
};

var initial = function() {
  for (var key in metrics) {
    var obj = metrics[key];

    if(!obj.op || obj.op === 'avg') {
      obj.value = obj.value / obj._count;
      emit(obj);

      delete metrics[key];
    }
  }  
};


var aggregate = function() {
  for (var key in metrics) {
    var obj = metrics[key];

    if(!obj.op || obj.op === 'avg') {
      obj.value = obj.value / obj._count;
    }

    emit(obj);
  }

  metrics = {};
};

