import { useState, useEffect } from "react";
import { useWallet } from "@pontem/aptos-wallet-adapter"; // Import the wallet adapter
import { postLoan } from "../../components/lender/contract_functions";
import { Aptos, AptosConfig, Network } from "@aptos-labs/ts-sdk";
import { AptosWalletAdapterProvider } from "@aptos-labs/wallet-adapter-react";

const config = new AptosConfig({ network: Network.DEVNET });
const aptos = new Aptos(config);

const PostLoan = () => {
    const [time, setTime] = useState(0);
    const [amount, setAmount] = useState(0);
    const [interest, setInterest] = useState(0);
    const [error, setError] = useState<string | undefined>('');
    const { account,  signAndSubmitTransaction, connect, disconnect } = useWallet(); // Use wallet functions

    useEffect(() => {
        // Optionally connect to the wallet on mount
        const connectWallet = async () => {
            if (!account) {
                await connect();
            }
        };
        connectWallet();
    }, [account, connect]);

    const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault();  
        if (!account) {
            setError('Please connect your wallet.');
            return;
        }

        try {
            console.log(amount, interest, time, account.address); // Use account.address
            const txn = await postLoan(amount, interest, time, account.address);
            const committedTxn = await signAndSubmitTransaction(txn);
            console.log(`Submitted transaction hash: ${committedTxn.hash}`);
            const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTxn.hash });
            console.log("executed transaction:  ",executedTransaction)

          } catch (err: unknown) {
            if (err instanceof Error) {
                setError(err.message); // Set the error message
            } else {
                setError('Failed to post loan'); // Fallback error message
            }
        }
    };

    return (
        <>
            <h1>Post Loan</h1>
            {!account ? (
              <button onClick={() => connect()}>Connect Wallet</button> 
            ) : (
                <div>
                    <p>Connected Account: {account.address}</p>
                    <button onClick={disconnect}>Disconnect</button>
                </div>
            )}
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
