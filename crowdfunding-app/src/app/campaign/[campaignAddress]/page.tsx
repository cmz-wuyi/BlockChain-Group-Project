'use client';
import { client } from "@/app/client";
import { TierCard } from "@/app/components/TierCard";
import { useParams } from "next/navigation";
import { useState } from "react";
import { getContract, prepareContractCall, ThirdwebContract } from "thirdweb";
import { sepolia } from "thirdweb/chains";
import { lightTheme, TransactionButton, useActiveAccount, useReadContract } from "thirdweb/react";
import { toWei } from "thirdweb/utils";
import { useEthUsdPrice } from "@/app/hooks/useEthUsdPrice";

const fromWei = (
    weiAmount: bigint | undefined | null,
    decimals: number = 18
): string => {
    if (!weiAmount || weiAmount === 0n) {
        return "0";
    }
    const divisor = 10n ** BigInt(decimals);
    const integerPart = (weiAmount / divisor).toString();
    const remainder = weiAmount % divisor;
    if (remainder === 0n) {
        return integerPart;
    }
    const fractionalPart = remainder.toString().padStart(decimals, '0');
    const trimmedFractional = fractionalPart.replace(/0+$/, '');
    return `${integerPart}.${trimmedFractional}`;
};

export default function CampaignPage() {
    // 1. Fetch price at the CampaignPage level
    const { price: ethPrice, isLoadingPrice } = useEthUsdPrice();
    const account = useActiveAccount();
    const { campaignAddress } = useParams();
    const [isEditing, setIsEditing] = useState<boolean>(false);
    const [isModalOpen, setIsModalOpen] = useState<boolean>(false);

    const contract = getContract({
        client: client,
        chain: sepolia,
        address: campaignAddress as string,
    });

    // Name of the campaign
    const { data: name, isLoading: isLoadingName } = useReadContract({
        contract: contract,
        method: "function name() view returns (string)",
        params: [],
    });

    // Description of the campaign
    const { data: description } = useReadContract({ 
        contract, 
        method: "function description() view returns (string)", 
        params: [] 
      });

    // Campaign deadline
    const { data: deadline, isLoading: isLoadingDeadline } = useReadContract({
        contract: contract,
        method: "function deadline() view returns (uint256)",
        params: [],
    });
    // Convert deadline to a date
    const deadlineDate = new Date(parseInt(deadline?.toString() as string) * 1000);
    // Check if deadline has passed
    const hasDeadlinePassed = deadlineDate < new Date();

    // Goal amount of the campaign
    const { data: goal, isLoading: isLoadingGoal } = useReadContract({
        contract: contract,
        method: "function goal() view returns (uint256)",
        params: [],
    });
    
    // Total funded balance of the campaign
    const { data: balance, isLoading: isLoadingBalance } = useReadContract({
        contract: contract,
        method: "function getContractBalance() view returns (uint256)",
        params: [],
    });

    // Calculate the total funded balance percentage
    let balancePercentage: number = 0;
    if (goal && balance && goal > 0n) {
        // Use BigInt for safe calculation
        const percentageBigInt = (balance * 100n) / goal;
        balancePercentage = Number(percentageBigInt); // Convert to Number for display
    }
    if (balancePercentage >= 100) {
        balancePercentage = 100;
    }

    // Get tiers for the campaign
    const { data: tiers, isLoading: isLoadingTiers } = useReadContract({
        contract: contract,
        method: "function getTiers() view returns ((string name, uint256 amount, uint256 backers)[])",
        params: [],
    });

    // Get owner of the campaign
    const { data: owner, isLoading: isLoadingOwner } = useReadContract({
        contract: contract,
        method: "function owner() view returns (address)",
        params: [],
    });

    // Get status of the campaign
    const { data: status } = useReadContract({ 
        contract, 
        method: "function state() view returns (uint8)", 
        params: [] 
      });
      
    const formatWeiToUsd = (wei: bigint | undefined): string => {
        if (!wei || isLoadingPrice || ethPrice === 0) return "$....";
        
        try {
            const ethValueStr = fromWei(wei);
            const ethValue = parseFloat(ethValueStr);
            const usdValue = ethValue * ethPrice;
    
            return usdValue.toLocaleString('en-US', {
                style: 'currency',
                currency: 'USD'
            });
        } catch (error) {
            console.error("Error formatting Wei to USD:", error);
            return "$0.00";
        }
    };  

    return (
        <div className="mx-auto max-w-7xl px-2 mt-4 sm:px-6 lg:px-8">
            <div className="flex flex-row justify-between items-center">
                {!isLoadingName && (
                    <p className="text-4xl font-semibold">{name}</p>
                )}
                {owner === account?.address && (
                    <div className="flex flex-row">
                        {isEditing && (
                            <p className="px-4 py-2 bg-gray-500 text-white rounded-md mr-2">
                                Status:  
                                {status === 0 ? " Active" : 
                                status === 1 ? " Successful" :
                                status === 2 ? " Failed" : "Unknown"}
                            </p>
                        )}
                        <button
                            className="px-4 py-2 bg-blue-500 text-white rounded-md"
                            onClick={() => setIsEditing(!isEditing)}
                        >{isEditing ? "Done" : "Edit"}</button>
                    </div>
                )}
            </div>
            <div className="my-4">
                <p className="text-lg font-semibold">Description:</p>
                <p>{description}</p>
            </div>
            <div className="mb-4">
                <p className="text-lg font-semibold">Deadline</p>
                {!isLoadingDeadline && (
                    <p>{deadlineDate.toDateString()}</p>
                )}
            </div>
            {!isLoadingBalance && (
                <div className="mb-4">
                    <p className="text-lg font-semibold">Campaign Goal: {formatWeiToUsd(goal)}</p>
                    <div className="relative w-full h-6 bg-gray-200 rounded-full dark:bg-gray-700">
                        <div className="h-6 bg-blue-600 rounded-full dark:bg-blue-500 text-right" style={{ width: `${balancePercentage?.toString()}%`}}>
                            <p className="text-white dark:text-white text-xs p-1">{formatWeiToUsd(balance)}</p>
                        </div>
                        <p className="absolute top-0 right-0 text-white dark:text-white text-xs p-1">
                            {balancePercentage >= 100 ? "" : `${balancePercentage?.toString()}%`}
                        </p>
                    </div>
                </div>
                
            )}
            <div>
                <p className="text-lg font-semibold">Tiers:</p>
                <div className="grid grid-cols-3 gap-4">
                    {isLoadingTiers ? (
                        <p >Loading...</p>
                    ) : (
                        tiers && tiers.length > 0 ? (
                            tiers.map((tier, index) => (
                                <TierCard
                                    key={index}
                                    tier={tier}
                                    index={index}
                                    contract={contract}
                                    isEditing={isEditing}
                                    ethPrice={ethPrice}
                                    isLoadingPrice={isLoadingPrice}
                                />
                            ))
                        ) : (
                            !isEditing && (
                                <p>No tiers available</p>
                            )
                        )
                    )}
                    {isEditing && (
                        // Add a button card with text centered in the middle
                        <button
                            className="max-w-sm flex flex-col text-center justify-center items-center font-semibold p-6 bg-blue-500 text-white border border-slate-100 rounded-lg shadow"
                            onClick={() => setIsModalOpen(true)}
                        >+ Add Tier</button>
                    )}
                </div>
            </div>
            
            {isModalOpen && (
                <CreateCampaignModal
                    setIsModalOpen={setIsModalOpen}
                    contract={contract}
                    ethPrice={ethPrice} // <-- Pass price
                    isLoadingPrice={isLoadingPrice} // <-- Pass loading state
                />
            )}
        </div>
    );
}

type CreateTierModalProps = {
    setIsModalOpen: (value: boolean) => void
    contract: ThirdwebContract
    ethPrice: number; // <-- Receive price
    isLoadingPrice: boolean; // <-- Receive loading state
}

const CreateCampaignModal = (
    { setIsModalOpen, contract, ethPrice, isLoadingPrice }: CreateTierModalProps
) => {
    const [tierName, setTierName] = useState<string>("");
    const [tierAmount, setTierAmount] = useState<string>("1");

    return (
        <div className="fixed inset-0 bg-black bg-opacity-75 flex justify-center items-center backdrop-blur-md">
            <div className="w-1/2 bg-slate-100 p-6 rounded-md">
                <div className="flex justify-between items-center mb-4">
                    <p className="text-lg font-semibold">Create a Funding Tier</p>
                    <button
                        className="text-sm px-4 py-2 bg-slate-600 text-white rounded-md"
                        onClick={() => setIsModalOpen(false)}
                    >Close</button>
                </div>
                <div className="flex flex-col">
                    <label>Tier Name:</label>
                    <input 
                        type="text" 
                        value={tierName}
                        onChange={(e) => setTierName(e.target.value)}
                        placeholder="Tier Name"
                        className="mb-4 px-4 py-2 bg-slate-200 rounded-md"
                    />
                    <label>Tier Cost (USD):</label>
                    <input 
                        type="text"
                        value={tierAmount}
                        onChange={(e) => setTierAmount(e.target.value)}
                        className="mb-4 px-4 py-2 bg-slate-200 rounded-md"
                    />
                    <TransactionButton
                        transaction={() => {
                            // --- Conversion Logic ---
                            // 1. Convert USD string input to a number
                            const tierAmountUsd = parseFloat(tierAmount);

                            // 2. Guard Clauses
                            if (isNaN(tierAmountUsd) || tierAmountUsd <= 0) {
                                // Prevent invalid numbers or 0/negative amounts
                                alert("Please enter a valid Tier Cost.");
                                throw new Error("Invalid Tier Cost");
                            }
                            if (!ethPrice || ethPrice === 0) {
                                alert("ETH Price is not available. Cannot calculate transaction.");
                                throw new Error("ETH Price not loaded");
                            }

                            // 3. Calculate the required ETH amount
                            // (USD Tier Amount) / (ETH Price) = ETH Tier Amount
                            const tierAmountEth = tierAmountUsd / ethPrice;

                            // 4. Prepare the contract call
                            return prepareContractCall({
                                contract: contract,
                                method: "function addTier(string _name, uint256 _amount)",
                                // 5. Convert the calculated ETH amount to Wei
                                params: [tierName, toWei(tierAmountEth.toString())]
                            });
                            // --- End conversion logic ---
                        }}
                        onTransactionConfirmed={async () => {
                            // Original logic: fires when the transaction is confirmed
                            alert("Tier added successfully!");
                            setIsModalOpen(false);
                        }}
                        onError={(error) => {
                            // Original logic: fires on transaction error
                            // We can improve the logging here
                            console.error("Tier Creation Error:", error);
                            alert(`Error adding tier: ${error.message}`);
                        }}
                        theme={lightTheme()}
                        // Disable button while price is loading or not yet loaded
                        disabled={isLoadingPrice || ethPrice === 0}
                    >
                        {/* Show different button text based on price loading state */}
                        {isLoadingPrice ? "Loading Price..." : "Add Tier"}
                    </TransactionButton>
                </div>
            </div>
        </div>
    )
}