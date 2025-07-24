// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title TestVulnerable
 * @dev Test contract with intentional vulnerabilities for pipeline testing
 */
contract TestVulnerable {
    mapping(address => uint256) public balances;
    address public immutable owner;
    bool private locked;
    
    constructor() {
        owner = msg.sender;
    }
    
    // Vulnerable to reentrancy attack
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // External call before state change - VULNERABLE!
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        // State change after external call - REENTRANCY RISK!
        balances[msg.sender] -= amount;
    }
    
    // Missing access control - VULNERABLE!
    function emergencyWithdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    // Unsafe external call - VULNERABLE!
    function proxyCall(address target, bytes calldata data) external returns (bytes memory) {
        (bool success, bytes memory result) = target.call(data);
        require(success, "Call failed");
        return result;
    }
    
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    
    receive() external payable {
        deposit();
    }
}
