const assertRevert = require('./helpers/assertRevert')
const eventWatcher = require('./helpers/EventWatcher')

const TweedentityStore = artifacts.require('./TweedentityStore.sol')
const TweedentityManager = artifacts.require('./TweedentityManager.sol')
const TweedentityClaimer = artifacts.require('./TweedentityClaimer.sol')

const Wait = require('./helpers/wait')
const Counter = artifacts.require('./helpers/Counter')

const fixtures = require('./fixtures')
const tweet = fixtures.tweets[0]

const log = require('./helpers/log')

function logValue(...x) {
  for (let i = 0; i < x.length; i++) {
    console.log(x[i].valueOf())
  }
}


contract('TweedentityClaimer', accounts => {

  let manager
  let store
  let claimer

  let wait

  let appNickname = 'twitter'
  let appId = 1

  before(async () => {
    store = await TweedentityStore.new()
    manager = await TweedentityManager.new()
    claimer = await TweedentityClaimer.new()

    await store.setManager(manager.address)
    await store.setApp(appNickname, appId)
    await manager.setAStore(appNickname, store.address)

    wait = (new Wait(await Counter.new())).wait
  })

  it('should authorize the manager to handle the store', async () => {
    await manager.setClaimer(claimer.address)
  })

  it('should revert trying to verify an account before setting the store', async () => {

    const gasPrice = 1e9
    const gasLimit = 30e4

    await assertRevert(
      claimer.claimOwnership(
        appNickname,
        tweet.id,
        gasPrice,
        16e4,
        {
          from: accounts[1],
          value: gasPrice * gasLimit,
          gas: 40e4
        }))

  })

  it('should set the manager in the claimer', async () => {
    await claimer.setManager(manager.address)
    assert.equal(await claimer.managerAddress(), manager.address)
  })

  it('should revert if the tweet id is empty', async () => {

    const gasPrice = 4e9
    const gasLimit = 20e4

    await assertRevert(claimer.claimOwnership(
      appNickname,
      '',
      21e9,
      16e4,
      {
        from: accounts[1],
        value: gasPrice * gasLimit,
        gas: 300e3
      }))
  })

  it('should call Oraclize, recover the signature from the tweet and verify that it is correct', async () => {

    const gasPrice = 4e9
    const gasLimit = 17e4

    await claimer.claimOwnership(
      appNickname,
      tweet.id,
      gasPrice,
      gasLimit,
      {
        from: accounts[1],
        value: gasPrice * gasLimit,
        gas: 270e3
      })

    // const result = await eventWatcher.watch(claimer, {
    //   event: 'OwnershipConfirmed',
    //   args: {
    //     addr: accounts[1]
    //   },
    //   fromBlock: web3.eth.blockNumer,
    //   toBlock: 'latest'
    // })
    //
    // assert.equal(result.args.uid, tweet.userId)

    let ok = false

    console.log('Waiting for result')
    for (let i = 0; i < 16; i++) {
      wait()
      let uid = await store.getUid(accounts[1])
      if (uid == tweet.userId) {
        ok = true
        break
      }
    }

    assert.isTrue(ok)

  })


  it('should call Oraclize, recover the signature from the tweet but be unable to update', async () => {

    const gasPrice = 4e9
    const gasLimit = 17e4

    await claimer.claimOwnership(
      appNickname,
      tweet.id,
      gasPrice,
      gasLimit,
      {
        from: accounts[1],
        value: gasPrice * gasLimit,
        gas: 270e3
      })

    // const result = await eventWatcher.watch(claimer, {
    //   event: 'OwnershipConfirmed',
    //   args: {
    //     addr: accounts[1]
    //   },
    //   fromBlock: web3.eth.blockNumer,
    //   toBlock: 'latest'
    // })
    //
    // assert.equal(result.args.uid, tweet.userId)

    let ok = false

    console.log('Waiting for result')
    for (let i = 0; i < 16; i++) {
      wait()
      let uid = await store.getUid(accounts[1])
      if (uid == tweet.userId) {
        ok = true
        break
      }
    }

    assert.isTrue(ok)

  })


})
