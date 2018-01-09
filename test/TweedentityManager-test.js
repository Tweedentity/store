const assertRevert = require('./helpers/assertRevert')

const sleep = require('sleep')

const TweedentityStore = artifacts.require('./TweedentityStore.sol')
const TweedentityManager = artifacts.require('./TweedentityManager.sol')
// const TweedentityManagerV2 = artifacts.require('./mocks/TweedentityManagerV2Mock.sol')

const fixtures = require('./fixtures')
const tweet = fixtures.tweets[0]
const signature = tweet.signature


function logValue(...x) {
  for (let i = 0; i < x.length; i++) {
    console.log(x[i].valueOf())
  }
}


contract('TweedentityManager', accounts => {

  return

  let manager
  let managerV2
  let store
  let oraclizeIds = []


  before(async () => {
    manager = await TweedentityManager.new()
    store = TweedentityStore.at(await manager.store())
  })

  it('should call Oraclize, recover the signature from the tweet and verify that it is correct', async () => {

    await manager.verifyAccountOwnership(tweet.screenName, tweet.id, {from: accounts[1], gas: 2000000})

    // set a limit to 30 seconds to avoid an infinite loop in case of errors
    for (let i = 0; i < 30; i++) {
      sleep.sleep(1)
      console.log('Waiting for result')
      logValue(await manager.uu())
      let result = (await manager.result()).valueOf()
      if (result != '') {
        assert.equal(result, signature.sig)
        break
      }
    }
    logValue(await manager.uu())
    logValue(await manager.uu2())
    logValue(await manager.uu3())

    // assert.equal(await store.tweedentities()[accounts[1]], tweet.screenName)

  })


})
