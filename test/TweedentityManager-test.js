const assertRevert = require('./helpers/assertRevert')
const logEvent = require('./helpers/logEvent')

const sleep = require('sleep')

const TweedentityStore = artifacts.require('./TweedentityStore.sol')
const TweedentityManager = artifacts.require('./mocks/TweedentityManagerMock.sol')
const TweedentityManagerV2 = artifacts.require('./mocks/TweedentityManagerV2Mock.sol')

const fixtures = require('./fixtures')
const tweet = fixtures.tweets[0]
const wrongtweet = fixtures.tweets[1]
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

  it('should return a string passing an address', async () => {
    let result = await manager.addressToString(accounts[0])
    assert.equal(result, accounts[0].substring(2))
  })

  it('should revert if the screenName is empty', async () => {
    await assertRevert(manager.verifyAccountOwnership('', tweet.id, 10e9))
  })

  it('should revert if the tweet id is empty', async () => {
    await assertRevert(manager.verifyAccountOwnership(tweet.screenName, '', 21e9))
  })

  it('should call Oraclize, recover the signature from the tweet and verify that it is correct', async () => {

    const gasPrice = 1e9

    await manager.verifyAccountOwnership(
    tweet.screenName,
    tweet.id,
    gasPrice, // << 1 Gwei
    {
      from: accounts[1],
      value: gasPrice * 160000,
      gas: 300000
    })

    let ownershipConfirmation
    for (let i = 0; i < 15; i++) {
      console.log('Waiting Oraclize result')
      sleep.sleep(1)
      ownershipConfirmation = await logEvent(manager, {
        event: 'ownershipConfirmation',
        logIndex: 1,
        args: {screenName: tweet.screenName}
      })
      if (ownershipConfirmation[0]) {
        break
      }
    }

    assert.isTrue(ownershipConfirmation[0].args.success)
    assert.equal(await store.tweedentities(accounts[1]), tweet.screenName)

  })


  it('should call Oraclize, not recover the signature from the tweet because it is incorrect', async () => {

    const gasPrice = 1e9

    await manager.verifyAccountOwnership(
    wrongtweet.screenName,
    wrongtweet.id,
    gasPrice,
    {
      from: accounts[1],
      value: gasPrice * 160000,
      gas: 300000
    })

    let ownershipConfirmation
    for (let i = 0; i < 15; i++) {
      // logValue(await manager.remainingGas())
      console.log('Waiting Oraclize result')
      sleep.sleep(1)
      ownershipConfirmation = await logEvent(manager, {
        event: 'ownershipConfirmation',
        logIndex: 0,
        args: {screenName: wrongtweet.screenName}
      })
      if (ownershipConfirmation[0]) {
        break
      }
    }

    assert.isFalse(ownershipConfirmation[0].args.success)

  })


})
