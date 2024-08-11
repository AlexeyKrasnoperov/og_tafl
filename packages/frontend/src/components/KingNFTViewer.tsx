import React from 'react';
import { ThirdwebNftMedia, useAddress, useWallet, useContract, useOwnedNFTs, SmartContract } from '@thirdweb-dev/react';
import { ethers } from 'ethers';
import KingNFTABI from '../contractInterfaces/KingNFTABI.json';

const KingNFTViewer: React.FC<string> = (nftContractAddress: string) => {
    const address = useAddress();
    const walletInstance = useWallet();

    const { contract } = useContract(nftContractAddress);
    const { data, isLoading, error } = useOwnedNFTs(contract, address);

    const mintKingNFT = async () => {
        if (!address) return;

        const signer = await walletInstance?.getSigner();
        const contract = new ethers.Contract(nftContractAddress, KingNFTABI, signer);

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

    return (
        <div>
            <h1>Your King NFTs</h1>
            {data && data.length > 0 ? (
                <div style={{ display: 'flex', gap: '20px' }}>
                    {data.map((nft, index) => (
                        <div key={index}>
                            <ThirdwebNftMedia metadata={nft.metadata} />
                        </div>
                    ))}
                </div>
            ) : (
                <div>
                    <p>You do not own any King NFTs.</p>
                    <button onClick={mintKingNFT}>Mint Your First King</button>
                </div>
            )}
        </div>
    );
};

export default KingNFTViewer;
