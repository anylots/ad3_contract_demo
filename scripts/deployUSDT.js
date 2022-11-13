const Token_Artifact = require("../artifacts/contracts/USDT.sol/Token.json")

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

  const USDT = await ethers.getContractFactory("Token");
  const token = await USDT.deploy("USDT", "USDT", 4, 10 ** 9);
  await token.deployed();
  console.log("usdt address:", token.address);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
