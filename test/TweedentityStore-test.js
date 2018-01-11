
const assertRevert = require('./helpers/assertRevert')

const TweedentityStore = artifacts.require('./mocks/TweedentityStoreMock.sol')


contract('TweedentityStore', accounts => {

  let store

  before(async () => {
    store = await TweedentityStore.new()
  })

  it('should be empty', async () => {
    assert.isTrue(await store.totalTweedentities() == 0)
  })

  it('should revert trying to add a new tweedentity', async () => {
    await assertRevert(store.addTweedentity(accounts[1], 'George'))
  })

  it('should authorize accounts[0] to manage the store', async () => {
    await store.authorize(accounts[0])
    assert.isTrue(await store.authorized(accounts[0]) == 1)

  })

  it('should add a new tweedentity (@George) for accounts[1]', async () => {
    await store.addTweedentity(accounts[1], 'George')
    assert.isTrue(await store.totalTweedentities() == 1)
    assert.isTrue(await store.tweedentities(accounts[1]) == 'George')
  })

  it('should show that minimumTimeRequiredBeforeUpdate is 1 days', async () => {
    assert.isTrue(await store.minimumTimeRequiredBeforeUpdate() == 86400)
  })

  it('should revert if accounts[0] tries to remove accounts[1] identity too early', async () => {
    await assertRevert(store.removeTweedentity(accounts[1]))
  })

  it('should change minimumTimeRequiredBeforeUpdate to zero (only in the mock)', async () => {
    await store.changeMinimumTimeRequiredBeforeUpdate(0)
    assert.isTrue(await store.minimumTimeRequiredBeforeUpdate() == 0)
  })

  it('should remove accounts[1] identity', async () => {
    await store.removeTweedentity(accounts[1])
    assert.isTrue(await store.totalTweedentities() == 0)
  })

  it('should add a new tweedentity (@marcus) for accounts[2]', async () => {
    await store.addTweedentity(accounts[2], 'marcus')
    console.log('await store.totalTweedentities()', await store.totalTweedentities())
    assert.isTrue(await store.totalTweedentities() == 1)
    assert.isTrue(await store.tweedentities(accounts[2]) == 'marcus')
  })

  it('should add again the tweedentity (@George) for accounts[1]', async () => {
    await store.addTweedentity(accounts[1], 'George')
    assert.isTrue(await store.totalTweedentities() == 2)
    assert.isTrue(await store.tweedentities(accounts[1]) == 'George')
  })

  it('should allow accounts[2] to remove its own identity', async () => {
    await store.removeMyTweedentity({from: accounts[2]})
    assert.isTrue(await store.totalTweedentities() == 1)
  })

  it('should return accounts[1] if searching for the screen name GEORGE', async () => {
    assert.isTrue(await store.getAddressByScreenName('GEORGE') == accounts[1])
  })

  it('should allow account[3] to be associated to @George', async () => {
    await store.removeTweedentity(accounts[1])
    await store.addTweedentity(accounts[3], 'George')
    assert.isTrue(await store.totalTweedentities() == 1)
    assert.isTrue(await store.tweedentities(accounts[3]) == 'George')
  })

  it('shoyld return the loweCase of a string', async () => {
    assert.equal(await manager.toLower('CASEsensiTiVe'), 'casesensitive')
  })

})
