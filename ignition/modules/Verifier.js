// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("VerifierCompare", (m) => {

  const verifier = m.contract("VerifierCompare");
  
  return { verifier };
});

module.exports = buildModule("VerifierRange", (m) => {

  const verifier = m.contract("VerifierRange");
  
  return { verifier };
});