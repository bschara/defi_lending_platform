import { useState } from "react";
// import { useWallet, WalletName } from "@pontem/aptos-wallet-adapter"; // Import the wallet adapter
import {
  Aptos,
  AptosConfig,
  buildTransaction,
  Network,
  TransactionPayloadEntryFunction,
} from "@aptos-labs/ts-sdk";
import {
  InputTransactionData,
  WalletName,
  useWallet,
} from "@aptos-labs/wallet-adapter-react";

const config = new AptosConfig({ network: Network.DEVNET });
const aptos = new Aptos(config);

const PostLoan = () => {
  const prefix = `${import.meta.env.VITE_NEXT_PUBLIC_CONTRACT_ADDRESS}::${
    import.meta.env.VITE_NEXT_PUBLIC_MAIN_MODULE
  }::`;

  const [time, setTime] = useState(0);
  const [amount, setAmount] = useState(0);
  const [interest, setInterest] = useState(0);
  const [error, setError] = useState<string | undefined>("");
  const { connect, disconnect, account, connected, signAndSubmitTransaction } =
    useWallet();

  const handleConnect = async () => {
    try {
      await connect("Pontem Wallet" as WalletName<"Pontem Wallet">);
      // await connect();
      console.log("Connected to wallet:", account);
    } catch (error) {
      console.error("Failed to connect to wallet:", error);
    }
  };

  const handleDisconnect = async () => {
    try {
      await disconnect();
      console.log("Disconnected from wallet");
    } catch (error) {
      console.error("Failed to disconnect from wallet:", error);
    }
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (!account) {
      setError("Please connect your wallet.");
      return;
    }

    try {
      console.log(amount, interest, time, account.address); // Use account.address
      const functionName = "postLoan";
      const fullFunctionName =
        `${prefix}${functionName}` as `${string}::${string}::${string}`;
      const transactionPayload: InputTransactionData = {
        data: {
          function: fullFunctionName,
          typeArguments: [],
          functionArguments: [
            // account,
            "0x39aaed73a211ef4e9068a6ba00a8e487363f6858fbfca063f1d6c7fd94b003f3",
            amount,
            interest,
            time,
          ],
        },
      };

      const trans = await aptos.transaction.build.simple({
        sender: account.address,
        data: {
          function: fullFunctionName,
          functionArguments: [
            "0x39aaed73a211ef4e9068a6ba00a8e487363f6858fbfca063f1d6c7fd94b003f3",
            amount,
            interest,
            time,
          ],
        },
      });

      const [userTransactionResponse] = await aptos.transaction.simulate.simple(
        {
          transaction: trans,
        }
      );
      console.log(userTransactionResponse);

      const response = await signAndSubmitTransaction(transactionPayload);

      const resHash = await aptos.waitForTransaction({
        transactionHash: response.hash,
      });

      console.log("transaction hash ", resHash);
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message); // Set the error message
      } else {
        setError("Failed to post loan"); // Fallback error message
      }
    }
  };

  return (
    <>
      <h1>Post Loan</h1>
      <div>
        {connected ? (
          <div>
            <p>Connected to: {account?.address?.toString()}</p>
            <button onClick={handleDisconnect}>Disconnect</button>
          </div>
        ) : (
          <button onClick={handleConnect}>Connect Wallet</button>
        )}
      </div>
      <form onSubmit={handleSubmit}>
        <input
          type="number"
          placeholder="Amount"
          value={amount}
          onChange={(e) => setAmount(Number(e.target.value))}
        />
        <input
          type="number"
          placeholder="Interest"
          value={interest}
          onChange={(e) => setInterest(Number(e.target.value))}
        />
        <input
          type="number"
          placeholder="Duration"
          value={time}
          onChange={(e) => setTime(Number(e.target.value))}
        />
        {error && <p>{error}</p>}
        <button type="submit">Submit</button>
      </form>
    </>
  );
};

export default PostLoan;
