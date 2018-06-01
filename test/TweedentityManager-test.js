const sleep = require('sleep')

const assertRevert = require('./helpers/assertRevert')
const log = require('./helpers/log')

const TweedentityStore = artifacts.require('./TweedentityStore.sol')
const TweedentityManager = artifacts.require('./mocks/TweedentityManagerMock.sol')

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

  let id1 = '12345'
  let id2 = '23456'
  let id3 = '34567'

  let verifierLevel
  let customerServiceLevel
  let devLevel

  async function wait() {
    console.log(`Sleep 1 second`)
    sleep.sleep(1)
    await manager.incCounter()
  }

  async function getValue(what) {
    return (await manager[what]()).valueOf()
  }

  before(async () => {
    store = await TweedentityStore.new()
    manager = await TweedentityManager.new()
    managerCaller = await TweedentityManagerCaller.new()

    store.setManager(manager.address)
    managerCaller.setManager(manager.address)
    manager.setStore(store.address)

    verifierLevel = (await manager.verifierLevel()).valueOf()
    customerServiceLevel = (await manager.customerServiceLevel()).valueOf()
    devLevel = (await manager.devLevel()).valueOf()
  })

  it('should be empty', async () => {
    assert.equal(await manager.identities(), 0)
  })

  it('should revert trying to add a new tweedentity', async () => {
    await assertRevert(manager.setIdentity(rita, id1))
  })

  it('should authorize verifier to handle the data', async () => {
    assert.equal(await store.manager(), manager.address)

    await manager.authorize(verifier, verifierLevel)
    assert.isTrue(await manager.amIAuthorized({
      from: verifier
    }))
    assert.equal(await manager.authorized(verifier), verifierLevel)
  })

  it('should authorize customerService to do customer service', async () => {
    await manager.authorize(customerService, customerServiceLevel)
    assert.equal(await manager.authorized(customerService), customerServiceLevel)
  })

  it('should authorize developer to change params', async () => {
    await manager.authorize(developer, devLevel)
    assert.equal(await manager.authorized(developer), devLevel)
  })

  it('should add a new identity with uid id1 for rita', async () => {
    assert.isFalse(await store.isUidSet(id1))

    await manager.setIdentity(rita, id1, {
      from: verifier
    })
    assert.equal(await store.getAddress(id1), rita)
    assert.isTrue(await store.isUidSet(id1))
    assert.isTrue(await store.isAddressSet(rita))
    assert.equal(await store.identities(), 1)
  })

  it('should show that minimumTimeBeforeUpdate is 1 days', async () => {
    assert.equal(await manager.minimumTimeBeforeUpdate(), 86400)
  })

  it('should revert trying to update rita with the uid id2', async () => {
    await assertRevert(manager.setIdentity(rita, id2, {
      from: verifier
    }))
  })

  it('should revert trying to associate accounts[5] to uid id3 using a not authorized owner', async () => {
    await assertRevert(manager.setIdentity(accounts[5], id3))
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

  it('should revert trying to associate bob with id1 since this is associated w/ rita', async () => {
    await assertRevert(manager.setIdentity(bob, id1, {
      from: verifier
    }))
  })

  it('should revert trying to associate again id1 to rita', async () => {
    await assertRevert(manager.setIdentity(rita, id1, {
      from: verifier
    }))
  })

  it('should associate now rita with the uid id2 and reverse after 1 second', async () => {
    await manager.setIdentity(rita, id2, {
      from: verifier
    })
    assert.equal(await store.identities(), 1)
    assert.equal(await store.getUid(rita), id2)

    await wait()
    assert.isTrue(await manager.isUidUpgradable(id1))

    await manager.setIdentity(rita, id1, {
      from: verifier
    })
    assert.isFalse(await manager.isUidUpgradable(id1))
    assert.equal(await store.identities(), 1)
    assert.equal(await store.getUid(rita), id1)
  })

  it('should associate id2 to alice', async () => {
    await manager.setIdentity(alice, id2, {
      from: verifier
    })
    assert.equal(await store.identities(), 2)
  })

  it('should return rita if searching for id1 and viceversa', async () => {
    assert.equal(await store.getAddress(id1), rita)
    assert.equal(await store.getUid(rita), id1)
  })

  it('should allow customerService to remove the identity for rita', async () => {

    assert.isTrue(await store.isAddressSet(rita))

    await manager.removeIdentity(rita, {
      from: customerService
    })
    assert.equal(await store.getUid(rita), '')

  })

  it('should allow bob to be associated to id1 after 1 second', async () => {

    await wait()

    assert.isTrue(await manager.isUidUpgradable(id1))

    await manager.setIdentity(bob, id1, {
      from: verifier
    })
    await wait()

    assert.isFalse(await store.isAddressSet(rita))
    assert.equal(await store.getUid(bob), id1)
    assert.equal(await store.getAddress(id1), bob)
    assert.isTrue(await manager.isUidUpgradable(id1))

  })

  it('should verify that all the function callable from other contracts are actually callable', async () => {

    assert.isTrue(await managerCaller.isUidUpgradable(id1))
    assert.isTrue(await managerCaller.isAddressUpgradable(bob))
    assert.isTrue(await managerCaller.isUpgradable(bob, id2))
    assert.isFalse(await managerCaller.isUpgradable(bob, id1))
  })


  it('should allow bob to remove their own identity', async () => {
    await manager.removeMyIdentity({
      from: bob
    })
    assert.equal(await store.getUid(bob), '')
    assert.equal(await store.getAddress(id1), 0)
  })

})