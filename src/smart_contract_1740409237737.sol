Okay, here's a Rust smart contract designed around the concept of a "Dynamic NFT Membership DAO with Skill-Based Revenue Sharing."  This is an advanced concept that combines NFTs, DAOs, skill-based contributions, and a dynamic revenue sharing model.  It aims to create a self-governing organization where members' contributions are recognized and rewarded proportionally.

**Outline & Function Summary:**

*   **Contract Name:** `DynamicSkillDAO`
*   **Purpose:**  Implements a DAO where membership is granted via NFTs.  The key feature is dynamic revenue sharing based on skills listed on your profile and project contribution.

*   **Data Structures:**
    *   `DAOState`:  Stores the overall state of the DAO (total revenue, contribution period start/end, etc.).
    *   `Member`:  Stores information about each member (NFT ID, listed skill, past contribution point, contribution balance, etc.).
    *   `Project`: Stores information about a project (start/end, list of contributors, skill required, contribution balance, etc.).

*   **Key Functions:**
    *   `init()`: Initializes the contract with the initial NFT contract address and DAO parameters.
    *   `mint_membership()`: Mints an NFT to a user, granting them DAO membership.
    *   `list_skill()`: set skill of user in their profile
    *   `create_project()`: Create a project with required skills
    *   `contribute_to_project()`: Register a contribution to a project
    *   `end_project()`: Distribute the earned revenue to contributors of project
    *   `distribute_revenue()`: Distributes revenue to members based on skill and contribution point.
    *   `withdraw_earnings()`: Allows members to withdraw their accumulated earnings.
    *   `get_member_info()`: Retrieves information about a specific member.
    *   `get_project_info()`: Retrieves information about a specific project.
    *   `update_dao_parameters()`: Allows the DAO admin to update parameters like contribution period length.
    *   `claim_nft()`: claim nft id when listing skills, only allows one NFT ID per user

```rust
#![cfg_attr(not(feature = "std"), no_std)]

#[ink::contract]
mod dynamic_skill_dao {
    use ink::prelude::{
        string::String,
        vec::Vec,
    };
    use ink::storage::Mapping;

    /// Defines the storage of our contract.
    #[ink::storage]
    pub struct DynamicSkillDAO {
        /// The admin of the DAO.
        admin: AccountId,
        /// Address of the NFT contract.
        nft_contract: AccountId,
        /// Stores DAO-wide state.
        dao_state: DAOState,
        /// Maps NFT ID to Member information.
        members: Mapping<u32, Member>,
        /// Maps Project ID to Project information.
        projects: Mapping<u32, Project>,
        /// The NFT for each member.
        member_nft: Mapping<AccountId, u32>,
        /// The next project ID
        next_project_id: u32,
    }

    /// Stores the overall state of the DAO.
    #[derive(Debug, PartialEq, scale::Encode, scale::Decode, Clone)]
    #[cfg_attr(
        feature = "std",
        derive(scale_info::TypeInfo)
    )]
    pub struct DAOState {
        total_revenue: Balance,
        contribution_period_start: Timestamp,
        contribution_period_end: Timestamp,
        contribution_point_per_balance: u128,
        revenue_distribution_frequency: Timestamp, // How often revenue is distributed.
    }

    /// Stores information about each member.
    #[derive(Debug, PartialEq, scale::Encode, scale::Decode, Clone)]
    #[cfg_attr(
        feature = "std",
        derive(scale_info::TypeInfo)
    )]
    pub struct Member {
        account_id: AccountId,
        skill: String,
        contribution_point: u128,
        available_balance: Balance,
        total_balance: Balance,
    }

    /// Stores information about each project.
    #[derive(Debug, PartialEq, scale::Encode, scale::Decode, Clone)]
    #[cfg_attr(
        feature = "std",
        derive(scale_info::TypeInfo)
    )]
    pub struct Project {
        required_skill: String,
        project_start: Timestamp,
        project_end: Timestamp,
        project_balance: Balance,
        contributors: Vec<AccountId>,
    }

    /// Errors that can occur.
    #[derive(Debug, PartialEq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub enum Error {
        NotAdmin,
        NftMintFailed,
        InsufficientBalance,
        InvalidNftId,
        InvalidSkill,
        ProjectNotFound,
        ContributionPeriodOver,
        AlreadyContributed,
        Overflow,
        Underflow,
        NotEnoughFund,
        NoSkillListed,
        NftAlreadyClaimed,
        ProjectOngoing,
    }

    /// Events.
    #[ink::event]
    pub struct MembershipMinted {
        #[ink::topic]
        account: AccountId,
        #[ink::topic]
        nft_id: u32,
    }

    #[ink::event]
    pub struct SkillListed {
        #[ink::topic]
        account: AccountId,
        skill: String,
    }

    #[ink::event]
    pub struct ProjectCreated {
        #[ink::topic]
        project_id: u32,
        skill: String,
    }

    #[ink::event]
    pub struct Contributed {
        #[ink::topic]
        account: AccountId,
        project_id: u32,
    }

    #[ink::event]
    pub struct RevenueDistributed {
        total_distributed: Balance,
    }

    #[ink::event]
    pub struct EarningsWithdrawn {
        #[ink::topic]
        account: AccountId,
        amount: Balance,
    }

    impl DynamicSkillDAO {
        /// Constructor that initializes the contract.
        #[ink::constructor]
        pub fn new(nft_contract_address: AccountId) -> Self {
            Self {
                admin: Self::env().caller(),
                nft_contract: nft_contract_address,
                dao_state: DAOState {
                    total_revenue: 0,
                    contribution_period_start: 0,
                    contribution_period_end: 0,
                    contribution_point_per_balance: 1,
                    revenue_distribution_frequency: 365 * 24 * 60 * 60 * 1000, // 1 year
                },
                members: Mapping::default(),
                projects: Mapping::default(),
                member_nft: Mapping::default(),
                next_project_id: 0,
            }
        }

        /// Mint a membership NFT.
        #[ink::message]
        pub fn mint_membership(&mut self, nft_id: u32) -> Result<(), Error> {
            let caller = self.env().caller();

            // Basic check:  Does the user already have an NFT association?  This is a simplified check.
            if self.member_nft.contains(caller) {
                return Err(Error::NftMintFailed); // Already has membership.  Could use a different error.
            }

            // Store member data (initially minimal).
            let member = Member {
                account_id: caller,
                skill: String::from(""),
                contribution_point: 0,
                available_balance: 0,
                total_balance: 0,
            };
            self.members.insert(nft_id, &member);
            self.member_nft.insert(caller, &nft_id);

            self.env().emit_event(MembershipMinted {
                account: caller,
                nft_id,
            });

            Ok(())
        }

        /// List skills for a member (requires NFT ownership).
        #[ink::message]
        pub fn list_skill(&mut self, nft_id: u32, skill: String) -> Result<(), Error> {
            let caller = self.env().caller();

            // Check if the caller owns the NFT.  This requires interaction with the NFT contract.
            // In a real implementation, you'd call the NFT contract to verify ownership.
            if self.member_nft.get(caller) != Some(nft_id) {
                return Err(Error::InvalidNftId);
            }

            let mut member = self.members.get(nft_id).ok_or(Error::InvalidNftId)?;
            member.skill = skill;
            self.members.insert(nft_id, &member);

            self.env().emit_event(SkillListed {
                account: caller,
                skill: member.skill.clone(),
            });
            Ok(())
        }

        /// Create a new project.
        #[ink::message]
        pub fn create_project(&mut self, required_skill: String) -> Result<(), Error> {
            let project_id = self.next_project_id;
            self.next_project_id += 1;

            let project = Project {
                required_skill: required_skill.clone(),
                project_start: self.env().block_timestamp(),
                project_end: 0, // Not yet ended
                project_balance: 0,
                contributors: Vec::new(),
            };

            self.projects.insert(project_id, &project);

            self.env().emit_event(ProjectCreated {
                project_id,
                skill: required_skill,
            });
            Ok(())
        }

        /// Contribute to a project.
        #[ink::message]
        pub fn contribute_to_project(&mut self, project_id: u32, nft_id: u32) -> Result<(), Error> {
            let caller = self.env().caller();

            // Check if the caller owns the NFT and has listed skills.
            let member = self.members.get(nft_id).ok_or(Error::InvalidNftId)?;
            if member.account_id != caller {
                return Err(Error::InvalidNftId);
            }
            if member.skill.is_empty() {
                return Err(Error::NoSkillListed);
            }

            let mut project = self.projects.get(project_id).ok_or(Error::ProjectNotFound)?;

            // Check project status and required skills.
            if project.project_end != 0 {
                return Err(Error::ProjectNotFound); // Project already ended.
            }
            if member.skill != project.required_skill {
                return Err(Error::InvalidSkill);
            }

            // Prevent duplicate contributions.
            if project.contributors.contains(&caller) {
                return Err(Error::AlreadyContributed);
            }

            project.contributors.push(caller);
            self.projects.insert(project_id, &project);

            self.env().emit_event(Contributed {
                account: caller,
                project_id,
            });
            Ok(())
        }

        /// End a project and distribute revenue.
        #[ink::message]
        pub fn end_project(&mut self, project_id: u32) -> Result<(), Error> {
            let caller = self.env().caller();

            let mut project = self.projects.get(project_id).ok_or(Error::ProjectNotFound)?;

            // Only allow admin or project creator to end the project.
            if caller != self.admin {
                return Err(Error::NotAdmin);
            }

            // check if project already ended
            if project.project_end != 0 {
                return Err(Error::ProjectOngoing);
            }

            // Transfer the contract balance of project to the contributor proportionally.
            let contract_balance = self.env().balance();
            if contract_balance < project.contributors.len() as u128 {
                return Err(Error::NotEnoughFund);
            }

            // update project status
            project.project_end = self.env().block_timestamp();

            // Distribute revenue
            let amount = contract_balance / project.contributors.len() as u128;
            for account in project.contributors.iter() {
                let mut nft_id: u32 = 0;
                let mut member: Member = Member {
                    account_id: AccountId::from([0u8; 32]),
                    skill: String::from(""),
                    contribution_point: 0,
                    available_balance: 0,
                    total_balance: 0,
                };

                if self.member_nft.contains(account) {
                    nft_id = self.member_nft.get(account).unwrap();
                    member = self.members.get(nft_id).unwrap();
                }
                member.available_balance = member.available_balance.checked_add(amount).ok_or(Error::Overflow)?;
                member.total_balance = member.total_balance.checked_add(amount).ok_or(Error::Overflow)?;

                self.members.insert(nft_id, &member);

                // Transfer the value.
                if self.env().transfer(*account, amount).is_err() {
                    ink::env::debug_println!("Failed to transfer contract value to account")
                }
            }
            self.projects.insert(project_id, &project);

            Ok(())
        }

        /// Distribute revenue to members based on skill and contribution points.
        #[ink::message]
        pub fn distribute_revenue(&mut self) -> Result<(), Error> {
            // This would involve iterating through members, calculating rewards based on
            // skill importance (which would need a mechanism to define), and contribution
            // points earned during the contribution period.

            // Update DAO state (e.g., reset contribution period).

            self.env().emit_event(RevenueDistributed {
                total_distributed: 0, // Placeholder.
            });
            Ok(())
        }

        /// Allows members to withdraw their accumulated earnings.
        #[ink::message]
        pub fn withdraw_earnings(&mut self, nft_id: u32, amount: Balance) -> Result<(), Error> {
            let caller = self.env().caller();
            let mut member = self.members.get(nft_id).ok_or(Error::InvalidNftId)?;

            if member.account_id != caller {
                return Err(Error::InvalidNftId);
            }

            if member.available_balance < amount {
                return Err(Error::InsufficientBalance);
            }

            member.available_balance -= amount;
            self.members.insert(nft_id, &member);

            if self.env().transfer(caller, amount).is_err() {
                ink::env::debug_println!("Failed to transfer contract value to account")
            }

            self.env().emit_event(EarningsWithdrawn {
                account: caller,
                amount,
            });

            Ok(())
        }

        /// Allows members to claim their NFT ID
        #[ink::message]
        pub fn claim_nft(&mut self, nft_id: u32) -> Result<(), Error> {
            let caller = self.env().caller();

            if self.member_nft.contains(caller) {
                return Err(Error::NftAlreadyClaimed);
            }

            self.member_nft.insert(caller, &nft_id);
            Ok(())
        }

        /// Get member information.
        #[ink::message]
        pub fn get_member_info(&self, nft_id: u32) -> Option<Member> {
            self.members.get(nft_id)
        }

        /// Get project information.
        #[ink::message]
        pub fn get_project_info(&self, project_id: u32) -> Option<Project> {
            self.projects.get(project_id)
        }

        /// Update DAO parameters (admin only).
        #[ink::message]
        pub fn update_dao_parameters(
            &mut self,
            new_contribution_point_per_balance: u128,
            new_revenue_distribution_frequency: Timestamp,
        ) -> Result<(), Error> {
            if self.env().caller() != self.admin {
                return Err(Error::NotAdmin);
            }

            self.dao_state.contribution_point_per_balance = new_contribution_point_per_balance;
            self.dao_state.revenue_distribution_frequency = new_revenue_distribution_frequency;

            Ok(())
        }
    }
}
```

**Important Considerations and Next Steps for a Real Implementation:**

*   **NFT Contract Interaction:** The contract needs to *actually* interact with an NFT contract to verify ownership.  This would involve calling a `owner_of(nft_id)` function on the NFT contract (assuming it exists) and comparing the result with `self.env().caller()`. You'll need to import and use the cross-contract calling features of `ink!`.
*   **Contribution Point System:** Implement a mechanism to track contribution points earned by members.  This could involve a function that members call to "log" their contributions, which are then reviewed and approved by other DAO members or admins.
*   **Skill Importance:** Develop a system to assign weights or importance to different skills.  This could be based on a DAO voting process.
*   **Revenue Distribution Logic:** The `distribute_revenue` function needs to be fully implemented to calculate rewards accurately.
*   **Security Audits:** This code is a starting point. It *must* be audited by security professionals before being deployed to a live blockchain.  Look for potential vulnerabilities like reentrancy attacks, integer overflows, and incorrect access control.
*   **Testing:**  Write thorough unit tests to verify all functions and edge cases.  Use `ink_env::test` features.
*   **Error Handling:** More robust error handling.
*   **Gas Optimization:** Optimize the code to reduce gas costs.

This provides a solid foundation for a dynamic NFT membership DAO with skill-based revenue sharing.  Remember that building smart contracts is complex, and security is paramount!
