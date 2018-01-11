module.exports = {
  networks: {
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*',
      gas: 6000000
    },
    private: {
      host: 'localhost',
      port: 8546,
      network_id: '11',
      gas: 2500000
    },
    kovan: {
      network_id: 42,
      host: 'localhost',
      port: 8545,
      gas: 2900000
    }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
}