import { Aptos, AptosConfig, Network } from "@aptos-labs/ts-sdk";

const config = new AptosConfig({ network: Network.DEVNET });
const aptos = new Aptos(config);

const prefix = `${process.env.NEXT_PUBLIC_CONTRACT_ADDRESS}::${process.env.NEXT_PUBLIC_MAIN_MODULE}::`;
const contract_address = "process.env.NEXT_PUBLIC_CONTRACT_ADDRESS";

const postLoan = async(amount: number, interest: number, time: number, caller_address: string) => {
    const functionName = "postLoan"; 
    const fullFunctionName = `${prefix}${functionName}` as `${string}::${string}::${string}`; 

    const transaction = await aptos.transaction.build.simple({
        sender: caller_address,
        data: {
          function: fullFunctionName,
          functionArguments: [contract_address, amount, interest, time],
        },
      });

      return transaction;

};

const liquidateLoan = async(loan_id: number, caller_address: string) => {
    const functionName = "liquidateLoan"; 
    const fullFunctionName = `${prefix}${functionName}` as `${string}::${string}::${string}`; 
    await aptos.transaction.build.simple({
        sender: caller_address,
        data: {
          function: fullFunctionName,
          functionArguments: [loan_id],
        },
      });

};

export {postLoan, liquidateLoan};