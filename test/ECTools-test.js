const assertRevert = require('./helpers/assertRevert')

const ECTools = artifacts.require('./ECTools.sol')

const fixtures = require('./fixtures')
const signature = fixtures.tweets[0].signature

function logValue(...x) {
  for (let i = 0; i < x.length; i++) {
    console.log(x[i].valueOf())
  }
}


contract('ECTools', accounts => {

  return

  let ectools
  let message

  const hashMessage = require('./helpers/hashMessage')(web3)

  before(async () => {
    ectools = await ECTools.new()

  })

  it('should hash a plain message', async () => {

    assert.equal(await ectools.toEthereumSignedMessage(signature.msg), hashMessage(signature.msg))

  })

  it('should verify if a message has been signed by the address', async () => {

    assert.isTrue(await ectools.isSignedBy(message, signature.sig, signature.address))

  })

  it('should convert a uint to string', async () => {
    const uint = 48
    assert.equal(await ectools.uintToString(uint), '48')
  })

  it('should return a substring', async () => {
    assert.equal(await ectools.substring('example', 2, 4), 'am')
  })



  it('should convert an hexstring to bytes', async () => {

    const hexstr = signature.sig.substring(2)

    assert.equal(await ectools.hexstrToBytes(hexstr), '0x' + hexstr.toLowerCase())

  })

  it('should revert if string is not an hexstring', async () => {

    await assertRevert(ectools.hexstrToBytes('x8SYhw5'))

  })

  it('should revert if the hexstring`s length is odd', async () => {

    await assertRevert(ectools.hexstrToBytes('aabbccd'))

  })

  it('should parse an hex char and return the correspondent integer', async () => {

    assert.equal(await ectools.parseInt16Char('a'), 10)
    assert.equal(await ectools.parseInt16Char('3'), 3)
    assert.equal(await ectools.parseInt16Char('B'), 11)

  })

  it('should revert if the char is not in [0-9a-fA-F]', async () => {

    await assertRevert(ectools.parseInt16Char('G'))
  })

  it('should convert a uint to bytes32', async () => {

    assert.equal(await ectools.uintToBytes32(32), '0x0000000000000000000000000000000000000000000000000000000000000020')

  })

})
