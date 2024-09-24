module LFPlatform::Main {
    use std::vector;
    use std::simple_map::{Self, SimpleMap};   
    use std::signer;
    use aptos_framework::aptos_account;
    use aptos_framework::debug;
    use std::string::{String, utf8};
    use std::timestamp; 
    use std::coin;
    use std::aptos_coin;
    use std::account;


    const NO_PAYMENT_FOUND: u64 = 18446744073709551615;  // This is 2^64 - 1

    struct OnGoingLoans has store, key {
        list: SimpleMap<u64, LoanContract>,
        counter: u64,
    }

    struct LenderLoans has store, key {
     list: SimpleMap<address, vector<u64>>,
    }

    struct CustomerLoans has store, key {
     list: SimpleMap<address, vector<u64>>,
    }

    struct LoanContract has key, copy, drop, store {
        id: u64,
        lender: address,
        borrower: address,
        nft_id: u64,
        amount: u64,
        interest: u64,
        total_amount: u64,
        payment_stubs: vector<PaymentSlips>,
        duration: u64,
        isPaid: bool
    }


    struct PaymentSlips has key, copy, drop, store {
        amount_next: u64,
        paid: bool,
        next_date: u64,
    }

    public entry fun postLoan(lender: &signer, contract: address, amount: u64, interest: u64, time: u64) acquires OnGoingLoans {
        // let borrower_balance = coin::balance<aptos_coin::AptosCoin>(signer::address_of(lender));
        // assert!(borrower_balance >= amount, 1000);
        
        // let withdrawn_coin = coin::withdraw<aptos_coin::AptosCoin>(lender, amount);
        // coin::deposit<aptos_coin::AptosCoin>(signer::address_of(contract), withdrawn_coin);
        

        let borrower_balance = LFPlatform::BasicTokens::balance_of(signer::address_of(lender));
        assert!(borrower_balance >= amount, 1000);
        
        let withdrawn_coin = LFPlatform::BasicTokens::withdraw(signer::address_of(lender), amount);
        LFPlatform::BasicTokens::deposit(contract, withdrawn_coin);

        let tmpCounter = &mut borrow_global_mut<OnGoingLoans>(contract).counter;
        let counter = *tmpCounter;
        let account = signer::address_of(lender);
        let totAmount = amount + ((amount * interest) / 100);
        let t1=timestamp::now_microseconds();
        let payStubs: vector<PaymentSlips> = generatePaymentStubs(amount, time, t1);
        let newLoan = LoanContract {
            id: counter,
            lender: account,
            borrower: @0x00,
            amount: amount,
            interest: interest,
            total_amount: totAmount,
            payment_stubs: payStubs,
            duration: time,
            isPaid: false,
            nft_id: 0,
        };
        *tmpCounter = counter + 1;
        let onLoans = borrow_global_mut<OnGoingLoans>(contract);
        simple_map::add(&mut onLoans.list, counter, newLoan);

        let event = CreateLoanEvent{
            loan_id: counter,
            lender: account
        };

        0x1::event::emit(event);
    }

    fun init_module(deployer: &signer){
        let onLoans = OnGoingLoans {
            list: simple_map::new<u64, LoanContract>(),
            counter: 0
        };

        let custLoans = CustomerLoans {
            list: simple_map::new<address, vector<u64>>(),
        };
                
        let lendLoans = LenderLoans {
            list: simple_map::new<address, vector<u64>>(),
        };
        
        move_to(deployer , onLoans);
        move_to(deployer , custLoans);
        move_to(deployer , lendLoans);
    }

    fun generatePaymentStubs(amount: u64, numOfMonth: u64, timestamps: u64): vector<PaymentSlips> {
        let amountPerMonth = amount / numOfMonth;
        let ts = timestamps;
        let my_vector: vector<PaymentSlips> = vector::empty<PaymentSlips>();
        let i = 1;
        while (i <= numOfMonth){
            let payment_slip = PaymentSlips {
                amount_next: amountPerMonth,
                paid: false,
                next_date: ts,
            };

            vector::push_back(&mut my_vector, payment_slip);
            i = i + 1;
            ts = ts + 2592000000000;
        };
   
            my_vector
    }

    // public fun liquidateLoan(): bool acquires OnGoingLoans {
    //         true
    // }

    public entry fun setBorrower(contract_id: u64,contract: address, borrower: &signer, nft_ID: u64) acquires OnGoingLoans{
                let borrower_addr = signer::address_of(borrower);
                // let borrower_balance = coin::balance<aptos_coin::AptosCoin>(borrower_addr);
                // assert!(borrower_balance >= 10, 1000);
                let on_going_loans = borrow_global_mut<OnGoingLoans>(contract);
                let contract = simple_map::borrow_mut(&mut on_going_loans.list, &contract_id);
                let lender = contract.lender;
                contract.borrower = borrower_addr;
                contract.nft_id = nft_ID; 

                let event = BorrowEvent {
                    loan_id: contract_id,
                    lender: lender,
                    borrower: borrower_addr

                };
                0x1::event::emit(event);
    }

    fun closeLoan(contract: &mut LoanContract): bool {
        let paystubs = &contract.payment_stubs;
        let i = 0;
        let duration = vector::length(paystubs);

        // Loop over all payment stubs to check if all payments have been made
        while (i < duration) {
            let payment_ref = vector::borrow(paystubs, i);
            if (!payment_ref.paid) {
                return false
            };
            i = i + 1;
        };
              true 
    }

    public entry fun makePayment(borrower: &signer, contract: address, amount: u64 , loan_id: u64) acquires OnGoingLoans {
        let loan_contract = borrow_global_mut<OnGoingLoans>(contract).list;
        let lender_address = simple_map::borrow(&loan_contract, &loan_id).lender;
        
        let payment_slip_index = getNextPayment(loan_id, contract);
        let payment_slip_vector = simple_map::borrow_mut(&mut loan_contract, &loan_id).payment_stubs;
        let payment_slip = vector::borrow_mut(&mut payment_slip_vector, payment_slip_index);

        assert!(payment_slip.amount_next > 0, 10);

        let borrower_balance = LFPlatform::BasicTokens::balance_of(signer::address_of(borrower));
        assert!(borrower_balance >= amount, 1000);
        
        let withdrawn_coin = LFPlatform::BasicTokens::withdraw(signer::address_of(borrower), amount);
        LFPlatform::BasicTokens::deposit(lender_address, withdrawn_coin);

        // let borrower_balance = coin::balance<aptos_coin::AptosCoin>(signer::address_of(borrower));
        // assert!(borrower_balance >= amount, 1000);
        
        // let withdrawn_coin = coin::withdraw<aptos_coin::AptosCoin>(borrower, amount);
        // coin::deposit<aptos_coin::AptosCoin>(lender_address, withdrawn_coin);

        payment_slip.paid = true;

        let event = MakePaymentEvent{
            loan_id: loan_id,
            lender: lender_address,
            borrower: signer::address_of(borrower),
            amount: amount
        };

        0x1::event::emit(event);


    }


    // public fun makeFullPayemnt(borrower: &signer) : bool acquires LoanContract, OnGoingLoans, CustomerLoans {
    //         true
    // }

    public fun getNextPayment(loan_id: u64, contract: address) : u64 acquires OnGoingLoans{
        let loan_contract = borrow_global<OnGoingLoans>(contract).list;
        let current_loan_payments = simple_map::borrow(&loan_contract, &loan_id).payment_stubs;

        let duration = vector::length(&current_loan_payments);
        for( i in 0..duration){
            let slip = vector::borrow(&current_loan_payments, i);
            if(slip.paid == false){
                return i
            }
        };
        return NO_PAYMENT_FOUND
    }

    #[event]
    struct CreateLoanEvent has drop, store {
        loan_id: u64 ,
        lender: address
        }

    #[event]
    struct BorrowEvent has drop, store {
        loan_id: u64,
        lender: address,
        borrower: address
        }

    #[event]
    struct MakePaymentEvent has drop, store {
        loan_id: u64,
        lender: address,
        borrower: address,
        amount: u64
        }

    #[event]
    struct LiquidateLoanEvent has drop, store {
        loan_id: u64,
        lender: address,
        borrower: address
        }    

    #[event]
    struct CloseLoanEvent has drop, store {
        loan_id: u64,
        lender: address,
        borrower: address
        }
    
        #[test(lender=@0x123, contract=@0x01, framework = @0x1, borrower = @0x12312)]
        public fun test_postLoan(lender: &signer, contract: &signer, framework: signer, borrower: &signer)  acquires OnGoingLoans{
                timestamp::set_time_has_started_for_testing(&framework);
                let on_going_loans = OnGoingLoans { counter: 0, list: simple_map::new<u64, LoanContract>() };
                // debug::print(&on_going_loans);
                move_to(contract, on_going_loans);

                let contract_addr = signer::address_of(contract);

                account::create_account_for_test(signer::address_of(lender));
                LFPlatform::BasicTokens::publish_balance(lender);

                account::create_account_for_test(contract_addr);
                LFPlatform::BasicTokens::publish_balance(contract);

                account::create_account_for_test(signer::address_of(borrower));
                LFPlatform::BasicTokens::publish_balance(borrower);

                // let contract_list = borrow_global_mut<OnGoingLoans>(contract_addr);
                // let list = contract_list.list;

                // Mint some tokens to Alice
                LFPlatform::BasicTokens::mint<LFPlatform::BasicTokens::Coin>(signer::address_of(lender), 50000);
                LFPlatform::BasicTokens::mint<LFPlatform::BasicTokens::Coin>(signer::address_of(borrower), 30000);

                let borrower3_balance = LFPlatform::BasicTokens::balance_of(signer::address_of(lender)); 
                debug::print(&borrower3_balance);

                let amount = 20000;
                let interest = 19;
                let dur = 1;

                postLoan(lender, contract, amount, interest, dur);

                // let nf_id = 1234323423;
                // debug::print(&cr.list);
                // let loan_ref = simple_map::borrow_mut(&mut cr.list, &0);
                // let paid_loan = closeLoan(loan_ref);
                // debug::print(loan_ref);
                // debug::print(&paid_loan);
                // let msg = utf8(b"after setting borrower");
                // debug::print(&msg);
                // setBorrower(0, contract, borrower, nf_id);
                let borrower_balance = LFPlatform::BasicTokens::balance_of(contract_addr); 
                debug::print(&borrower_balance);

                let borrower2_balance = LFPlatform::BasicTokens::balance_of(signer::address_of(lender)); 
                debug::print(&borrower2_balance);

                let borrower4_balance = LFPlatform::BasicTokens::balance_of(signer::address_of(borrower)); 
                debug::print(&borrower4_balance);

                let pay_amount = 20000;
                makePayment(contract, borrower, pay_amount, 0);

                let onLoans = borrow_global<OnGoingLoans>(contract_addr).list;
                debug::print(&onLoans); 

                let borrower5_balance = LFPlatform::BasicTokens::balance_of(signer::address_of(borrower)); 
                debug::print(&borrower5_balance);



            }
        }