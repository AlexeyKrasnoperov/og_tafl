import React, { useEffect, useState } from 'react';
import { NFT, useAddress, useWallet, useContract, useOwnedNFTs, ThirdwebNftMedia } from '@thirdweb-dev/react';
import { ethers } from 'ethers';
import GameLobbyABI from '../contractInterfaces/LobbyABI.json';
import KingNFTABI from '../contractInterfaces/KingNFTABI.json';

const CONTRACT_ADDRESS = "0x3ec0F4AEAEa2A9a0ebaB5A495a0AAb6F3906192a";
const NFT_CONTRACT_ADDRESS = "0x88029C2f6aa77c8236Dd1A1B61AE3201D851adC2";

const Lobby: React.FC<Object[]> = (nfts: Object[]) => {
    const address = useAddress();
    const walletInstance = useWallet();
    const [availableGames, setAvailableGames] = useState<any[]>([]);
    const [playerGames, setPlayerGames] = useState<any[]>([]);


    const { contract } = useContract(NFT_CONTRACT_ADDRESS);
    const { data, isLoading, error } = useOwnedNFTs(contract, address);

    useEffect(() => {
        if (walletInstance && address) {
            loadAvailableGames();
            loadPlayerGames();
        }
    }, [walletInstance, address]);

    const loadAvailableGames = async () => {
        const signer = await walletInstance?.getSigner();

        const contract = new ethers.Contract(CONTRACT_ADDRESS, GameLobbyABI, signer);
        const games = await contract.listGames();
        setAvailableGames(games);
    };

    const loadPlayerGames = async () => {
        const signer = await walletInstance?.getSigner();

        const contract = new ethers.Contract(CONTRACT_ADDRESS, GameLobbyABI, signer);
        const games = await contract.getPlayerGames(address);
        setPlayerGames(games);
    };

    async function createGame(nftTokenId) {
        if (!nftTokenId) {
            alert("Please enter a valid NFT Token ID.");
            return;
        }
        const signer = await walletInstance?.getSigner();

        const contract = new ethers.Contract(CONTRACT_ADDRESS, GameLobbyABI, signer);

        try {
            const tx = await contract.createGame(nftTokenId);
            await tx.wait();
            alert('Game created successfully!');
            loadAvailableGames();
            loadPlayerGames();
        } catch (error) {
            console.error("Failed to create game", error);
        }
    };

    const joinGame = async (gameId: number, tokenId: string) => {
        if (!tokenId) {
            alert("Please enter a valid NFT Token ID.");
            return;
        }
        const signer = await walletInstance?.getSigner();

        const contract = new ethers.Contract(CONTRACT_ADDRESS, GameLobbyABI, signer);

        try {
            const tx = await contract.joinGame(gameId, tokenId);
            await tx.wait();
            alert('Joined game successfully!');
            loadAvailableGames();
            loadPlayerGames();
        } catch (error) {
            console.error("Failed to join game", error);
        }
    };

    const mintKingNFT = async () => {
        if (!address) return;

        const signer = await walletInstance?.getSigner();
        const contract = new ethers.Contract(NFT_CONTRACT_ADDRESS, KingNFTABI, signer);

        try {
            const tx = await contract.mintKingNFT();
            await tx.wait();
            alert('King NFT minted successfully!');
            window.location.reload();
        } catch (error) {
            console.error("Minting failed", error);
        }
    };

    if (isLoading) return <p>Loading Kings...</p>;
    if (data && data.length === 0) return (
        <div>
                    <p>You do not own any King NFTs.</p>
                    <button onClick={mintKingNFT}>Mint Your First King</button>
                </div>
    );

    return (
        <div>
            <h1>Game Lobby</h1>
            <div>
                <h2>Create Game</h2>

                {data && data.length > 0 ? (
                    <div style={{ display: 'flex', gap: '20px' }}>
                        {data.map((nft, index) => (
                            <div key={index} style={{ maxWidth: "150px" }}>
                                <img src="/kings/eth.png" alt={nft.metadata.name} style={{ width: '100px', height: '100px' }} />
                                <button onClick={() => { createGame(nft.metadata.id) }}>Create Game With This King {nft.metadata.id}</button>

                                {/* <ThirdwebNftMedia metadata={nft.metadata} /> */}
                            </div>
                        ))}
                    </div>
                ) : (<></>)}
            </div>

            <div>
                <h2>Available Games</h2>
                {availableGames.length === 0 ? (
                    <p>No available games to join.</p>
                ) : (
                    availableGames.map((game, index) => (
                        <div key={index}>
                            <p>Game ID: {game.gameId}</p>
                            <p>Creator: {game.creator}</p>

                            {data && data.map((nft, index) => (
                                <div key={index} style={{ maxWidth: "150px" }}>
                                    <img src="/kings/eth.png" alt={nft.metadata.name} style={{ width: '100px', height: '100px' }} />
                                    <button onClick={() => { joinGame(game.gameId, nft.metadata.id) }}>Join Game With This King {nft.metadata.id}</button>

                                    {/* <ThirdwebNftMedia metadata={nft.metadata} /> */}
                                </div>
                            ))}
                        </div>
                    ))
                )}
            </div>

            <div>
                <h2>Your Games</h2>
                {playerGames.length === 0 ? (
                    <p>You have no active games.</p>
                ) : (
                    playerGames.map((game, index) => (
                        <div key={index}>
                            <p>Game ID: {game.gameId}</p>
                            <p>Opponent: {game.opponent || "Waiting for opponent..."}</p>
                        </div>
                    ))
                )}
            </div>
        </div>
    );
};

export default Lobby;
