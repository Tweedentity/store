const assertRevert = require('./helpers/assertRevert')

const TweedentityData = artifacts.require('./TweedentityData.sol')


contract('TweedentityData', accounts => {

  let store
  let data

  before(async () => {
    data = await TweedentityData.new()
  })

  it('should be empty', async () => {
    assert.equal(await data.totalTweedentities(), 0)
  })

  it('should revert trying to add a new tweedentity', async () => {
    await assertRevert(data.addTweedentity(accounts[1], 'George', '12345'))
  })

  it('should authorize accounts[0] to handle the data', async () => {
    await data.authorize(accounts[0], 1)
    assert.equal(await data.authorized(accounts[0]), 1)
  })

  it('should add a new tweedentity (@George) for accounts[1]', async () => {

    assert.equal(await data.isSet('12345'), false)
    
    await data.addTweedentity(accounts[1], 'George', '12345')
    assert.equal(await data.totalTweedentities(), 1)
    assert.equal(await data.screenNameByAddress(accounts[1]), 'george')
  })

  it('should show that minimumTimeRequiredBeforeUpdate is 1 days', async () => {
    assert.equal(await data.minimumTimeRequiredBeforeUpdate(), 86400)
  })

  it('should change minimumTimeRequiredBeforeUpdate to zero (only in the mock)', async () => {
    await data.changeMinimumTimeRequiredBeforeUpdate(0)
    assert.equal(await data.minimumTimeRequiredBeforeUpdate(), 0)
  })

  it('should remove accounts[1] identity', async () => {
    await data.removeTweedentity(accounts[1])
    console.log((await data.totalTweedentities()).valueOf())
    assert.equal(await data.totalTweedentities(), 0)
  })

  it('should add a new tweedentity (@marcus) for accounts[2]', async () => {
    await data.addTweedentity(accounts[2], 'marcus', '23456')
    assert.equal(await data.totalTweedentities(), 1)
    assert.equal(await data.screenNameByAddress(accounts[2]), 'marcus')
  })

  it('should add again the tweedentity (@George) for accounts[1]', async () => {
    await data.addTweedentity(accounts[1], 'George', '12345')
    assert.equal(await data.totalTweedentities(), 2)
    assert.equal(await data.screenNameByAddress(accounts[1]), 'george')
  })

  it('should return accounts[1] if searching for the screen name GEorGE', async () => {
    assert.equal(await data.getAddressByScreenName('GEorGE'), accounts[1])
  })

  it('should allow account[3] to be associated to @George', async () => {
    await data.removeTweedentity(accounts[1])
    await data.addTweedentity(accounts[3], 'George', '12345')
    assert.equal(await data.totalTweedentities(), 1)
    assert.equal(await data.screenNameByAddress(accounts[3]), 'george')
  })

  it('shoyld return the lowerCase of a string', async () => {
    assert.equal(await data.toLower('CASEsensiTiVe'), 'casesensitive')
  })

})
