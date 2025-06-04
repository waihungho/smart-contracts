Okay, let's design a smart contract centered around managing "Abstract Digital Concepts" or "Ideas". It incorporates features like dynamic scoring, concept combination (creating a graph-like structure), reputation/contribution tracking, role-based access control, and parameter governance. This avoids standard token/NFT/DeFi patterns directly and builds a unique internal system.

We will call this contract `ConceptForge`.

Here's the outline and function summary, followed by the Solidity code.

---

## ConceptForge Smart Contract

**Outline:**

1.  **Contract Description:** Manages the lifecycle, contribution, and evolution of abstract digital concepts on-chain.
2.  **State Variables:**
    *   Mappings for Concepts, Contributors, Roles, Delegated Rights, Unclaimed Points, Parameters.
    *   Counters for Concept IDs.
3.  **Structs:** `Concept`, `Contributor`.
4.  **Enums:** `ConceptStatus`, `Role`.
5.  **Events:** Signalling key actions like concept creation, status changes, role assignments, points claimed, etc.
6.  **Modifiers:** For enforcing roles and concept status.
7.  **Parameters:** Configurable values for scoring, points, etc.
8.  **Core Logic:**
    *   Concept Lifecycle (Propose, Develop, Review, Finalize, Archive).
    *   Contribution Tracking & Reputation Points.
    *   Dynamic Concept Scoring based on activity.
    *   Concept Combination & Graph Structure.
    *   Role-Based Access Control (Admin, Reviewer, etc.).
    *   Delegation of Contribution Rights.
    *   Parameter Governance (Admin configurable).
9.  **Functions:** 24 functions covering creation, modification, interaction, querying, and administration.

**Function Summary:**

*   **Concept Creation & Lifecycle:**
    1.  `proposeConcept(string name, string description)`: Creates a new concept in `Draft` status. Assigns creator.
    2.  `updateConceptDetails(uint conceptId, string newDescription)`: Updates the description of a concept if allowed by status/role.
    3.  `addContributorToConcept(uint conceptId, address contributor)`: Adds a contributor to a concept. Requires creator or admin role.
    4.  `removeContributorFromConcept(uint conceptId, address contributor)`: Removes a contributor. Requires creator or admin role.
    5.  `submitConceptForReview(uint conceptId)`: Changes concept status from `Developing` to `UnderReview`.
    6.  `finalizeConceptByReviewers(uint conceptId)`: Changes status from `UnderReview` to `Finalized`. Requires `Reviewer` role. Accrues points.
    7.  `rejectConceptByReviewers(uint conceptId, string reason)`: Changes status from `UnderReview` back to `Developing`. Requires `Reviewer` role.
    8.  `archiveConcept(uint conceptId)`: Archives a concept. Requires `Admin` role.
*   **Concept Interaction & Scoring:**
    9.  `rateConcept(uint conceptId, uint rating)`: Allows users to rate a concept (1-5). Updates dynamic score and accrues points for the rater.
    10. `combineConcepts(uint conceptId1, uint conceptId2, string newName, string newDescription)`: Creates a *new* concept linking the two parent concepts. Requires parents to be `Finalized`. Accrues points for the creator of the combined concept.
*   **Contributor Management & Reputation:**
    11. `delegateContributionRights(uint conceptId, address delegatee)`: Allows a concept contributor to delegate their right to contribute to that specific concept to another address.
    12. `revokeContributionRights(uint conceptId, address delegatee)`: Revokes previously delegated contribution rights.
    13. `claimAccruedPoints()`: Transfers points accrued from activities (rating, finalizing, combining) into the contributor's main reputation points balance.
*   **Role-Based Access Control (RBAC):**
    14. `assignRole(address contributor, Role role)`: Assigns a specific role (`Reviewer`, `Admin`). Requires `Admin` role.
    15. `revokeRole(address contributor, Role role)`: Removes a specific role. Requires `Admin` role.
    16. `delegateAdminRole(address delegatee)`: Transfers the `Admin` role from the caller to another address. Requires `Admin` role. (One admin at a time for simplicity).
*   **Parameter Governance (Admin):**
    17. `updateScoringParameters(uint ratingPoints, uint finalizePoints, uint combinePoints, uint ratingInfluenceFactor)`: Updates parameters affecting point accrual and score calculation. Requires `Admin` role.
*   **View Functions (Read-only):**
    18. `getConceptDetails(uint conceptId)`: Retrieves details of a concept.
    19. `getConceptContributors(uint conceptId)`: Retrieves the list of contributors for a concept.
    20. `getConceptScore(uint conceptId)`: Retrieves the dynamic score of a concept.
    21. `getContributorProfile(address contributor)`: Retrieves details of a contributor profile.
    22. `getAvailableReputationPoints(address contributor)`: Retrieves the reputation points balance for a contributor.
    23. `getConceptsCreatedBy(address creator)`: Lists IDs of concepts created by a specific address.
    24. `getConceptsWaitingForReview()`: Lists IDs of concepts currently in `UnderReview` status.
    25. `getConceptsCombinedFrom(uint parentConceptId)`: Lists IDs of concepts created by combining the given parent concept.
    26. `getRole(address contributor)`: Retrieves the role assigned to an address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ConceptForge
 * @dev A smart contract for managing abstract digital concepts/ideas on-chain.
 * It allows users to propose, develop, combine, rate, and finalize concepts,
 * incorporating dynamic scoring, contribution tracking, RBAC, delegation,
 * and configurable parameters.
 */

// --- Outline ---
// 1. Contract Description
// 2. State Variables
// 3. Structs: Concept, Contributor
// 4. Enums: ConceptStatus, Role
// 5. Events
// 6. Modifiers
// 7. Parameters (Admin Configurable)
// 8. Core Logic (Lifecycle, Contribution, Scoring, Combination, RBAC, Delegation, Parameters)
// 9. Functions (24+)

// --- Function Summary ---
// Concept Creation & Lifecycle:
// 1. proposeConcept(string name, string description)
// 2. updateConceptDetails(uint conceptId, string newDescription)
// 3. addContributorToConcept(uint conceptId, address contributor)
// 4. removeContributorFromConcept(uint conceptId, address contributor)
// 5. submitConceptForReview(uint conceptId)
// 6. finalizeConceptByReviewers(uint conceptId)
// 7. rejectConceptByReviewers(uint conceptId, string reason)
// 8. archiveConcept(uint conceptId)
// Concept Interaction & Scoring:
// 9. rateConcept(uint conceptId, uint rating)
// 10. combineConcepts(uint conceptId1, uint conceptId2, string newName, string newDescription)
// Contributor Management & Reputation:
// 11. delegateContributionRights(uint conceptId, address delegatee)
// 12. revokeContributionRights(uint conceptId, address delegatee)
// 13. claimAccruedPoints()
// Role-Based Access Control (RBAC):
// 14. assignRole(address contributor, Role role)
// 15. revokeRole(address contributor, Role role)
// 16. delegateAdminRole(address delegatee)
// Parameter Governance (Admin):
// 17. updateScoringParameters(uint ratingPoints, uint finalizePoints, uint combinePoints, uint ratingInfluenceFactor)
// View Functions (Read-only):
// 18. getConceptDetails(uint conceptId)
// 19. getConceptContributors(uint conceptId)
// 20. getConceptScore(uint conceptId)
// 21. getContributorProfile(address contributor)
// 22. getAvailableReputationPoints(address contributor)
// 23. getConceptsCreatedBy(address creator)
// 24. getConceptsWaitingForReview()
// 25. getConceptsCombinedFrom(uint parentConceptId)
// 26. getRole(address contributor)

contract ConceptForge {

    // --- Enums ---
    enum ConceptStatus { Draft, Developing, UnderReview, Finalized, Archived }
    enum Role { None, Contributor, Reviewer, Admin } // Contributor role here for explicit assignment, base users have implicit contribution ability

    // --- Structs ---
    struct Concept {
        uint id;
        string name;
        string description;
        address creator;
        ConceptStatus status;
        uint creationTimestamp;
        // Dynamic Scoring
        uint totalRatingSum; // Sum of all ratings
        uint ratingCount;    // Number of ratings received
        // Contribution Tracking
        address[] contributors;
        // Concept Graph
        uint[] parentConcepts; // IDs of concepts this one was combined from
        uint[] childConcepts;  // IDs of concepts created by combining this one
    }

    struct Contributor {
        address userAddress;
        uint reputationPoints; // Points earned from activities
    }

    // --- State Variables ---
    uint private nextConceptId;
    mapping(uint => Concept) public concepts;
    mapping(address => Contributor) public contributors;
    mapping(address => Role) public userRoles;
    // Delegation mapping: conceptId => delegator => delegatee
    mapping(uint => mapping(address => address)) private contributionDelegations;
    // Points earned but not yet claimed into reputationPoints
    mapping(address => uint) private unclaimedPoints;
    // Parameter storage (admin configurable)
    mapping(bytes32 => uint) private parameters; // e.g., keccak256("ratingPoints") -> 10

    // --- Events ---
    event ConceptCreated(uint indexed conceptId, address indexed creator, string name);
    event ConceptStatusChanged(uint indexed conceptId, ConceptStatus indexed oldStatus, ConceptStatus indexed newStatus);
    event ContributorAdded(uint indexed conceptId, address indexed contributor);
    event ContributorRemoved(uint indexed conceptId, address indexed contributor);
    event ConceptRated(uint indexed conceptId, address indexed rater, uint rating, uint newScore);
    event ConceptsCombined(uint indexed newConceptId, uint indexed parent1, uint indexed parent2, address indexed creator);
    event ContributionDelegated(uint indexed conceptId, address indexed delegator, address indexed delegatee);
    event ContributionRevoked(uint indexed conceptId, address indexed delegator, address indexed delegatee);
    event PointsAccrued(address indexed contributor, uint amount, string activity); // Signalling points added to unclaimed
    event PointsClaimed(address indexed contributor, uint amount, uint newTotal);    // Signalling points moved to reputation
    event RoleAssigned(address indexed contributor, Role indexed role);
    event RoleRevoked(address indexed contributor, Role indexed role);
    event AdminRoleDelegated(address indexed oldAdmin, address indexed newAdmin);
    event ParameterUpdated(bytes32 indexed parameterName, uint indexed newValue);

    // --- Modifiers ---
    modifier onlyRole(Role requiredRole) {
        require(userRoles[msg.sender] >= requiredRole, "AccessControl: caller is not authorized");
        _;
    }

    modifier conceptExists(uint conceptId) {
        require(concepts[conceptId].id != 0, "Concept does not exist");
        _;
    }

    modifier conceptInStatus(uint conceptId, ConceptStatus status) {
        require(concepts[conceptId].status == status, "Concept not in required status");
        _;
    }

    modifier isConceptCreator(uint conceptId) {
        require(concepts[conceptId].creator == msg.sender, "Concept: caller is not the creator");
        _;
    }

    // Check if sender is creator OR a contributor OR has delegated rights from one
    modifier canContributeToConcept(uint conceptId) {
        bool isCreator = concepts[conceptId].creator == msg.sender;
        bool isContributor = false;
        address[] storage contributorsList = concepts[conceptId].contributors;
        for (uint i = 0; i < contributorsList.length; i++) {
            if (contributorsList[i] == msg.sender) {
                isContributor = true;
                break;
            }
        }
        // Check if sender is a delegatee for the creator or a contributor
        bool isDelegatee = contributionDelegations[conceptId][concepts[conceptId].creator] == msg.sender;
        if (!isDelegatee) {
             for (uint i = 0; i < contributorsList.length; i++) {
                if (contributionDelegations[conceptId][contributorsList[i]] == msg.sender) {
                    isDelegatee = true;
                    break;
                }
            }
        }

        require(isCreator || isContributor || isDelegatee || userRoles[msg.sender] >= Role.Admin,
                "Concept: caller cannot contribute to this concept");
        _;
    }

    // --- Constructor ---
    constructor() {
        nextConceptId = 1;
        // Assign initial admin role to the deployer
        userRoles[msg.sender] = Role.Admin;
        emit RoleAssigned(msg.sender, Role.Admin);

        // Set default parameters (can be updated later by Admin)
        parameters[keccak256("ratingPoints")] = 5;      // Points for rating a concept
        parameters[keccak256("finalizePoints")] = 50;   // Points for finalizing a concept (for reviewer)
        parameters[keccak256("combinePoints")] = 30;    // Points for combining concepts
        parameters[keccak256("ratingInfluenceFactor")] = 100; // Factor for score calculation (e.g., score = totalRatingSum * factor / ratingCount)
    }

    // --- Parameter Configuration (Admin) ---
    /**
     * @dev Updates scoring parameters.
     * @param ratingPoints_ Points awarded for rating.
     * @param finalizePoints_ Points awarded to reviewer for finalizing.
     * @param combinePoints_ Points awarded for combining concepts.
     * @param ratingInfluenceFactor_ Factor for dynamic score calculation.
     */
    function updateScoringParameters(
        uint ratingPoints_,
        uint finalizePoints_,
        uint combinePoints_,
        uint ratingInfluenceFactor_
    ) external onlyRole(Role.Admin) {
        parameters[keccak256("ratingPoints")] = ratingPoints_;
        parameters[keccak256("finalizePoints")] = finalizePoints_;
        parameters[keccak256("combinePoints")] = combinePoints_;
        parameters[keccak256("ratingInfluenceFactor")] = ratingInfluenceFactor_;

        emit ParameterUpdated(keccak256("ratingPoints"), ratingPoints_);
        emit ParameterUpdated(keccak256("finalizePoints"), finalizePoints_);
        emit ParameterUpdated(keccak256("combinePoints"), combinePoints_);
        emit ParameterUpdated(keccak256("ratingInfluenceFactor"), ratingInfluenceFactor_);
    }

    // --- Concept Creation & Lifecycle ---

    /**
     * @dev Proposes a new concept.
     * @param name The name of the concept.
     * @param description A detailed description of the concept.
     * @return The ID of the newly created concept.
     */
    function proposeConcept(string calldata name, string calldata description) external returns (uint) {
        uint conceptId = nextConceptId++;
        concepts[conceptId] = Concept({
            id: conceptId,
            name: name,
            description: description,
            creator: msg.sender,
            status: ConceptStatus.Draft,
            creationTimestamp: block.timestamp,
            totalRatingSum: 0,
            ratingCount: 0,
            contributors: new address[](0), // Creator is implicitly a contributor
            parentConcepts: new uint[](0),
            childConcepts: new uint[](0)
        });

        // Add creator to contributors list
        concepts[conceptId].contributors.push(msg.sender);

        // Ensure contributor profile exists (lazy creation)
        if (contributors[msg.sender].userAddress == address(0)) {
             contributors[msg.sender].userAddress = msg.sender;
        }

        emit ConceptCreated(conceptId, msg.sender, name);
        return conceptId;
    }

    /**
     * @dev Updates the description of a concept.
     * @param conceptId The ID of the concept to update.
     * @param newDescription The new description.
     */
    function updateConceptDetails(uint conceptId, string calldata newDescription)
        external
        conceptExists(conceptId)
        canContributeToConcept(conceptId)
    {
        ConceptStatus currentStatus = concepts[conceptId].status;
        require(currentStatus == ConceptStatus.Draft || currentStatus == ConceptStatus.Developing,
                "Concept: cannot update details in current status");

        concepts[conceptId].description = newDescription;
        // No event for simple detail update to save gas, or add a specific one if needed
    }

    /**
     * @dev Adds a contributor to a concept.
     * @param conceptId The ID of the concept.
     * @param contributor The address of the contributor to add.
     */
    function addContributorToConcept(uint conceptId, address contributor)
        external
        conceptExists(conceptId)
    {
         // Only creator or admin can add contributors
         require(concepts[conceptId].creator == msg.sender || userRoles[msg.sender] >= Role.Admin,
                 "Concept: caller cannot add contributors");

        address[] storage contributorsList = concepts[conceptId].contributors;
        for (uint i = 0; i < contributorsList.length; i++) {
            require(contributorsList[i] != contributor, "Concept: contributor already added");
        }

        concepts[conceptId].contributors.push(contributor);

        // Ensure contributor profile exists
        if (contributors[contributor].userAddress == address(0)) {
             contributors[contributor].userAddress = contributor;
        }

        emit ContributorAdded(conceptId, contributor);
    }

     /**
     * @dev Removes a contributor from a concept.
     * @param conceptId The ID of the concept.
     * @param contributor The address of the contributor to remove.
     */
    function removeContributorFromConcept(uint conceptId, address contributor)
        external
        conceptExists(conceptId)
    {
         // Only creator or admin can remove contributors, and cannot remove creator
         require(concepts[conceptId].creator == msg.sender || userRoles[msg.sender] >= Role.Admin,
                 "Concept: caller cannot remove contributors");
         require(concepts[conceptId].creator != contributor, "Concept: cannot remove creator");

        address[] storage contributorsList = concepts[conceptId].contributors;
        bool found = false;
        for (uint i = 0; i < contributorsList.length; i++) {
            if (contributorsList[i] == contributor) {
                // Simple removal by swapping with last element (order doesn't matter here)
                contributorsList[i] = contributorsList[contributorsList.length - 1];
                contributorsList.pop();
                found = true;
                break;
            }
        }
        require(found, "Concept: contributor not found");

        emit ContributorRemoved(conceptId, contributor);
    }

    /**
     * @dev Submits a concept for review.
     * @param conceptId The ID of the concept to submit.
     */
    function submitConceptForReview(uint conceptId)
        external
        conceptExists(conceptId)
        canContributeToConcept(conceptId)
        conceptInStatus(conceptId, ConceptStatus.Developing)
    {
        concepts[conceptId].status = ConceptStatus.UnderReview;
        emit ConceptStatusChanged(conceptId, ConceptStatus.Developing, ConceptStatus.UnderReview);
        // Could accrue points for submitting, but let's reward finalization instead.
    }

    /**
     * @dev Finalizes a concept. Requires Reviewer role.
     * @param conceptId The ID of the concept to finalize.
     */
    function finalizeConceptByReviewers(uint conceptId)
        external
        onlyRole(Role.Reviewer)
        conceptExists(conceptId)
        conceptInStatus(conceptId, ConceptStatus.UnderReview)
    {
        concepts[conceptId].status = ConceptStatus.Finalized;

        // Accrue points for the reviewer who finalized it
        uint finalizePoints = parameters[keccak256("finalizePoints")];
        if (finalizePoints > 0) {
             unclaimedPoints[msg.sender] += finalizePoints;
             emit PointsAccrued(msg.sender, finalizePoints, "FinalizeConcept");
        }

        emit ConceptStatusChanged(conceptId, ConceptStatus.UnderReview, ConceptStatus.Finalized);
    }

     /**
     * @dev Rejects a concept during review. Requires Reviewer role.
     * @param conceptId The ID of the concept to reject.
     * @param reason The reason for rejection.
     */
    function rejectConceptByReviewers(uint conceptId, string calldata reason)
        external
        onlyRole(Role.Reviewer)
        conceptExists(conceptId)
        conceptInStatus(conceptId, ConceptStatus.UnderReview)
    {
        concepts[conceptId].status = ConceptStatus.Developing;
        // Optionally store rejection reason? Adds complexity/gas.
        // Emit event with reason.
        emit ConceptStatusChanged(conceptId, ConceptStatus.UnderReview, ConceptStatus.Developing);
        // Could add a specific rejection event with reason
    }


    /**
     * @dev Archives a concept. Requires Admin role.
     * @param conceptId The ID of the concept to archive.
     */
    function archiveConcept(uint conceptId)
        external
        onlyRole(Role.Admin)
        conceptExists(conceptId)
    {
        ConceptStatus oldStatus = concepts[conceptId].status;
        concepts[conceptId].status = ConceptStatus.Archived;
        emit ConceptStatusChanged(conceptId, oldStatus, ConceptStatus.Archived);
    }

    // --- Concept Interaction & Scoring ---

    /**
     * @dev Rates a concept. Affects dynamic score and accrues points.
     * @param conceptId The ID of the concept to rate.
     * @param rating The rating (1-5).
     */
    function rateConcept(uint conceptId, uint rating)
        external
        conceptExists(conceptId)
    {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        // Cannot rate Draft or Archived concepts? Or allow rating Finalized? Let's allow rating Developing, UnderReview, Finalized.
        ConceptStatus currentStatus = concepts[conceptId].status;
        require(currentStatus != ConceptStatus.Draft && currentStatus != ConceptStatus.Archived,
                "Concept: cannot rate in current status");

        concepts[conceptId].totalRatingSum += rating;
        concepts[conceptId].ratingCount++;

        // Accrue points for rating
        uint ratingPoints = parameters[keccak256("ratingPoints")];
        if (ratingPoints > 0) {
             unclaimedPoints[msg.sender] += ratingPoints;
             emit PointsAccrued(msg.sender, ratingPoints, "RateConcept");
        }

        uint currentScore = getConceptScore(conceptId); // Recalculate score
        emit ConceptRated(conceptId, msg.sender, rating, currentScore);
    }

     /**
     * @dev Combines two finalized concepts into a new concept. Creates a graph structure.
     * @param conceptId1 The ID of the first parent concept.
     * @param conceptId2 The ID of the second parent concept.
     * @param newName The name for the new combined concept.
     * @param newDescription The description for the new combined concept.
     * @return The ID of the newly created combined concept.
     */
    function combineConcepts(uint conceptId1, uint conceptId2, string calldata newName, string calldata newDescription)
        external
        conceptExists(conceptId1)
        conceptExists(conceptId2)
        conceptInStatus(conceptId1, ConceptStatus.Finalized)
        conceptInStatus(conceptId2, ConceptStatus.Finalized)
        returns (uint)
    {
        require(conceptId1 != conceptId2, "Cannot combine a concept with itself");

        uint newConceptId = nextConceptId++;
        concepts[newConceptId] = Concept({
            id: newConceptId,
            name: newName,
            description: newDescription,
            creator: msg.sender, // Creator of the new concept is the caller
            status: ConceptStatus.Developing, // Combined concept starts in Developing
            creationTimestamp: block.timestamp,
            totalRatingSum: 0, // Starts with fresh scoring
            ratingCount: 0,
            contributors: new address[](0), // Starts with creator as sole contributor
            parentConcepts: new uint[](2),
            childConcepts: new uint[](0)
        });

        // Link parents to the new concept
        concepts[newConceptId].parentConcepts[0] = conceptId1;
        concepts[newConceptId].parentConcepts[1] = conceptId2;

        // Link the new concept as a child to the parents
        concepts[conceptId1].childConcepts.push(newConceptId);
        concepts[conceptId2].childConcepts.push(newConceptId);

        // Add creator to contributors list of the new concept
        concepts[newConceptId].contributors.push(msg.sender);

         // Ensure contributor profile exists (lazy creation)
        if (contributors[msg.sender].userAddress == address(0)) {
             contributors[msg.sender].userAddress = msg.sender;
        }

        // Accrue points for combining
        uint combinePoints = parameters[keccak256("combinePoints")];
        if (combinePoints > 0) {
             unclaimedPoints[msg.sender] += combinePoints;
             emit PointsAccrued(msg.sender, combinePoints, "CombineConcepts");
        }

        emit ConceptsCombined(newConceptId, conceptId1, conceptId2, msg.sender);
        return newConceptId;
    }

    // --- Contributor Management & Reputation ---

    /**
     * @dev Allows a contributor of a concept to delegate their contribution rights to another address.
     * The delegatee can then perform actions on that concept as if they were the delegator.
     * @param conceptId The ID of the concept.
     * @param delegatee The address to delegate rights to.
     */
    function delegateContributionRights(uint conceptId, address delegatee)
        external
        conceptExists(conceptId)
    {
        // Check if msg.sender is a contributor or the creator
        bool isContributorOrCreator = false;
        if (concepts[conceptId].creator == msg.sender) {
            isContributorOrCreator = true;
        } else {
            address[] storage contributorsList = concepts[conceptId].contributors;
             for (uint i = 0; i < contributorsList.length; i++) {
                if (contributorsList[i] == msg.sender) {
                    isContributorOrCreator = true;
                    break;
                }
            }
        }
        require(isContributorOrCreator, "Delegation: caller is not a contributor or creator of the concept");
        require(delegatee != address(0), "Delegation: delegatee cannot be zero address");
        require(delegatee != msg.sender, "Delegation: cannot delegate to yourself");

        contributionDelegations[conceptId][msg.sender] = delegatee;

        emit ContributionDelegated(conceptId, msg.sender, delegatee);
    }

    /**
     * @dev Revokes previously delegated contribution rights for a concept.
     * @param conceptId The ID of the concept.
     * @param delegatee The address whose rights were delegated.
     */
    function revokeContributionRights(uint conceptId, address delegatee)
        external
        conceptExists(conceptId)
    {
         // Check if msg.sender is the original delegator
         require(contributionDelegations[conceptId][msg.sender] == delegatee, "Revocation: no such delegation exists from caller to delegatee");

        delete contributionDelegations[conceptId][msg.sender];

        emit ContributionRevoked(conceptId, msg.sender, delegatee);
    }

    /**
     * @dev Transfers unclaimed points earned from activities to the contributor's main reputation balance.
     */
    function claimAccruedPoints() external {
        uint amount = unclaimedPoints[msg.sender];
        require(amount > 0, "Points: No unclaimed points to claim");

        // Ensure contributor profile exists (lazy creation)
        if (contributors[msg.sender].userAddress == address(0)) {
             contributors[msg.sender].userAddress = msg.sender;
        }

        contributors[msg.sender].reputationPoints += amount;
        unclaimedPoints[msg.sender] = 0;

        emit PointsClaimed(msg.sender, amount, contributors[msg.sender].reputationPoints);
    }


    // --- Role-Based Access Control (RBAC) ---

    /**
     * @dev Assigns a role to a contributor. Requires Admin role.
     * @param contributor The address to assign the role to.
     * @param role The role to assign (e.g., Role.Reviewer).
     */
    function assignRole(address contributor, Role role) external onlyRole(Role.Admin) {
        require(contributor != address(0), "Role: cannot assign role to zero address");
        require(role != Role.None, "Role: cannot assign None role");
        require(userRoles[contributor] != role, "Role: contributor already has this role");

        // Cannot overwrite Admin role using assignRole (use delegateAdminRole)
        require(role != Role.Admin || userRoles[contributor] == Role.None, "Role: use delegateAdminRole to transfer Admin role");

        userRoles[contributor] = role;

        // Ensure contributor profile exists (lazy creation)
        if (contributors[contributor].userAddress == address(0)) {
             contributors[contributor].userAddress = contributor;
        }

        emit RoleAssigned(contributor, role);
    }

    /**
     * @dev Revokes a role from a contributor. Requires Admin role.
     * @param contributor The address to revoke the role from.
     * @param role The role to revoke.
     */
    function revokeRole(address contributor, Role role) external onlyRole(Role.Admin) {
        require(contributor != address(0), "Role: cannot revoke role from zero address");
        require(role != Role.None, "Role: cannot revoke None role");
        require(userRoles[contributor] == role, "Role: contributor does not have this role");

         // Cannot revoke Admin role using revokeRole (use delegateAdminRole carefully, or a specific transfer/renounce)
        require(role != Role.Admin, "Role: cannot revoke Admin role via this function");


        userRoles[contributor] = Role.None;
        emit RoleRevoked(contributor, role);
    }

    /**
     * @dev Delegates the Admin role from the caller to another address.
     * Requires the caller to have the Admin role. This transfers the role,
     * the caller loses Admin role.
     * @param delegatee The address to delegate the Admin role to.
     */
    function delegateAdminRole(address delegatee) external onlyRole(Role.Admin) {
        require(delegatee != address(0), "Admin: cannot delegate to zero address");
        require(delegatee != msg.sender, "Admin: cannot delegate to yourself");

        address oldAdmin = msg.sender;
        userRoles[oldAdmin] = Role.None;
        userRoles[delegatee] = Role.Admin;

         // Ensure delegatee profile exists (lazy creation)
        if (contributors[delegatee].userAddress == address(0)) {
             contributors[delegatee].userAddress = delegatee;
        }

        emit RoleRevoked(oldAdmin, Role.Admin); // Signal old admin loses role
        emit RoleAssigned(delegatee, Role.Admin); // Signal new admin gains role
        emit AdminRoleDelegated(oldAdmin, delegatee); // Specific admin transfer event
    }


    // --- Admin Functions (Utilities) ---

     /**
     * @dev Admin function to set concept status directly (e.g., in case of issues).
     * Use with caution.
     * @param conceptId The ID of the concept.
     * @param newStatus The new status to set.
     */
    function setConceptStatusByAdmin(uint conceptId, ConceptStatus newStatus)
        external
        onlyRole(Role.Admin)
        conceptExists(conceptId)
    {
        ConceptStatus oldStatus = concepts[conceptId].status;
        if (oldStatus == newStatus) {
            return; // No change
        }
        concepts[conceptId].status = newStatus;
        emit ConceptStatusChanged(conceptId, oldStatus, newStatus);
    }

    /**
     * @dev Admin function to remove a concept completely. Use with extreme caution.
     * This marks the concept as removed internally but doesn't delete storage to avoid state corruption.
     * Consider archiving instead in most cases.
     * @param conceptId The ID of the concept to remove.
     */
    function removeConceptByAdmin(uint conceptId)
        external
        onlyRole(Role.Admin)
        conceptExists(conceptId)
    {
        // Mark as archived to signify removal without deleting state directly
        // A more complex implementation might use a 'Removed' status or a separate flag
         ConceptStatus oldStatus = concepts[conceptId].status;
        concepts[conceptId].status = ConceptStatus.Archived; // Using Archived to signify removed by Admin
        // In a real scenario, you might also want to clear sensitive data or unlink references
        // For simplicity here, we just change status and log event.
        emit ConceptStatusChanged(conceptId, oldStatus, ConceptStatus.Archived); // Signalling removal via Archive status
        // Could add a dedicated ConceptRemoved event
    }


    // --- View Functions (Read-only) ---

    /**
     * @dev Gets details of a concept.
     * @param conceptId The ID of the concept.
     * @return Concept struct data.
     */
    function getConceptDetails(uint conceptId)
        external
        view
        conceptExists(conceptId)
        returns (uint, string memory, string memory, address, ConceptStatus, uint)
    {
        Concept storage c = concepts[conceptId];
        return (c.id, c.name, c.description, c.creator, c.status, c.creationTimestamp);
    }

    /**
     * @dev Gets the list of contributors for a concept.
     * @param conceptId The ID of the concept.
     * @return An array of contributor addresses.
     */
    function getConceptContributors(uint conceptId)
        external
        view
        conceptExists(conceptId)
        returns (address[] memory)
    {
        return concepts[conceptId].contributors;
    }

    /**
     * @dev Calculates and returns the dynamic score of a concept.
     * Score = totalRatingSum * ratingInfluenceFactor / ratingCount (if ratingCount > 0)
     * @param conceptId The ID of the concept.
     * @return The calculated score, or 0 if no ratings.
     */
    function getConceptScore(uint conceptId)
        public
        view
        conceptExists(conceptId)
        returns (uint)
    {
        Concept storage c = concepts[conceptId];
        if (c.ratingCount == 0) {
            return 0;
        }
        uint ratingInfluenceFactor = parameters[keccak256("ratingInfluenceFactor")];
        // Prevent division by zero and handle potential overflow on large sums
        return (c.totalRatingSum * ratingInfluenceFactor) / c.ratingCount;
    }

     /**
     * @dev Gets the profile details of a contributor.
     * @param contributor The address of the contributor.
     * @return Contributor struct data (address, reputationPoints).
     */
    function getContributorProfile(address contributor)
        external
        view
        returns (address, uint)
    {
         if (contributors[contributor].userAddress == address(0)) {
             // Return a default profile if user hasn't interacted yet
             return (contributor, 0);
         }
        return (contributors[contributor].userAddress, contributors[contributor].reputationPoints);
    }

    /**
     * @dev Gets the unclaimed points balance for a contributor.
     * These are points earned but not yet moved to the main reputation balance via claimAccruedPoints().
     * @param contributor The address of the contributor.
     * @return The unclaimed points balance.
     */
    function getAvailableReputationPoints(address contributor)
        external
        view
        returns (uint)
    {
        return unclaimedPoints[contributor];
    }

    /**
     * @dev Gets the role assigned to an address.
     * @param contributor The address to check.
     * @return The role of the contributor.
     */
    function getRole(address contributor)
        external
        view
        returns (Role)
    {
        return userRoles[contributor];
    }

    /**
     * @dev Gets the IDs of concepts created by a specific address.
     * Note: This requires iterating through all concepts, which can be gas-intensive
     * for a large number of concepts. A more gas-efficient approach would require
     * storing lists of concepts per creator, adding complexity on writes.
     * For a view function, this is acceptable within limits.
     * @param creator The address of the creator.
     * @return An array of concept IDs.
     */
    function getConceptsCreatedBy(address creator)
        external
        view
        returns (uint[] memory)
    {
        uint[] memory createdConcepts = new uint[](nextConceptId - 1);
        uint count = 0;
        for (uint i = 1; i < nextConceptId; i++) {
            if (concepts[i].creator == creator) {
                createdConcepts[count] = i;
                count++;
            }
        }
        // Trim array to actual size
        uint[] memory result = new uint[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = createdConcepts[i];
        }
        return result;
    }

     /**
     * @dev Gets the IDs of concepts currently in 'UnderReview' status.
      * Note: Similar to getConceptsCreatedBy, iterates all concepts.
     * @return An array of concept IDs.
     */
    function getConceptsWaitingForReview()
        external
        view
        returns (uint[] memory)
    {
        uint[] memory reviewConcepts = new uint[](nextConceptId - 1); // Max possible size
        uint count = 0;
        for (uint i = 1; i < nextConceptId; i++) {
            if (concepts[i].status == ConceptStatus.UnderReview) {
                reviewConcepts[count] = i;
                count++;
            }
        }
         // Trim array
        uint[] memory result = new uint[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = reviewConcepts[i];
        }
        return result;
    }

     /**
     * @dev Gets the IDs of concepts that were created by combining the given parent concept.
     * This traverses the childConcepts link.
     * @param parentConceptId The ID of the parent concept.
     * @return An array of concept IDs created from the parent.
     */
    function getConceptsCombinedFrom(uint parentConceptId)
        external
        view
        conceptExists(parentConceptId)
        returns (uint[] memory)
    {
        return concepts[parentConceptId].childConcepts;
    }

    // --- Internal Helpers (if any) ---
    // (None needed for current functions, but could add e.g., _accruePoints)
}
```