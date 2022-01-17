pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface TokenInterface {
  function balanceOf(address _addr) external returns(uint256);
  function transfer(address _to, uint256 _amount) external returns(bool);
}

contract Vault is Ownable {
  address private withdrawAddress;
  address private tokenAddress;
  IERC20 private _token;

  constructor(address _tokenAddr) {
    withdrawAddress = msg.sender;
    tokenAddress = _tokenAddr;
    _token = IERC20(tokenAddress);
  }

  event WithdrawEvent(address _to, uint256 _amount);

  function withdraw() public onlyOwner {
    uint256 balance = _token.balanceOf(address(this));
    _token.transfer(withdrawAddress, balance);
    emit WithdrawEvent(withdrawAddress, balance);
  }


  function setWithdrawAddress(address _addr) public onlyOwner {
    withdrawAddress = _addr;
  }

  function setTokenAddress(address _addr) public onlyOwner {
    tokenAddress = _addr;
    _token = IERC20(tokenAddress);
  }
}
