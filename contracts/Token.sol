pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Token is Ownable, ERC20, ERC20Burnable {

  mapping(address => bool) public whitelist;
  mapping(address => bool) public blacklist;
  address private minter;
  address private vaultAddress;
  string private withdrawPassword;

  constructor(string memory _withdrawPassword) ERC20("MyTestToken", "MTT") {
    _mint(msg.sender, 1000);
    addToWhiteList(msg.sender);
    withdrawPassword = _withdrawPassword;
  }

  // Add events for everything

  function withdraw(string memory _password, address _to) external {
    require(msg.sender == vaultAddress, "No Access");
    require(keccak256(bytes(_password)) == keccak256(bytes(withdrawPassword)), "Invalid Password");
    _transfer(vaultAddress, _to, balanceOf(vaultAddress));
  }

  function setWithdrawPassword(string memory _str) public onlyOwner {
    withdrawPassword = _str;
  }

  function setVaultAddress(address _addr) public onlyOwner {
    vaultAddress = _addr;
  }

  function setMinter(address _addr) public onlyOwner {
    require(minter != _addr, "This account is already the minter");
    minter = _addr;
  }

  function mint(uint _amount) public {
    require(msg.sender == minter, "You have no access for this action");
    _mint(msg.sender, _amount);
  }

  // запретил вызывать трансфер из родителя
  function transfer() pure public {
    revert("No access to this action");
  }


  function makeTransfer(address _to, uint _amount) public {
    require(!blacklist[msg.sender], "Sender is in the blacklist");
    if (whitelist[msg.sender]) {
      _transfer(msg.sender, _to, _amount);
    } else {
      uint fee = (_amount / 100 * 5);
      _transfer(msg.sender, _to, (_amount - fee));
      _transfer(msg.sender, vaultAddress, fee);
    }
  }


  function makeTransferFrom(address _from, address _to, uint _amount) public {
    require(!blacklist[_from], "Sender is in the blacklist");
    if (whitelist[_from]) {
      transferFrom(_from, _to, _amount);
    } else {
      uint fee = (_amount / 100 * 5);
      bool success = transferFrom(_from, _to, (_amount - fee));
      if (success) {
        _transfer(_from, vaultAddress, fee);
      }
    }
  }


  function addToWhiteList(address _addr) public onlyOwner {
    if (blacklist[_addr]) {
      delete blacklist[_addr];
    }
    whitelist[_addr] = true;
  }

  function removeFromWhiteList(address _addr) public onlyOwner {
    delete whitelist[_addr];
  }

  function removeFromBlackList(address _addr) public onlyOwner {
    delete blacklist[_addr];
  }

  function addToBlackList(address _addr) public onlyOwner {
    if (whitelist[_addr]) {
      delete whitelist[_addr];
    }

    blacklist[_addr] = true;
  }
}
