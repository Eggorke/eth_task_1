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

  event MintEvent(address _from, uint256 amount);
  event TrasferFeeEvent(address _from, uint256 amount);
  event AddToWhiteListEvent(address _addr);
  event AddToBlackListEvent(address _addr);
  event RemoveFromWhiteListEvent(address _addr);
  event RemoveFromBlackListEvent(address _addr);

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
    emit MintEvent(msg.sender, _amount);
  }

  function transfer(address _to, uint256 _amount) override public returns(bool) {
    require(!blacklist[msg.sender], "Sender is in the blacklist");
    if (whitelist[msg.sender]) {
      _transfer(msg.sender, _to, _amount);
    } else {
      uint256 fee = countFee(_amount);
      _transfer(msg.sender, _to, (_amount - fee));
      _transferFee(msg.sender, fee);
    }
    return true;
  }

  function _transferFee(address _from, uint256 _fee) private {
    _transfer(_from, vaultAddress, _fee);
    emit TrasferFeeEvent(_from, _fee);
  }

  function countFee(uint256 _amount) private view returns(uint256) {
    uint256 fee = _amount * percentFee / 100;
    return fee;
  }


  // Did this function to collect fees if _from account is not in da blacklist.
  // But don't know what to do with inherited transferFrom() method, it is still open, and potentially it could be called without paying fee.
  function makeTransferFrom(address _from, address _to, uint256 _amount) public {
    require(!blacklist[_from], "Sender is in the blacklist");
    if (whitelist[_from]) {
      transferFrom(_from, _to, _amount);
    } else {
      uint256 fee = countFee(_amount);
      bool success = transferFrom(_from, _to, (_amount - fee));
      if (success) {
        _transferFee(_from, fee);
      }
    }
  }


  function addToWhiteList(address _addr) public onlyOwner {
    if (blacklist[_addr]) {
      removeFromBlackList(_addr);
    }
    whitelist[_addr] = true;
    emit AddToWhiteListEvent(_addr);
  }

  function removeFromWhiteList(address _addr) public onlyOwner {
    delete whitelist[_addr];
    // Looks like event will call even if we try to remove user which is not in white list. Maybe it needs to add require or index to Event.
    emit RemoveFromWhiteListEvent(_addr);
  }

  function removeFromBlackList(address _addr) public onlyOwner {
    delete blacklist[_addr];
    emit RemoveFromBlackListEvent(_addr);
  }

  function addToBlackList(address _addr) public onlyOwner {
    if (whitelist[_addr]) {
      removeFromWhiteList(_addr);
    }
    blacklist[_addr] = true;
    emit AddToBlackListEvent(_addr);
  }
}
