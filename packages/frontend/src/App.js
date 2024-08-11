import './App.css';
import KingNFTViewer from './components/KingNFTViewer.tsx';
import OgtaflBoard from './components/OgtaflBoard.tsx';
import Lobby from './components/Lobby.tsx';
import { ThirdwebProvider, ConnectWallet, useAddress, useOwnedNFTs, useContract, useDisconnect } from "@thirdweb-dev/react";

function App() {
  const NFT_CONTRACT_ADDRESS = "0x88029C2f6aa77c8236Dd1A1B61AE3201D851adC2";

  const disconnect = useDisconnect();
  const address = useAddress();

  return (
      <div className="App">
        <div>
          {address ? (
            <>
              <p>Connected as: {address}</p>
              <button onClick={disconnect}>Disconnect</button>
            </>
          ) : (
            <ConnectWallet />
          )}
        </div>
        <header className="App-header">
          <h1>OG Tafl</h1>

          { address ? <Lobby nftContractAddress={NFT_CONTRACT_ADDRESS} /> : "Connect your wallet to see your Kings" }
          <OgtaflBoard />
          {/* <KingNFTViewer contractAddress={NFT_CONTRACT_ADDRESS} /> */}
        </header>
      </div>
  );
}

export default function MyApp() {
  return (
    <ThirdwebProvider activeChain="sepolia" clientId={process.env.THIRDWEB_CLIENT_ID}>
      <App />
    </ThirdwebProvider>
  );
}
