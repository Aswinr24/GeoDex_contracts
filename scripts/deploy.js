async function main() {
  const [deployer] = await ethers.getSigners()

  console.log('Deploying contracts with the account:', deployer.address)

  const LandRegistry = await ethers.getContractFactory('LandRegistry')
  const landRegistry = await LandRegistry.deploy()

  console.log(
    'LandRegistry contract deployed to:',
    await landRegistry.getAddress()
  )

  const LandNFT = await ethers.getContractFactory('LandNFT')
  const landNFT = await LandNFT.deploy()

  console.log('LandNFT contract deployed to:', await landNFT.getAddress())
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
