const Campaign_Artifact = require("../artifacts/contracts/Campaign.sol/Campaign.json")
const Token_Artifact = require("../artifacts/contracts/USDT.sol/Token.json")

const campaign_address = '0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6';
const usdt_address = '0x5FbDB2315678afecb367f032d93F642f64180aa3';

const overrides = {
  gasLimit: 9999999,
  gasPrice: 100 * (10 ** 9)
}

// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.
async function main() {

  // await transferUSDT();
  await pushPay();

}

async function approveUSDT() {
  let privateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
  // Connect a wallet to localhost
  let customHttpProvider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
  let wallet = new ethers.Wallet(privateKey, customHttpProvider);

  let Token = new ethers.Contract(
    usdt_address,
    Token_Artifact.abi,
    wallet
  );

  await Token.approve("");

}

async function transferUSDT() {
  let privateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
  // Connect a wallet to localhost
  let customHttpProvider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
  let wallet = new ethers.Wallet(privateKey, customHttpProvider);

  let Token = new ethers.Contract(
    usdt_address,
    Token_Artifact.abi,
    wallet
  );

  let balance = await Token.balanceOf('0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266');
  console.log("balance is:" + balance);

  await Token.transfer(campaign_address, 1000000);

}


async function pushPay() {
  let privateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
  // Connect a wallet to localhost
  let customHttpProvider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
  let wallet = new ethers.Wallet(privateKey, customHttpProvider);

  let Campaign = new ethers.Contract(
    campaign_address,
    Campaign_Artifact.abi,
    wallet
  );



  //18,19
  let users1 = ["0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199", "0xdD2FD4581271e230360230F9337D5c0430Bf44C0"]

  //16,17
  let users2 = ["0x2546BcD3c84621e976D8185a91A922aE77ECEc30", "0xbDA5747bFD65F08deb54cb465eB87D40e51B197E"]


  let kols = [{ kol_address: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8", users: users1, ratio: 50 },
  { kol_address: "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", users: users2, ratio: 50 }]

  await Campaign.pushPay(kols,overrides);

  console.log("pushPay complated");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
