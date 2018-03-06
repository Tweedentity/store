const assertRevert = require('./helpers/assertRevert')
const logEvent = require('./helpers/logEvent')

const sleep = require('sleep')

const Store = artifacts.require('./Store.sol')
const Manager = artifacts.require('./Manager.sol')

const fixtures = require('./fixtures')
const tweet = fixtures.tweets[0]


function logValue(...x) {
  for (let i = 0; i < x.length; i++) {
    console.log(x[i].valueOf())
  }
}


contract('Manager', accounts => {

  // return

  let manager
  let store
  let oraclizeIds = []

  const hashMessage = require('./helpers/hashMessage')(web3)


  before(async () => {
    store = await Store.new() //at(await manager.store())
    manager = await Manager.new()
  })

  it('should authorize the manager to handle the store', async () => {
    await store.authorize(manager.address, 1)
    assert.isTrue(await store.authorized(manager.address) == 1)
  })

  it('should revert trying to verify an account before setting the store', async () => {

    const gasPrice = 1e9

    await assertRevert(
    manager.verifyTwitterAccountOwnership(
    tweet.screenName,
    tweet.id,
    gasPrice,
    {
      from: accounts[1],
      value: gasPrice * 200000,
      gas: 300000
    }))

  })

  it('should set the store in the manager', async () => {
    await manager.setStore(store.address)
    assert.isTrue(await manager.storeSet())
  })

  it('should revert if the screenName is empty', async () => {
    await assertRevert(manager.verifyTwitterAccountOwnership('', tweet.id, 10e9))
  })

  it('should revert if the tweet id is empty', async () => {
    await assertRevert(manager.verifyTwitterAccountOwnership(tweet.screenName, '', 21e9))
  })

  it('should call Oraclize, recover the signature from the tweet and verify that it is correct', async () => {

    const gasPrice = 1e9

    await manager.verifyTwitterAccountOwnership(
    tweet.screenName,
    tweet.id,
    gasPrice, // << 1 Gwei
    {
      from: accounts[1],
      value: gasPrice * 160000,
      gas: 300000 // 200963 on testnet
    })

    let ok = false

    for (let i = 0; i < 30; i++) {
      console.log('Waiting for result')
      sleep.sleep(1)
      let uid = await store.getUid(accounts[1])
      if (uid == tweet.userId) {
        ok = true
        break
      }
    }

    assert.isTrue(ok)

  })



})
