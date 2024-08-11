const { ethers } = require('hardhat');

async function main() {
  const OgtaflLobby = await ethers.getContractFactory('OgtaflLobby');
  const ogtaflLobby = await OgtaflLobby.deploy("0x88029C2f6aa77c8236Dd1A1B61AE3201D851adC2");
  await ogtaflLobby.waitForDeployment();

  console.log("OgtaflLobby deployed to:", await ogtaflLobby.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
