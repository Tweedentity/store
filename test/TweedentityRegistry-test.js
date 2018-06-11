const TweedentityStore = artifacts.require('./TweedentityStore.sol')
const TweedentityManager = artifacts.require('./TweedentityManager.sol')
const TweedentityClaimer = artifacts.require('./TweedentityClaimer.sol')
const TweedentityRegistry = artifacts.require('./TweedentityRegistry.sol')


contract('TweedentityRegistry', accounts => {

  let manager
  let twitterStore
  let githubStore
  let claimer
  let registry

  before(async () => {
    twitterStore = await TweedentityStore.new()
    githubStore = await TweedentityStore.new()
    manager = await TweedentityManager.new()
    claimer = await TweedentityClaimer.new()

    await twitterStore.setManager(manager.address)
    await twitterStore.setApp('twitter', 1)
    await manager.setAStore('twitter', twitterStore.address)

    await githubStore.setManager(manager.address)
    await githubStore.setApp('github', 2)
    await manager.setAStore('github', githubStore.address)

    await manager.setClaimer(claimer.address)
  })


  beforeEach(async () => {
    registry = await TweedentityRegistry.new()
  })

  it('should set the store for Twitter', async () => {
    await registry.setAStore('twitter', twitterStore.address)
    assert.equal(await registry.getStore('twitter'), twitterStore.address)
  })

  it('should set the store for Github', async () => {
    await registry.setAStore('github', githubStore.address)
    assert.equal(await registry.getStore('github'), githubStore.address)
  })

  it('should set the manager', async () => {
    await registry.setManager(manager.address)
    assert.equal(await registry.manager(), manager.address)
  })

  it('should set the claimer', async () => {
    await registry.setClaimer(claimer.address)
    assert.equal(await registry.claimer(), claimer.address)
  })

  it('should set manager and claimer', async () => {
    await registry.setManagerAndClaimer(manager.address, claimer.address)
    assert.equal(await registry.manager(), manager.address)
    assert.equal(await registry.claimer(), claimer.address)
  })

  it('should set all and be ready', async() => {
    await registry.setAStore('twitter', twitterStore.address)
    await registry.setAStore('github', githubStore.address)
    await registry.setManagerAndClaimer(manager.address, claimer.address)
    assert.isTrue(await registry.isReady())
  })

  it('should set all and be ready', async() => {
    await registry.setAStore('twitter', twitterStore.address)
    await registry.setAStore('github', githubStore.address)
    await registry.setManagerAndClaimer(manager.address, claimer.address)
    assert.isTrue(await registry.isReady())
  })

  it('should set all but be not ready because manager is paused', async() => {
    await registry.setAStore('twitter', twitterStore.address)
    await registry.setAStore('github', githubStore.address)
    await registry.setManagerAndClaimer(manager.address, claimer.address)
    await manager.pause()
    assert.isFalse(await registry.isReady())
  })


})
