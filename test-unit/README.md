# Unit Testing Suite

This directory contains the comprehensive unit test suite for the **Crowdfunding Platform** smart contracts. The tests are built using the **Foundry** development framework to ensure the security, logic correctness, and state consistency of the application.



## 🛠 Testing Framework

- **Framework**: [Foundry](https://book.getfoundry.sh/) (Forge)
- **Strategy**: Modular unit testing focusing on factory patterns, business logic, access control, and state machine transitions.



## 📂 Test Coverage

The test suite is divided into modular files, each targeting specific functional areas of the protocol:



### 1. `CampaignCreationTest.t.sol`

Tests the **Factory Pattern** and campaign initialization logic.

- Verifies correct deployment of the `CrowdfundingFactory`.
- Validates individual campaign creation parameters.
- Ensures isolation between campaigns created by different users.
- Checks data persistence and storage integrity.



### 2. `FundTest.t.sol`

Validates the core **Funding Logic** and tier mechanisms.

- **Happy Path**: Successful funding scenarios.
- **Edge Cases**: Insufficient funds, invalid tier indexes.
- **State Restrictions**: Reverts when the campaign is paused or ended.
- **Concurrency**: Handles multiple users and multiple contributions from the same user.



### 3. `WithdrawTest.t.sol`

Focuses on **Access Control** and fund security for project owners.

- Ensures only the `owner` can withdraw.
- Verifies withdrawals fail if the campaign goal is not met (State: `Active` or `Failed`).
- Prevents withdrawals when the contract has no balance.



### 4. `RefundTest.t.sol`

Tests the protection mechanism for backers (Pull Payment Pattern).

- Allows backers to claim refunds only when the campaign state is `Failed`.
- Prevents refunds for active campaigns or non-contributors.
- Validates balance updates after multiple users claim refunds.



### 5. `PauseTest.t.sol`

Tests the **Circuit Breaker (Emergency Stop)** functionality.

- Verifies only the `owner` can toggle the paused state.
- Ensures critical actions (funding, withdrawing) are blocked when paused.
- Confirms that refunds can still be processed (or restricted depending on logic) during a pause, ensuring fund safety.



## 🚀 Running Tests

To execute the test suite using Foundry:

Bash

```
# Run all tests
forge test

# Run tests with verbosity (to see logs and traces)
forge test -vvvv

# Check test coverage
forge coverage
```



## 🛡 Security Audit Note

In addition to these unit tests, the contracts have undergone static analysis using **Slither**. The analysis confirmed that the core business logic is secure, with no critical vulnerabilities found in the covered paths.