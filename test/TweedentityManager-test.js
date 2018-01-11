const assertRevert = require('./helpers/assertRevert')
const logEvent = require('./helpers/logEvent')

const sleep = require('sleep')

const TweedentityStore = artifacts.require('./TweedentityStore.sol')
const TweedentityManager = artifacts.require('./mocks/TweedentityManagerMock.sol')
const TweedentityManagerV2 = artifacts.require('./mocks/TweedentityManagerV2Mock.sol')

const fixtures = require('./fixtures')
const tweet = fixtures.tweets[0]
const signature = tweet.signature


function logValue(...x) {
  for (let i = 0; i < x.length; i++) {
    console.log(x[i].valueOf())
  }
}


contract('TweedentityManager', accounts => {

  // return

  let manager
  let managerV2
  let store
  let oraclizeIds = []

  const hashMessage = require('./helpers/hashMessage')(web3)


  before(async () => {
    manager = await TweedentityManager.new()
    manager2 = await TweedentityManagerV2.new()
    store = TweedentityStore.at(await manager.store())
  })

  it('should call Oraclize, recover the signature from the tweet and verify that it is correct', async () => {

    await manager.verifyAccountOwnership(tweet.screenName, tweet.id, {
      from: accounts[1],
      value: web3.toWei(1, 'ether'), // 10000 * 2000000 * 21000,
      gas: 1000000
    })

    let newOraclizeQuery = await logEvent(manager, {event: 'newOraclizeQuery', logIndex: 1, args: {}})
    let oraclizeID = newOraclizeQuery[0].args.oraclizeID

    console.log('Cost for 200000:')
    logValue(await manager.cost())
    console.log('Cost for 2000000:')
    logValue(await manager.cost2())

    let ownershipConfirmation
    for (let i = 0; i < 30; i++) {
      console.log('Waiting Oraclize result')
      sleep.sleep(1)
      ownershipConfirmation = await logEvent(manager, {event: 'ownershipConfirmation', logIndex: 1, args: {oraclizeID}})
      if (ownershipConfirmation[0]) {
        break
      }
    }

    assert.isTrue(ownershipConfirmation[0].args.success)
    assert.equal(await store.tweedentities(accounts[1]), tweet.screenName)

    logValue(await manager.remainingGas())

  })

  it('should revert if the screenName is empty', async () => {
    await assertRevert(manager.verifyAccountOwnership('', tweet.id))
  })

  it('should revert if the tweet id is empty', async () => {
    await assertRevert(manager.verifyAccountOwnership(tweet.screenName, ''))
  })

})
