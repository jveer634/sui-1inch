import * as Sdk from "@1inch/cross-chain-sdk";
import { uint8ArrayToHex, UINT_40_MAX } from "@1inch/byte-utils";
import { EscrowFactory } from "./escrow-factory";

import {
    ethers,
    JsonRpcProvider,
    parseEther,
    parseUnits,
    randomBytes,
} from "ethers";

import { SuiClient } from "@mysten/sui/client";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { decodeSuiPrivateKey } from "@mysten/sui/cryptography";

import "dotenv/config";

import { config } from "./config";
import { Transaction } from "@mysten/sui/transactions";
import { Resolver } from "./resolver";
import { Wallet } from "./Wallet";
import { ImmutablesParams } from "./helpers/sui-helpers";
import { deployResolver } from "./helpers/evm-helpers";

const { Address } = Sdk;

const SECRET = uint8ArrayToHex(randomBytes(32));

const suiAddressToUint256 = (address: string) => {
    // Remove 0x prefix if present
    if (address.startsWith("0x")) {
        address = address.slice(2);
    }
    // Convert hex string to BigInt
    return BigInt("0x" + address);
};

const main = async () => {
    const ethProvider = new JsonRpcProvider(config.chain.eth.url);
    const suiProvider = new SuiClient({
        url: config.chain.sui.url,
    });

    const makerETHPK = config.chain.eth.userPrivateKey;
    const makerSuiPK = config.chain.sui.userPrivateKey;
    const takerSUIPK = config.chain.sui.ownerPrivateKey;
    const takerETHPK = config.chain.eth.ownerPrivateKey;

    const makerETHSigner = new Wallet(makerETHPK, ethProvider);
    const makerSuiSigner = Ed25519Keypair.fromSecretKey(
        decodeSuiPrivateKey(makerSuiPK).secretKey
    );

    const takerETHSigner = new Wallet(takerETHPK, ethProvider);
    const takerSuiSigner = Ed25519Keypair.fromSecretKey(
        decodeSuiPrivateKey(takerSUIPK).secretKey
    );

    const takerOnSui = takerSuiSigner.toSuiAddress();
    const takerOnETH = await takerETHSigner.getAddress();

    const makerOnSui = makerSuiSigner.toSuiAddress();
    const makerOnETH = await makerETHSigner.getAddress();

    const salt = Sdk.randBigInt(1000);

    const srcTimestamp = BigInt(
        (await ethProvider.getBlock("latest"))!.timestamp
    );

    const makingAmount = parseUnits("100", 6);
    const takingAmount = parseUnits("99", 6);

    const srcChainId = Sdk.NetworkEnum.ETHEREUM;
    const dstChainId = Sdk.NetworkEnum.BINANCE; // taking as a place holder for sui

    const ethResolver = await deployResolver(
        [
            config.chain.eth.limitOrderProtocol,
            "0xa7bCb4EAc8964306F9e3764f67Db6A7af6DdF99A",
            takerOnETH,
        ],
        new ethers.Wallet(takerETHPK, ethProvider)
    );

    const src = {
        escrowFactory: "0xa7bCb4EAc8964306F9e3764f67Db6A7af6DdF99A",
        resolver: ethResolver,
    };

    const dst = {
        resolver:
            "0x367cb81086fb9b09e90ea929293db99efce859af8ead66cecfd37a75855ccdf6",
        escrowFactory:
            "0x0fdea587790ad075b1234cbe3483d886a1e1d28aff92da5723ec7e3cafb6794b",
    };

    const srcFactory = new EscrowFactory(ethProvider, src.escrowFactory);

    const order = Sdk.CrossChainOrder.new(
        new Address(src.escrowFactory),
        {
            salt,
            maker: Address.fromBigInt(suiAddressToUint256(makerOnSui)),
            makingAmount,
            takingAmount,
            makerAsset: new Address(config.chain.eth.tokens.USDC.address),
            takerAsset: Address.ZERO_ADDRESS,
        },
        {
            hashLock: Sdk.HashLock.forSingleFill(SECRET),
            timeLocks: Sdk.TimeLocks.new({
                srcWithdrawal: 10n, // 10sec finality lock for test
                srcPublicWithdrawal: 120n, // 2m for private withdrawal
                srcCancellation: 121n, // 1sec public withdrawal
                srcPublicCancellation: 122n, // 1sec private cancellation
                dstWithdrawal: 10n, // 10sec finality lock for test
                dstPublicWithdrawal: 100n, // 100sec private withdrawal
                dstCancellation: 101n, // 1sec public withdrawal
            }),
            srcChainId,
            dstChainId,
            srcSafetyDeposit: parseEther("0.001"),
            dstSafetyDeposit: parseUnits("0.001", 9),
        },
        {
            auction: new Sdk.AuctionDetails({
                initialRateBump: 0,
                points: [],
                duration: 120n,
                startTime: srcTimestamp,
            }),
            whitelist: [
                {
                    address: new Address(src.resolver),
                    allowFrom: 0n,
                },
            ],
            resolvingStartTime: 0n,
        },
        {
            nonce: Sdk.randBigInt(UINT_40_MAX),
            allowPartialFills: false,
            allowMultipleFills: false,
        }
    );

    const signature = await makerETHSigner.signOrder(srcChainId, order);

    console.log("Order Signed by user ...... ", signature);

    const orderHash = order.getOrderHash(srcChainId);
    console.log(`[${srcChainId}]`, `Filling order ${orderHash}`);

    const resolverContract = new Resolver(src.resolver, dst.resolver);

    const srcChainResolver = new Wallet(takerETHPK, ethProvider);

    // deploy the source escrow - ethereum
    const fillAmount = order.makingAmount;
    const { txHash: orderFillHash, blockHash: srcDeployBlock } =
        await srcChainResolver.send(
            resolverContract.deploySrc(
                srcChainId,
                order,
                signature,
                Sdk.TakerTraits.default()
                    .setExtension(order.extension)
                    .setAmountMode(Sdk.AmountMode.maker)
                    .setAmountThreshold(order.takingAmount),
                fillAmount
            )
        );

    console.log(
        `[${srcChainId}]`,
        `Order ${orderHash} filled for ${fillAmount} in tx ${orderFillHash}`
    );

    await ethProvider.waitForTransaction(orderFillHash);

    const srcEscrowEvent = await srcFactory.getSrcDeployEvent(srcDeployBlock);

    console.log("Source Escrow contract deployed....");

    const dstImmutables = srcEscrowEvent[0]
        .withComplement(srcEscrowEvent[1])
        .withTaker(new Address(takerOnETH));

    // deploy the sui escrow on dst
    const tx = new Transaction();

    const takerTraits = Sdk.TakerTraits.default()
        .setExtension(order.extension)
        .setAmountMode(Sdk.AmountMode.maker)
        .setAmountThreshold(order.takingAmount)
        .encode();

    let [safety_deposit] = tx.splitCoins(tx.gas, [parseUnits("0.001", 9)]);
    let srcCancellationTs = 100n;

    const immutables = ImmutablesParams.serialize({
        order_hash: Buffer.from(dstImmutables.orderHash),
        hash_lock: Buffer.from(dstImmutables.hashLock.toString()),
        safety_deposit: dstImmutables.safetyDeposit,
        maker: dstImmutables.maker.toString(),
        taker: dstImmutables.taker.toString(),
        amount: dstImmutables.amount,
        timelocks: dstImmutables.timeLocks.build(),
    });

    tx.moveCall({
        function: "deploy_dst",
        module: "resolver",
        package: dst.resolver,
        arguments: [
            immutables,
            tx.pure.u256(srcCancellationTs),
            tx.object(safety_deposit),
            tx.pure.u256(100),
            tx.pure.u256(takerTraits.trait),
        ],
    });

    const { digest, objectChanges } =
        await suiProvider.signAndExecuteTransaction({
            transaction: tx,
            signer: takerSuiSigner,
            options: { showObjectChanges: true },
        });

    await suiProvider.waitForTransaction({
        digest,
    });

    const dstEscrow = objectChanges
        ?.filter((object) => object.type == "created")
        .filter((object) => object.objectType.includes("EscrowDst"))[0]
        .objectId as string;

    console.log("Destination Object Id: ", dstEscrow);

    console.log("Contracts deployed on the Sui side: ", digest);

    const type = config.chain.sui.tokens.USDC.address;

    const withdrawTx = new Transaction();

    withdrawTx.moveCall({
        function: "withdraw",
        module: "escrow_dst",
        package: dst.escrowFactory,
        arguments: [
            withdrawTx.object(dstEscrow),
            withdrawTx.pure.vector("u8", Buffer.from(SECRET)),
        ],
    });

    const { digest: withdrawDigest } =
        await suiProvider.signAndExecuteTransaction({
            transaction: withdrawTx,
            signer: takerSuiSigner,
            options: { showObjectChanges: true },
        });

    await suiProvider.waitForTransaction({
        digest,
    });

    console.log("User funds withdraw at: ", withdrawDigest);
};

main();
