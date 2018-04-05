const sleep = require('sleep')

const assertRevert = require('./helpers/assertRevert')
const log = require('./helpers/log')

const Store = artifacts.require('./mocks/StoreMock.sol')
const StoreCaller = artifacts.require('./helpers/StoreCaller')

function now() {
  console.log(parseInt('' + Date.now() / 1000, 10), 'now')
}

contract('Store', accounts => {

  let store
  let storeCaller

  let owner = accounts[0]
  let manager = accounts[1]
  let customerService = accounts[2]
  let bob = accounts[3]
  let alice = accounts[4]
  let rita = accounts[5]

  let id1 = '12345'
  let id2 = '23456'
  let id3 = '34567'

  async function wait() {
    console.log(`Sleep 1 second`)
    sleep.sleep(1)
    await store.incCounter()
  }

  before(async () => {
    store = await Store.new()
    storeCaller = await StoreCaller.new()
    storeCaller.setStore(store.address)
  })

  it('should be empty', async () => {
    assert.equal(await store.identities(), 0)
  })

  it('should revert trying to add a new tweedentity', async () => {
    await assertRevert(store.setIdentity(rita, id1))
  })

  it('should authorize manager to handle the data', async () => {
    await store.authorize(manager, 40)
    assert.isTrue(await store.amIAuthorized({from: manager}))
    assert.equal(await store.authorized(manager), 40)
  })

  it('should authorize customerService to do customer service', async () => {
    await store.authorize(customerService, 30)
    assert.equal(await store.authorized(customerService), 30)
  })

  it('should add a new identity with uid id1 for rita', async () => {
    assert.isFalse(await store.isUidSet(id1))

    await store.setIdentity(rita, id1, {from: manager})
    assert.equal(await store.getAddress(id1), rita)
    assert.isTrue(await store.isUidSet(id1))
    assert.isTrue(await store.isAddressSet(rita))
    assert.equal(await store.identities(), 1)
  })


  it('should show that minimumTimeBeforeUpdate is 1 days', async () => {
    assert.equal(await store.minimumTimeBeforeUpdate(), 86400)
  })

  it('should revert trying to update rita with the uid id2', async () => {
    await assertRevert(store.setIdentity(rita, id2, {from: manager}))
  })

  it('should revert trying to associate accounts[5] to uid id3 using a not authorized owner', async () => {
    await assertRevert(store.setIdentity(accounts[5], id3))
  })

  it('should change minimumTimeBeforeUpdate to 1 second', async () => {
    await store.changeMinimumTimeBeforeUpdate(1, {from: manager})
    assert.equal(await store.minimumTimeBeforeUpdate(), 1)
  })

  it('should wait 1 second', async () => {
    await wait()
  })

  it('should revert trying to associate bob with id1 since this is associated w/ rita', async () => {
    await assertRevert(store.setIdentity(bob, id1, {from: manager}))
  })

  it('should revert trying to associate again id1 to rita', async () => {
    await assertRevert(store.setIdentity(rita, id1, {from: manager}))
  })

  it('should associate now rita with the uid id2 and reverse after 1 second', async () => {
    await store.setIdentity(rita, id2, {from: manager})
    assert.equal(await store.identities(), 1)
    assert.equal(await store.getUid(rita), id2)

    await wait()
    assert.isTrue(await store.isUidUpgradable(id1))

    await store.setIdentity(rita, id1, {from: manager})
    assert.isFalse(await store.isUidUpgradable(id1))
    assert.equal(await store.identities(), 1)
    assert.equal(await store.getUid(rita), id1)
  })

  it('should associate id2 to alice', async () => {
    await store.setIdentity(alice, id2, {from: manager})
    assert.equal(await store.identities(), 2)
  })

  it('should return rita if searching for id1 and viceversa', async () => {
    assert.equal(await store.getAddress(id1), rita)
    assert.equal(await store.getUid(rita), id1)
  })

  it('should allow customerService to remove the identity for rita', async () => {

    assert.isTrue(await store.isAddressSet(rita))

    await store.removeIdentity(rita, {from: customerService})
    assert.equal(await store.getUid(rita), '')

  })

  it('should allow bob to be associated to id1 after 1 second', async () => {

    await wait()

    assert.isTrue(await store.isUidUpgradable(id1))

    await store.setIdentity(bob, id1, {from: manager})
    await wait()

    assert.isFalse(await store.isAddressSet(rita))
    assert.equal(await store.getUid(bob), id1)
    assert.equal(await store.getAddress(id1), bob)
    assert.isTrue(await store.isUidUpgradable(id1))

  })

  it('should verify that all the function callable from other contracts are actually callable', async () => {

    assert.isTrue(await storeCaller.isUidSet(id1))
    assert.isTrue(await storeCaller.isAddressSet(bob))
    assert.isTrue(await storeCaller.isUidUpgradable(id1))
    assert.isTrue(await storeCaller.isAddressUpgradable(bob))
    assert.isTrue(await storeCaller.isUpgradable(bob, id2))
    assert.isFalse(await storeCaller.isUpgradable(bob, id1))
    assert.equal(await storeCaller.getUidAsInteger(bob), 12345)
    assert.equal(await storeCaller.getAddress(id1), bob)
    assert.equal(await storeCaller.getAddressLastUpdate(bob), (await store.getAddressLastUpdate(bob)).valueOf())
    assert.equal(await storeCaller.getUidLastUpdate(id1), (await store.getUidLastUpdate(id1)).valueOf())
  })


  it('should allow bob to remove their own identity', async () => {
    await store.removeMyIdentity({from: bob})
    assert.equal(await store.getUid(bob), '')
    assert.equal(await store.getAddress(id1), 0)
  })


})
