```rust
#![cfg_attr(not(feature = "std"), no_std)]

// Define the modules for various functionalities.
pub mod utils;
pub mod staking;
pub mod governance;
pub mod pricing;

// Import necessary dependencies.
use ink_lang:: {
    contract, 
    env::CallFlags, 
    codegen::Env, 
    EnvAccess,
    EmitEvent,
    reflect::ContractEvent
};
use ink_storage:: {
    traits::{PackedLayout, SpreadLayout},
    collections::{
        HashMap as StorageHashMap,
        Vec as StorageVec,
    },
    Lazy,
};

use scale::{Decode, Encode};
use ink_prelude::{
    vec::Vec,
    string::String,
};

#[derive(Debug, PartialEq, Eq, Encode, Decode, Clone)]
#[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
pub enum Error {
    /// Returned if the account doesn't exist.
    AccountNotFound,
    /// Returned if the account is not valid.
    InvalidAccount,
    /// Returned if the caller is not the owner.
    NotOwner,
    /// Returned if the value is out of range.
    ValueOutOfRange,
    /// Returned if the balance is insufficient.
    InsufficientBalance,
    /// Returned if the staking period is not valid.
    InvalidStakingPeriod,
    /// Returned if the staking amount is not valid.
    InvalidStakingAmount,
    /// Returned if the contract is paused.
    ContractPaused,
    /// Returned if the operation is not allowed.
    NotAllowed,
    /// Returned if the proposal is not found.
    ProposalNotFound,
    /// Returned if the voting period is not valid.
    InvalidVotingPeriod,
    /// Returned if the user has already voted.
    AlreadyVoted,
    /// Returned if the pricing data is not valid.
    InvalidPricingData,
    /// Returned if the conversion failed.
    ConversionFailed,
    /// Returned if the Overflow occurred.
    Overflow,
    /// Returned if the Underflow occurred.
    Underflow,
    /// Returned if the DivisionByZero occurred.
    DivisionByZero,
    /// Custom error message.
    Custom(String),
}

pub type Result<T> = core::result::Result<T, Error>;

// Defining events for important state changes
#[ink::event]
pub struct OwnershipTransferred {
    #[ink(topic)]
    previous_owner: Option<AccountId>,
    #[ink(topic)]
    new_owner: Option<AccountId>,
}

#[ink::event]
pub struct ContractPaused {
    #[ink(topic)]
    by: AccountId,
}

#[ink::event]
pub struct ContractUnpaused {
    #[ink(topic)]
    by: AccountId,
}

#[ink::event]
pub struct GenericEvent {
    #[ink(topic)]
    name: String,
    data: Vec<(String, String)>,
}

/// A smart contract implementing dynamic DeFi strategies with on-chain governance and pricing oracles.
#[ink::contract]
mod dynamic_defi {
    use super::*;

    /// Defines the storage of your contract.
    #[ink(storage)]
    pub struct DynamicDefi {
        /// Contract Owner.
        owner: AccountId,
        /// Flag indicating if the contract is paused.
        paused: bool,
        /// Total supply of the governance token.
        total_supply: Balance,
        /// Mapping from account id to balance.
        balances: StorageHashMap<AccountId, Balance>,
        /// Staking module.
        staking: staking::StakingModule,
        /// Governance module.
        governance: governance::GovernanceModule,
        /// Pricing oracle module.
        pricing: pricing::PricingModule,
    }

    impl DynamicDefi {
        /// Constructor that initializes the contract.
        #[ink(constructor)]
        pub fn new(initial_supply: Balance) -> Self {
            let caller = Self::env().caller();
            let mut balances = StorageHashMap::new();
            balances.insert(caller, initial_supply);

            Self {
                owner: caller,
                paused: false,
                total_supply: initial_supply,
                balances,
                staking: staking::StakingModule::new(),
                governance: governance::GovernanceModule::new(),
                pricing: pricing::PricingModule::new(),
            }
        }

        /// Returns the total supply of the token.
        #[ink(message)]
        pub fn total_supply(&self) -> Balance {
            self.total_supply
        }

        /// Returns the balance of the account.
        #[ink(message)]
        pub fn balance_of(&self, owner: AccountId) -> Balance {
            *self.balances.get(&owner).unwrap_or(&0)
        }

        /// Transfers token from the caller to the `to` AccountId.
        #[ink(message)]
        pub fn transfer(&mut self, to: AccountId, value: Balance) -> Result<()> {
            let from = self.env().caller();
            self.transfer_from_to(from, to, value)
        }

        /// Transfers token from the `from` AccountId to the `to` AccountId.
        #[ink(message)]
        pub fn transfer_from_to(&mut self, from: AccountId, to: AccountId, value: Balance) -> Result<()> {
            if self.paused {
                return Err(Error::ContractPaused);
            }

            let from_balance = self.balance_of(from);
            if from_balance < value {
                return Err(Error::InsufficientBalance);
            }

            self.balances.insert(from, from_balance - value);
            let to_balance = self.balance_of(to);
            self.balances.insert(to, to_balance + value);
            Ok(())
        }

        /// Returns the owner of the contract.
        #[ink(message)]
        pub fn owner(&self) -> AccountId {
            self.owner
        }

        /// Transfers ownership of the contract to the `new_owner`.
        #[ink(message)]
        pub fn transfer_ownership(&mut self, new_owner: AccountId) -> Result<()> {
            self.ensure_caller_is_owner()?;

            let previous_owner = Some(self.owner);
            self.owner = new_owner;
            self.env().emit_event(OwnershipTransferred {
                previous_owner,
                new_owner: Some(new_owner),
            });
            Ok(())
        }

        /// Pauses the contract.
        #[ink(message)]
        pub fn pause(&mut self) -> Result<()> {
            self.ensure_caller_is_owner()?;
            if self.paused {
                return Err(Error::Custom(String::from("Contract already paused.")));
            }
            self.paused = true;
            self.env().emit_event(ContractPaused { by: self.env().caller() });
            Ok(())
        }

        /// Unpauses the contract.
        #[ink(message)]
        pub fn unpause(&mut self) -> Result<()> {
            self.ensure_caller_is_owner()?;
            if !self.paused {
                return Err(Error::Custom(String::from("Contract already unpaused.")));
            }
            self.paused = false;
            self.env().emit_event(ContractUnpaused { by: self.env().caller() });
            Ok(())
        }

        /// Returns true if the contract is paused, false otherwise.
        #[ink(message)]
        pub fn paused(&self) -> bool {
            self.paused
        }

        /// Executes a strategy. This is a placeholder. Needs to be implemented with actual DeFi strategy logic.
        #[ink(message)]
        pub fn execute_strategy(&mut self, strategy_id: u32, params: Vec<u8>) -> Result<()> {
            // Check if the contract is paused.
            if self.paused {
                return Err(Error::ContractPaused);
            }

            // This is just a placeholder.
            // Actual logic should be implemented based on the strategy.
            self.env().emit_event(GenericEvent {
                name: String::from("StrategyExecuted"),
                data: vec![
                    (String::from("strategy_id"), strategy_id.to_string()),
                    (String::from("params"), String::from_utf8_lossy(&params).to_string()),
                ],
            });

            Ok(())
        }

        /// ----------- Staking Module --------------
        /// Delegate calls to the Staking Module.
        #[ink(message)]
        pub fn stake(&mut self, amount: Balance, duration: u64) -> Result<()> {
            self.staking.stake(self.env().caller(), amount, duration)
        }

        #[ink(message)]
        pub fn withdraw(&mut self) -> Result<()> {
            self.staking.withdraw(self.env().caller())
        }

        #[ink(message)]
        pub fn get_staking_info(&self, account: AccountId) -> Result<staking::StakingInfo> {
            self.staking.get_staking_info(account)
        }

        /// ----------- Governance Module --------------
        /// Delegate calls to the Governance Module.
        #[ink(message)]
        pub fn create_proposal(
            &mut self,
            description: String,
            target_contract: AccountId,
            encoded_call: Vec<u8>,
        ) -> Result<()> {
            self.governance.create_proposal(
                self.env().caller(),
                description,
                target_contract,
                encoded_call,
            )
        }

        #[ink(message)]
        pub fn vote(&mut self, proposal_id: u32, support: bool) -> Result<()> {
            self.governance.vote(self.env().caller(), proposal_id, support)
        }

        #[ink(message)]
        pub fn execute_proposal(&mut self, proposal_id: u32) -> Result<()> {
            self.governance.execute_proposal(proposal_id)
        }

        #[ink(message)]
        pub fn get_proposal_state(&self, proposal_id: u32) -> Result<governance::ProposalState> {
            self.governance.get_proposal_state(proposal_id)
        }

        /// ----------- Pricing Module --------------
        /// Delegate calls to the Pricing Module.
        #[ink(message)]
        pub fn set_price(&mut self, asset: String, price: u128) -> Result<()> {
            self.pricing.set_price(asset, price)
        }

        #[ink(message)]
        pub fn get_price(&self, asset: String) -> Result<u128> {
            self.pricing.get_price(asset)
        }

        /// Converts an amount from one asset to another based on current prices.
        #[ink(message)]
        pub fn convert(&self, from_asset: String, to_asset: String, amount: u128) -> Result<u128> {
            let from_price = self.pricing.get_price(from_asset.clone())?;
            let to_price = self.pricing.get_price(to_asset.clone())?;

            if to_price == 0 {
                return Err(Error::DivisionByZero);
            }

            let result = amount.checked_mul(from_price)
                .ok_or(Error::Overflow)?
                .checked_div(to_price)
                .ok_or(Error::DivisionByZero)?;

            Ok(result)
        }

        /// Helper function to ensure the caller is the owner.
        fn ensure_caller_is_owner(&self) -> Result<()> {
            if self.env().caller() != self.owner {
                return Err(Error::NotOwner);
            }
            Ok(())
        }

        /// Helper function to transfer tokens internally
        fn _transfer(&mut self, from: AccountId, to: AccountId, value: Balance) -> Result<()> {
            let from_balance = self.balance_of(from);
            if from_balance < value {
                return Err(Error::InsufficientBalance);
            }

            self.balances.insert(from, from_balance - value);
            let to_balance = self.balance_of(to);
            self.balances.insert(to, to_balance + value);
            Ok(())
        }
    }

    /// Unit tests in Rust are normally defined within such a module and are
    /// conditionally compiled.
    #[cfg(test)]
    mod tests {
        /// Imports all the definitions from the outer scope so we can use them here.
        use super::*;

        use ink_lang as ink;

        /// We test if the default constructor does its job.
        #[ink::test]
        fn default_works() {
            let dynamic_defi = DynamicDefi::new(1000);
            assert_eq!(dynamic_defi.total_supply(), 1000);
        }

        /// We test a simple use case of our contract.
        #[ink::test]
        fn it_works() {
            let mut dynamic_defi = DynamicDefi::new(1000);
            assert_eq!(dynamic_defi.balance_of(AccountId::from([0x01; 32])), 1000);
            assert_eq!(dynamic_defi.transfer(AccountId::from([0x02; 32]), 10), Ok(()));
            assert_eq!(dynamic_defi.balance_of(AccountId::from([0x01; 32])), 990);
            assert_eq!(dynamic_defi.balance_of(AccountId::from([0x02; 32])), 10);
        }

        #[ink::test]
        fn transfer_fails_on_insufficient_balance() {
            let mut dynamic_defi = DynamicDefi::new(100);
            assert_eq!(
                dynamic_defi.transfer(AccountId::from([0x02; 32]), 200),
                Err(Error::InsufficientBalance)
            );
        }

        #[ink::test]
        fn only_owner_can_pause_and_unpause() {
            let mut dynamic_defi = DynamicDefi::new(100);
            let accounts = ink_env::test::default_accounts::<ink_env::DefaultEnvironment>().unwrap();

            // Trying to pause with a non-owner account should fail.
            ink_env::test::set_caller::<ink_env::DefaultEnvironment>(accounts.bob);
            assert_eq!(dynamic_defi.pause(), Err(Error::NotOwner));

            // Pause with the owner account.
            ink_env::test::set_caller::<ink_env::DefaultEnvironment>(accounts.alice);
            assert_eq!(dynamic_defi.pause(), Ok(()));
            assert_eq!(dynamic_defi.paused(), true);

            // Trying to unpause with a non-owner account should fail.
            ink_env::test::set_caller::<ink_env::DefaultEnvironment>(accounts.bob);
            assert_eq!(dynamic_defi.unpause(), Err(Error::NotOwner));

            // Unpause with the owner account.
            ink_env::test::set_caller::<ink_env::DefaultEnvironment>(accounts.alice);
            assert_eq!(dynamic_defi.unpause(), Ok(()));
            assert_eq!(dynamic_defi.paused(), false);
        }

        #[ink::test]
        fn transfer_fails_when_paused() {
            let mut dynamic_defi = DynamicDefi::new(100);
            let accounts = ink_env::test::default_accounts::<ink_env::DefaultEnvironment>().unwrap();

            // Pause the contract.
            ink_env::test::set_caller::<ink_env::DefaultEnvironment>(accounts.alice);
            assert_eq!(dynamic_defi.pause(), Ok(()));
            assert_eq!(dynamic_defi.paused(), true);

            // Attempting a transfer while paused should fail.
            assert_eq!(
                dynamic_defi.transfer(AccountId::from([0x02; 32]), 50),
                Err(Error::ContractPaused)
            );

            // Unpause the contract.
            assert_eq!(dynamic_defi.unpause(), Ok(()));
            assert_eq!(dynamic_defi.paused(), false);

            // Transfer should now succeed.
            assert_eq!(dynamic_defi.transfer(AccountId::from([0x02; 32]), 50), Ok(()));
        }

        #[ink::test]
        fn test_strategy_execution() {
            let mut dynamic_defi = DynamicDefi::new(100);

            // Execute a strategy.
            let result = dynamic_defi.execute_strategy(1, vec![1, 2, 3]);
            assert!(result.is_ok());
        }

         #[ink::test]
        fn test_convert() {
            let mut dynamic_defi = DynamicDefi::new(100);

            // Set prices
            dynamic_defi.pricing.set_price("ETH".to_string(), 3000).unwrap();
            dynamic_defi.pricing.set_price("USD".to_string(), 1).unwrap();

            // Convert 1 ETH to USD
            let result = dynamic_defi.convert("ETH".to_string(), "USD".to_string(), 1).unwrap();
            assert_eq!(result, 3000);

             // Convert 3000 USD to ETH
            let result = dynamic_defi.convert("USD".to_string(), "ETH".to_string(), 3000).unwrap();
            assert_eq!(result, 1);
        }
    }
}

// -------------------------- Module Implementations --------------------------

pub mod staking {
    use super::*;

    #[derive(Debug, PartialEq, Eq, Encode, Decode, Clone, SpreadLayout, PackedLayout)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub struct StakingInfo {
        amount: Balance,
        start_time: Timestamp,
        duration: u64, // Staking duration in blocks.
    }

    #[ink::event]
    pub struct Staked {
        #[ink(topic)]
        account: AccountId,
        amount: Balance,
        duration: u64,
    }

    #[ink::event]
    pub struct Withdrawn {
        #[ink(topic)]
        account: AccountId,
        amount: Balance,
    }

    #[derive(Debug, Encode, Decode, Clone, SpreadLayout, PackedLayout)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub struct StakingModule {
        stakers: StorageHashMap<AccountId, StakingInfo>,
        min_staking_duration: u64,
        max_staking_duration: u64,
        min_staking_amount: Balance,
    }

    impl StakingModule {
        pub fn new() -> Self {
            Self {
                stakers: StorageHashMap::new(),
                min_staking_duration: 100,   // Minimum 100 blocks.
                max_staking_duration: 10000, // Maximum 10000 blocks.
                min_staking_amount: 10,      // Minimum 10 tokens.
            }
        }

        /// Stakes tokens for a given duration.
        pub fn stake(&mut self, account: AccountId, amount: Balance, duration: u64) -> Result<()> {
            // Validate input parameters.
            if amount < self.min_staking_amount {
                return Err(Error::InvalidStakingAmount);
            }

            if duration < self.min_staking_duration || duration > self.max_staking_duration {
                return Err(Error::InvalidStakingPeriod);
            }

            let current_time = Self::env().block_timestamp();
            let staking_info = StakingInfo {
                amount,
                start_time: current_time,
                duration,
            };

            self.stakers.insert(account, staking_info.clone());
            Self::env().emit_event(Staked {
                account,
                amount,
                duration,
            });

            Ok(())
        }

        /// Withdraws staked tokens.
        pub fn withdraw(&mut self, account: AccountId) -> Result<()> {
            let staking_info = self.stakers.get(&account).cloned().ok_or(Error::AccountNotFound)?;

            let current_time = Self::env().block_timestamp();
            if current_time < staking_info.start_time + staking_info.duration {
               return  Err(Error::Custom(String::from("Staking duration not yet elapsed.")));
            }

            self.stakers.remove(&account);
            Self::env().emit_event(Withdrawn {
                account,
                amount: staking_info.amount,
            });
            Ok(())
        }

        /// Returns the staking information for a given account.
        pub fn get_staking_info(&self, account: AccountId) -> Result<StakingInfo> {
            self.stakers.get(&account).cloned().ok_or(Error::AccountNotFound)
        }

        fn env(&self) -> EnvAccess<'_, Env> {
            EnvAccess::new(self)
        }
    }

    impl ink_lang::Env for StakingModule {
        fn env() -> EnvAccess<'static, Env> {
            panic!("`Env::env()` can only be called on contract instances");
        }
    }
}

pub mod governance {
    use super::*;

    #[derive(Debug, PartialEq, Eq, Encode, Decode, Clone)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub enum ProposalState {
        Active,
        Canceled,
        Pending,
        Defeated,
        Succeeded,
        Executed,
    }

    #[derive(Debug, Encode, Decode, Clone, SpreadLayout, PackedLayout)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub struct Proposal {
        proposer: AccountId,
        description: String,
        start_block: BlockNumber,
        end_block: BlockNumber,
        for_votes: Balance,
        against_votes: Balance,
        executed: bool,
        target_contract: AccountId,
        encoded_call: Vec<u8>,
    }

    #[ink::event]
    pub struct ProposalCreated {
        #[ink(topic)]
        proposal_id: u32,
        proposer: AccountId,
        description: String,
    }

    #[ink::event]
    pub struct VoteCast {
        #[ink(topic)]
        proposal_id: u32,
        voter: AccountId,
        support: bool,
        votes: Balance,
    }

    #[ink::event]
    pub struct ProposalExecuted {
        #[ink(topic)]
        proposal_id: u32,
        result: bool,
    }

    #[derive(Debug, Encode, Decode, Clone, SpreadLayout, PackedLayout)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub struct GovernanceModule {
        proposals: StorageHashMap<u32, Proposal>,
        votes: StorageHashMap<(u32, AccountId), bool>, // (proposal_id, voter) -> support
        proposal_count: u32,
        voting_period: BlockNumber,
        quorum_percentage: u8,
    }

    impl GovernanceModule {
        pub fn new() -> Self {
            Self {
                proposals: StorageHashMap::new(),
                votes: StorageHashMap::new(),
                proposal_count: 0,
                voting_period: 100, // 100 blocks voting period.
                quorum_percentage: 20, // 20% quorum.
            }
        }

        /// Creates a new proposal.
        pub fn create_proposal(
            &mut self,
            proposer: AccountId,
            description: String,
            target_contract: AccountId,
            encoded_call: Vec<u8>,
        ) -> Result<()> {
            let current_block = Self::env().block_number();
            let end_block = current_block + self.voting_period;

            self.proposal_count += 1;
            let proposal_id = self.proposal_count;

            let proposal = Proposal {
                proposer,
                description: description.clone(),
                start_block: current_block,
                end_block,
                for_votes: 0,
                against_votes: 0,
                executed: false,
                target_contract,
                encoded_call,
            };

            self.proposals.insert(proposal_id, proposal);

            Self::env().emit_event(ProposalCreated {
                proposal_id,
                proposer,
                description,
            });

            Ok(())
        }

        /// Casts a vote for a proposal.
        pub fn vote(&mut self, voter: AccountId, proposal_id: u32, support: bool) -> Result<()> {
            let proposal = self.proposals.get_mut(&proposal_id).ok_or(Error::ProposalNotFound)?;

            if Self::env().block_number() > proposal.end_block {
                return Err(Error::InvalidVotingPeriod);
            }

            if self.votes.contains_key(&(proposal_id, voter)) {
                return Err(Error::AlreadyVoted);
            }

            // In a real implementation, the voting power should be based on the user's token balance or staked amount.
            // For simplicity, we assume each account has 1 vote.
            let voting_power: Balance = 1;

            if support {
                proposal.for_votes += voting_power;
            } else {
                proposal.against_votes += voting_power;
            }

            self.votes.insert((proposal_id, voter), support);

            Self::env().emit_event(VoteCast {
                proposal_id,
                voter,
                support,
                votes: voting_power,
            });

            Ok(())
        }

        /// Executes a proposal.
        pub fn execute_proposal(&mut self, proposal_id: u32) -> Result<()> {
            let proposal = self.proposals.get_mut(&proposal_id).ok_or(Error::ProposalNotFound)?;

            if proposal.executed {
                return Err(Error::Custom(String::from("Proposal already executed.")));
            }

            if Self::env().block_number() <= proposal.end_block {
                 return Err(Error::Custom(String::from("Voting period is still active.")));
            }

            let total_votes = proposal.for_votes + proposal.against_votes;
            let quorum = (total_votes as u128)
                .checked_mul(self.quorum_percentage as u128)
                .ok_or(Error::Overflow)?
                .checked_div(100)
                .ok_or(Error::DivisionByZero)? as Balance;

            let passed = proposal.for_votes > proposal.against_votes && total_votes >= quorum;

            let mut result = false;

            if passed {
                // Execute the call to the target contract.
                result = self.execute_cross_contract_call(proposal.target_contract, proposal.encoded_call.clone())?;
                proposal.executed = true;
            } else {
                // Proposal failed.
                proposal.executed = true;
            }

             Self::env().emit_event(ProposalExecuted {
                proposal_id,
                result,
            });

            Ok(())
        }

        fn execute_cross_contract_call(&self, target_contract: AccountId, encoded_call: Vec<u8>) -> Result<bool> {
            let result = Self::env()
                .invoke_contract(
                    &ink_env::call::FromAccountId::from_account_id(target_contract),
                    0, // value: Balance
                    selector_from_bytes(&encoded_call[0..4]), // Adjust based on your selector definition.
                    encoded_call[4..].to_vec(),
                    CallFlags::default()
                );

            match result {
                Ok(_r) => {Ok(true)}, // You might need to handle the result appropriately.
                Err(_e) => {
                    Ok(false)
                }
            }
        }

        /// Returns the state of a proposal.
        pub fn get_proposal_state(&self, proposal_id: u32) -> Result<ProposalState> {
            let proposal = self.proposals.get(&proposal_id).ok_or(Error::ProposalNotFound)?;

            if proposal.executed {
                return Ok(ProposalState::Executed);
            }

            if Self::env().block_number() > proposal.end_block {
                let total_votes = proposal.for_votes + proposal.against_votes;
                let quorum = (total_votes as u128)
                .checked_mul(self.quorum_percentage as u128)
                .ok_or(Error::Overflow)?
                .checked_div(100)
                .ok_or(Error::DivisionByZero)? as Balance;

                if proposal.for_votes > proposal.against_votes && total_votes >= quorum {
                    return Ok(ProposalState::Succeeded);
                } else {
                    return Ok(ProposalState::Defeated);
                }
            }

            Ok(ProposalState::Active)
        }

         fn env(&self) -> EnvAccess<'_, Env> {
            EnvAccess::new(self)
        }
    }

    impl ink_lang::Env for GovernanceModule {
        fn env() -> EnvAccess<'static, Env> {
            panic!("`Env::env()` can only be called on contract instances");
        }
    }

    fn selector_from_bytes(bytes: &[u8]) -> u32 {
        let mut result = [0u8; 4];
        result.copy_from_slice(&bytes[0..4]);
        u32::from_be_bytes(result)
    }
}

pub mod pricing {
    use super::*;

    #[ink::event]
    pub struct PriceUpdated {
        asset: String,
        price: u128,
    }

    #[derive(Debug, Encode, Decode, Clone, SpreadLayout, PackedLayout)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub struct PricingModule {
        prices: StorageHashMap<String, u128>,
    }

    impl PricingModule {
        pub fn new() -> Self {
            Self {
                prices: StorageHashMap::new(),
            }
        }

        /// Sets the price for a given asset.
        pub fn set_price(&mut self, asset: String, price: u128) -> Result<()> {
            self.prices.insert(asset.clone(), price);
            Self::env().emit_event(PriceUpdated { asset, price });
            Ok(())
        }

        /// Returns the price for a given asset.
        pub fn get_price(&self, asset: String) -> Result<u128> {
            self.prices.get(&asset).cloned().ok_or(Error::Custom(String::from("Price not found for asset.")))
        }

         fn env(&self) -> EnvAccess<'_, Env> {
            EnvAccess::new(self)
        }
    }

    impl ink_lang::Env for PricingModule {
        fn env() -> EnvAccess<'static, Env> {
            panic!("`Env::env()` can only be called on contract instances");
        }
    }
}

pub mod utils {
    // Add utility functions here if needed.
}
```

**Outline and Function Summary:**

This smart contract, `DynamicDefi`, aims to provide a dynamic DeFi strategy platform with on-chain governance and pricing oracles.  It utilizes separate modules for Staking, Governance, and Pricing to enhance modularity and readability.

**Core Functionality:**

*   **Token Management:**
    *   `total_supply()`: Returns the total supply of the governance token.
    *   `balance_of(AccountId)`: Returns the token balance of a given account.
    *   `transfer(AccountId, Balance)`: Transfers tokens from the caller to another account.
    *   `transfer_from_to(AccountId, AccountId, Balance)`: Transfers tokens from one specified account to another.

*   **Ownership and Pausability:**
    *   `owner()`: Returns the contract owner.
    *   `transfer_ownership(AccountId)`: Transfers contract ownership.
    *   `pause()`: Pauses the contract, preventing certain actions. Only owner.
    *   `unpause()`: Unpauses the contract. Only owner.
    *   `paused()`: Returns the paused state of the contract.

*   **DeFi Strategy Execution (Placeholder):**
    *   `execute_strategy(u32, Vec<u8>)`:  A placeholder function for executing DeFi strategies.  It currently emits an event.  The actual implementation would involve complex logic interacting with other contracts.

*   **Staking Module:**  Handles token staking with variable durations.
    *   `stake(Balance, u64)`: Allows users to stake tokens for a specified duration.
    *   `withdraw()`: Allows users to withdraw their staked tokens after the duration has elapsed.
    *   `get_staking_info(AccountId)`: Returns staking information for a given account.

*   **Governance Module:**  Manages on-chain proposals and voting.
    *   `create_proposal(String, AccountId, Vec<u8>)`: Creates a new governance proposal.  Takes a description, a target contract address, and encoded function call data as input.
    *   `vote(u32, bool)`: Allows users to vote on a proposal (for or against).
    *   `execute_proposal(u32)`: Executes a proposal if it passes (based on voting results and quorum).  This involves making a cross-contract call to the specified `target_contract` with the `encoded_call` data.
    *   `get_proposal_state(u32)`: Returns the current state of a proposal (e.g., Active, Succeeded, Executed).

*   **Pricing Module:** Provides price oracle functionality.
    *   `set_price(String, u128)`: Sets the price of an asset.
    *   `get_price(String)`: Retrieves the price of an asset.
    *   `convert(String, String, u128)`: Converts an amount from one asset to another based on the prices obtained from the pricing oracle.

**Advanced Concepts and Creative Features:**

1.  **Dynamic DeFi Strategies:** The `execute_strategy` function acts as a central point for orchestrating complex DeFi strategies. This example provides a placeholder. Real-world strategies could involve:

    *   **Yield Farming Automation:** Automatically allocating funds to different yield farms based on current APRs and risk profiles.
    *   **Liquidity Provisioning:** Automatically managing liquidity positions on decentralized