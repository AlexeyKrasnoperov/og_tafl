const { ethers } = require('hardhat');

async function main() {
  const OgtaflKingNFT = await ethers.getContractFactory('OgtaflKingNFT');
  const ogtaflKingNFT = await OgtaflKingNFT.deploy();
  await ogtaflKingNFT.waitForDeployment();

  console.log("OgtaflKingNFT deployed to:", await ogtaflKingNFT.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
