const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("Auction", (m) => {

    const auction = m.contract("Auction", ["0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512", "0x5FbDB2315678afecb367f032d93F642f64180aa3"]);

    return { auction };
});
