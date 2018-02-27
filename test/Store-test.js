const sleep = require('sleep')

const assertRevert = require('./helpers/assertRevert')
const log = require('./helpers/log')

const Data = artifacts.require('./Data.sol')
const Store = artifacts.require('./Store.sol')


contract('Store', accounts => {

  let store
  let data

  before(async () => {
    store = await Store.new()
    data = await Data.new()
  })

  it('should be empty', async () => {
    assert.equal(await data.totalTweedentities(), 0)
  })

  it('should revert trying to add a new tweedentity', async () => {
    await assertRevert(store.setIdentity(accounts[1], 'George', '12345'))
  })

  it('should authorize accounts[0] to manage the store', async () => {
    await store.authorize(accounts[0], 1)
    assert.equal(await store.authorized(accounts[0]), 1)
  })

  it('should revert trying to add a new tweedentity before the store is not authorized to handle the data ', async () => {
    await assertRevert(store.setIdentity(accounts[1], 'George', '12345'))
  })

  it('should authorize the store to handle the data', async () => {
    await data.authorize(store.address, 1)
    assert.equal(await data.authorized(store.address), 1)
  })

  it('should set the data address', async () => {
    await store.setData(data.address)
  })

  it('should add a new tweedentity (@George) for accounts[1]', async () => {
    await store.setIdentity(accounts[1], 'George', '12345')
    assert.equal(await data.totalTweedentities(), 1)
    assert.equal(await data.screenNameByAddress(accounts[1]), 'george')
    log(await store.count())
  })

  it('should revert trying to update the tweedentity (@George) for accounts[1] using accounts[3]', async () => {
    await assertRevert(data.setIdentity(accounts[3], 'George', '12345'))
  })

  it('should change minimumTimeRequiredBeforeUpdate to 1 second', async () => {
    await store.changeMinimumTimeRequiredBeforeUpdate(1)
    assert.equal(await data.minimumTimeRequiredBeforeUpdate(), 1)
  })

  it('should update the tweedentity (@George) using accounts[3], after waiting 2 seconds', async () => {
    sleep.sleep(2)
    await data.setIdentity(accounts[3], 'George', '12345')
    log(await store.count())
    // assert.equal(await data.screenNameByAddress(accounts[3]), 'george')
    // assert.equal(await data.screenNameByAddress(accounts[1]), 'undefined')
  })



})
