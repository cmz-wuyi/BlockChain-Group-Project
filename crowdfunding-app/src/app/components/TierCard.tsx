import { prepareContractCall, ThirdwebContract } from "thirdweb";
import { TransactionButton } from "thirdweb/react";

const fromWei = (
    weiAmount: bigint | undefined | null,
    decimals: number = 18
): string => {
    // 1. 处理空值或0
    if (!weiAmount || weiAmount === 0n) {
        return "0";
    }

    const divisor = 10n ** BigInt(decimals);

    // 2. 计算整数部分
    const integerPart = (weiAmount / divisor).toString();

    // 3. 计算小数部分
    const remainder = weiAmount % divisor;

    // 如果没有小数
    if (remainder === 0n) {
        return integerPart;
    }

    // 4. 格式化小数部分
    // a. 将余数转为字符串，并在左侧填充0，使其达到18位
    const fractionalPart = remainder.toString().padStart(decimals, '0');

    // b. 去除末尾多余的0
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
    // 添加的新 Props
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