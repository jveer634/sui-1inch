import { ContractFactory, Wallet } from "ethers";

import { abi, bytecode } from "../ABI/Resolver.json";

// params - lop address, factory address, deployer address
export async function deployResolver(
    params: string[],
    deployer: Wallet
): Promise<string> {
    const deployed = await new ContractFactory(abi, bytecode, deployer).deploy(
        ...params
    );
    await deployed.waitForDeployment();

    return await deployed.getAddress();
}
