const log = require('./helpers/log')
const assertRevert = require('./helpers/assertRevert')

const eventWatcher = require('./helpers/EventWatcher')

const TweedentityStore = artifacts.require('./TweedentityStore.sol')
const TweedentityStoreCaller = artifacts.require('./helpers/TweedentityStoreCaller')

const Wait = require('./helpers/wait')
const Counter = artifacts.require('./helpers/Counter')

function now() {
  console.log(parseInt('' + Date.now() / 1000, 10), 'now')
}

contract('TweedentityStore', accounts => {

  let store
  let storeCaller

  let manager = accounts[1]
  let bob = accounts[3]
  let alice = accounts[4]
  let rita = accounts[5]

  let id1 = '12345'
  let id2 = '23456'
  let id3 = '34567'

  let wait

  async function getValue(what) {
    return (await store[what]()).valueOf()
  }

  before(async () => {
    store = await TweedentityStore.new()
    storeCaller = await TweedentityStoreCaller.new()
    await storeCaller.setStore(store.address)
    wait = (new Wait(await Counter.new())).wait
  })

  it('should be empty', async () => {
    assert.equal(await store.identities(), 0)
  })

  it('should revert trying to add a new tweedentity', async () => {
    await assertRevert(store.setIdentity(rita, id1))
  })

  it('should authorize manager to handle the data', async () => {
    await store.setManager(manager)
    assert.equal((await store.manager()), manager)
  })

  it('should revert trying to add a new tweedentity because the store is not declared', async () => {
    await assertRevert(store.setIdentity(rita, id1))
  })

  it('should declare the store', async () => {
    await store.setApp('twitter', 1)
    assert.equal(await store.getAppNickname(), web3.sha3('twitter'))
    assert.equal(await store.getAppId(), 1)
  })

  it('should add a new identity with uid id1 for rita', async () => {
    assert.equal(await store.getAddress(id1), 0)

    await store.setIdentity(rita, id1, {from: manager})
    assert.equal(await store.getAddress(id1), rita)
    assert.equal(await store.getUid(rita), id1)
    assert.equal(await store.identities(), 1)
  })

  it('should revert trying to associate accounts[5] to uid id3 using a not authorized owner', async () => {
    await assertRevert(store.setIdentity(accounts[5], id3))
  })

  it('should revert trying to associate bob with id1 since this is associated w/ rita', async () => {
    await assertRevert(store.setIdentity(bob, id1, {from: manager}))
  })

  it('should not revert trying to associate again id1 to rita', async () => {
    const lastUpdate = await store.getAddressLastUpdate(rita)
    wait()
    await store.setIdentity(rita, id1, {from: manager})
    assert.isTrue(await store.getAddressLastUpdate(rita) != lastUpdate)
  })

  it('should associate now rita with the uid id2 and reverse after 1 second', async () => {
    await store.setIdentity(rita, id2, {from: manager})
    assert.equal(await store.identities(), 1)
    assert.equal(await store.getUid(rita), id2)

    await store.setIdentity(rita, id1, {from: manager})
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

  it('should allow manager to remove the identity for rita', async () => {

    assert.notEqual(await store.getUid(rita), 0)
    await store.unsetIdentity(rita, {from: manager})
    assert.equal(await store.getUid(rita), '')

  })

  it('should allow bob to be associated to id1', async () => {

    await store.setIdentity(bob, id1, {from: manager})

    assert.equal(await store.getUid(rita), 0)
    assert.equal(await store.getUid(bob), id1)
    assert.equal(await store.getAddress(id1), bob)

  })

  it('should verify that all the function callable from other contracts are actually callable', async () => {

    assert.equal(await storeCaller.getAddress(id1), bob)
    assert.equal(await storeCaller.getUidAsInteger(bob), 12345)
    assert.equal(await storeCaller.getAddress(id1), bob)
    assert.equal(await storeCaller.getAddressLastUpdate(bob), (await store.getAddressLastUpdate(bob)).valueOf())
    assert.equal(await storeCaller.getUidLastUpdate(id1), (await store.getUidLastUpdate(id1)).valueOf())
  })



})
