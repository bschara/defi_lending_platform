import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import LandingPage from "./pages/landing_page";
import PostLoan from "./pages/post_loan";
import {
  AptosWalletAdapterProvider,
  AvailableWallets,
} from "@aptos-labs/wallet-adapter-react";
// import { PontemWallet } from "@pontem/wallet-adapter-plugin";
import { Network } from "@aptos-labs/ts-sdk";
import { PropsWithChildren } from "react";

const App = ({ children }: PropsWithChildren) => {
  let wallets: AvailableWallets[] = ["Pontem Wallet", "Petra"];

  return (
    <AptosWalletAdapterProvider
      optInWallets={wallets}
      autoConnect={true}
      dappConfig={{ network: Network.DEVNET }}
      onError={(error) => {
        console.log("error", error);
      }}
    >
      {children}
      <Router>
        <Routes>
          <Route path="/" element={<LandingPage />} />
          <Route path="/postLoan" element={<PostLoan />} />
        </Routes>
      </Router>
    </AptosWalletAdapterProvider>
  );
};

export default App;
