// const _ = require('lodash')

module.exports = (contract, filter) => {
  return new Promise((resolve, reject) => {
    const event = contract[filter.event](filter.args, {fromBlock: filter.fromBlock || 0, toBlock: filter.toBlock || 'latest'})
    event.watch((error, result) => {
      if (result) {
        resolve(result)
      } else {
        reject('Failed to find events for ' + event)
      }
      event.stopWatching()
    })
  })
}