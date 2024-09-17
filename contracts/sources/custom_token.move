module LFPlatform::MyCustomToken {
    use std::error;
    use std::option::{Self, Option};
    use std::signer;
    use std::string::{Self, String};
    use aptos_framework::object::{Self, ConstructorRef, Object};
    use aptos_token_objects::collection;
    use aptos_token_objects::token;
    use aptos_std::string_utils;
    use std::debug;


    const EINVALID_CREATOR: u64 = 1;


    struct OnChainConfig has key {
        collection: String,
    }

    struct CollatNFT has key {
        category: String,
        price: u64,
        mutator_ref: token::MutatorRef,
    }

    // Initialize the module by creating a collection for tokens
    fun init_module(account: &signer) {
        let collection = string::utf8(b"Lending Platform NFTs");
        collection::create_unlimited_collection(
            account,
            string::utf8(b"collection description"),
            collection,
            option::none(),
            string::utf8(b"collection uri"),
        );

        let on_chain_config = OnChainConfig {
            collection,
        };
        move_to(account, on_chain_config);
    }

    fun create(
        creator: &signer,
        description: String,
        name: String,
        uri: String,
    ): ConstructorRef acquires OnChainConfig {
        let on_chain_config = borrow_global<OnChainConfig>(signer::address_of(creator));
        token::create_named_token(
            creator,
            on_chain_config.collection,
            description,
            name,
            option::none(),
            uri,
        )
    }

    // Creation methods

    public fun create_nft(
        creator: &signer,
        description: String,
        name: String,
        _category: String,
        _price: u64,
        uri: String,
    ): Object<CollatNFT> acquires OnChainConfig {
        let constructor_ref = create(creator, description, name, uri);
        let token_signer = object::generate_signer(&constructor_ref);

        let collatNFT = CollatNFT {
            category: _category,
            price: _price,
            mutator_ref: token::generate_mutator_ref(&constructor_ref),
        };
        move_to(&token_signer, collatNFT);

        object::address_to_object(signer::address_of(&token_signer))
    }


    public fun transfer_token(
        sender: &signer,
        receiver: address,
        token: Object<CollatNFT>
    )  {
        object::transfer(sender, token, receiver);
    }

        #[test(lender=@0x123, contract=@0x01, framework = @0x1, borrower = @0x12312)]
        public fun test_token_contract(lender: &signer, contract: &signer, framework: signer, borrower: &signer) acquires OnChainConfig {
                init_module(contract);

                let name = string::utf8(b"token 1");
                let description = string::utf8(b"new token 1");
                let category = string::utf8(b"cat1");
                let price = 1;
                let uri = string::utf8(b"dummy uri");
                let nft = create_nft(contract, description, name, category, price, uri);
                // debug::print(&nft);
                transfer_token(contract, signer::address_of(lender), nft);
            
            }
}