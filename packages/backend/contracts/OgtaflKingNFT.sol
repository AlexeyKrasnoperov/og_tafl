// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OgtaflKingNFT is ERC721 {
    
    uint256 public constant MAX_KINGS = 4;
    uint256 public currentTokenId;

    string[MAX_KINGS] public kingURIs = [
        "ipfs://QmXgrvc9hmo7iRjZEM4SY8A4YDKBVKiaupm31QAdcBDNkT",
        "ipfs://QmaXm1DHF1nQhkdM51dxDBGcR88ZxLKczzzRTrvMWk2G9C",
        "ipfs://QmVL6Q6AwGnG3DJ63CtYaaF7AeHeyR8PjVJeQ5uE2Ten77",
        "ipfs://QmPLcApbLFBPJLoH8KcjxcAPqUgCy6rEjoxRa24WzeJCDB"
    ];

    constructor() ERC721("OgtaflKing", "KING") {}

    function mintKingNFT() public {
        require(balanceOf(msg.sender) == 0, "You already own a Ogtafl King NFT");

        currentTokenId++;
        _mint(msg.sender, currentTokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // TODO: Randomize king selection via Chainlink VRF
        return kingURIs[tokenId - 1];
    }
}
