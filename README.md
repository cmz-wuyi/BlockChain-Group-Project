
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



## 5. Getting Started (Local Development)


Please refer to the README.md files in the crowdfunding-platform folder and the crowdfunding-app folder.


## 6. Security & Known Issues



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



## 7. License



This project is licensed under the MIT License.
