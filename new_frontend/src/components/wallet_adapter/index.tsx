import { AptosWalletAdapterProvider } from "@aptos-labs/wallet-adapter-react";
import { PontemWalletAdapter } from "@pontem/aptos-wallet-adapter";
import { PropsWithChildren } from "react";
import { Network } from "@aptos-labs/ts-sdk";

export const WalletProvider = ({ children }: PropsWithChildren) => {
  const wallets = [new PontemWalletAdapter()];

  return (
    <AptosWalletAdapterProvider
      plugins={wallets}
      autoConnect={true}
      dappConfig={{ network: Network.DEVNET }}
      onError={(error: any) => {
        console.log("error", error);
      }}
    >
      {children}
    </AptosWalletAdapterProvider>
  );
};
