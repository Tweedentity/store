const assertRevert = require('./helpers/assertRevert')

const TweedentityData = artifacts.require('./TweedentityData.sol')
const TweedentityStore = artifacts.require('./mocks/TweedentityStoreMock.sol')


contract('TweedentityStore', accounts => {

  let store
  let data

  before(async () => {
    store = await TweedentityStore.new()
    data = await TweedentityData.new()
  })

  it('should be empty', async () => {
    assert.equal(await data.totalTweedentities(), 0)
  })

  it('should revert trying to add a new tweedentity', async () => {
    await assertRevert(store.addTweedentity(accounts[1], 'George', '12345'))
  })

  it('should authorize accounts[0] to manage the store', async () => {
    await store.authorize(accounts[0], 1)
    assert.equal(await store.authorized(accounts[0]), 1)
  })

  it('should revert trying to add a new tweedentity before the store is authorized to handle the data ', async () => {
    await assertRevert(store.addTweedentity(accounts[1], 'George', '12345'))
  })

  it('should authorize the store to handle the data', async () => {
    await data.authorize(store.address, 1)
    assert.equal(await data.authorized(store.address), 1)
  })

  it('should add a new tweedentity (@George) for accounts[1]', async () => {
    await store.addTweedentity(accounts[1], 'George', '12345')
    assert.equal(await data.totalTweedentities(), 1)
    assert.equal(await data.tweedentities(accounts[1]), 'george')
  })

  return

  it('should show that minimumTimeRequiredBeforeUpdate is 1 days', async () => {
    assert.equal(await store.minimumTimeRequiredBeforeUpdate(), 86400)
  })

  it('should revert if accounts[0] tries to remove accounts[1] identity too early', async () => {
    await assertRevert(store.removeTweedentity(accounts[1]))
  })

  it('should change minimumTimeRequiredBeforeUpdate to zero (only in the mock)', async () => {
    await store.changeMinimumTimeRequiredBeforeUpdate(0)
    assert.equal(await data.minimumTimeRequiredBeforeUpdate(), 0)
  })

  it('should remove accounts[1] identity', async () => {
    await store.removeTweedentity(accounts[1])
    assert.equal(await data.totalTweedentities(), 0)
  })

  it('should add a new tweedentity (@marcus) for accounts[2]', async () => {
    await store.addTweedentity(accounts[2], 'marcus', '23456')
    assert.equal(await data.totalTweedentities(), 1)
    assert.equal(await data.tweedentities(accounts[2]), 'marcus')
  })

  it('should revert trying to add again the tweedentity (@George) for accounts[1] with a different user-id', async () => {
    await assertRevert(store.addTweedentity(accounts[1], 'George', '54321'))
  })

  it('should add again the tweedentity (@George) for accounts[1]', async () => {
    await store.addTweedentity(accounts[1], 'George', '12345')
    assert.equal(await data.totalTweedentities(), 2)
    assert.equal(await data.tweedentities(accounts[1]), 'george')
  })

  it('should allow accounts[2] to remove its own identity', async () => {
    await store.removeMyTweedentity({from: accounts[2]})
    assert.equal(await data.totalTweedentities(), 1)
  })

  it('should return accounts[1] if searching for the screen name GEorGE', async () => {
    assert.equal(await data.getAddressByScreenName('GEorGE'), accounts[1])
  })

  it('should allow account[3] to be associated to @George', async () => {
    await store.removeTweedentity(accounts[1])
    await store.addTweedentity(accounts[3], 'George', '12345')
    assert.equal(await data.totalTweedentities(), 1)
    assert.equal(await data.tweedentities(accounts[3]), 'george')
  })

  it('shoyld return the lowerCase of a string', async () => {
    assert.equal(await data.toLower('CASEsensiTiVe'), 'casesensitive')
  })

})
