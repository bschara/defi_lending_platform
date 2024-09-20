import { Aptos, AptosConfig, Network } from "@aptos-labs/ts-sdk";

const config = new AptosConfig({ network: Network.TESTNET });
const aptos = new Aptos(config);

const prefix = `${process.env.ADDRESS}::${process.env.MODULE}::`;
const contract_address = process.env.CONTRACT_ADDRESS;

const postLoan = async(amount: number, interest: number, time: number, caller_address: string, ) => {
    const functionName = "postLoan"; 
    const fullFunctionName = `${prefix}${functionName}` as `${string}::${string}::${string}`; 

    await aptos.transaction.build.simple({
        sender: caller_address,
        data: {
          function: fullFunctionName,
          functionArguments: [contract_address, amount, interest, time],
        },
      });
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