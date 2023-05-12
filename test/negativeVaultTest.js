/* global BigInt */
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

        await negativeNFT.setVault(negativeVault.address);

        return { negativeNFT, negativeVault, owner, addr1, addr2 };
    }

    it("Should return decimals", async function () {
        const { negativeVault } = await loadFixture(deployFixture);

        expect(await negativeVault.decimals()).to.equal(18);
    });
    
    it("Should return asset", async function () {
        const { negativeNFT, negativeVault } = await loadFixture(deployFixture);

        expect(await negativeVault.asset()).to.equal(negativeNFT.address);
    });

    it("Should return total assets", async function () {
        const { negativeNFT, negativeVault, addr1 } = await loadFixture(deployFixture);

        await negativeNFT.mint(addr1.address, 0, 40, []);

        await negativeVault.connect(addr1).deposit([0], [40], addr1.address, addr1.address);

        expect(await negativeVault.totalAssets()).to.equal(40);
    });

    it("Should convert to shares", async function () {
        const { negativeVault } = await loadFixture(deployFixture);

        expect(await negativeVault.convertToShares(40)).to.equal(40n*10n**20n);
    });

    it("Should convert to assets", async function () {
        const { negativeVault } = await loadFixture(deployFixture);

        expect(await negativeVault.convertToAssets(40n*10n**20n)).to.equal(40);
    });

    it("Should return max deposit", async function () {
        const { negativeNFT, negativeVault } = await loadFixture(deployFixture);

        expect(await negativeVault.maxDeposit(negativeNFT.address)).to.equal(2n**256n-1n);
    });

    it("Should return max withdraw", async function () {
        const { negativeNFT, negativeVault, addr1 } = await loadFixture(deployFixture);

        await negativeNFT.mint(addr1.address, 0, 40, []);

        await negativeVault.connect(addr1).deposit([0], [40], addr1.address, addr1.address);

        expect(await negativeVault.maxWithdraw(addr1.address)).to.equal(40);
    });

    it("Should preview deposit", async function () {
        const { negativeVault } = await loadFixture(deployFixture);

        expect(await negativeVault.previewDeposit(40)).to.equal(40n*10n**20n);
    });

    it("Should preview withdraw", async function () {
        const { negativeVault } = await loadFixture(deployFixture);

        expect(await negativeVault.previewWithdraw(40)).to.equal(40n*10n**20n);
    });

    it("Should deposit", async function () {
        const { negativeNFT, negativeVault, addr1, addr2 } = await loadFixture(deployFixture);

        await negativeNFT.mint(addr1.address, 0, 40, []);

        await negativeVault.connect(addr1).deposit([0], [40], addr2.address, addr1.address);

        expect(await negativeVault.balanceOf(addr2.address)).to.equal(40n*10n**20n);
    });

    it("Should withdraw", async function () {
        const { negativeNFT, negativeVault, addr1, addr2 } = await loadFixture(deployFixture);

        await negativeNFT.mint(addr1.address, 0, 40, []);

        await negativeVault.connect(addr1).deposit([0], [40], addr2.address, addr1.address);

        await negativeVault.connect(addr2).withdraw([0], [40], addr1.address, addr2.address);

        expect(await negativeVault.balanceOf(addr2.address)).to.equal(0);
    });

    it("Should withdraw approved", async function () {
        const { negativeNFT, negativeVault, owner, addr1, addr2 } = await loadFixture(deployFixture);

        await negativeNFT.mint(addr1.address, 0, 40, []);

        await negativeVault.connect(addr1).deposit([0], [40], addr2.address, addr1.address);

        await negativeVault.connect(addr2).approve(owner.address, 40n*10n**20n);

        await negativeVault.withdraw([0], [40], addr1.address, addr2.address);

        expect(await negativeVault.balanceOf(addr2.address)).to.equal(0);
    });

    it("Should revert not approved deposit", async function () {
        const { negativeNFT, negativeVault, addr1, addr2 } = await loadFixture(deployFixture);

        await negativeNFT.mint(addr1.address, 0, 40, []);

        await expect(negativeVault.connect(addr2).deposit([0], [40], addr2.address, addr1.address)).to.be.reverted;
    });

    it("Should revert excessive withdrawal", async function () {
        const { negativeNFT, negativeVault, addr1, addr2 } = await loadFixture(deployFixture);

        await negativeNFT.mint(addr1.address, 0, 40, []);

        await negativeVault.connect(addr1).deposit([0], [40], addr2.address, addr1.address);

        await expect(negativeVault.connect(addr2).withdraw([0], [41], addr1.address, addr2.address)).to.be.reverted;
    });

    it("Should revert unapproved withdrawal", async function () {
        const { negativeNFT, negativeVault, owner, addr1, addr2 } = await loadFixture(deployFixture);

        await negativeNFT.mint(addr1.address, 0, 40, []);

        await negativeVault.connect(addr1).deposit([0], [40], addr2.address, addr1.address);

        await expect(negativeVault.withdraw([0], [40], addr1.address, addr2.address)).to.be.reverted;
    });
});