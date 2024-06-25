async function main() {
  const [deployer] = await ethers.getSigners()

  console.log('Deploying contracts with the account:', deployer.address)
  //console.log('Account balance:', (await deployer.getBalance()).toString())

  const LandRegistry = await ethers.getContractFactory('LandRegistry')
  const landRegistry = await LandRegistry.deploy()

  console.log(
    'LandRegistry contract deployed to:',
    await landRegistry.getAddress()
  )
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
