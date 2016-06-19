import log4js from 'log4js';

let logger = {};

logger.getLogger = (name) => {  
  return log4js.getLogger(name);  
}

logger.silentLogger = () => {
  return {
    trace() {},
    debug() {},
    info() {},
    warn() {},
    error() {},
    fatal() {}
  };
}

module.exports = logger;