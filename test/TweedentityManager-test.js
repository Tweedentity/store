const assertRevert = require('./helpers/assertRevert')
const log = require('./helpers/log')
const eventWatcher = require('./helpers/EventWatcher')

const TweedentityStore = artifacts.require('./TweedentityStore.sol')
const TweedentityManager = artifacts.require('./TweedentityManager.sol')

const Wait = require('./helpers/wait')
const Counter = artifacts.require('./helpers/Counter')

const TweedentityManagerCaller = artifacts.require('./helpers/TweedentityManagerCaller')

contract('TweedentityManager', accounts => {

  let store
  let manager
  let managerCaller

  let claimer = accounts[1]
  let customerService = accounts[2]
  let bob = accounts[3]
  let alice = accounts[4]
  let rita = accounts[5]
  let mark = accounts[7]

  let id1 = '1'
  let id2 = '2'
  let id3 = '3'
  let id4 = '4'

  let appNickname = 'twitter'
  let appId = 1

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
    await store.setApp('Twitter', 'twitter.com', appNickname, appId)

    await managerCaller.setManager(manager.address)

    upgradable = await getValue('upgradable')
    notUpgradableInStore = await getValue('notUpgradableInStore')
    uidNotUpgradable = await getValue('uidNotUpgradable')
    addressNotUpgradable = await getValue('addressNotUpgradable')
    uidAndAddressNotUpgradable = await getValue('uidAndAddressNotUpgradable')

    wait = (new Wait(await Counter.new())).wait
  })

  it('should configure the manager', async () => {

    await manager.setClaimer(claimer)
    await manager.setCustomerService(customerService, true)

  })

  it('should see that the store has not been set', async () => {
    assert.isFalse(await manager.getIsStoreSet(appNickname))
  })

  it('should set the store', async () => {
    await manager.setAStore(appNickname, store.address)
    assert.isTrue(await manager.getIsStoreSet(appNickname))
    assert.equal(await store.managerAddress(), manager.address)
  })

  it('should revert trying to add a new tweedentity', async () => {
    await assertRevert(manager.setIdentity(appId, rita, id1))
  })

  it('should add a new identity with uid id1 for rita', async () => {
    assert.isFalse(await store.isUidSet(id1))

    await manager.setIdentity(appId, rita, id1, {
      from: claimer
    })
    assert.equal(await store.getAddress(id1), rita)
    assert.isTrue(await store.isUidSet(id1))
    assert.isTrue(await store.isAddressSet(rita))
  })

  it('should show that minimumTimeBeforeUpdate is 1 days', async () => {
    assert.equal(await manager.minimumTimeBeforeUpdate(), 86400)
  })

  it('should refuse trying to update rita with the uid id2', async () => {

    manager.setIdentity(appId, rita, id2, {
      from: claimer
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

  it('should revert trying to associate accounts[mark to uid id3 using a not authorized owner', async () => {

    await assertRevert(manager.setIdentity(appId, mark, id3))

  })

  it('should change minimumTimeBeforeUpdate to 2 seconds', async () => {
    await manager.changeMinimumTimeBeforeUpdate(2)
    assert.equal(await manager.minimumTimeBeforeUpdate(), 2)
  })

  it('should wait 2 seconds', async () => {
    await wait(2)
    assert.isTrue(true)
  })

  it('should refuse trying to associate bob with id1 since this is associated w/ rita', async () => {

    assert.equal(await store.getUid(rita), id1)

    manager.setIdentity(appId, bob, id1, {
      from: claimer
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
    manager.setIdentity(appId, rita, id1, {
      from: claimer
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
    await manager.setIdentity(appId, mark, id4, {
      from: claimer
    })

    assert.equal(await manager.getUpgradability(appId, rita, id4), notUpgradableInStore)
    assert.equal(await manager.getUpgradability(appId, rita, id3), addressNotUpgradable)
    assert.equal(await manager.getUpgradability(appId, alice, id2), upgradable)
    assert.equal(await manager.getUpgradability(appId, alice, id1), notUpgradableInStore)
    assert.equal(await manager.getUpgradability(appId, rita, id1), uidAndAddressNotUpgradable)

    await wait(2)
    assert.equal(await manager.getUpgradability(appId, rita, id1), upgradable)
    assert.equal(await manager.getUpgradability(appId, rita, id2), upgradable)
    assert.equal(await manager.getUpgradability(appId, rita, id4), notUpgradableInStore)

  })

  it('should associate after a second rita with the uid id2', async () => {

    assert.equal(await store.getAddress(id2), 0)

    await manager.setIdentity(appId, rita, id2, {
      from: claimer
    })
    assert.equal(await store.getUid(rita), id2)

  })

  it('should be able to reverse after 2 seconds', async () => {
    await wait(2)
    // assert.isTrue(await manager.isUidUpgradable(store, id1))

    await manager.setIdentity(appId, rita, id1, {
      from: claimer
    })
    // assert.isFalse(await manager.isUidUpgradable(store,id1))
    assert.equal(await store.getUid(rita), id1)
  })

  it('should associate id2 to alice', async () => {
    await manager.setIdentity(appId, alice, id2, {
      from: claimer
    })
    assert.equal(await store.getUid(alice), id2)
  })

  it('should return rita if searching for id1 and viceversa', async () => {
    assert.equal(await store.getAddress(id1), rita)
    assert.equal(await store.getUid(rita), id1)
  })

  it('should allow customerService to remove the identity for rita', async () => {

    assert.isTrue(await store.isAddressSet(rita))

    await manager.removeIdentity(appId, rita, {
      from: customerService
    })
    assert.equal(await store.getUid(rita), '')
    assert.isFalse(await store.isAddressSet(rita))
  })

  it('should allow bob to be associated to id1 after 2 seconds', async () => {

    await wait(2)

    await manager.setIdentity(appId, bob, id1, {
      from: claimer
    })

    assert.equal(await store.getUid(bob), id1)
    assert.equal(await store.getAddress(id1), bob)

  })

  it('should verify that all the function callable from other contracts are actually callable', async () => {

    assert.equal(await managerCaller.getUpgradability(appId, bob, id1), uidAndAddressNotUpgradable)
    assert.equal(await managerCaller.getUpgradability(appId, bob, id2), notUpgradableInStore)
  })


  it('should allow bob to remove their own identity', async () => {
    await manager.removeMyIdentity(appId, {
      from: bob
    })
    assert.equal(await store.getUid(bob), '')
    assert.equal(await store.getAddress(id1), 0)
  })

})
