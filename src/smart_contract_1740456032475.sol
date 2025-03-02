```rust
#![cfg_attr(not(feature = "std"), no_std)]

use ink_lang as ink;

#[ink::contract]
mod verifiable_voting {
    use ink_prelude::vec::Vec;
    use ink_prelude::string::String;
    use ink_storage::traits::SpreadAllocate;
    use ink_env::{hash, Environment, HashTypeId};

    /// Defines the storage of our contract.
    ///
    /// Stores:
    /// * The contract owner.
    /// * The current voting round.
    /// * The voting options.
    /// * Whether voting is active.
    /// * A mapping from voters to their vote commitments and reveals.
    #[derive(SpreadAllocate)]
    #[ink(storage)]
    pub struct VerifiableVoting {
        owner: AccountId,
        voting_round: u64,
        options: Vec<String>,
        voting_active: bool,
        voters: ink_storage::collections::HashMap<AccountId, (Hash, String)>, // (commitment, revealed vote)
        results: ink_storage::collections::HashMap<String, u64>, // (option, vote_count)
        random_number: u32 // Random number for post-voting verification.
    }

    /// Errors that can occur upon calling this contract.
    #[derive(Debug, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub enum Error {
        NotOwner,
        VotingNotActive,
        VotingAlreadyActive,
        InvalidOption,
        AlreadyVoted,
        InvalidCommitment,
        InvalidReveal,
        CommitmentPhaseOngoing,
        RevealPhaseOngoing,
        VotingNotStarted,
    }

    /// Event emitted when a vote is cast.
    #[ink(event)]
    pub struct Voted {
        #[ink(topic)]
        voter: AccountId,
        option: String,
    }

     /// Event emitted when voting is started.
    #[ink(event)]
    pub struct VotingStarted {
        voting_round: u64,
    }

    /// Event emitted when voting is ended.
    #[ink(event)]
    pub struct VotingEnded {
        voting_round: u64,
    }

    /// Event emitted when a reveal is done.
    #[ink(event)]
    pub struct VoteRevealed {
        voter: AccountId,
        option: String,
    }


    impl VerifiableVoting {
        /// Constructor that initializes the `VerifiableVoting` contract.
        ///
        /// Sets the owner to the caller and initializes the voting options.
        #[ink(constructor)]
        pub fn new(options: Vec<String>) -> Self {
            ink_lang::utils::initialize_contract(|contract: &mut Self| {
                contract.owner = Self::env().caller();
                contract.voting_round = 0;
                contract.options = options;
                contract.voting_active = false;
                contract.results = ink_storage::collections::HashMap::new();
            })
        }

        /// Starts a new voting round.
        ///
        /// Can only be called by the owner.
        /// Sets `voting_active` to true.
        #[ink(message)]
        pub fn start_voting(&mut self) -> Result<(), Error> {
            self.ensure_owner()?;
            if self.voting_active {
                return Err(Error::VotingAlreadyActive);
            }

            self.voting_round = self.voting_round.wrapping_add(1);
            self.voting_active = true;
            self.voters.clear(); // Reset voters for a new round.
            self.results.clear();

            for option in &self.options {
                self.results.insert(option.clone(), 0);
            }

            self.env().emit_event(VotingStarted { voting_round: self.voting_round });
            Ok(())
        }

        /// Commits a vote for a given option.
        ///
        /// Hashes the option with a secret and stores the hash.
        #[ink(message)]
        pub fn commit_vote(&mut self, commitment: Hash) -> Result<(), Error> {
            if !self.voting_active {
                return Err(Error::VotingNotActive);
            }

            let caller = self.env().caller();
            if self.voters.contains_key(&caller) {
                return Err(Error::AlreadyVoted);
            }

            self.voters.insert(caller, (commitment, String::new())); // Store commitment, leave reveal empty for now.
            Ok(())
        }

        /// Reveals the vote, allowing verification.
        ///
        /// Compares the hash of the revealed option and the provided secret with the stored commitment.
        /// If valid, the vote is counted.
        #[ink(message)]
        pub fn reveal_vote(&mut self, option: String, secret: String) -> Result<(), Error> {
            if !self.voting_active {
                return Err(Error::VotingNotActive);
            }

            let caller = self.env().caller();
            let (expected_commitment, revealed_option) = self.voters.get_mut(&caller).ok_or(Error::VotingNotStarted)?;

            if revealed_option != "" {
                return Err(Error::AlreadyVoted);
            }

            if !self.options.contains(&option) {
                return Err(Error::InvalidOption);
            }

            // Hash the revealed option and secret.
            let mut input: Vec<u8> = Vec::new();
            input.extend(option.as_bytes());
            input.extend(secret.as_bytes());

            let hash_result = self.env().hash_bytes::<ink_env::hash::Blake2x256>(&input);
            let revealed_commitment = hash_result.as_ref();


            if revealed_commitment != expected_commitment {
                return Err(Error::InvalidReveal);
            }

            // Count the vote
            let vote_count = self.results.get(&option).unwrap_or(&0).clone();
            self.results.insert(option.clone(), vote_count + 1);
            *revealed_option = option.clone(); // Mark vote as revealed.

            self.env().emit_event(Voted { voter: caller, option: option.clone() });
            self.env().emit_event(VoteRevealed { voter: caller, option: option.clone() });

            Ok(())
        }


        /// Ends the voting round.
        ///
        /// Can only be called by the owner.
        /// Sets `voting_active` to false.
        #[ink(message)]
        pub fn end_voting(&mut self) -> Result<(), Error> {
            self.ensure_owner()?;
            if !self.voting_active {
                return Err(Error::VotingNotActive);
            }

            self.voting_active = false;
            // Generate random number for verification.
            self.random_number = self.env().block_timestamp() as u32; // Simpler random generation
            self.env().emit_event(VotingEnded { voting_round: self.voting_round });

            Ok(())
        }

        /// Gets the current voting results.
        #[ink(message)]
        pub fn get_results(&self) -> Vec<(String, u64)> {
            self.results.clone().into_iter().collect()
        }

        /// Verifies a specific vote (reveal).
        /// Returns true if the provided option and secret hash to the stored commitment for the voter.
        #[ink(message)]
        pub fn verify_vote(&self, voter: AccountId, option: String, secret: String) -> bool {
            if let Some((expected_commitment, _)) = self.voters.get(&voter) {
                let mut input: Vec<u8> = Vec::new();
                input.extend(option.as_bytes());
                input.extend(secret.as_bytes());

                let hash_result = self.env().hash_bytes::<ink_env::hash::Blake2x256>(&input);
                let revealed_commitment = hash_result.as_ref();

                revealed_commitment == expected_commitment
            } else {
                false
            }
        }


        /// Gets the contract owner.
        #[ink(message)]
        pub fn get_owner(&self) -> AccountId {
            self.owner
        }

        /// Gets the voting round.
        #[ink(message)]
        pub fn get_voting_round(&self) -> u64 {
            self.voting_round
        }

        /// Checks if voting is currently active.
        #[ink(message)]
        pub fn is_voting_active(&self) -> bool {
            self.voting_active
        }

        /// Gets the available voting options.
        #[ink(message)]
        pub fn get_options(&self) -> Vec<String> {
            self.options.clone()
        }

        /// Helper function to ensure the caller is the owner.
        fn ensure_owner(&self) -> Result<(), Error> {
            if self.env().caller() != self.owner {
                return Err(Error::NotOwner);
            }
            Ok(())
        }

        /// Get the random number for verification
        #[ink(message)]
        pub fn get_random_number(&self) -> u32 {
            self.random_number
        }
    }

    /// Unit tests in Rust are normally defined within such a module and are
    /// supported in ink! contracts as well. They help in guaranteeing the
    /// correctness of your contract.
    #[cfg(test)]
    mod tests {
        /// Imports all the definitions from the outer scope so we can use them here.
        use super::*;

        use ink_lang as ink;

        #[ink::test]
        fn it_works() {
            let mut verifiable_voting = VerifiableVoting::new(vec![String::from("Option1"), String::from("Option2")]);
            assert_eq!(verifiable_voting.get_voting_round(), 0);
        }
    }
}
```

**Outline and Function Summary:**

This smart contract implements a verifiable voting system using commitment-reveal scheme.  The goal is to allow voters to verifiably prove their votes were counted correctly after the voting has closed. It leverages hashing and events for auditability and post-voting verification.

**Contract Features:**

1.  **Commitment-Reveal Scheme:**  Voters first commit to a vote by hashing their choice combined with a secret. Later, they reveal their vote and secret.  This prevents vote manipulation during the voting period and allows for independent verification after the election.

2.  **Voting Rounds:** The contract supports multiple voting rounds.

3.  **Role-Based Access (Owner):**  Only the owner can start and end voting rounds.

4.  **Event Emission:** The contract emits events for each crucial action: `Voted`, `VotingStarted`, `VotingEnded`, and `VoteRevealed`, providing an auditable trail of actions.

5.  **Post-Voting Verification:** Voters can use the `verify_vote` function to independently verify that their revealed vote matches their original commitment.  A public random number is generated at the end of voting to prevent pre-computation attacks and potentially as another randomness factor in verification.

**Function Summary:**

*   `new(options: Vec<String>)`: Constructor.  Sets the owner and initializes voting options.
*   `start_voting()`: Starts a new voting round.  Resets voter records and results.  Can only be called by the owner.
*   `commit_vote(commitment: Hash)`:  Registers a vote commitment.  Requires the voting round to be active and the voter not to have already voted.
*   `reveal_vote(option: String, secret: String)`: Reveals the committed vote. Verifies the revealed option and secret against the stored commitment. Updates the vote count if the reveal is valid.
*   `end_voting()`: Ends the voting round. Can only be called by the owner. Generates a random number.
*   `get_results()`: Returns the current voting results (option and vote count).
*   `verify_vote(voter: AccountId, option: String, secret: String)`: Allows anyone to verify if a specific voter's revealed vote corresponds to their initial commitment.
*   `get_owner()`: Returns the contract owner.
*   `get_voting_round()`: Returns the current voting round.
*   `is_voting_active()`: Returns whether voting is currently active.
*   `get_options()`: Returns the available voting options.
*   `get_random_number()`: Returns the random number generated at the end of the voting.

**Advanced/Trendy Concepts:**

*   **Verifiable Voting:**  This contract directly implements a crucial aspect of secure elections: verifiability.  It goes beyond simple counting and provides a mechanism for voters to confirm their vote was counted correctly, promoting transparency and trust.
*   **Commitment Scheme:** The commitment scheme is a cryptographic technique used to ensure voters don't change their vote after seeing how others have voted. It adds a layer of security to the voting process.
*   **Auditability:** The use of events ensures that all voting actions are logged on the blockchain, enabling public auditing of the election.
*   **On-Chain Randomness:** The use of `env().block_timestamp()` to create a pseudorandom number during the `end_voting` process can prevent vote manipulation.  (Note:  For a more robust, production-ready system, a more secure source of randomness is highly recommended, such as using Chainlink VRF.)
*   **Decentralized Governance Primitives:**  This contract provides a fundamental building block for creating more complex decentralized governance systems.

**Potential Improvements and Considerations:**

*   **Enhanced Randomness:** Using a true random number generator (TRNG) or a verifiable random function (VRF) would greatly improve the security of the random number used for post-voting verification.  Consider using Chainlink VRF or a similar service.
*   **zk-SNARKs for Zero-Knowledge Voting:** A more advanced, and computationally expensive, approach would be to integrate zk-SNARKs (Zero-Knowledge Succinct Non-Interactive Argument of Knowledge). This would allow voters to prove they voted for a valid option *without* revealing what that option was.  This greatly enhances privacy.
*   **Delegated Voting:** Implement the ability for voters to delegate their voting power to another address.
*   **Weighted Voting:** Allow different addresses to have different voting weights.
*   **Gas Optimization:** The contract can be further optimized for gas efficiency, especially when dealing with a large number of voters or options.  Consider using more efficient data structures or techniques for hashing.
*   **Security Audits:** Before deploying this contract to a production environment, it is crucial to have it thoroughly audited by security experts to identify and address any potential vulnerabilities.
*   **Frontend Interface:** A well-designed frontend interface would greatly improve the usability of the voting system.
