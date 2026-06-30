const hre = require("hardhat");

const main = async () => {
    try {
        const { ethers, network } = hre;
        const [deployer] = await ethers.getSigners();
        const { chainId } = await deployer.provider.getNetwork();

        const initialMaxRecipients = Number(process.env.MAX_RECIPIENTS || 200);
        if (!Number.isInteger(initialMaxRecipients) || initialMaxRecipients <= 0) {
            throw new Error("MAX_RECIPIENTS must be a positive integer.");
        }

        console.log(`Network: ${network.name} (ChainId ${chainId})`);
        console.log(`Deployer: ${deployer.address}`);
        console.log(`Max recipients: ${initialMaxRecipients}`);

        const BatchExecutor = await ethers.getContractFactory("BatchExecutor", deployer);
        const batchExecutor = await BatchExecutor.deploy(initialMaxRecipients);
        await batchExecutor.waitForDeployment();

        const contractAddress = await batchExecutor.getAddress();
        const deploymentTx = batchExecutor.deploymentTransaction();
        const txHash = deploymentTx ? deploymentTx.hash : "N/A";

        console.log(`Contract deployed at: ${contractAddress}`);
        console.log(`Deployment tx hash: ${txHash}`);

        console.log("\nVerify Command:");
        console.log(
            `npx hardhat verify --network ${network.name} ${contractAddress} ${initialMaxRecipients}`
        );

    } catch (error) {
        console.error("Deployment failed:", error);
        process.exitCode = 1;
    }
};

main();