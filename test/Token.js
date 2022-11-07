const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

// `describe` is a Mocha function that allows you to organize your tests.
describe("Token contract", function () {

  async function deployAD3HubFixture() {
    // Get the ContractFactory and Signers here.
    const AD3Hub = await ethers.getContractFactory("AD3Hub");
    const [owner, addr1, addr2] = await ethers.getSigners();

    const ad3Hub = await AD3Hub.deploy();

    await ad3Hub.deployed();

    // Fixtures can return anything you consider useful for your tests
    return { ad3Hub, owner, addr1, addr2 };
  }

  async function deployPaymentToken() {

    const USDT = await ethers.getContractFactory("Token");
    const token = await USDT.deploy("USDT", "USDT", 2, 10 ** 9);
    await token.deployed();
    return { token };
  }

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

  // You can nest describe calls to create subsections.
  describe("Deployment", function () {

    it("Should set the right owner", async function () {
      const { ad3Hub, owner } = await loadFixture(deployAD3HubFixture);
      expect(await ad3Hub.owner()).to.equal(owner.address);
    });

    it("Should balance of campaign equals init budget", async function () {
      const { ad3Hub, owner } = await loadFixture(deployAD3HubFixture);
      const { token } = await loadFixture(deployPaymentToken);

      await ad3Hub.setPaymentToken(token.address);


      let kols = await getKolsFixtrue();

      console.log("starting createCampaign");
      await token.approve(ad3Hub.address, 100000);
      await ad3Hub.createCampaign(kols, 100000, 10);

      let campaignAddress = await ad3Hub.getCampaignAddress(owner.address,1);
      console.log(campaignAddress);

      let campaignAddressList = await ad3Hub.getCampaignAddressList(owner.address);
      console.log(campaignAddressList);
      expect(1).to.equal(campaignAddressList.length);
      expect(campaignAddress).to.equal(campaignAddressList[0]);


      // expect(await campaign.remainBalance()).to.equal(100000);
    });
  });

  // describe("Transactions", function () {
  //   it("Should transfer tokens between accounts", async function () {
  //     const { ad3Hub, owner, addr1, addr2 } = await loadFixture(deployTokenFixture);
  //     // Transfer 50 tokens from owner to addr1
  //     await expect(ad3Hub.transfer(addr1.address, 50))
  //       .to.changeTokenBalances(ad3Hub, [owner, addr1], [-50, 50]);
  //     await expect(ad3Hub.connect(addr1).transfer(addr2.address, 50))
  //       .to.changeTokenBalances(ad3Hub, [addr1, addr2], [-50, 50]);
  //   });
  // });
});
