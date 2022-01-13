const { expect } = require("chai");
require('dotenv').config();

describe("Token contract", function () {

  let Token;
  let hardhatToken;
  let owner;
  let alice;
  let bob;

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    Token = await ethers.getContractFactory("Token");
    [owner, alice, bob] = await ethers.getSigners();

    hardhatToken = await Token.deploy(process.env.WITHDRAW_PASSWORD);
  });

  it("Deployment should assign the total supply of tokens to the owner", async function () {
    const ownerBalance = await hardhatToken.balanceOf(owner.address);
    expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
  });

  it("Should allow owner to set minter", async function () {
    const tokensToMint = 1000;
    const initialTokens = await hardhatToken.totalSupply();
    await hardhatToken.setMinter(alice.address);
    await hardhatToken.connect(alice).mint(tokensToMint);

    expect(await hardhatToken.totalSupply()).to.equal(tokensToMint + parseInt(initialTokens));
  });

  it("Should dissallow not owner to set minter", async function () {
    await expect(hardhatToken.connect(alice).setMinter(alice.address))
      .to
      .revertedWith("VM Exception while processing transaction: reverted with reason string 'Ownable: caller is not the owner'")
  });

  it("Should dissallow not minter to make mint", async function () {
    await expect(hardhatToken.connect(bob).mint(1000))
      .to
      .revertedWith("VM Exception while processing transaction: reverted with reason string 'You have no access for this action'")
  });

  it("Should dissallow not owner to add to whitelist", async function () {
    await expect(hardhatToken.connect(bob).addToWhiteList(alice.address))
      .to
      .revertedWith("VM Exception while processing transaction: reverted with reason string 'Ownable: caller is not the owner'")
  });

  it("Should allow owner to add accounts to whitelist", async function () {
    await hardhatToken.addToWhiteList(alice.address);
    await hardhatToken.addToWhiteList(bob.address);
    const res_1 = await hardhatToken.whitelist(alice.address);
    const res_2 = await hardhatToken.whitelist(bob.address);
    expect(JSON.stringify([res_1, res_2])).to.equal(JSON.stringify([true, true]));
  });

  it("Should transfer token to another address without fee", async function () {
    await hardhatToken.makeTransfer(alice.address, 500);
    const aliceBalance = await hardhatToken.balanceOf(alice.address)
    const ownerBalance = await hardhatToken.balanceOf(owner.address)
    expect(aliceBalance).to.equal(500);
    expect(ownerBalance).to.equal(500);
  });

  // finish it
  it("Should transfer token to another address with fee", async function () {
    Vault = await ethers.getContractFactory("Vault");
    hardhatVault = await Vault.deploy(hardhatToken.address);

    await hardhatToken.setVaultAddress(hardhatVault.address)
    await hardhatToken.makeTransfer(alice.address, 500);
    await hardhatToken.connect(alice).makeTransfer(bob.address, 500);
    const aliceBalance = await hardhatToken.balanceOf(alice.address)
    const bobBalance = await hardhatToken.balanceOf(bob.address)
    await hardhatVault.vaultWithdraw(process.env.WITHDRAW_PASSWORD)
    const ownerBalance = await hardhatToken.balanceOf(owner.address)
    //expect(aliceBalance).to.equal(500);
    //expect(ownerBalance).to.equal(500);
    console.log(aliceBalance)
    console.log(bobBalance)
    console.log(ownerBalance)
  });

});
