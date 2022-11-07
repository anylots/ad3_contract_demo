const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const Campaign_Artifact = require("../artifacts/contracts/Campaign.sol/Campaign.json")
const Token_Artifact = require("../artifacts/contracts/USDT.sol/Token.json")

// Ad3 contract uniting test
describe("Ad3 contract", function () {

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
    return kols;
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

  // Test Deployment of Hub
  describe("Deployment", function () {

    it("Should set the right owner", async function () {
      const { ad3Hub, owner } = await loadFixture(deployAD3HubFixture);
      expect(await ad3Hub.owner()).to.equal(owner.address);
    });

    it("Should balance of campaign equals init budget", async function () {
      const { ad3Hub, owner } = await loadFixture(deployAD3HubFixture);
      const { token } = await deployPaymentToken();

      await ad3Hub.setPaymentToken(token.address);
      let payment = await ad3Hub.getPaymentToken();
      console.log(payment);
    });

  });



  // Test createCampaign
  describe("CreateCampaign", function () {

    it("create a campaign", async function () {
      const { ad3Hub, owner } = await loadFixture(deployAD3HubFixture);
      const { token } = await deployPaymentToken();
      await ad3Hub.setPaymentToken(token.address);

      await token.approve(ad3Hub.address, 100000);

      let kols = await getKolsFixtrue();
      console.log("starting createCampaign");
      await ad3Hub.createCampaign(kols, 100000, 10);

      let campaignAddress = await ad3Hub.getCampaignAddress(owner.address, 1);
      console.log(campaignAddress);

      let campaignAddressList = await ad3Hub.getCampaignAddressList(owner.address);
      console.log(campaignAddressList);
      expect(1).to.equal(campaignAddressList.length);
      expect(campaignAddress).to.equal(campaignAddressList[0]);


      let Campaign = new ethers.Contract(
        campaignAddress,
        Campaign_Artifact.abi,
        owner
      );

      let result = await Campaign.remainBalance();
      console.log(result);

      expect(result).to.equal(100000);
    });

  });


  // Test Payment
  describe("Payment", function () {
    it("payfixFee", async function () {
      const { ad3Hub, owner } = await loadFixture(deployAD3HubFixture);
      const { token } = await deployPaymentToken();
      await ad3Hub.setPaymentToken(token.address);

      await token.approve(ad3Hub.address, 100000);

      let kols = await getKolsFixtrue();
      console.log("starting createCampaign");
      await ad3Hub.createCampaign(kols, 100000, 10);

      let campaignAddress = await ad3Hub.getCampaignAddress(owner.address, 1);
      console.log(campaignAddress);

      let Campaign = new ethers.Contract(
        campaignAddress,
        Campaign_Artifact.abi,
        owner
      );
      let resultBeforePay = await Campaign.remainBalance();
      console.log(resultBeforePay);

      let kolAddress = await getKolsAddress();
      await ad3Hub.payfixFee(kolAddress, owner.address, 1);
      let resultAfterPay = await Campaign.remainBalance();
      console.log(resultAfterPay);

      expect(resultAfterPay).to.equal(100000 - 100);
    });


    it("pushPay", async function () {
      const { ad3Hub, owner } = await loadFixture(deployAD3HubFixture);
      const { token } = await deployPaymentToken();
      await ad3Hub.setPaymentToken(token.address);

      await token.approve(ad3Hub.address, 100000);
    });
  });
});
