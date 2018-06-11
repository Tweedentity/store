
const TweedentityRegistry = artifacts.require('./TweedentityRegistry.sol')


contract('TweedentityRegistry', accounts => {


  let registry
  const storeTwitter = '0xe5277b95e1d4dbc9183686deee59619779005e85'
  const storeGithub = '0x993486b29bce5b40e54600959c710f1314fa5f45'
  const manager = '0x3326dfffe082df29d2795e7d18831014c95f04e2'
  const claimer = '0xc46bda87cc365b752d3db2eef1ec8487010e49c7'

  beforeEach(async () => {
    registry = await TweedentityRegistry.new()
  })

  it('should set the store for Twitter', async () => {
    await registry.setAStore('twitter', storeTwitter)
    assert.equal(await registry.getStore('twitter'), storeTwitter)
  })

  it('should set the store for Github', async () => {
    await registry.setAStore('github', storeGithub)
    assert.equal(await registry.getStore('github'), storeGithub)
  })

  it('should set the manager', async () => {
    await registry.setManager(manager)
    assert.equal(await registry.manager(), manager)
  })

  it('should set the claimer', async () => {
    await registry.setClaimer(claimer)
    assert.equal(await registry.claimer(), claimer)
  })

  it('should set manager and claimer', async () => {
    await registry.setManagerAndClaimer(manager, claimer)
    assert.equal(await registry.manager(), manager)
    assert.equal(await registry.claimer(), claimer)
  })

  it('should set all and be ready', async() => {
    await registry.setAStore('twitter', storeTwitter)
    await registry.setAStore('github', storeGithub)
    await registry.setManagerAndClaimer(manager, claimer)
    assert.isTrue(await registry.isReady())
  })



})
