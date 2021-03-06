const { expect } = require("chai");
require('dotenv').config();

describe("Token contract", function () {

  let Token;
  let hardhatToken;
  let owner;
  let alice;
  let bob;
  let Vault;
  let hardhatVault;

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    Token = await ethers.getContractFactory("Token");
    [owner, alice, bob] = await ethers.getSigners();

    hardhatToken = await Token.deploy();

    Vault = await ethers.getContractFactory("Vault");
    hardhatVault = await Vault.deploy(hardhatToken.address);
    await hardhatToken.setVaultAddress(hardhatVault.address)
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
    await hardhatToken.transfer(alice.address, 500);
    const aliceBalance = await hardhatToken.balanceOf(alice.address)
    const ownerBalance = await hardhatToken.balanceOf(owner.address)
    expect(aliceBalance).to.equal(500);
    expect(ownerBalance).to.equal(500);
  });

  it("Should transfer token to another address with fee", async function () {
    await hardhatToken.transfer(alice.address, 500);
    await hardhatToken.connect(alice).transfer(bob.address, 500);

    const ownerBalance = await hardhatToken.balanceOf(owner.address);
    const aliceBalance = await hardhatToken.balanceOf(alice.address);
    const bobBalance = await hardhatToken.balanceOf(bob.address);
    const vaultBalance = await hardhatToken.balanceOf(hardhatVault.address);

    expect(aliceBalance).to.equal(0);
    expect(ownerBalance).to.equal(500);
    expect(bobBalance).to.equal(475);
    expect(vaultBalance).to.equal(25);
  });

  it("Should dissalow user from blacklist to make transfer", async function () {
    await hardhatToken.addToBlackList(alice.address);
    await hardhatToken.transfer(alice.address, 200);
    await expect(hardhatToken.connect(alice).transfer(bob.address, 100))
      .to
      .revertedWith("VM Exception while processing transaction: reverted with reason string 'Sender is in the blacklist'")
  });

  it("Should allow owner to make withdraw", async function () {
    await hardhatToken.transfer(alice.address, 500);
    await hardhatToken.connect(alice).transfer(bob.address, 500);
    const ownerBalanceBeforeWithdraw = await hardhatToken.balanceOf(owner.address);
    expect(ownerBalanceBeforeWithdraw).to.equal(500);
    await hardhatVault.withdraw();
    const ownerBalanceAfterWithdraw = await hardhatToken.balanceOf(owner.address);
    expect(ownerBalanceAfterWithdraw).to.equal(525);
  });

  it("Should allow user to call transferFrom with fee", async function () {
    await hardhatToken.transfer(alice.address, 500);
    await expect(hardhatToken.transferFrom(alice.address, bob.address, 100))
      .to
      .revertedWith("VM Exception while processing transaction: reverted with reason string 'ERC20: transfer amount exceeds allowance'");
    await hardhatToken.connect(alice).approve(bob.address, 200);
    await hardhatToken.connect(bob).transferFrom(alice.address, bob.address, 100);
    const bobBalance = await hardhatToken.balanceOf(bob.address);
    expect(bobBalance).to.equal(95);
  });

  it("Should allow user to call transferFrom without fee", async function () {
    await hardhatToken.transfer(alice.address, 500);
    await hardhatToken.addToWhiteList(alice.address);
    await hardhatToken.connect(alice).approve(bob.address, 200);
    await hardhatToken.connect(bob).transferFrom(alice.address, bob.address, 100);
    const bobBalance = await hardhatToken.balanceOf(bob.address);
    expect(bobBalance).to.equal(100);
  });

  it("Should dissalow user to call transfer from if sender is in blacklist", async function () {
    await hardhatToken.transfer(alice.address, 500);
    await hardhatToken.addToBlackList(alice.address);
    await hardhatToken.connect(alice).approve(bob.address, 200);
    await expect(hardhatToken.connect(bob).transferFrom(alice.address, bob.address, 100))
      .to
      .revertedWith("VM Exception while processing transaction: reverted with reason string 'Sender is in the blacklist'");
  });

  it("Should allow user to call burn", async function () {

    await hardhatToken.transfer(alice.address, 500);

    await hardhatToken.connect(alice).burn(300);
    const aliceBalance = await hardhatToken.balanceOf(alice.address);
    expect(aliceBalance).to.equal(200);

    // try to burn exceed amount of tokens
    await expect(hardhatToken.connect(alice).burn(300))
      .to
      .revertedWith("VM Exception while processing transaction: reverted with reason string 'ERC20: burn amount exceeds balance'");
  });

  it("Should allow user to call burnFrom", async function () {
    await hardhatToken.transfer(alice.address, 500);
    await expect(hardhatToken.connect(bob).burnFrom(alice.address, 500))
      .to
      .revertedWith("VM Exception while processing transaction: reverted with reason string 'ERC20: burn amount exceeds allowance'");
    await hardhatToken.connect(alice).approve(bob.address, 400);
    await hardhatToken.connect(bob).burnFrom(alice.address, 200);
    const allowance = await hardhatToken.allowance(alice.address, bob.address);
    expect(allowance).to.equal(200);
    const aliceBalance = await hardhatToken.balanceOf(alice.address);
    expect(aliceBalance).to.equal(300)
  });
});
