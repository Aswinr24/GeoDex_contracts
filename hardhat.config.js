require('@nomicfoundation/hardhat-toolbox')
require('dotenv').config()

/** @type import('hardhat/config').HardhatUserConfig */

const API_KEY = `${process.env.API_KEY}`
const PRIVATE_KEY = process.env.PRIVATE_KEY

module.exports = {
  solidity: '0.8.20',
  defaultNetwork: 'zkEVMTestnet',
  networks: {
    hardhat: {},
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${API_KEY}`,
      accounts: [`0x${PRIVATE_KEY}`],
    },
    zkEVMTestnet: {
      url: `https://polygonzkevm-cardona.g.alchemy.com/v2/${API_KEY}`,
      accounts: [`0x${PRIVATE_KEY}`],
    },
  },
}
