const hre = require("hardhat");
const fs = require('fs');
const path = require('path');

async function main() {
  const VerifierRange = await hre.ethers.getContractFactory("VerifierRange");
  const verifierRange = await VerifierRange.deploy();
  await verifierRange.waitForDeployment();
  const verifierRangeAddress = await verifierRange.getAddress();

  const VerifierCompare = await hre.ethers.getContractFactory("VerifierCompare");
  const verifierCompare = await VerifierCompare.deploy();
  await verifierCompare.waitForDeployment();
  const verifierCompareAddress = await verifierCompare.getAddress();

  const Auction = await hre.ethers.getContractFactory("Auction");
  const auction = await Auction.deploy(verifierRangeAddress, verifierCompareAddress);
  await auction.waitForDeployment();
  const auctionAddress = await auction.getAddress();

  const envPath = path.join(__dirname, '..', 'contractInfo.env');
  const envContent = `AUCTION_CONTRACT_ADDRESS="${auctionAddress}"\nVERIFIER_RANGE_CONTRACT_ADDRESS="${verifierRangeAddress}"\nVERIFIER_COMPARE_CONTRACT_ADDRESS="${verifierCompareAddress}"\n`;

  fs.writeFileSync(envPath, envContent);
  console.log('\nContract addresses written to .env file');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});