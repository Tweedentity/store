const assertRevert = require('./helpers/assertRevert')
const log = require('./helpers/log')

const TweedentityData = artifacts.require('./mocks/TweedentityDataMock.sol')


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
    assert.isFalse(await data.isSetU('12345'))
    await data.addTweedentity(accounts[1], 'George', '12345')
    assert.equal(await data.getAddressByUid('12345'), accounts[1])
    assert.equal(await data.getAddressByScreenName('george'), accounts[1])
    assert.isTrue(await data.isSetU('12345'))
    assert.isTrue(await data.isSet(accounts[1]))
    assert.equal(await data.totalTweedentities(), 1)
    assert.equal(await data.screenNameByAddress(accounts[1]), 'george')
  })

  it('should show that minimumTimeRequiredBeforeUpdate is 1 days', async () => {
    assert.equal(await data.minimumTimeRequiredBeforeUpdate(), 86400)
  })

  it('should revert trying to update the tweedentity (@George) for accounts[1]', async () => {
    await assertRevert(data.addTweedentity(accounts[3], 'George', '12345'))
  })

  it('should change minimumTimeRequiredBeforeUpdate to zero', async () => {
    await data.changeMinimumTimeRequiredBeforeUpdate(0)
    assert.equal(await data.minimumTimeRequiredBeforeUpdate(), 0)
  })

  it('should remove accounts[1] identity', async () => {
    await data.removeTweedentity(accounts[1])

    console.log((await data.totalTweedentities()).valueOf())
    assert.equal(await data.totalTweedentities(), 0)
  })

  it('should add a new tweedentity (@marcus) for accounts[2]', async () => {
    await data.addTweedentity(accounts[2], 'marcus', '23456')git pull

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

  it('should deassociate @george from account[1] and allow account[3] to be associated to @George', async () => {
    assert.isTrue(await data.isSet(accounts[1]))

    await data.removeTweedentity(accounts[1])

    assert.isFalse(await data.isSet(accounts[1]))
    assert.equal(await data.screenNameByAddress(accounts[1]), '')

    await data.addTweedentity(accounts[3], 'George', '12345')

    assert.equal(await data.screenNameByAddress(accounts[3]), 'george')
  })

  it('shoyld return the lowerCase of a string', async () => {
    assert.equal(await data.toLower('CASEsensiTiVe'), 'casesensitive')
  })

})
