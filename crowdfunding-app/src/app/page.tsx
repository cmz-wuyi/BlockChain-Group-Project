'use client';
import { useReadContract } from "thirdweb/react";
import { client } from "./client";
import { sepolia } from "thirdweb/chains";
import { getContract } from "thirdweb";
import { CROWDFUNDING_FACTORY } from "./constants/contracts";
import { CampaignCard } from "./components/CampaignCard";
import { CROWDFUNDING_FACTORY_ABI } from "@/app/constants/CrowdfundingFactoryABI"; 
import { useEthUsdPrice } from "./hooks/useEthUsdPrice";

export default function Home() {
  // Get CrowdfundingFactory contract
  const contract = getContract({
    client: client,
    chain: sepolia,
    address: CROWDFUNDING_FACTORY,
    abi: CROWDFUNDING_FACTORY_ABI,
  });

  const { price: ethPrice, isLoadingPrice } = useEthUsdPrice();

  const {data: campaigns, isPending: isPendingCampaigns, refetch: refetchCampaigns } = useReadContract({
    contract: contract,
    method: 
    "getAllCampaigns",
    // "function getAllCampaigns() view returns ((address campaignAddress, address owner, string name)[])",
    params: []
  });

  return (
    <main className="mx-auto max-w-7xl px-4 mt-4 sm:px-6 lg:px-8">
      <div className="py-10">
        <h1 className="text-4xl font-bold mb-4">Campaigns:</h1>
        <div className="grid grid-cols-3 gap-4">
          {/* A. Handle loading state first */}
          {isPendingCampaigns && (
            <p>Loading campaigns...</p>
          )}

          {/* B. Handle "no campaigns" state after loading */}
          {!isPendingCampaigns && (!campaigns || campaigns.length === 0) && (
            <p>No Campaigns</p>
          )}

          {/* C. Handle "campaigns available" state after loading */}
          {!isPendingCampaigns && campaigns && campaigns.length > 0 && (
            campaigns.map((campaign) => (
              // You can use CampaignCard now, or test with a simple div
              <CampaignCard
                key={campaign.campaignAddress}
                campaignAddress={campaign.campaignAddress}
                ethPrice={ethPrice}
                isLoadingPrice={isLoadingPrice}
              />
              /* // Or use your own simple div for testing:
              <div key={campaign.campaignAddress}>
                 <p>Campaign: {campaign.name}</p>
                 <p>Address: {campaign.campaignAddress}</p>
              </div>
              */
            ))
          )}
        </div>
      </div>
    </main>
  );
}