// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping(address => uint256) public balances;

  uint256 constant public threshold = 1 ether;
  uint256 public deadline = block.timestamp + 72 hours;

  event Stake(address indexed sender, uint256 amount);
  event Withdraw(address indexed sender, uint256 amount);

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier deadlineReached() {
    uint256 timeRemaining = timeLeft();
    require(timeRemaining == 0, "Deadline is not reached yet");
    _;
  }

  modifier deadlineRemaining() {
    uint256 timeRemaining = timeLeft();
    require(timeRemaining > 0, "Deadline is already reached");
    _;
  }

  modifier stakeNotCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "staking process already completed");
    _;
  }

  function stake() public payable deadlineRemaining stakeNotCompleted {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  function withdraw() public deadlineReached stakeNotCompleted {
    require(balances[msg.sender] > 0, "You don't have balance to withdraw");

    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;

    (bool sent, ) = msg.sender.call{value: amount}("");
    require(sent, "Failed to send user balance back to the user");

    
  }

  function execute() public stakeNotCompleted deadlineReached {
    if(address(this).balance >= threshold) {

      exampleExternalContract.complete{value: address(this).balance}();
    }
  }

  function timeLeft() public view returns (uint256 timeleft) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }
}
