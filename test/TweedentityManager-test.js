const assertRevert = require('./helpers/assertRevert')
const log = require('./helpers/log')
const eventWatcher = require('./helpers/EventWatcher')

const TweedentityStore = artifacts.require('./TweedentityStore.sol')
const TweedentityManager = artifacts.require('./TweedentityManager.sol')

const Wait = require('./helpers/wait')
const Counter = artifacts.require('./helpers/Counter')

const TweedentityManagerCaller = artifacts.require('./helpers/TweedentityManagerCaller')

function now() {
  console.log(parseInt('' + Date.now() / 1000, 10), 'now')
}

contract('TweedentityManager', accounts => {

  let store
  let manager
  let managerCaller

  let owner = accounts[0]
  let verifier = accounts[1]
  let customerService = accounts[2]
  let bob = accounts[3]
  let alice = accounts[4]
  let rita = accounts[5]
  let developer = accounts[6]

  let id1 = '1'
  let id2 = '2'
  let id3 = '3'

  let verifierLevel
  let customerServiceLevel
  let devLevel

  let upgradable
  let notUpgradableInStore
  let uidNotUpgradable
  let addressNotUpgradable
  let uidAndAddressNotUpgradable

  let wait

  async function getValue(what) {
    return (await manager[what]()).valueOf()
  }

  before(async () => {
    store = await TweedentityStore.new()
    manager = await TweedentityManager.new()
    managerCaller = await TweedentityManagerCaller.new()

    await store.setManager(manager.address)
    await store.setApp('Twitter', 'twitter.com', 'twitter')

    await managerCaller.setManager(manager.address)

    await manager.authorize(verifier, await getValue('verifierLevel'))
    await manager.authorize(customerService, await getValue('customerServiceLevel'))
    await manager.authorize(developer, await getValue('devLevel'))

    upgradable = await getValue('upgradable')
    notUpgradableInStore = await getValue('notUpgradableInStore')
    uidNotUpgradable = await getValue('uidNotUpgradable')
    addressNotUpgradable = await getValue('addressNotUpgradable')
    uidAndAddressNotUpgradable = await getValue('uidAndAddressNotUpgradable')

    wait = (new Wait(await Counter.new())).wait
  })

  it('should see that the store has not been set', async () => {
    assert.isFalse(await manager.getStoreSet('twitter'))
  })

  it('should set the store', async () => {
    await manager.setAStore('twitter', store.address)
    assert.isTrue(await manager.getStoreSet('twitter'))
    assert.equal(await store.manager(), manager.address)
  })

  it('should revert trying to add a new tweedentity', async () => {
    await assertRevert(manager.setIdentity('twitter', rita, id1))
  })

  it('should add a new identity with uid id1 for rita', async () => {
    assert.isFalse(await store.isUidSet(id1))

    await manager.setIdentity('twitter', rita, id1, {
      from: verifier
    })
    assert.equal(await store.getAddress(id1), rita)
    assert.isTrue(await store.isUidSet(id1))
    assert.isTrue(await store.isAddressSet(rita))
  })

  it('should show that minimumTimeBeforeUpdate is 1 days', async () => {
    assert.equal(await manager.minimumTimeBeforeUpdate(), 86400)
  })

  it('should refuse trying to update rita with the uid id2', async () => {

    manager.setIdentity('twitter', rita, id2, {
      from: verifier
    })

    const result = await eventWatcher.watch(manager, {
      event: 'IdentityNotUpgradable',
      args: {
        addr: rita
      },
      fromBlock: web3.eth.blockNumer,
      toBlock: 'latest'
    })

    assert.equal(result.args.uid, id2)
  })

  it('should revert trying to associate accounts[5] to uid id3 using a not authorized owner', async () => {

    await assertRevert(manager.setIdentity('twitter', accounts[5], id3))

  })

  it('should change minimumTimeBeforeUpdate to 1 second', async () => {
    await manager.changeMinimumTimeBeforeUpdate(1, {
      from: developer
    })
    assert.equal(await manager.minimumTimeBeforeUpdate(), 1)
  })

  it('should wait 1 second', async () => {
    await wait()
    assert.isTrue(true)
  })

  it('should refuse trying to associate bob with id1 since this is associated w/ rita', async () => {

    assert.equal(await store.getUid(rita), id1)

    manager.setIdentity('twitter', bob, id1, {
      from: verifier
    })

    const result = await eventWatcher.watch(manager, {
      event: 'IdentityNotUpgradable',
      args: {
        addr: bob
      },
      fromBlock: web3.eth.blockNumer,
      toBlock: 'latest'
    })

    assert.equal(result.args.uid, id1)

  })

  it('should associate again id1 to rita', async () => {
    manager.setIdentity('twitter', rita, id1, {
      from: verifier
    })

    const result = await eventWatcher.watch(store, {
      event: 'IdentitySet',
      args: {
        addr: rita
      },
      fromBlock: web3.eth.blockNumer,
      toBlock: 'latest'
    })

    assert.equal(result.args.uid, id1)
  })

  it('should check upgradabilities', async () => {
    assert.equal(await manager.getUpgradability('twitter', rita, id2), addressNotUpgradable)
    assert.equal(await manager.getUpgradability('twitter', alice, id2), upgradable)
    assert.equal(await manager.getUpgradability('twitter', alice, id1), notUpgradableInStore)
    assert.equal(await manager.getUpgradability('twitter', rita, id1), uidAndAddressNotUpgradable)

    await wait()

    assert.equal(await manager.getUpgradability('twitter', rita, id2), upgradable)
  })

  it('should associate after a second rita with the uid id2', async () => {

    assert.equal(await store.getAddress(id2), 0)

    await manager.setIdentity('twitter', rita, id2, {
      from: verifier
    })
    assert.equal(await store.getUid(rita), id2)

  })

  it('should be able to reverse after 1 second', async () => {
    await wait()
    // assert.isTrue(await manager.isUidUpgradable(store, id1))

    await manager.setIdentity('twitter', rita, id1, {
      from: verifier
    })
    // assert.isFalse(await manager.isUidUpgradable(store,id1))
    assert.equal(await store.getUid(rita), id1)
  })

  it('should associate id2 to alice', async () => {
    await manager.setIdentity('twitter', alice, id2, {
      from: verifier
    })
    assert.equal(await store.getUid(alice), id2)
  })

  it('should return rita if searching for id1 and viceversa', async () => {
    assert.equal(await store.getAddress(id1), rita)
    assert.equal(await store.getUid(rita), id1)
  })

  it('should allow customerService to remove the identity for rita', async () => {

    assert.isTrue(await store.isAddressSet(rita))

    await manager.removeIdentity('twitter', rita, {
      from: customerService
    })
    assert.equal(await store.getUid(rita), '')
    assert.isFalse(await store.isAddressSet(rita))
  })

  it('should allow bob to be associated to id1 after 1 second', async () => {

    await wait()

    await manager.setIdentity('twitter', bob, id1, {
      from: verifier
    })

    assert.equal(await store.getUid(bob), id1)
    assert.equal(await store.getAddress(id1), bob)

  })

  it('should verify that all the function callable from other contracts are actually callable', async () => {

    assert.equal(await managerCaller.getUpgradability('twitter', bob, id1), uidAndAddressNotUpgradable)
    assert.equal(await managerCaller.getUpgradability('twitter', bob, id2), notUpgradableInStore)
  })


  it('should allow bob to remove their own identity', async () => {
    await manager.removeMyIdentity('twitter', {
      from: bob
    })
    assert.equal(await store.getUid(bob), '')
    assert.equal(await store.getAddress(id1), 0)
  })

})
