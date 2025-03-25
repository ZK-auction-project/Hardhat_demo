// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("VerifierCompare", (m) => {

  const verifiers = m.contract("VerifierCompare");
  
  return { verifiers };
});

module.exports = buildModule("VerifierRange", (m) => {

  const verifier = m.contract("VerifierRange");
  console.log(verifier)
  return { verifier };
});