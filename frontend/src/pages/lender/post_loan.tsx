import { useState } from "react";
import {postLoan} from "../../components/lender/contract_functions"

const PostLoan = () => {
    const [time, setTime] = useState(Number);
    const [amount, setAmount] = useState(Number);
    const [interest, setInterest] = useState(Number);
    const [error, setError] = useState('');
    
    const caller_address = '';
  
    const handleSubmit = async(e: React.FormEvent<HTMLFormElement>) => {
      e.preventDefault();  
      try {
        await postLoan(amount, interest, time, caller_address);
    } catch (err) {
        setError('Failed to post loan');
    }
    };
  
    return (
      <>
      <h1>Post Loan</h1>
      <form  onSubmit={handleSubmit}>
        <input
          type="number"
          placeholder="Amount"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
        />

        <input
          type="number"
          placeholder="Interest"
          value={interest}
          onChange={(e) => setInterest(e.target.value)}
        />
        
        <input
          type="number"
          placeholder="Duration"
          value={time}
          onChange={(e) => setTime(e.target.value)}
        />
        {error && <p>{error}</p>}
        <button type="submit">Submit</button>
      </form>
      </>
    );
}

export default PostLoan;