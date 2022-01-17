pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Token is Ownable, ERC20, ERC20Burnable {

  mapping(address => bool) public whitelist;
  mapping(address => bool) public blacklist;

  address private minter;
  address private vaultAddress;
  uint256 private percentFee = 5;

  constructor() ERC20("MyTestToken", "MTT") {
    _mint(msg.sender, 1000);
    addToWhiteList(msg.sender);
  }

  event Mint(address _from, uint256 amount);
  event TransferFee(address _from, uint256 amount);
  event AddToWhiteList(address _addr);
  event AddToBlackList(address _addr);
  event RemoveFromWhiteList(address _addr);
  event RemoveFromBlackList(address _addr);

  function setVaultAddress(address _addr) public onlyOwner {
    vaultAddress = _addr;
    addToWhiteList(_addr);
  }

  function setPercentFee(uint256 _percent) public onlyOwner {
    percentFee = _percent;
  }

  function setMinter(address _addr) public onlyOwner {
    require(minter != _addr, "This account is already the minter");
    minter = _addr;
  }

  function mint(uint256 _amount) public {
    require(msg.sender == minter, "You have no access for this action");
    _mint(msg.sender, _amount);
    emit Mint(msg.sender, _amount);
  }

  function addToWhiteList(address _addr) public onlyOwner {
    if (blacklist[_addr]) {
      removeFromBlackList(_addr);
    }
    whitelist[_addr] = true;
    emit AddToWhiteList(_addr);
  }

  function removeFromWhiteList(address _addr) public onlyOwner {
    delete whitelist[_addr];
    emit RemoveFromWhiteList(_addr);
  }

  function removeFromBlackList(address _addr) public onlyOwner {
    delete blacklist[_addr];
    emit RemoveFromBlackList(_addr);
  }

  function addToBlackList(address _addr) public onlyOwner {
    if (whitelist[_addr]) {
      removeFromWhiteList(_addr);
    }
    blacklist[_addr] = true;
    emit AddToBlackList(_addr);
  }

  function _transfer(
        address sender,
        address recipient,
        uint256 amount
  ) internal override {
    require(!blacklist[sender], "Sender is in the blacklist");
    if (whitelist[sender]) {
      super._transfer(sender, recipient, amount);
    } else {
      uint256 fee = countFee(amount);
      super._transfer(sender, recipient, (amount - fee));
      super._transfer(sender, vaultAddress, fee);
      emit TransferFee(sender, fee);
    }
  }

  function countFee(uint256 _amount) private view returns(uint256) {
    uint256 fee = _amount * percentFee / 100;
    return fee;
  }
}
