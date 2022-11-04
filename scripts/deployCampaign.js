const Campaign = require("../artifacts/contracts/Campaign.sol/Campaign.json")


// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.
async function main() {
  let privateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

  // Connect a wallet to localhost
  let customHttpProvider = new ethers.providers.JsonRpcProvider("http://localhost:8545");

  let deployer = new ethers.Wallet(privateKey, customHttpProvider);

  console.log(
    "Deploying the contracts with the account:",
    await deployer.getAddress()
  );
  console.log("Account balance:", (await deployer.getBalance()).toString());

  

  const Campaign = await ethers.getContractFactory("Campaign");
  const campaign = await Campaign.deploy("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", 
  ["0x70997970C51812dc3A010C7d01b50e0d17dc79C8","0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"], 100000);

  await campaign.deployed();
  console.log("campaign address:", campaign.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
