import { getContract } from "thirdweb";
import { sepolia } from "thirdweb/chains";
import { useReadContract } from "thirdweb/react";
import { client } from "@/app/client"; // Ensure the client path is correct

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

// Chainlink ETH/USD Price Feed address on Sepolia testnet
const CHAINLINK_ETH_USD_FEED = "0x694AA1769357215DE4FAC081bf1f309aDC325306";

// ABI for the Chainlink price feed data structure
const CHAINLINK_ABI = "function latestRoundData() view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)";

// Chainlink price feeds use 8 decimals
const CHAINLINK_DECIMALS = 8;

/**
 * @name useEthUsdPrice
 * @description Custom hook to fetch the current ETH/USD price from Chainlink.
 * @returns { price: number, isLoadingPrice: boolean }
 */
export const useEthUsdPrice = () => {
    const contract = getContract({
        client: client,
        chain: sepolia,
        address: CHAINLINK_ETH_USD_FEED,
    });

    // Read the latest price data
    const { data: latestRoundData, isLoading: isLoadingPrice } = useReadContract({
        contract: contract,
        method: CHAINLINK_ABI,
        params: [],
    });

    let price: number = 0;

    if (latestRoundData) {
        // latestRoundData is an array, the price (answer) is at index 1
        const priceAsBigInt = latestRoundData[1] as bigint;
        
        // Price must be divided by 10^8 (Chainlink's decimals)
        price = Number(priceAsBigInt) / (10 ** CHAINLINK_DECIMALS);
    }

    return { price, isLoadingPrice };
};