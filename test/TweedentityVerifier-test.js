const assertRevert = require('./helpers/assertRevert')
const logEvent = require('./helpers/logEvent')

const TweedentityStore = artifacts.require('./TweedentityStore.sol')
const TweedentityManager = artifacts.require('./TweedentityManager.sol')
const TweedentityVerifier = artifacts.require('./TweedentityVerifier.sol')

const Wait = require('./helpers/wait')
const Counter = artifacts.require('./helpers/Counter')

const fixtures = require('./fixtures')
const tweet = fixtures.tweets[0]


function logValue(...x) {
  for (let i = 0; i < x.length; i++) {
    console.log(x[i].valueOf())
  }
}


contract('TweedentityVerifier', accounts => {

  let manager
  let store
  let verifier

  let wait

  before(async () => {
    store = await TweedentityStore.new()
    manager = await TweedentityManager.new()
    verifier = await TweedentityVerifier.new()

    store.setManager(manager.address)
    manager.setStore(store.address)

    wait = (new Wait(await Counter.new())).wait
  })

  it('should authorize the manager to handle the store', async () => {
    const verifierLevel = (await manager.verifierLevel()).valueOf()
    await manager.authorize(verifier.address, verifierLevel)
    assert.equal(await manager.authorized(verifier.address), verifierLevel)
  })

  it('should revert trying to verify an account before setting the store', async () => {

    const gasPrice = 1e9
    const gasLimit = 16e4

    await assertRevert(
        verifier.verifyTwitterAccountOwnership(
            tweet.id,
            gasPrice,
            16e4,
            {
              from: accounts[1],
              value: gasPrice * gasLimit,
              gas: 300000 // 171897 on Ropsten
            }))

  })

  it('should set the manager in the verifier', async () => {
    await verifier.setManager(manager.address)
    assert.equal(await verifier.managerAddress(), manager.address)
  })

  it('should revert if the tweet id is empty', async () => {
    await assertRevert(verifier.verifyTwitterAccountOwnership('', 21e9, 16e4))
  })

  it('should call Oraclize, recover the signature from the tweet and verify that it is correct', async () => {

    const gasPrice = 4e9
    const gasLimit = 17e4

    await verifier.verifyTwitterAccountOwnership(
        tweet.id,
        gasPrice,
        gasLimit,
        {
          from: accounts[1],
          value: gasPrice * gasLimit,
          gas: 232e3
        })

    // const result = await logEvent(verifier, {
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
    for (let i = 0; i < 12; i++) {
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
