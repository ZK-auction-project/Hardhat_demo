const hre = require("hardhat");

async function main() {
  // Deploy VerifierRange contract
  const VerifierRange = await hre.ethers.getContractFactory("VerifierRange");
  const verifierRange = await VerifierRange.deploy();
  await verifierRange.waitForDeployment();
  console.log("VerifierRange deployed to:", verifierRange.target);

  // Deploy VerifierCompare contract
  const VerifierCompare = await hre.ethers.getContractFactory("VerifierCompare");
  const verifierCompare = await VerifierCompare.deploy();
  await verifierCompare.waitForDeployment();
  console.log("VerifierCompare deployed to:", verifierCompare.target);

  // Deploy Auction contract, passing the addresses of the Verifier contracts
  const Auction = await hre.ethers.getContractFactory("Auction");
  const auction = await Auction.deploy(verifierRange.target, verifierCompare.target);
  await auction.waitForDeployment();
  console.log("Auction deployed to:", auction.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});