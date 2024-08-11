// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./OgtaflGame.sol";

contract GameLobby {
    struct Game {
        address creator;
        address opponent;
        address gameContract;
        bool isActive;
    }

    mapping(uint256 => Game) public games;
    uint256 public gameCount;

    IERC721 public nftContract;

    event GameCreated(uint256 gameId, address creator, address gameContract, uint256 creatorNFT);
    event GameJoined(uint256 gameId, address opponent, uint256 opponentNFT);

    constructor(address _nftContract) {
        nftContract = IERC721(_nftContract);
    }

    function createGame(uint256 tokenId) public returns (uint256) {
        require(nftContract.ownerOf(tokenId) == msg.sender, "You don't own this NFT");

        gameCount++;
        OgtaflGame game = new OgtaflGame(msg.sender, address(nftContract), tokenId);
        games[gameCount] = Game(msg.sender, address(0), address(game), false);

        // Transfer the creator's NFT to the game contract
        nftContract.transferFrom(msg.sender, address(game), tokenId);

        emit GameCreated(gameCount, msg.sender, address(game), tokenId);
        return gameCount;
    }

    function joinGame(uint256 gameId, uint256 tokenId) public {
        require(gameId > 0 && gameId <= gameCount, "Invalid game ID");
        Game storage game = games[gameId];
        require(game.creator != address(0), "Game does not exist");
        require(game.opponent == address(0), "Game already has an opponent");
        require(game.creator != msg.sender, "Creator cannot join their own game");
        require(nftContract.ownerOf(tokenId) == msg.sender, "You don't own this NFT");

        game.opponent = msg.sender;
        game.isActive = true;

        // Transfer the opponent's NFT to the game contract
        nftContract.transferFrom(msg.sender, game.gameContract, tokenId);

        // Start the game with the opponent's NFT
        OgtaflGame(game.gameContract).startGame(msg.sender, tokenId);

        emit GameJoined(gameId, msg.sender, tokenId);
    }
}
