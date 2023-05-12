const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
require('solidity-coverage');

describe("Negative NFT test", function () {
    async function deployFixture() {
        const NegativeNFT = await ethers.getContractFactory("NegativeNFT");
        const NegativeVault = await ethers.getContractFactory("NegativeVault");

        const [owner, addr1, addr2] = await ethers.getSigners();

        const negativeNFT = await NegativeNFT.deploy(-2, "http://placeholder.com");

        await negativeNFT.deployed();

        const negativeVault = await NegativeVault.deploy(negativeNFT.address, "Negative Vault", "NEGV");

        await negativeVault.deployed();

        return { negativeNFT, negativeVault, owner, addr1, addr2 };
    }

    it("Should set vault", async function () {
        const { negativeNFT, negativeVault } = await loadFixture(deployFixture);

        await negativeNFT.setVault(negativeVault.address);

        expect(await negativeNFT.vault()).to.equal(negativeVault.address);
    });

    it("Should set uri", async function () {
        const { negativeNFT } = await loadFixture(deployFixture);

        await negativeNFT.setURI("testURI://testURI");

        expect(await negativeNFT.uri(0)).to.equal("testURI://testURI");
    });

    it("Should mint single", async function () {
        const { negativeNFT, addr1 } = await loadFixture(deployFixture);

        await negativeNFT.mint(addr1.address, 0, 40, []);

        expect(await negativeNFT.balanceOf(addr1.address, 0)).to.equal(40);
        expect(await negativeNFT.totalSupply()).to.equal(40);
    });

    it("Should mint batch", async function () {
        const { negativeNFT, addr1 } = await loadFixture(deployFixture);

        await negativeNFT.mintBatch(addr1.address, [0, 1], [50, 60], []);

        expect(await negativeNFT.balanceOf(addr1.address, 0)).to.equal(50);
        expect(await negativeNFT.balanceOf(addr1.address, 1)).to.equal(60);
        expect(await negativeNFT.totalSupply()).to.equal(110);
    });

    it("Should burn single", async function () {
        const { negativeNFT, addr1 } = await loadFixture(deployFixture);

        await negativeNFT.mint(addr1.address, 0, 40, []);

        await negativeNFT.connect(addr1).burn(addr1.address, 0, 20);

        expect(await negativeNFT.balanceOf(addr1.address, 0)).to.equal(20);
        expect(await negativeNFT.totalSupply()).to.equal(20);
    });

    it("Should burn batch", async function () {
        const { negativeNFT, addr1 } = await loadFixture(deployFixture);

        await negativeNFT.mintBatch(addr1.address, [0, 1], [50, 60], []);

        await negativeNFT.connect(addr1).burnBatch(addr1.address, [0, 1], [20, 30]);

        expect(await negativeNFT.balanceOf(addr1.address, 0)).to.equal(30);
        expect(await negativeNFT.balanceOf(addr1.address, 1)).to.equal(30);
        expect(await negativeNFT.totalSupply()).to.equal(60);
    });

    it("Should revert non-vault lock attempt", async function () {
        const { negativeNFT, addr1 } = await loadFixture(deployFixture);

        await negativeNFT.mint(addr1.address, 0, 40, []);

        await expect(negativeNFT.lock(addr1.address, [0], [40])).to.be.reverted;
    });

    it("Should revert non-vault unlock attempt", async function () {
        const { negativeNFT, negativeVault, addr1, addr2 } = await loadFixture(deployFixture);

        await negativeNFT.setVault(negativeVault.address);

        await negativeNFT.mint(addr1.address, 0, 40, []);

        await negativeVault.connect(addr1).deposit([0], [40], addr2.address, addr1.address);

        await expect(negativeNFT.unlock(addr1.address, [0], [40])).to.be.reverted;
    });
});