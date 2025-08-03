import * as Sdk from "@1inch/cross-chain-sdk";
import { uint8ArrayToHex, UINT_40_MAX } from "@1inch/byte-utils";

import {
    computeAddress,
    ContractFactory,
    ethers,
    JsonRpcProvider,
    MaxUint256,
    parseEther,
    parseUnits,
    randomBytes,
    Wallet,
    keccak256,
} from "ethers";

import { SuiClient, SuiHTTPTransport } from "@mysten/sui/client";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { formatAddress } from "@mysten/sui/utils";


import "dotenv/config";

import { config } from "./config";
import { decodeSuiPrivateKey } from "@mysten/sui/cryptography";

const { Address } = Sdk;

const main = async () => {
    const provider = new SuiClient({
        url: config.chain.sui.url,
    });
    const makerPK = config.chain.sui.ownerPrivateKey;
    const signer = Ed25519Keypair.fromSecretKey(
        decodeSuiPrivateKey(makerPK).secretKey
    );

    const salt = Sdk.randBigInt(1000);
    const maker = signer.toSuiAddress(); // sui address;
    const taker = ""; // eth address

    const srcTimestamp = BigInt(Date.now());

    const makingAmount = parseUnits("100", 6);
    const takingAmount = parseUnits("99", 6);

    const srcChainId = Sdk.NetworkEnum.ETHEREUM;
    const dstChainId = Sdk.NetworkEnum.BINANCE; // taking as a place holder for sui

    const secret = uint8ArrayToHex(randomBytes(32));

    const src = {
        escrowFactory: "0xDFD2168901BD0825d48d44e10A8a387A035aaf2F",
        resolver: "0xDFD2168901BD0825d48d44e10A8a387A035aaf2F",
    };

    const typeToId = (assetType: string) =>
        keccak256(ethers.toBeHex(assetType));

    const order = {
        salt,
        maker,
        reciever: formatAddress("0x0"),
        makerAsset: formatAddress(config.chain.sui.tokens.USDC.address),
        takerAsset: new Address(config.chain.eth.tokens.USDC.address),
        makingAmount: makingAmount.toString(),
        takingAmount: takingAmount.toString(),
    };

    console.log("Order: ", order);
    const messageString = JSON.stringify(order, (key, value) =>
        typeof value === "bigint" ? value.toString() : value
    );
    const messageBytes = new TextEncoder().encode(messageString);

    const sign = await signer.sign(messageBytes);

    console.log("Signed message: ", sign.toString());
};

main();
