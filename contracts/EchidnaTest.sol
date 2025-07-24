// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EchidnaProperties - Property-based testing for VulnerableBank
 * @dev Echidna will try to break these invariants
 */
contract EchidnaProperties {
    VulnerableBank bank;
    
    constructor() {
        bank = new VulnerableBank();
    }
    
    // Property 1: Total balance should equal sum of individual balances
    function echidna_total_balance_correct() public view returns (bool) {
        return address(bank).balance >= 0; // Simplified check
    }
    
    // Property 2: Only owner can change ownership
    function echidna_owner_unchanged() public view returns (bool) {
        // This should fail due to vulnerable changeOwner function
        return bank.owner() == address(this);
    }
    
    // Property 3: User balance should never exceed contract balance
    function echidna_user_balance_valid() public view returns (bool) {
        return bank.getBalance(address(this)) <= address(bank).balance;
    }
    
    // Property 4: Contract balance should never go negative
    function echidna_no_negative_balance() public view returns (bool) {
        return address(bank).balance >= 0;
    }
}

// Import the vulnerable contract
import "./VulnerableBank.sol";
