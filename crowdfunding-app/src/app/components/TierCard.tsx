import { prepareContractCall, ThirdwebContract } from "thirdweb";
import { TransactionButton } from "thirdweb/react";

const fromWei = (
    weiAmount: bigint | undefined | null,
    decimals: number = 18
): string => {
    // 1. Handle null, undefined, or 0
    if (!weiAmount || weiAmount === 0n) {
        return "0";
    }

    const divisor = 10n ** BigInt(decimals);

    // 2. Calculate integer part
    const integerPart = (weiAmount / divisor).toString();

    // 3. Calculate fractional part
    const remainder = weiAmount % divisor;

    // If there is no remainder
    if (remainder === 0n) {
        return integerPart;
    }

    // 4. Format fractional part
    // a. Convert remainder to string and pad with leading zeros to match decimals
    const fractionalPart = remainder.toString().padStart(decimals, '0');

    // b. Trim trailing zeros
    // e.g., "500000000000000000" -> "5"
    // e.g., "001000000000000000" -> "001"
    const trimmedFractional = fractionalPart.replace(/0+$/, '');

    return `${integerPart}.${trimmedFractional}`;
};

type Tier = {
    name: string;
    amount: bigint;
    backers: bigint;
};

type TierCardProps = {
    tier: Tier;
    index: number;
    contract: ThirdwebContract
    isEditing: boolean;
    // New props added
    ethPrice: number;
    isLoadingPrice: boolean;
}

export const TierCard: React.FC<TierCardProps> = ({ tier, index, contract, isEditing, ethPrice, isLoadingPrice }) => {

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
        <div className="max-w-sm flex flex-col justify-between p-6 bg-white border border-slate-100 rounded-lg shadow">
            <div>
                <div className="flex flex-row justify-between items-center">
                    <p className="text-2xl font-semibold">{tier.name}</p>
                    <p className="text-2xl font-semibold">{formatWeiToUsd(tier.amount)}</p>
                </div>
            </div>
            <div className="flex flex-row justify-between items-end">
                <p className="text-xs font-semibold">Total Backers: {tier.backers.toString()}</p>
                <TransactionButton
                    transaction={() => prepareContractCall({
                        contract: contract,
                        method: "function fund(uint256 _tierIndex) payable",
                        params: [BigInt(index)],
                        value: tier.amount,
                    })}
                    onError={(error) => alert(`Error: ${error.message}`)}
                    onTransactionConfirmed={async () => alert("Funded successfully!")}
                    style={{
                        marginTop: "1rem",
                        backgroundColor: "#2563EB",
                        color: "white",
                        padding: "0.5rem 1rem",
                        borderRadius: "0.375rem",
                        cursor: "pointer",
                    }}
                >Select</TransactionButton>
            </div>
            {isEditing && (
                <TransactionButton
                    transaction={() => prepareContractCall({
                        contract: contract,
                        method: "function removeTier(uint256 _index)",
                        params: [BigInt(index)],
                    })}
                    onError={(error) => alert(`Error: ${error.message}`)}
                    onTransactionConfirmed={async () => alert("Removed successfully!")}
                    style={{
                        marginTop: "1rem",
                        backgroundColor: "red",
                        color: "white",
                        padding: "0.5rem 1rem",
                        borderRadius: "0.375rem",
                        cursor: "pointer",
                    }}
                >Remove</TransactionButton>
            )}
        </div>
    )
};