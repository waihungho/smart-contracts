```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation and Skill Marketplace with Evolving NFTs
 * @author Bard (Example - Not for Production)
 * @dev A smart contract for a decentralized marketplace where users can offer and request services based on skills.
 *      Reputation is dynamically tracked and reflected in evolving NFTs that represent user profiles.
 *      This contract incorporates advanced concepts like dynamic NFTs, reputation-based access, and decentralized governance elements.
 *
 * **Outline:**
 * 1. Profile Management: User registration, skill management, profile retrieval.
 * 2. Service Offering:  Creating service offers, browsing services, service details.
 * 3. Service Request & Execution: Requesting services, accepting/rejecting requests, marking completion, verification.
 * 4. Reputation System: Rating service providers, calculating reputation, reputation tiers.
 * 5. Dynamic NFTs: Minting profile NFTs, evolving NFT levels based on reputation, NFT metadata updates.
 * 6. Decentralized Governance (Simple): Feature proposal and voting (basic example).
 * 7. Dispute Resolution (Simplified):  Initiating and resolving disputes (basic example).
 * 8. Platform Fee & Revenue Management: Setting platform fee, withdrawing platform revenue.
 * 9. Utility Functions:  Helper functions for data retrieval and contract state.
 * 10. Security & Access Control:  Ownership, role-based access (simplified).
 *
 * **Function Summary:**
 * 1. `registerProfile(string _name, string[] _skills, string _profileURI)`: Registers a new user profile with name, skills, and profile URI.
 * 2. `updateProfile(string _name, string[] _skills, string _profileURI)`: Updates an existing user profile.
 * 3. `getProfile(address _user)`: Retrieves profile information for a given user.
 * 4. `addSkill(address _user, string _skill)`: Adds a skill to a user's profile.
 * 5. `removeSkill(address _user, string _skill)`: Removes a skill from a user's profile.
 * 6. `offerService(string _title, string _description, uint256 _price, string[] _requiredSkills, string _serviceURI)`: Creates a new service offer.
 * 7. `updateServiceOffer(uint256 _offerId, string _title, string _description, uint256 _price, string[] _requiredSkills, string _serviceURI)`: Updates an existing service offer.
 * 8. `getServiceOffer(uint256 _offerId)`: Retrieves details of a specific service offer.
 * 9. `getAllServiceOffers()`: Retrieves a list of all active service offers.
 * 10. `getServiceOffersBySkill(string _skill)`: Retrieves service offers that require a specific skill.
 * 11. `requestService(uint256 _offerId, string _requestDetails)`: Requests a service from a service provider.
 * 12. `acceptServiceRequest(uint256 _requestId)`: Service provider accepts a service request.
 * 13. `rejectServiceRequest(uint256 _requestId)`: Service provider rejects a service request.
 * 14. `markServiceCompleted(uint256 _requestId)`: Service provider marks a service request as completed.
 * 15. `verifyServiceCompletion(uint256 _requestId, uint8 _rating, string _review)`: Service requester verifies service completion and provides a rating and review.
 * 16. `rateServiceProvider(address _provider, uint8 _rating, string _review)`: Allows any user to rate a service provider (more general rating, not tied to specific request).
 * 17. `getReputation(address _user)`: Retrieves the reputation score and tier of a user.
 * 18. `mintProfileNFT(address _user)`: Mints a dynamic NFT for a user (internal function, triggered on profile registration).
 * 19. `getProfileNFT(address _user)`: Retrieves the NFT ID associated with a user's profile.
 * 20. `updateNFTMetadata(uint256 _tokenId)`: Updates the metadata of a profile NFT based on reputation (internal function).
 * 21. `proposeFeature(string _proposalDetails)`: Allows users to propose new features for the platform (governance example).
 * 22. `voteOnFeature(uint256 _proposalId, bool _vote)`: Allows users to vote on feature proposals (governance example).
 * 23. `initiateDispute(uint256 _requestId, string _disputeDetails)`: Allows users to initiate a dispute for a service request.
 * 24. `resolveDispute(uint256 _disputeId, address _resolver, bool _providerWins)`: Allows an admin/resolver to resolve a dispute.
 * 25. `setPlatformFee(uint256 _feePercentage)`: Allows the contract owner to set the platform fee percentage.
 * 26. `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 * 27. `pauseContract()`: Allows the contract owner to pause the contract.
 * 28. `unpauseContract()`: Allows the contract owner to unpause the contract.
 * 29. `isContractPaused()`: Returns whether the contract is currently paused.
 */

contract SkillMarketplace {
    // --- Structs ---
    struct UserProfile {
        string name;
        string[] skills;
        string profileURI;
        uint256 reputationScore;
        uint8 reputationTier; // e.g., Bronze, Silver, Gold
        uint256 profileNFTId;
        bool exists;
    }

    struct ServiceOffer {
        uint256 id;
        address provider;
        string title;
        string description;
        uint256 price;
        string[] requiredSkills;
        string serviceURI;
        bool isActive;
        uint256 createdAt;
    }

    struct ServiceRequest {
        uint256 id;
        uint256 offerId;
        address requester;
        address provider; // Redundant, but for easier access
        string requestDetails;
        Status status;
        uint8 rating;
        string review;
        uint256 createdAt;
        uint256 completedAt;
    }

    struct ReputationData {
        uint256 score;
        uint8 tier;
    }

    struct FeatureProposal {
        uint256 id;
        string proposalDetails;
        address proposer;
        uint256 upvotes;
        uint256 downvotes;
        bool isActive;
        uint256 createdAt;
    }

    struct Dispute {
        uint256 id;
        uint256 requestId;
        address initiator;
        string disputeDetails;
        DisputeStatus status;
        address resolver;
        bool providerWins;
        uint256 createdAt;
        uint256 resolvedAt;
    }

    // --- Enums ---
    enum Status { Pending, Accepted, Rejected, Completed, Verified, Disputed }
    enum DisputeStatus { Open, Resolved }
    enum ReputationTier { Bronze, Silver, Gold, Platinum, Diamond } // Example tiers

    // --- State Variables ---
    address public owner;
    uint256 public platformFeePercentage = 2; // 2% platform fee by default
    uint256 public nextServiceOfferId = 1;
    uint256 public nextServiceRequestId = 1;
    uint256 public nextFeatureProposalId = 1;
    uint256 public nextDisputeId = 1;
    bool public paused = false;

    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => ServiceOffer) public serviceOffers;
    mapping(uint256 => ServiceRequest) public serviceRequests;
    mapping(uint256 => ReputationData) public userReputations;
    mapping(uint256 => FeatureProposal) public featureProposals;
    mapping(uint256 => Dispute) public disputes;
    mapping(address => uint256) public userProfileNFTs; // Mapping user address to NFT token ID (example, assuming a simple NFT contract is integrated)

    // --- Events ---
    event ProfileRegistered(address user, string name);
    event ProfileUpdated(address user, string name);
    event SkillAdded(address user, string skill);
    event SkillRemoved(address user, string skill);
    event ServiceOffered(uint256 offerId, address provider, string title);
    event ServiceOfferUpdated(uint256 offerId, string title);
    event ServiceRequested(uint256 requestId, uint256 offerId, address requester);
    event ServiceRequestAccepted(uint256 requestId);
    event ServiceRequestRejected(uint256 requestId);
    event ServiceCompleted(uint256 requestId);
    event ServiceVerified(uint256 requestId, uint8 rating);
    event ReputationUpdated(address user, uint256 newScore, uint8 newTier);
    event ProfileNFTMinted(address user, uint256 tokenId);
    event NFTMetadataUpdated(uint256 tokenId);
    event FeatureProposed(uint256 proposalId, address proposer, string proposalDetails);
    event FeatureVoted(uint256 proposalId, address voter, bool vote);
    event DisputeInitiated(uint256 disputeId, uint256 requestId, address initiator);
    event DisputeResolved(uint256 disputeId, address resolver, bool providerWins);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(address owner, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier profileExists(address _user) {
        require(userProfiles[_user].exists, "Profile does not exist.");
        _;
    }

    modifier profileDoesNotExist(address _user) {
        require(!userProfiles[_user].exists, "Profile already exists.");
        _;
    }

    modifier validServiceOffer(uint256 _offerId) {
        require(serviceOffers[_offerId].isActive, "Service offer is not active or does not exist.");
        _;
    }

    modifier validServiceRequest(uint256 _requestId) {
        require(serviceRequests[_requestId].status != Status.Rejected && serviceRequests[_requestId].status != Status.Verified, "Invalid service request status.");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- 1. Profile Management ---
    function registerProfile(string memory _name, string[] memory _skills, string memory _profileURI) public whenNotPaused profileDoesNotExist(msg.sender) {
        userProfiles[msg.sender] = UserProfile({
            name: _name,
            skills: _skills,
            profileURI: _profileURI,
            reputationScore: 0,
            reputationTier: uint8(ReputationTier.Bronze),
            profileNFTId: 0, // NFT ID will be assigned later during minting
            exists: true
        });
        emit ProfileRegistered(msg.sender, _name);
        _mintProfileNFT(msg.sender); // Mint NFT upon profile registration
    }

    function updateProfile(string memory _name, string[] memory _skills, string memory _profileURI) public whenNotPaused profileExists(msg.sender) {
        UserProfile storage profile = userProfiles[msg.sender];
        profile.name = _name;
        profile.skills = _skills;
        profile.profileURI = _profileURI;
        emit ProfileUpdated(msg.sender, _name);
    }

    function getProfile(address _user) public view returns (UserProfile memory) {
        return userProfiles[_user];
    }

    function addSkill(address _user, string memory _skill) public whenNotPaused profileExists(_user) {
        bool skillExists = false;
        for (uint256 i = 0; i < userProfiles[_user].skills.length; i++) {
            if (keccak256(bytes(userProfiles[_user].skills[i])) == keccak256(bytes(_skill))) {
                skillExists = true;
                break;
            }
        }
        if (!skillExists) {
            userProfiles[_user].skills.push(_skill);
            emit SkillAdded(_user, _skill);
        }
    }

    function removeSkill(address _user, string memory _skill) public whenNotPaused profileExists(_user) {
        for (uint256 i = 0; i < userProfiles[_user].skills.length; i++) {
            if (keccak256(bytes(userProfiles[_user].skills[i])) == keccak256(bytes(_skill))) {
                delete userProfiles[_user].skills[i];
                // Compact the array - optional, but can save gas in some cases if removals are frequent
                if (i < userProfiles[_user].skills.length - 1) {
                    userProfiles[_user].skills[i] = userProfiles[_user].skills[userProfiles[_user].skills.length - 1];
                }
                userProfiles[_user].skills.pop();
                emit SkillRemoved(_user, _skill);
                break;
            }
        }
    }

    // --- 2. Service Offering ---
    function offerService(string memory _title, string memory _description, uint256 _price, string[] memory _requiredSkills, string memory _serviceURI) public whenNotPaused profileExists(msg.sender) {
        serviceOffers[nextServiceOfferId] = ServiceOffer({
            id: nextServiceOfferId,
            provider: msg.sender,
            title: _title,
            description: _description,
            price: _price,
            requiredSkills: _requiredSkills,
            serviceURI: _serviceURI,
            isActive: true,
            createdAt: block.timestamp
        });
        emit ServiceOffered(nextServiceOfferId, msg.sender, _title);
        nextServiceOfferId++;
    }

    function updateServiceOffer(uint256 _offerId, string memory _title, string memory _description, uint256 _price, string[] memory _requiredSkills, string memory _serviceURI) public whenNotPaused validServiceOffer(_offerId) {
        require(serviceOffers[_offerId].provider == msg.sender, "Only service provider can update the offer.");
        ServiceOffer storage offer = serviceOffers[_offerId];
        offer.title = _title;
        offer.description = _description;
        offer.price = _price;
        offer.requiredSkills = _requiredSkills;
        offer.serviceURI = _serviceURI;
        emit ServiceOfferUpdated(_offerId, _title);
    }

    function getServiceOffer(uint256 _offerId) public view validServiceOffer(_offerId) returns (ServiceOffer memory) {
        return serviceOffers[_offerId];
    }

    function getAllServiceOffers() public view returns (ServiceOffer[] memory) {
        uint256 offerCount = 0;
        for (uint256 i = 1; i < nextServiceOfferId; i++) {
            if (serviceOffers[i].isActive) {
                offerCount++;
            }
        }
        ServiceOffer[] memory activeOffers = new ServiceOffer[](offerCount);
        uint256 index = 0;
        for (uint256 i = 1; i < nextServiceOfferId; i++) {
            if (serviceOffers[i].isActive) {
                activeOffers[index] = serviceOffers[i];
                index++;
            }
        }
        return activeOffers;
    }

    function getServiceOffersBySkill(string memory _skill) public view returns (ServiceOffer[] memory) {
        uint256 offerCount = 0;
        for (uint256 i = 1; i < nextServiceOfferId; i++) {
            if (serviceOffers[i].isActive) {
                for (uint256 j = 0; j < serviceOffers[i].requiredSkills.length; j++) {
                    if (keccak256(bytes(serviceOffers[i].requiredSkills[j])) == keccak256(bytes(_skill))) {
                        offerCount++;
                        break;
                    }
                }
            }
        }
        ServiceOffer[] memory skillOffers = new ServiceOffer[](offerCount);
        uint256 index = 0;
        for (uint256 i = 1; i < nextServiceOfferId; i++) {
            if (serviceOffers[i].isActive) {
                for (uint256 j = 0; j < serviceOffers[i].requiredSkills.length; j++) {
                    if (keccak256(bytes(serviceOffers[i].requiredSkills[j])) == keccak256(bytes(_skill))) {
                        skillOffers[index] = serviceOffers[i];
                        index++;
                        break;
                    }
                }
            }
        }
        return skillOffers;
    }

    // --- 3. Service Request & Execution ---
    function requestService(uint256 _offerId, string memory _requestDetails) public payable whenNotPaused validServiceOffer(_offerId) profileExists(msg.sender) {
        require(msg.sender != serviceOffers[_offerId].provider, "Cannot request service from yourself.");
        require(msg.value >= serviceOffers[_offerId].price, "Insufficient payment sent.");

        serviceRequests[nextServiceRequestId] = ServiceRequest({
            id: nextServiceRequestId,
            offerId: _offerId,
            requester: msg.sender,
            provider: serviceOffers[_offerId].provider,
            requestDetails: _requestDetails,
            status: Status.Pending,
            rating: 0,
            review: "",
            createdAt: block.timestamp,
            completedAt: 0
        });
        emit ServiceRequested(nextServiceRequestId, _offerId, msg.sender);
        nextServiceRequestId++;
    }

    function acceptServiceRequest(uint256 _requestId) public whenNotPaused validServiceRequest(_requestId) {
        require(serviceRequests[_requestId].provider == msg.sender, "Only service provider can accept the request.");
        require(serviceRequests[_requestId].status == Status.Pending, "Request is not in pending status.");
        serviceRequests[_requestId].status = Status.Accepted;
        emit ServiceRequestAccepted(_requestId);
    }

    function rejectServiceRequest(uint256 _requestId) public whenNotPaused validServiceRequest(_requestId) {
        require(serviceRequests[_requestId].provider == msg.sender, "Only service provider can reject the request.");
        require(serviceRequests[_requestId].status == Status.Pending, "Request is not in pending status.");
        serviceRequests[_requestId].status = Status.Rejected;
        payable(serviceRequests[_requestId].requester).transfer(serviceOffers[serviceRequests[_requestId].offerId].price); // Refund requester
        emit ServiceRequestRejected(_requestId);
    }

    function markServiceCompleted(uint256 _requestId) public whenNotPaused validServiceRequest(_requestId) {
        require(serviceRequests[_requestId].provider == msg.sender, "Only service provider can mark the request as completed.");
        require(serviceRequests[_requestId].status == Status.Accepted, "Request is not in accepted status.");
        serviceRequests[_requestId].status = Status.Completed;
        serviceRequests[_requestId].completedAt = block.timestamp;
        emit ServiceCompleted(_requestId);
    }

    function verifyServiceCompletion(uint256 _requestId, uint8 _rating, string memory _review) public whenNotPaused validServiceRequest(_requestId) {
        require(serviceRequests[_requestId].requester == msg.sender, "Only service requester can verify completion.");
        require(serviceRequests[_requestId].status == Status.Completed, "Request is not in completed status.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");

        ServiceRequest storage request = serviceRequests[_requestId];
        request.status = Status.Verified;
        request.rating = _rating;
        request.review = _review;

        uint256 platformFee = (serviceOffers[request.offerId].price * platformFeePercentage) / 100;
        uint256 providerPayment = serviceOffers[request.offerId].price - platformFee;

        payable(request.provider).transfer(providerPayment); // Pay provider minus platform fee
        payable(owner).transfer(platformFee); // Collect platform fee

        _updateReputation(request.provider, _rating);
        emit ServiceVerified(_requestId, _rating);
    }

    // --- 4. Reputation System ---
    function rateServiceProvider(address _provider, uint8 _rating, string memory _review) public whenNotPaused profileExists(_provider) profileExists(msg.sender) {
        require(_provider != msg.sender, "Cannot rate yourself.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");

        _updateReputation(_provider, _rating);
        // Consider storing reviews separately if needed for more complex analysis or display
        emit ReputationUpdated(_provider, userReputations[_provider].score, userReputations[_provider].tier);
    }

    function getReputation(address _user) public view profileExists(_user) returns (ReputationData memory) {
        return userReputations[_user];
    }

    function _updateReputation(address _user, uint8 _rating) internal {
        uint256 currentScore = userReputations[_user].score;
        uint256 newScore = currentScore + _rating; // Simple reputation update - can be made more sophisticated
        userReputations[_user].score = newScore;
        userReputations[_user].tier = _calculateReputationTier(newScore);
        _updateNFTMetadata(userProfileNFTs[_user]); // Update NFT metadata on reputation change
        emit ReputationUpdated(_user, newScore, userReputations[_user].tier);
    }

    function _calculateReputationTier(uint256 _score) internal pure returns (uint8) {
        if (_score >= 500) {
            return uint8(ReputationTier.Diamond);
        } else if (_score >= 250) {
            return uint8(ReputationTier.Platinum);
        } else if (_score >= 100) {
            return uint8(ReputationTier.Gold);
        } else if (_score >= 50) {
            return uint8(ReputationTier.Silver);
        } else {
            return uint8(ReputationTier.Bronze);
        }
    }

    // --- 5. Dynamic NFTs (Simplified Example - Requires external NFT contract integration for a full implementation) ---
    function _mintProfileNFT(address _user) internal {
        // In a real-world scenario, this would interact with an external NFT contract.
        // For this example, we'll simulate NFT minting and metadata update within this contract.

        uint256 tokenId = block.timestamp + uint256(uint160(_user)); // Simple token ID generation - replace with proper NFT minting logic
        userProfileNFTs[_user] = tokenId;
        userProfiles[_user].profileNFTId = tokenId;
        emit ProfileNFTMinted(_user, tokenId);
        _updateNFTMetadata(tokenId); // Initial metadata update
    }

    function getProfileNFT(address _user) public view profileExists(_user) returns (uint256) {
        return userProfileNFTs[_user];
    }

    function _updateNFTMetadata(uint256 _tokenId) internal {
        // In a real-world scenario, this would update metadata on IPFS or a similar storage solution.
        // The metadata would be dynamically generated based on user profile data and reputation.
        // Example metadata update logic (very simplified):

        // Fetch user profile associated with the NFT (assuming token ID can be linked back to user) - In a real NFT contract, this link would be maintained.
        address userAddress = address(uint160(uint256(tokenId) - block.timestamp)); // Reverse engineered simple token ID for example - not robust in real use.
        if (!userProfiles[userAddress].exists) return; // User might not exist anymore or token ID not correctly linked.
        UserProfile memory profile = userProfiles[userAddress];
        ReputationData memory reputation = userReputations[userAddress];

        // Example metadata structure (JSON):
        string memory metadata = string(abi.encodePacked(
            '{"name": "', profile.name, ' Profile NFT", "description": "Dynamic NFT representing profile and reputation.", "attributes": [',
            '{"trait_type": "Reputation Tier", "value": "', _tierToString(reputation.tier), '"}, ',
            '{"trait_type": "Reputation Score", "value": "', _uintToString(reputation.score), '"}, ',
            '{"trait_type": "Skills", "value": "', _skillsArrayToString(profile.skills), '"}]}'
        ));
        // In a real system, you would upload this metadata to IPFS and update the NFT contract with the new URI.
        // For this example, we just emit an event indicating metadata update.
        emit NFTMetadataUpdated(_tokenId);
        // In a real NFT contract, you might have functions to set token URI and retrieve metadata.
    }

    function _tierToString(uint8 _tier) internal pure returns (string memory) {
        if (_tier == uint8(ReputationTier.Diamond)) return "Diamond";
        if (_tier == uint8(ReputationTier.Platinum)) return "Platinum";
        if (_tier == uint8(ReputationTier.Gold)) return "Gold";
        if (_tier == uint8(ReputationTier.Silver)) return "Silver";
        return "Bronze";
    }

    function _uintToString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function _skillsArrayToString(string[] memory _skills) internal pure returns (string memory) {
        string memory skillsString = "[";
        for (uint256 i = 0; i < _skills.length; i++) {
            skillsString = string(abi.encodePacked(skillsString, '"', _skills[i], '"'));
            if (i < _skills.length - 1) {
                skillsString = string(abi.encodePacked(skillsString, ", "));
            }
        }
        skillsString = string(abi.encodePacked(skillsString, "]"));
        return skillsString;
    }


    // --- 6. Decentralized Governance (Simple Example) ---
    function proposeFeature(string memory _proposalDetails) public whenNotPaused profileExists(msg.sender) {
        featureProposals[nextFeatureProposalId] = FeatureProposal({
            id: nextFeatureProposalId,
            proposalDetails: _proposalDetails,
            proposer: msg.sender,
            upvotes: 0,
            downvotes: 0,
            isActive: true,
            createdAt: block.timestamp
        });
        emit FeatureProposed(nextFeatureProposalId, msg.sender, _proposalDetails);
        nextFeatureProposalId++;
    }

    function voteOnFeature(uint256 _proposalId, bool _vote) public whenNotPaused profileExists(msg.sender) {
        require(featureProposals[_proposalId].isActive, "Proposal is not active.");
        if (_vote) {
            featureProposals[_proposalId].upvotes++;
        } else {
            featureProposals[_proposalId].downvotes++;
        }
        emit FeatureVoted(_proposalId, msg.sender, _vote);
    }

    // --- 7. Dispute Resolution (Simplified Example) ---
    function initiateDispute(uint256 _requestId, string memory _disputeDetails) public whenNotPaused validServiceRequest(_requestId) {
        require(serviceRequests[_requestId].requester == msg.sender || serviceRequests[_requestId].provider == msg.sender, "Only requester or provider can initiate a dispute.");
        require(serviceRequests[_requestId].status != Status.Verified && serviceRequests[_requestId].status != Status.Rejected, "Dispute can only be initiated for active requests.");

        disputes[nextDisputeId] = Dispute({
            id: nextDisputeId,
            requestId: _requestId,
            initiator: msg.sender,
            disputeDetails: _disputeDetails,
            status: DisputeStatus.Open,
            resolver: address(0), // Set resolver to null initially
            providerWins: false, // Default to provider not winning initially
            createdAt: block.timestamp,
            resolvedAt: 0
        });
        serviceRequests[_requestId].status = Status.Disputed; // Update request status
        emit DisputeInitiated(nextDisputeId, _requestId, msg.sender);
        nextDisputeId++;
    }

    function resolveDispute(uint256 _disputeId, address _resolver, bool _providerWins) public onlyOwner whenNotPaused {
        require(disputes[_disputeId].status == DisputeStatus.Open, "Dispute is already resolved.");
        uint256 requestId = disputes[_disputeId].requestId;

        disputes[_disputeId].status = DisputeStatus.Resolved;
        disputes[_disputeId].resolver = _resolver;
        disputes[_disputeId].providerWins = _providerWins;
        disputes[_disputeId].resolvedAt = block.timestamp;

        if (_providerWins) {
            payable(serviceRequests[requestId].provider).transfer(serviceOffers[serviceRequests[requestId].offerId].price); // Pay provider even in dispute win in this simplified example
        } else {
            payable(serviceRequests[requestId].requester).transfer(serviceOffers[serviceRequests[requestId].offerId].price); // Refund requester if provider loses dispute
        }
        emit DisputeResolved(_disputeId, _resolver, _providerWins);
    }

    // --- 8. Platform Fee & Revenue Management ---
    function setPlatformFee(uint256 _feePercentage) public onlyOwner whenNotPaused {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    function withdrawPlatformFees() public onlyOwner whenNotPaused {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit PlatformFeesWithdrawn(owner, balance);
    }

    // --- 9. Utility Functions ---
    function isContractPaused() public view returns (bool) {
        return paused;
    }

    // --- 10. Security & Access Control ---
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    // Fallback function to prevent accidental sending of Ether to the contract
    receive() external payable {
        revert("This contract does not accept direct Ether transfers.");
    }
}
```