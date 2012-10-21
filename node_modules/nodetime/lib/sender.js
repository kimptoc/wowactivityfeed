
var nt;

var infoBuffer;
var metricsBuffer = [];
var samplesBuffer = [];

exports.init = function(_nt) {
  nt = _nt;

  nt.on('info', function(info) {
    if(!nt.headless)
      infoBuffer = info;
  });

  nt.on('metric', function(metric) {
    if(!nt.headless)
      metricsBuffer.push(metric);
  });

  nt.on('sample', function(sample) {
    if(!nt.headless && nt.sessionId)
      samplesBuffer.push(sample);
  });

  setInterval(function() {
    try {
      sendInfo();
      sendMetrics();
      sendSamples();
    }
    catch(e) {
      nt.error(e);
    }
  }, 2000);


  // empty buffer if no sessionId for more than 30 sec
  setInterval(function() {
    try {
      if(!nt.sessionId) 
        metricsBuffer = [];
    }
    catch(e) {
      nt.error(e);
    }
  }, 30000);
};


var sendInfo = function() {
  if(!nt.sessionId || !infoBuffer) return;

  nt.agent.send({cmd: 'updateData', args: infoBuffer});
  infoBuffer = undefined;
};


var sendMetrics = function() {
  if(!nt.sessionId || metricsBuffer.length == 0) return;

  metricsBuffer.forEach(function(metric) {
    nt.agent.send({cmd: 'updateData', args: metric});
  });

  metricsBuffer = [];
};


var sendSamples = function() {
  if(!nt.sessionId || samplesBuffer.length == 0) return;


  // send slowest macro samples
  var macroOps = samplesBuffer.filter(function(sample) {
    return sample.isMacro;
  });

  var macroOps = macroOps.sort(function(a, b) {
    return b._ms - a._ms;
  });

  for(var i = 0; i < (macroOps.length < 10 ? macroOps.length : 10); i++) {
    nt.agent.send({cmd: 'updateData', args: macroOps[i]});
  }


  // send slowest non-macro samples
  var simpleOps = samplesBuffer.filter(function(sample) {
    return !sample.isMacro;
  });

  var simpleOps = simpleOps.sort(function(a, b) {
    return b._ms - a._ms;
  });

  for(var i = 0; i < (simpleOps.length < 10 ? simpleOps.length : 10); i++) {
    nt.agent.send({cmd: 'updateData', args: simpleOps[i]});
  }


  samplesBuffer = [];
};


