
const Campaign_Artifact = require("../artifacts/contracts/Campaign.sol/Campaign.json")

const overrides = {
    gasLimit: 15000000,
    gasPrice: 10 * (10 ** 9)
  }

async function main() {

    // await transferUSDT();
    await pushPay();

}

async function pushPay() {
    // Connect a wallet to localhost
    let customHttpProvider = new ethers.providers.JsonRpcProvider("http://localhost:8545");

    const { ad3Hub, owner } = await deployAD3HubFixture();
    const { token } = await deployPaymentToken();
    await ad3Hub.setPaymentToken(token.address);
    await token.approve(ad3Hub.address, 100000);
    let kols = await getKolsFixtrue();
    console.log("startCreateCampaign:" + kols.length);

    await ad3Hub.createCampaign(kols, 100000, 10);

    let campaignAddress = await ad3Hub.getCampaignAddress(owner.address, 1);
    let Campaign = new ethers.Contract(
        campaignAddress,
        Campaign_Artifact.abi,
        owner
    );
    let resultBeforePay = await Campaign.remainBalance();
    console.log("resultBeforePay:" + resultBeforePay);

    let kolAddress = await getKolsAddress();
    //first kol pay
    await ad3Hub.payfixFee(kolAddress, owner.address, 1);
    //second kol pay
    await ad3Hub.payfixFee(kolAddress, owner.address, 1);


    //UserPay and check campaign's balance
    let kolWithUsers = await getKolWithUsers();

    console.log("starting pushPay");

    // let result = await Campaign.pushPay(kolWithUsers);
    // let result = await ad3Hub.pushPayTest(owner.address, 1, kolWithUsers, overrides);
    
    let result = await ad3Hub.pushPay(owner.address, 1, kolWithUsers, overrides);
    console.log("finish pushPay");
    let info = await customHttpProvider.getTransactionReceipt(result.hash);
    console.log("gas used:" + info.gasUsed);
    let resultAfterUserPay = await Campaign.remainBalance();
    console.log("resultAfterUserPay:" + resultAfterUserPay);
    console.log("pushPay complated");

    //   expect(resultAfterUserPay).to.equal(100000 - 200 - 40);
}



async function deployAD3HubFixture() {
    // Get the ContractFactory and Signers here.
    const AD3Hub = await ethers.getContractFactory("AD3Hub");
    const [owner, addr1, addr2] = await ethers.getSigners();

    const ad3Hub = await AD3Hub.deploy();
    await ad3Hub.deployed();
    // Fixtures can return anything you consider useful for your tests
    return { ad3Hub, owner, addr1, addr2 };
}

// token of payment
async function deployPaymentToken() {
    const USDT = await ethers.getContractFactory("Token");
    const token = await USDT.deploy("USDT", "USDT", 2, 10 ** 9);
    await token.deployed();
    return { token };
}


//kols for deployment
async function getKolsFixtrue() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    let kols = [
        {
            _address: addr1.getAddress(),
            fixedFee: 100,
            ratio: 70,
            _paymentStage: 0,
        },
        {
            _address: addr2.getAddress(),
            fixedFee: 100,
            ratio: 70,
            _paymentStage: 0,
        }
    ];

    // for (let i = 0; i < 1000; i++) {
    //     kols.push(
    //         {
    //             _address: addr2.getAddress(),
    //             fixedFee: 100,
    //             ratio: 70,
    //             _paymentStage: 0
    //         }
    //     );
    // }
    return kols;
}

//kols for pushpay
async function getKolWithUsers() {
    const [owner, addr1, addr2, addr3, addr4, addr5, addr6, addr7] = await ethers.getSigners();
    let userList = [];
    for (let i = 0; i < 1000; i++) {
        userList.push(addr6.getAddress());
    }
    let kolWithUsers = [
        {
            _address: addr1.getAddress(),
            users: [addr3.getAddress(), addr4.getAddress()]
        },
        {
            users: userList,
            _address: addr2.getAddress()
        }
    ];

    return kolWithUsers;
}

//kols for payfixFee
async function getKolsAddress() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    let kols = [
        addr1.getAddress(),
        addr2.getAddress()
    ];
    return kols;
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });