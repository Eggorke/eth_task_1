pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

interface TokenInterface {
  function withdraw(string memory _password, address _to) external;
}

contract Vault is Ownable {
  address private withdrawAddress;
  address private tokenAddress;

  constructor(address _tokenAddr) {
    withdrawAddress = msg.sender;
    tokenAddress = _tokenAddr;
  }

  function vaultWithdraw(string memory _password) public {
    TokenInterface(tokenAddress).withdraw(_password, withdrawAddress);
  }

  function setWithdrawAddress(address _addr) public onlyOwner {
    withdrawAddress = _addr;
  }

  function setTokenAddress(address _addr) public onlyOwner {
    tokenAddress = _addr;
  }
}
