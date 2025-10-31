import { getContract } from "thirdweb";
import { sepolia } from "thirdweb/chains";
import { useReadContract } from "thirdweb/react";
import { client } from "@/app/client"; // 确保 client 路径正确

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

// Sepolia 测试网的 Chainlink ETH/USD 价格源地址
const CHAINLINK_ETH_USD_FEED = "0x694AA1769357215DE4FAC081bf1f309aDC325306";

// Chainlink 价格源返回的数据结构 ABI
const CHAINLINK_ABI = "function latestRoundData() view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)";

// Chainlink 价格使用 8 位小数
const CHAINLINK_DECIMALS = 8;

/**
 * @name useEthUsdPrice
 * @description 一个自定义 Hook，用于从 Chainlink 获取当前的 ETH/USD 价格。
 * @returns { price: number, isLoadingPrice: boolean }
 */
export const useEthUsdPrice = () => {
    const contract = getContract({
        client: client,
        chain: sepolia,
        address: CHAINLINK_ETH_USD_FEED,
    });

    // 读取最新的价格数据
    const { data: latestRoundData, isLoading: isLoadingPrice } = useReadContract({
        contract: contract,
        method: CHAINLINK_ABI,
        params: [],
    });

    let price: number = 0;

    if (latestRoundData) {
        // latestRoundData 是一个数组，价格在索引 1 (answer)
        const priceAsBigInt = latestRoundData[1] as bigint;
        
        // 价格需要除以 10^8 (Chainlink 的小数位数)
        price = Number(priceAsBigInt) / (10 ** CHAINLINK_DECIMALS);
    }

    return { price, isLoadingPrice };
};