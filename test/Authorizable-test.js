
const assertRevert = require('./helpers/assertRevert')

const Authorizable = artifacts.require('./mocks/AuthorizableMock.sol')


contract('Authorizable', accounts => {

  return

  let authorizable
  let authorizedLevel1 = accounts[1]
  let authorizedLevel5 = accounts[2]

  before(async () => {
    authorizable = await Authorizable.new()
  })

  it('should be inactive', async () => {
    let _authorized = await authorizable.getAuthorizedAddresses()
    assert.isTrue(_authorized.length == 0)
  })

  it('should authorize authorizedLevel1', async () => {
    await authorizable.authorize(authorizedLevel1)
    let level = await authorizable.authorized(authorizedLevel1)
    assert.isTrue(level == 1)
    let _authorized = await authorizable.getAuthorizedAddresses()
    assert.isTrue(_authorized.length == 1)
  })

  it('should authorize authorizedLevel5', async () => {
    await authorizable.authorizeLevel(authorizedLevel5, 5)
    let level = await authorizable.authorized(authorizedLevel5)
    assert.isTrue(level == 5)
    let _authorized = await authorizable.getAuthorizedAddresses()
    assert.isTrue(_authorized.length == 2)
  })

  // owner

  it('should throw if calling setTestVariable1, 2 and 3 from owner', async () => {
    await assertRevert(authorizable.setTestVariable1())
    await assertRevert(authorizable.setTestVariable2())
    await assertRevert(authorizable.setTestVariable3())
  })

  it('should call setTestVariable4, 5 and 6 from owner', async () => {
    await authorizable.setTestVariable4()
    let testVariable = await authorizable.testVariable()
    assert.isTrue(testVariable == 4);
    await authorizable.setTestVariable5()
    testVariable = await authorizable.testVariable()
    assert.isTrue(testVariable == 5);
    await authorizable.setTestVariable6()
    testVariable = await authorizable.testVariable()
    assert.isTrue(testVariable == 6);
    // reset to 1
    await authorizable.setTestVariable1({ from: authorizedLevel1 })
  })

  // authorizedLevel1

  it('should call setTestVariable1 and 4 from authorizedLevel1', async () => {
    await authorizable.setTestVariable1({ from: authorizedLevel1 })
    let testVariable = await authorizable.testVariable()
    assert.isTrue(testVariable == 1)
    await authorizable.setTestVariable4({ from: authorizedLevel1 })
    testVariable = await authorizable.testVariable()
    assert.isTrue(testVariable == 4)
  })

  it('should throw if calling setTestVariable2, 3, 5 and 6 from authorizedLevel1', async () => {
    await assertRevert(authorizable.setTestVariable2({ from: authorizedLevel1 }))
    await assertRevert(authorizable.setTestVariable3({ from: authorizedLevel1 }))
    await assertRevert(authorizable.setTestVariable5({ from: authorizedLevel1 }))
    await assertRevert(authorizable.setTestVariable6({ from: authorizedLevel1 }))
  })

  // authorizedLevel5

  it('should call setTestVariable1 to 6 from authorizedLevel5', async () => {
    await authorizable.setTestVariable1({ from: authorizedLevel5 })
    let testVariable = await authorizable.testVariable()
    assert.isTrue(testVariable == 1);
    await authorizable.setTestVariable2({ from: authorizedLevel5 })
    testVariable = await authorizable.testVariable()
    assert.isTrue(testVariable == 2);
    await authorizable.setTestVariable3({ from: authorizedLevel5 })
    testVariable = await authorizable.testVariable()
    assert.isTrue(testVariable == 3);
    await authorizable.setTestVariable4({ from: authorizedLevel5 })
    testVariable = await authorizable.testVariable()
    assert.isTrue(testVariable == 4);
    await authorizable.setTestVariable5({ from: authorizedLevel5 })
    testVariable = await authorizable.testVariable()
    assert.isTrue(testVariable == 5);
    await authorizable.setTestVariable6({ from: authorizedLevel5 })
    testVariable = await authorizable.testVariable()
    assert.isTrue(testVariable == 6);
  })

  it('should deAuthorize authorizedLevel1 called by itself', async () => {
    await authorizable.deAuthorize({from: authorizedLevel1})
    let level = await authorizable.authorized(authorizedLevel1)
    assert.isTrue(level == 0)
  })

  it('should throw if calling setTestVariable1 from authorizedLevel1', async () => {
    await assertRevert(authorizable.setTestVariable1({ from: authorizedLevel1 }))
  })

})
