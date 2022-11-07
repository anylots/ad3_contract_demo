const Campaign = require("../artifacts/contracts/Campaign.sol/Campaign.json")


// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.
async function main() {
  let privateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
  const Campaign1 = await ethers.getContractFactory("Campaign");
  console.log(Campaign1.abi);

  // Connect a wallet to localhost
  let customHttpProvider = new ethers.providers.JsonRpcProvider("http://localhost:8545");

  let deployer = new ethers.Wallet(privateKey, customHttpProvider);

  console.log(
    "Deploying the contracts with the account:",
    await deployer.getAddress()
  );
  console.log("Account balance:", (await deployer.getBalance()).toString());

  let kols = [{ _address: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8", fixedFee: 1, ratio: 60 , _paymentStage:0},
  { _address: "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", fixedFee: 1, ratio: 60 , _paymentStage:0}];
  console.log(1);

  const Campaign = await ethers.getContractFactory("Campaign");
  
  const campaign = await Campaign.deploy(kols, 100);

  let result = await campaign.deployed();
  // console.log("campaign result:", result);
  console.log("campaign address:", campaign.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
