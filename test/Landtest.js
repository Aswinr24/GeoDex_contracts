const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('LandRegistry', function () {
  let LandRegistry
  let landRegistry
  let owner
  let user1
  let user2
  let govtAuthority

  beforeEach(async function () {
    ;[owner, user1, user2, govtAuthority] = await ethers.getSigners()

    LandRegistry = await ethers.getContractFactory('LandRegistry')
    landRegistry = await LandRegistry.deploy()
  })

  it('Should register a user', async function () {
    await landRegistry
      .connect(user1)
      .registerUser(
        'User One',
        '123456789012',
        'PAN1234',
        '1234567890',
        'user1@example.com'
      )
    const user = await landRegistry.users(user1.address)
    expect(user.name).to.equal('User One')
  })

  it('Should register a government authority', async function () {
    await landRegistry
      .connect(govtAuthority)
      .registerGovtAuthority('GOVT123', 'Authority One', 'Designation One')
    const authority = await landRegistry.govtAuthorities(govtAuthority.address)
    expect(authority.name).to.equal('Authority One')
  })

  it('Should verify a user by a government authority', async function () {
    await landRegistry
      .connect(user1)
      .registerUser(
        'User One',
        '123456789012',
        'PAN1234',
        '1234567890',
        'user1@example.com'
      )
    await landRegistry
      .connect(govtAuthority)
      .registerGovtAuthority('GOVT123', 'Authority One', 'Designation One')
    await landRegistry.connect(govtAuthority).verifyUser(user1.address)
    const user = await landRegistry.users(user1.address)
    expect(user.isUserVerified).to.be.true
  })

  it('Should register land by a verified user', async function () {
    await landRegistry
      .connect(user1)
      .registerUser(
        'User One',
        '123456789012',
        'PAN1234',
        '1234567890',
        'user1@example.com'
      )
    await landRegistry
      .connect(govtAuthority)
      .registerGovtAuthority('GOVT123', 'Authority One', 'Designation One')
    await landRegistry.connect(govtAuthority).verifyUser(user1.address)

    await landRegistry
      .connect(user1)
      .registerLand('PROP123', 100, '123 Street', 1000)
    const land = await landRegistry.lands(1)
    expect(land.propertyId).to.equal('PROP123')
    expect(land.ownerAddress).to.equal(user1.address)
  })

  it('Should list land for sale by the owner', async function () {
    await landRegistry
      .connect(user1)
      .registerUser(
        'User One',
        '123456789012',
        'PAN1234',
        '1234567890',
        'user1@example.com'
      )
    await landRegistry
      .connect(govtAuthority)
      .registerGovtAuthority('GOVT123', 'Authority One', 'Designation One')
    await landRegistry.connect(govtAuthority).verifyUser(user1.address)

    await landRegistry
      .connect(user1)
      .registerLand('PROP123', 100, '123 Street', 1000)
    await landRegistry.connect(user1).setTokenURI(1, 'https://token-uri.com')
    await landRegistry.connect(govtAuthority).verifyLand(1)

    await landRegistry.connect(user1).listLandForSale(1, 2000)
    const land = await landRegistry.lands(1)
    expect(land.isForSale).to.be.true
    expect(land.landPrice).to.equal(2000)
  })

  it('Should allow a verified user to request to buy land', async function () {
    await landRegistry
      .connect(user1)
      .registerUser(
        'User One',
        '123456789012',
        'PAN1234',
        '1234567890',
        'user1@example.com'
      )
    await landRegistry
      .connect(user2)
      .registerUser(
        'User Two',
        '123456789013',
        'PAN5678',
        '0987654321',
        'user2@example.com'
      )
    await landRegistry
      .connect(govtAuthority)
      .registerGovtAuthority('GOVT123', 'Authority One', 'Designation One')
    await landRegistry.connect(govtAuthority).verifyUser(user1.address)
    await landRegistry.connect(govtAuthority).verifyUser(user2.address)

    await landRegistry
      .connect(user1)
      .registerLand('PROP123', 100, '123 Street', 1000)
    await landRegistry.connect(user1).setTokenURI(1, 'https://token-uri.com')
    await landRegistry.connect(govtAuthority).verifyLand(1)

    await landRegistry.connect(user1).listLandForSale(1, 2000)
    await landRegistry.connect(user2).requestToBuyLand(1)

    const buyer = await landRegistry.landToBuyer(1)
    expect(buyer).to.equal(user2.address)
  })

  it('Should allow the land owner to approve the sale', async function () {
    await landRegistry
      .connect(user1)
      .registerUser(
        'User One',
        '123456789012',
        'PAN1234',
        '1234567890',
        'user1@example.com'
      )
    await landRegistry
      .connect(user2)
      .registerUser(
        'User Two',
        '123456789013',
        'PAN5678',
        '0987654321',
        'user2@example.com'
      )
    await landRegistry
      .connect(govtAuthority)
      .registerGovtAuthority('GOVT123', 'Authority One', 'Designation One')
    await landRegistry.connect(govtAuthority).verifyUser(user1.address)
    await landRegistry.connect(govtAuthority).verifyUser(user2.address)

    await landRegistry
      .connect(user1)
      .registerLand('PROP123', 100, '123 Street', 1000)
    await landRegistry.connect(user1).setTokenURI(1, 'https://token-uri.com')
    await landRegistry.connect(govtAuthority).verifyLand(1)

    await landRegistry.connect(user1).listLandForSale(1, 2000)
    await landRegistry.connect(user2).requestToBuyLand(1)
    await landRegistry
      .connect(user1)
      .approveSaleByOwner(1, 'https://proof-url.com')

    const proof = await landRegistry.landTransactionProofs(1)
    expect(proof).to.equal('https://proof-url.com')
  })

  it('Should allow the government authority to approve the sale', async function () {
    await landRegistry
      .connect(user1)
      .registerUser(
        'User One',
        '123456789012',
        'PAN1234',
        '1234567890',
        'user1@example.com'
      )
    await landRegistry
      .connect(user2)
      .registerUser(
        'User Two',
        '123456789013',
        'PAN5678',
        '0987654321',
        'user2@example.com'
      )
    await landRegistry
      .connect(govtAuthority)
      .registerGovtAuthority('GOVT123', 'Authority One', 'Designation One')
    await landRegistry.connect(govtAuthority).verifyUser(user1.address)
    await landRegistry.connect(govtAuthority).verifyUser(user2.address)

    await landRegistry
      .connect(user1)
      .registerLand('PROP123', 100, '123 Street', 1000)
    await landRegistry.connect(user1).setTokenURI(1, 'https://token-uri.com')
    await landRegistry.connect(govtAuthority).verifyLand(1)

    await landRegistry.connect(user1).listLandForSale(1, 2000)
    await landRegistry.connect(user2).requestToBuyLand(1)
    await landRegistry
      .connect(user1)
      .approveSaleByOwner(1, 'https://proof-url.com')

    await landRegistry.connect(govtAuthority).approveSaleByAuthority(1)

    const land = await landRegistry.lands(1)
    expect(land.ownerAddress).to.equal(user2.address)
    expect(land.isForSale).to.be.false
  })
})
