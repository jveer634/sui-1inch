import { z } from "zod";
import { NetworkEnum } from "@1inch/cross-chain-sdk";
import * as process from "node:process";

const ConfigSchema = z.object({
    ETH_CHAIN_RPC: z.url(),
    SUI_CHAIN_RPC: z.url(),

    SUI_PRIVATE_KEY: z.string(),
    ETH_PRIVATE_KEY: z.string(),

    SUI_USER_PK: z.string().startsWith("suip"),
    ETH_USER_PK: z.string(),
});

const fromEnv = ConfigSchema.parse(process.env);

export const config = {
    chain: {
        eth: {
            chainId: NetworkEnum.ETHEREUM,
            url: fromEnv.ETH_CHAIN_RPC,
            limitOrderProtocol: "0x111111125421ca6dc452d289314280a0f8842a65",
            wrappedNative: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
            userPrivateKey: fromEnv.ETH_USER_PK,
            ownerPrivateKey: fromEnv.ETH_PRIVATE_KEY,
            tokens: {
                USDC: {
                    address: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
                    donor: "0xd54F23BE482D9A58676590fCa79c8E43087f92fB",
                },
            },
        },
        sui: {
            chainId: NetworkEnum.BINANCE,
            url: fromEnv.SUI_CHAIN_RPC,
            limitOrderProtocol: "0x111111125421ca6dc452d289314280a0f8842a65",
            wrappedNative: "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c",
            userPrivateKey: fromEnv.SUI_USER_PK,
            ownerPrivateKey: fromEnv.SUI_PRIVATE_KEY,
            tokens: {
                USDC: {
                    address:
                        "0x40197b7f7a400cd4488cda7290a739c5bc6498b32c3a920da802a4f489256894::token::MOCK_TOKEN",
                    donor: "0x4188663a85C92EEa35b5AD3AA5cA7CeB237C6fe9", // no need here
                },
            },
        },
    },
} as const;

export type ChainConfig = (typeof config.chain)["eth" | "sui"];
