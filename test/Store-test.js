const sleep = require('sleep')

const assertRevert = require('./helpers/assertRevert')
const log = require('./helpers/log')

const Store = artifacts.require('./Store.sol')


contract('Store', accounts => {

  let store

  before(async () => {
    store = await Store.new()
  })

  it('should be empty', async () => {
    assert.equal(await store.identities(), 0)
  })

  it('should revert trying to add a new tweedentity', async () => {
    await assertRevert(store.setIdentity(accounts[4], '12345'))
  })

  it('should authorize accounts[1] to handle the data', async () => {
    await store.authorize(accounts[1], 1)
    assert.equal(await store.authorized(accounts[1]), 1)
  })

  it('should add a new identity with uid 12345 for accounts[4]', async () => {
    assert.isFalse(await store.isUidSet('12345'))
    await store.setIdentity(accounts[4], '12345', {from:accounts[1]})
    assert.equal(await store.getAddress('12345'), accounts[4])
    assert.isTrue(await store.isUidSet('12345'))
    assert.isTrue(await store.isAddressSet(accounts[4]))
    assert.equal(await store.identities(), 1)
  })

  it('should show that minimumTimeBeforeUpdate is 1 days', async () => {
    assert.equal(await store.minimumTimeBeforeUpdate(), 86400)
  })

  it('should revert trying to update accounts[4] with the uid 23456', async () => {
    await assertRevert(store.setIdentity(accounts[4], '23456', {from:accounts[1]}))
  })

  it('should revert trying to associate accounts[5] to uid 34567 using a not authorized accounts[0]', async () => {
    await assertRevert(store.setIdentity(accounts[5], '34567'))
  })



  it('should change minimumTimeBeforeUpdate to 1 second', async () => {
    await store.changeMinimumTimeBeforeUpdate(1, {from:accounts[1]})
    assert.equal(await store.minimumTimeBeforeUpdate(), 1)
  })

  it('should wait 1 second', async () => {
    sleep.sleep(1)
  })

  it('should revert trying to associate accounts[3] with 12345 since this is associated w/ accounts[4]', async () => {
    await assertRevert(store.setIdentity(accounts[3], '12345', {from:accounts[1]}))
  })

  it('should revert trying to associate again 12345 to accounts[4]', async () => {
    await assertRevert(store.setIdentity(accounts[4], '12345', {from:accounts[1]}))
  })

  it('should associate 23456 to accounts[2]', async () => {
    await store.setIdentity(accounts[2], '23456', {from:accounts[1]})
    assert.equal(await store.identities(), 2)
  })

  it('should return accounts[4] if searching for 12345 and viceversa', async () => {
    assert.equal(await store.getAddress('12345'), accounts[4])
    assert.equal(await store.getUid(accounts[4]), '12345')
  })

  it('should return sha3("12345") if looking at the hash of the uid associated with accounts[4]', async () => {
    assert.equal(await store.getUidHash(accounts[4]), web3.sha3('12345'))
  })

  it('should deassociate 12345 from account[1] and allow account[3] to be associated to 12345', async () => {
    assert.isTrue(await store.isAddressSet(accounts[4]))
    await store.removeIdentity(accounts[4], {from:accounts[1]})
    assert.equal(await store.getUid(accounts[4]), '')
    assert.equal(await store.getUidHash(accounts[4]), web3.sha3(''))
    assert.equal(await store.getUidHash(accounts[4]), web3.sha3(''))
    assert.isFalse(await store.isAddressSet(accounts[4]))
    await store.setIdentity(accounts[3], '12345', {from:accounts[1]})
    assert.equal(await store.getUid(accounts[3]), '12345')
    assert.equal(await store.getAddress('12345'), accounts[3])
  })

  it('should allow account[3] to remove their own identity', async () => {
    await store.removeMyIdentity({from:accounts[3]})
    assert.equal(await store.getUid(accounts[3]), '')
    assert.equal(await store.getAddress('12345'), 0)
  })

})
