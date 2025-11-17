
# Web3 Decentralized Crowdfunding Platform



This project is a decentralized crowdfunding platform (dApp) built on the blockchain. It aims to solve the core pain points of traditional Web2 platforms (like Kickstarter), such as low transparency, high platform fees, and long settlement periods ().

------



## 1. Problem Statement



Traditional crowdfunding platforms act as centralized intermediaries, controlling funds and data. This project aims to build a trustless, transparent, and efficient system using smart contracts to achieve:

- **Full Transparency:** All fundraising and fund flows are publicly verifiable on the blockchain ().
- **Automated Settlement:** Smart contracts automatically execute withdrawal (on success) and refund (on failure) logic, eliminating human intervention and delays ().
- **Lower Costs:** Eliminating high intermediary platform fees.
- **Decentralization:** Anyone can permissionlessly launch a crowdfunding campaign ().



## 2. Core Features



- **Create Campaigns:** Users can create new crowdfunding campaigns with funding goals set in **USD** ().
- **Browse Campaigns:** The homepage displays all active campaigns on the platform ().
- **Personal Dashboard:** Users can view all campaigns they have personally created ().
- **Tiered Funding:** Creators can set up different funding tiers, and backers can fund a specific tier ().
- **Automated State Machine:** The contract automatically determines the campaign state (Active, Successful, Failed) based on the `deadline` and `goal` ().
- **Secure Withdrawals:** Only the project `owner` can withdraw funds after a campaign is successful ().
- **Automatic Refunds:** If a campaign fails, any backer can call `refund` to retrieve their own funds ().



## 3. Tech Stack



| **Category**           | **Technology**          | **Description**                                              |
| ---------------------- | ----------------------- | ------------------------------------------------------------ |
| **Smart Contracts**    | Solidity ^0.8.0         | Used to write the core business logic ().                    |
| **Contract Framework** | Foundry                 | Used for compiling, testing, and deploying contracts ().     |
| **Frontend Framework** | Next.js 15 (App Router) | For building the high-performance dApp user interface ().    |
| **Web3 Library**       | thirdweb SDK v5         | Greatly simplifies wallet connection and contract read/writes (). |
| **UI Library**         | TailwindCSS             | For rapid, modern UI development ().                         |
| **Infrastructure**     | Sepolia Testnet         | The EVM-compatible network for deployment and testing (11).  |
| **Oracle**             | Chainlink (ETH/USD)     | Used to fetch real-time ETH/USD prices for USD-denominated goals (). |



## 4. Architecture



The project follows a "backend/frontend" split between on-chain contracts and an off-chain application ().



### On-Chain Contracts (`crowdfunding-platform`)



We implemented the **Factory Pattern** () for decentralization and scalability:

1. **`CrowdfundingFactory.sol` (Factory Contract):**
   - Acts as a "registry" whose sole purpose is to deploy and track new campaigns.
   - `createCampaign`: Deploys a new `Crowdfunding` contract instance.
   - `getAllCampaigns` / `getUserCampaigns`: Maintains lists of all campaigns, providing a data source for the dApp ().
2. **`Crowdfunding.sol` (Campaign Instance Contract):**
   - Each campaign is a separate instance of this contract, with its **own isolated data and fund pool**.
   - `fund()`: A `payable` function to receive ETH from backers ().
   - `withdraw()`: An `onlyOwner` function to extract funds when `state == Successful` ().
   - `refund()`: A `public` function allowing backers to reclaim funds when `state == Failed` ().
   - `checkAndUpdateCampaignState()`: An internal state machine to auto-update the campaign's status ().



### Off-Chain dApp (`crowdfunding-app`)



The dApp is the user interface for interacting with the smart contracts:

1. **Chainlink Integration (`hooks/useEthUsdPrice.tsx`):**
   - The dApp allows users to input goals in USD ().
   - This hook calls the Chainlink Price Feed Oracle to get the ETH/USD rate ().
   - When submitting a transaction (like `createCampaign`), the dApp converts the USD amount to ETH (Wei) before sending it to the contract ().
2. **Thirdweb SDK v5:**
   - The app is wrapped in `<ThirdwebProvider>` to provide Web3 context ().
   - It uses the `useReadContract` hook for real-time data fetching from the chain (e.g., `getAllCampaigns`).
   - It uses the `TransactionButton` component for all write operations (e.g., `fund`), which simplifies transaction state management ().


## 5. Project Directory Structure

This project is organized as a monorepo containing both the smart contract development environment and the frontend application.

### 📂 `crowdfunding-platform` (Smart Contracts)

The Foundry-based environment for contract development, testing, and deployment.

- **`src/`**: Contains the Solidity smart contracts.
  - **`CrowdfundingFactory.sol`**: The factory contract implementing the registry pattern to deploy and track campaigns.
  - **`Crowdfunding.sol`**: The core logic for individual crowdfunding campaigns, handling funds, states, and refunds.
- **`test/`**: Foundry test suites (`.t.sol`) ensuring contract security and logic correctness.
- **`foundry.toml`**: Configuration file for the Foundry toolkit (remappings, compiler settings, etc.).



### 📂 `crowdfunding-app` (Frontend dApp)

The Next.js application that interacts with the deployed contracts using the thirdweb SDK.

- **`src/app/`**: Utilizes the Next.js App Router for navigation.
  - **`page.tsx`**: The landing page displaying all active campaigns.
  - **`dashboard/[walletAddress]/`**: Personalized dashboard for campaign creators/page.tsx].
  - **`campaign/[campaignAddress]/`**: Dynamic route for viewing individual campaign details and funding them/page.tsx].
- **`src/components/`**: Reusable UI components.
  - **`Navbar.tsx`**: Handles wallet connection and navigation.
  - **`CampaignCard.tsx`**: Displays campaign summaries (goal, deadline, raised amount).
- **`src/hooks/`**: Custom Web3 hooks.
  - **`useEthUsdPrice.tsx`**: Integrates Chainlink Oracle to convert USD goals to ETH.
- **`src/constants/`**: Stores ABI files and contract addresses required for frontend interaction.



### 📂 `contracts`

Contains the core Solidity smart contract source code, serving as the single source of truth for the project's business logic.

- **`CrowdfundingFactory.sol`**: The factory contract implementing the registry pattern to deploy and track campaigns.
- **`Crowdfunding.sol`**: The core logic for individual crowdfunding campaigns, handling funds, states, tiers, and refunds.



### 📂 `test-unit`

Contains a comprehensive suite of modular unit tests (`.t.sol`) ensuring the security and correctness of specific contract features.

- **`CampaignCreationTest.t.sol`**: Validates the entire lifecycle of campaign creation, including factory deployment and data storage verification.
- **`FundTest.t.sol`**: Tests the funding mechanism, ensuring backers can correctly contribute to tiers.
- **`WithdrawTest.t.sol`**: Secures the withdrawal process, ensuring only owners can withdraw from successful campaigns.
- **`RefundTest.t.sol`**: Verifies that backers can retrieve their funds if a campaign fails.
- **`PauseTest.t.sol`**: Checks the emergency pause functionality for contract security.


## 6. Getting Started (Local Development)


Please refer to the README.md files in the crowdfunding-platform folder and the crowdfunding-app folder.


## 7. Security & Known Issues



Security Considerations (Assignment R4 16)



- **Re-entrancy Guard:** The `refund` function in `Crowdfunding.sol` follows the "Checks-Effects-Interactions" pattern, zeroing the user's `totalContribution` *before* the `transfer`, which effectively prevents re-entrancy attacks ().
- **Access Control:** Critical functions (like `withdraw`, `addTier`) are protected with `onlyOwner` modifiers ().
- **State Machine Protection:** The `campaignOpen` modifier and `state` checks ensure that fund operations (`fund`, `withdraw`, `refund`) can only be executed in the correct state ().
- **Gas Optimization:** The `removeTier` function uses an efficient array deletion technique (swapping with the last element and popping) to save gas ().



### Known Issue & Design Conflict



***Important:\*** As noted in the technical documentation, the frontend's "Create Campaign" modal (`dashboard/.../page.tsx`) currently uses thirdweb's `deployPublishedContract` function ().

- **Problem:** This **bypasses** our `CrowdfundingFactory.sol` contract.
- **Consequence:** Campaigns created this way are "orphaned" and are not tracked by the factory. Therefore, newly created campaigns will **not** appear on the homepage or the user's dashboard ().
- **Recommended Fix:** The `CreateCampaignModal` component should be refactored to call the `createCampaign` function on the deployed `CrowdfundingFactory` contract, which is the architecturally correct implementation ().



## 8. License



This project is licensed under the MIT License.
