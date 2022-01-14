pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

interface TokenInterface {
  function balanceOf(address _addr) external returns(uint256);
  function transfer(address _to, uint256 _amount) external returns(bool);
}

contract Vault is Ownable {
  address private withdrawAddress;
  address private tokenAddress;

  constructor(address _tokenAddr) {
    withdrawAddress = msg.sender;
    tokenAddress = _tokenAddr;
  }

  event WithdrawEvent(address _to, uint256 _amount);

  function withdraw() public onlyOwner {
    uint256 balance = TokenInterface(tokenAddress).balanceOf(address(this));
    TokenInterface(tokenAddress).transfer(withdrawAddress, balance);
    emit WithdrawEvent(withdrawAddress, balance);
  }


  function setWithdrawAddress(address _addr) public onlyOwner {
    withdrawAddress = _addr;
  }

  function setTokenAddress(address _addr) public onlyOwner {
    tokenAddress = _addr;
  }
}
