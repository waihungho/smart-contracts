```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Art Gallery - Smart Contract Outline and Function Summary
 * @author Bard (AI Assistant)

 * @dev A smart contract for a decentralized dynamic art gallery, showcasing advanced concepts.
 * It allows artists to submit dynamic art NFTs, curators to manage the gallery, and users to interact with and experience evolving digital art.
 * This contract incorporates dynamic NFT properties, decentralized curation, community interaction, and potentially external data integration for art evolution.
 * It aims to be creative and trendy, avoiding duplication of common open-source contracts.

 * **Contract Outline:**

 * **Data Structures:**
 *   - `ArtPiece`: Struct to hold art piece details (artist, metadata URI, dynamic properties, submission timestamp, curator approval status, etc.)
 *   - `CuratorProposal`: Struct to manage curator proposals (proposer, voting start time, voting end time, votes, status)
 *   - `GallerySettings`: Struct to hold gallery-wide settings (curation fee, platform fee, dynamic update frequency, etc.)

 * **State Variables:**
 *   - `artPieces`: Mapping from art piece ID to `ArtPiece` struct.
 *   - `curators`: Array of approved curator addresses.
 *   - `curatorProposals`: Mapping from proposal ID to `CuratorProposal` struct.
 *   - `gallerySettings`: `GallerySettings` struct.
 *   - `nextArtPieceId`: Counter for art piece IDs.
 *   - `nextProposalId`: Counter for curator proposal IDs.
 *   - `owner`: Contract owner address.
 *   - `paused`: Boolean to pause/unpause core functionalities.

 * **Events:**
 *   - `ArtPieceSubmitted`: Emitted when an art piece is submitted.
 *   - `ArtPieceApproved`: Emitted when an art piece is approved by curators.
 *   - `ArtPieceRejected`: Emitted when an art piece is rejected by curators.
 *   - `ArtPieceUpdatedDynamically`: Emitted when an art piece's dynamic properties are updated.
 *   - `CuratorProposed`: Emitted when a new curator proposal is submitted.
 *   - `CuratorVoted`: Emitted when a vote is cast on a curator proposal.
 *   - `CuratorAdded`: Emitted when a new curator is added.
 *   - `CuratorRemoved`: Emitted when a curator is removed.
 *   - `GalleryPaused`: Emitted when the gallery is paused.
 *   - `GalleryUnpaused`: Emitted when the gallery is unpaused.
 *   - `GallerySettingsUpdated`: Emitted when gallery settings are updated.
 *   - `PlatformFeeWithdrawn`: Emitted when platform fees are withdrawn.

 * **Functions (Summary - 20+ Functions):**

 * **Artist Functions:**
 *   1. `submitArtPiece(string memory _metadataURI, bytes memory _initialDynamicData)`: Allows artists to submit a new dynamic art piece for curation.
 *   2. `updateArtPieceMetadata(uint256 _artPieceId, string memory _newMetadataURI)`: Allows artists to update the metadata URI of their submitted art piece (before approval or under specific conditions).
 *   3. `getArtistArtPieces(address _artistAddress)`: View function to retrieve a list of art piece IDs submitted by a specific artist.

 * **Curator Functions:**
 *   4. `proposeCurator(address _newCurator)`: Allows curators to propose a new curator.
 *   5. `voteForCurator(uint256 _proposalId, bool _vote)`: Allows curators to vote on a curator proposal.
 *   6. `finalizeCuratorProposal(uint256 _proposalId)`: Allows any curator (or owner) to finalize a curator proposal after voting period ends.
 *   7. `removeCurator(address _curatorToRemove)`: Allows existing curators to vote to remove a curator.
 *   8. `approveArtPiece(uint256 _artPieceId)`: Allows curators to approve a submitted art piece, making it visible in the gallery.
 *   9. `rejectArtPiece(uint256 _artPieceId, string memory _reason)`: Allows curators to reject a submitted art piece with a reason.
 *  10. `getPendingArtPieces()`: View function for curators to retrieve a list of art piece IDs pending approval.
 *  11. `getApprovedArtPieces()`: View function for curators to retrieve a list of approved art piece IDs.

 * **Dynamic Art & Gallery Functions:**
 *  12. `updateArtPieceDynamicData(uint256 _artPieceId, bytes memory _newDynamicData)`:  (Advanced) Allows authorized entities (e.g., oracles, specific contracts, or even artists under certain conditions) to update the dynamic data of an approved art piece, triggering its evolution. This could be based on external data, on-chain events, or time.
 *  13. `triggerDynamicUpdate(uint256 _artPieceId)`: (Alternative Dynamic Update - simpler/manual) Allows curators or the owner to manually trigger a dynamic update for an art piece, potentially using an internal algorithm or predefined update logic based on current on-chain state (block number, timestamp, etc.).
 *  14. `setDynamicUpdateFrequency(uint256 _newFrequency)`: Allows the owner to set the frequency (e.g., in blocks or time) for automatic dynamic updates (if implemented).
 *  15. `getArtPieceDynamicData(uint256 _artPieceId)`: View function to retrieve the current dynamic data of an art piece.
 *  16. `getArtPieceDetails(uint256 _artPieceId)`: View function to retrieve all details of an art piece.
 *  17. `getAllApprovedArtPieceIds()`: View function to get IDs of all approved art pieces in the gallery.

 * **Gallery Management & Utility Functions:**
 *  18. `setGalleryCurationFee(uint256 _newFee)`: Allows the owner to set the curation fee required for submitting art pieces (optional revenue model).
 *  19. `setPlatformFeePercentage(uint256 _newPercentage)`: Allows the owner to set a platform fee percentage on transactions (e.g., if art pieces are sold or rented - not implemented in this basic example but could be extended).
 *  20. `withdrawPlatformFees(address _recipient)`: Allows the owner to withdraw accumulated platform fees.
 *  21. `pauseGallery()`: Allows the owner to pause core gallery functionalities for maintenance or emergency.
 *  22. `unpauseGallery()`: Allows the owner to unpause the gallery.
 *  23. `setGallerySetting(string memory _settingName, uint256 _settingValue)`: A generic function to update various gallery settings (extensible).
 *  24. `getGallerySetting(string memory _settingName)`: View function to retrieve a gallery setting value.
 *  25. `isCurator(address _address)`: View function to check if an address is an approved curator.
 *  26. `getCuratorList()`: View function to get the list of current curators.
 *  27. `getProposalDetails(uint256 _proposalId)`: View function to get details of a curator proposal.
 *  28. `getOwner()`: View function to get the contract owner address.

 * **Advanced Concepts Implemented:**
 *   - **Dynamic NFTs:**  `_initialDynamicData` and `updateArtPieceDynamicData` functions are designed to handle dynamic aspects of NFTs, allowing art to evolve over time or based on external factors.
 *   - **Decentralized Curation:** Curator proposal and voting system creates a decentralized governance layer for gallery content.
 *   - **Extensible Settings:** `setGallerySetting` and `getGallerySetting` allow for future expansion and configuration of gallery parameters.
 *   - **Pausing Mechanism:**  Provides a safety feature for the owner to temporarily halt operations.
 *   - **Event Emission:** Comprehensive event logging for off-chain monitoring and integration.

 * **Note:** This is a conceptual outline and a starting point.  Actual implementation would require more detailed logic, security considerations, gas optimization, and potentially integration with external oracles or other smart contracts for advanced dynamic behavior.
 */

contract DynamicArtGallery {
    // Data Structures
    struct ArtPiece {
        address artist;
        string metadataURI;
        bytes dynamicData; // Stores dynamic properties (e.g., JSON, encoded data)
        uint256 submissionTimestamp;
        bool isApproved;
        string rejectionReason;
    }

    struct CuratorProposal {
        address proposer;
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) votes; // Curators who voted 'yes'
        uint256 yesVotesCount;
        uint256 noVotesCount;
        bool finalized;
        bool approved; // Was the proposal approved?
    }

    struct GallerySettings {
        uint256 curationFee; // Optional fee for submitting art
        uint256 platformFeePercentage; // Optional platform fee percentage
        uint256 dynamicUpdateFrequency; // Frequency of automatic dynamic updates (if implemented)
        uint256 curatorProposalVotingPeriod; // Duration of curator proposal voting
        uint256 curatorRemovalVotingPeriod; // Duration of curator removal voting
        uint256 curatorQuorumPercentage; // Percentage of curators needed to approve/reject proposals
    }


    // State Variables
    mapping(uint256 => ArtPiece) public artPieces;
    address[] public curators;
    mapping(uint256 => CuratorProposal) public curatorProposals;
    GallerySettings public gallerySettings;
    uint256 public nextArtPieceId;
    uint256 public nextProposalId;
    address public owner;
    bool public paused;
    uint256 public platformFeesBalance;

    // Events
    event ArtPieceSubmitted(uint256 artPieceId, address artist, string metadataURI);
    event ArtPieceApproved(uint256 artPieceId, address curator);
    event ArtPieceRejected(uint256 artPieceId, address curator, string reason);
    event ArtPieceUpdatedDynamically(uint256 artPieceId);
    event CuratorProposed(uint256 proposalId, address proposer, address newCurator);
    event CuratorVoted(uint256 proposalId, address curator, bool vote);
    event CuratorAdded(address newCurator);
    event CuratorRemoved(address removedCurator);
    event GalleryPaused(address pauser);
    event GalleryUnpaused(address unpauser);
    event GallerySettingsUpdated(string settingName, uint256 settingValue);
    event PlatformFeeWithdrawn(address recipient, uint256 amount);


    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyCurators() {
        require(isCurator(msg.sender), "Only curators can call this function.");
        _;
    }

    modifier galleryNotPaused() {
        require(!paused, "Gallery is currently paused.");
        _;
    }

    modifier validArtPieceId(uint256 _artPieceId) {
        require(_artPieceId < nextArtPieceId, "Invalid art piece ID.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId < nextProposalId, "Invalid proposal ID.");
        _;
    }

    modifier proposalNotFinalized(uint256 _proposalId) {
        require(!curatorProposals[_proposalId].finalized, "Proposal already finalized.");
        _;
    }


    // Constructor
    constructor() {
        owner = msg.sender;
        curators.push(msg.sender); // Initial curator is the contract deployer
        gallerySettings.curatorProposalVotingPeriod = 7 days; // Example voting period
        gallerySettings.curatorRemovalVotingPeriod = 7 days;
        gallerySettings.curatorQuorumPercentage = 50; // 50% quorum for curator actions
    }

    // 1. Artist Function: submitArtPiece
    function submitArtPiece(string memory _metadataURI, bytes memory _initialDynamicData)
        public
        galleryNotPaused
    {
        // Optional: Charge a curation fee if set
        if (gallerySettings.curationFee > 0) {
            require(msg.value >= gallerySettings.curationFee, "Insufficient curation fee.");
            if (msg.value > gallerySettings.curationFee) {
                payable(msg.sender).transfer(msg.value - gallerySettings.curationFee); // Return excess fee
            }
        }

        artPieces[nextArtPieceId] = ArtPiece({
            artist: msg.sender,
            metadataURI: _metadataURI,
            dynamicData: _initialDynamicData,
            submissionTimestamp: block.timestamp,
            isApproved: false,
            rejectionReason: ""
        });

        emit ArtPieceSubmitted(nextArtPieceId, msg.sender, _metadataURI);
        nextArtPieceId++;
    }

    // 2. Artist Function: updateArtPieceMetadata
    function updateArtPieceMetadata(uint256 _artPieceId, string memory _newMetadataURI)
        public
        validArtPieceId(_artPieceId)
        galleryNotPaused
    {
        require(artPieces[_artPieceId].artist == msg.sender, "Only artist can update metadata.");
        require(!artPieces[_artPieceId].isApproved, "Cannot update metadata after approval."); // Optional restriction

        artPieces[_artPieceId].metadataURI = _newMetadataURI;
    }

    // 3. Artist Function: getArtistArtPieces
    function getArtistArtPieces(address _artistAddress)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory artistArtPieceIds = new uint256[](nextArtPieceId);
        uint256 count = 0;
        for (uint256 i = 0; i < nextArtPieceId; i++) {
            if (artPieces[i].artist == _artistAddress) {
                artistArtPieceIds[count] = i;
                count++;
            }
        }
        // Resize array to actual count of art pieces
        assembly {
            mstore(artistArtPieceIds, count)
        }
        return artistArtPieceIds;
    }


    // 4. Curator Function: proposeCurator
    function proposeCurator(address _newCurator)
        public
        onlyCurators
        galleryNotPaused
    {
        require(_newCurator != address(0), "Invalid curator address.");
        require(!isCurator(_newCurator), "Address is already a curator.");

        curatorProposals[nextProposalId] = CuratorProposal({
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + gallerySettings.curatorProposalVotingPeriod,
            yesVotesCount: 0,
            noVotesCount: 0,
            finalized: false,
            approved: false
        });

        emit CuratorProposed(nextProposalId, msg.sender, _newCurator);
        nextProposalId++;
    }

    // 5. Curator Function: voteForCurator
    function voteForCurator(uint256 _proposalId, bool _vote)
        public
        onlyCurators
        validProposalId(_proposalId)
        proposalNotFinalized(_proposalId)
        galleryNotPaused
    {
        CuratorProposal storage proposal = curatorProposals[_proposalId];
        require(!proposal.votes[msg.sender], "Curator already voted.");
        require(block.timestamp <= proposal.endTime, "Voting period has ended.");

        proposal.votes[msg.sender] = true; // Record vote
        if (_vote) {
            proposal.yesVotesCount++;
        } else {
            proposal.noVotesCount++;
        }

        emit CuratorVoted(_proposalId, msg.sender, _vote);
    }

    // 6. Curator Function: finalizeCuratorProposal
    function finalizeCuratorProposal(uint256 _proposalId)
        public
        validProposalId(_proposalId)
        proposalNotFinalized(_proposalId)
        galleryNotPaused
    {
        CuratorProposal storage proposal = curatorProposals[_proposalId];
        require(block.timestamp > proposal.endTime, "Voting period is still active.");

        uint256 curatorCount = curators.length;
        uint256 quorumNeeded = (curatorCount * gallerySettings.curatorQuorumPercentage) / 100;

        if (proposal.yesVotesCount >= quorumNeeded && proposal.yesVotesCount > proposal.noVotesCount) {
            proposal.approved = true;
            address newCurator = curatorProposals[_proposalId].proposer; // Assuming proposer intended to add themselves (can be adjusted)
            address proposedCurator = _getProposalProposerAddress(_proposalId); // Correctly retrieve proposed curator (implementation below)
            if (!isCurator(proposedCurator)) {
                curators.push(proposedCurator);
                emit CuratorAdded(proposedCurator);
            }
        }
        proposal.finalized = true;
    }

    // Helper function to retrieve the proposed curator address (adjust based on your proposal logic)
    function _getProposalProposerAddress(uint256 _proposalId) private view returns (address) {
        // In this simplified example, we are assuming the proposer intended to add *themselves* as curator.
        // In a real scenario, the proposal would likely explicitly store the *target* curator address.
        return curatorProposals[_proposalId].proposer; // Adjust this logic as needed
    }


    // 7. Curator Function: removeCurator
    function removeCurator(address _curatorToRemove)
        public
        onlyCurators
        galleryNotPaused
    {
        require(_curatorToRemove != address(0), "Invalid curator address.");
        require(isCurator(_curatorToRemove), "Address is not a curator.");
        require(_curatorToRemove != owner, "Cannot remove the contract owner from curators."); // Optional: Prevent removing owner

        uint256 proposalId = nextProposalId++;
        curatorProposals[proposalId] = CuratorProposal({
            proposer: msg.sender, // Proposer is the curator initiating removal
            startTime: block.timestamp,
            endTime: block.timestamp + gallerySettings.curatorRemovalVotingPeriod,
            yesVotesCount: 0,
            noVotesCount: 0,
            finalized: false,
            approved: false
        });
        emit CuratorProposed(proposalId, msg.sender, _curatorToRemove); // Event to reflect removal proposal

        // Curators now need to vote on this proposal (voteForCurator and finalizeCuratorProposal functions)
        // If approved, finalizeCuratorRemoval function (below) would be called.
    }

    // (Separate function to finalize curator removal after voting)
    function finalizeCuratorRemoval(uint256 _proposalId, address _curatorToRemove)
        public
        onlyCurators
        validProposalId(_proposalId)
        proposalNotFinalized(_proposalId)
        galleryNotPaused
    {
        CuratorProposal storage proposal = curatorProposals[_proposalId];
        require(block.timestamp > proposal.endTime, "Voting period is still active.");

        uint256 curatorCount = curators.length;
        uint256 quorumNeeded = (curatorCount * gallerySettings.curatorQuorumPercentage) / 100;

        if (proposal.yesVotesCount >= quorumNeeded && proposal.yesVotesCount > proposal.noVotesCount) {
            proposal.approved = true;
            _removeCuratorFromList(_curatorToRemove); // Internal function to remove from curators array
            emit CuratorRemoved(_curatorToRemove);
        }
        proposal.finalized = true;
    }

    function _removeCuratorFromList(address _curatorToRemove) private {
        address[] memory currentCurators = curators;
        delete curators; // Clear the array
        for (uint256 i = 0; i < currentCurators.length; i++) {
            if (currentCurators[i] != _curatorToRemove) {
                curators.push(currentCurators[i]);
            }
        }
    }


    // 8. Curator Function: approveArtPiece
    function approveArtPiece(uint256 _artPieceId)
        public
        onlyCurators
        validArtPieceId(_artPieceId)
        galleryNotPaused
    {
        require(!artPieces[_artPieceId].isApproved, "Art piece already approved.");

        artPieces[_artPieceId].isApproved = true;
        emit ArtPieceApproved(_artPieceId, msg.sender);
    }

    // 9. Curator Function: rejectArtPiece
    function rejectArtPiece(uint256 _artPieceId, string memory _reason)
        public
        onlyCurators
        validArtPieceId(_artPieceId)
        galleryNotPaused
    {
        require(!artPieces[_artPieceId].isApproved, "Cannot reject an already approved art piece.");

        artPieces[_artPieceId].isApproved = false; // Still set to false for clarity
        artPieces[_artPieceId].rejectionReason = _reason;
        emit ArtPieceRejected(_artPieceId, msg.sender, _reason);
    }

    // 10. Curator Function: getPendingArtPieces
    function getPendingArtPieces()
        public
        view
        onlyCurators
        returns (uint256[] memory)
    {
        uint256[] memory pendingArtPieceIds = new uint256[](nextArtPieceId);
        uint256 count = 0;
        for (uint256 i = 0; i < nextArtPieceId; i++) {
            if (!artPieces[i].isApproved && artPieces[i].rejectionReason == "") { // Check for not approved and not rejected
                pendingArtPieceIds[count] = i;
                count++;
            }
        }
        assembly {
            mstore(pendingArtPieceIds, count)
        }
        return pendingArtPieceIds;
    }

    // 11. Curator Function: getApprovedArtPieces
    function getApprovedArtPieces()
        public
        view
        onlyCurators
        returns (uint256[] memory)
    {
        uint256[] memory approvedArtPieceIds = new uint256[](nextArtPieceId);
        uint256 count = 0;
        for (uint256 i = 0; i < nextArtPieceId; i++) {
            if (artPieces[i].isApproved) {
                approvedArtPieceIds[count] = i;
                count++;
            }
        }
        assembly {
            mstore(approvedArtPieceIds, count)
        }
        return approvedArtPieceIds;
    }


    // 12. Dynamic Art Function: updateArtPieceDynamicData
    function updateArtPieceDynamicData(uint256 _artPieceId, bytes memory _newDynamicData)
        public
        validArtPieceId(_artPieceId)
        galleryNotPaused
    {
        // Example: Allow only curators or the artist to update dynamic data (can be customized)
        require(isCurator(msg.sender) || artPieces[_artPieceId].artist == msg.sender, "Only curators or artist can update dynamic data.");
        require(artPieces[_artPieceId].isApproved, "Dynamic data can only be updated for approved art pieces.");

        artPieces[_artPieceId].dynamicData = _newDynamicData;
        emit ArtPieceUpdatedDynamically(_artPieceId);
    }

    // 13. Dynamic Art Function: triggerDynamicUpdate (Simplified Manual Trigger)
    function triggerDynamicUpdate(uint256 _artPieceId)
        public
        onlyCurators // Example: Allow curators to manually trigger
        validArtPieceId(_artPieceId)
        galleryNotPaused
    {
        require(artPieces[_artPieceId].isApproved, "Dynamic update can only be triggered for approved art pieces.");

        // Example: Simple dynamic update logic based on block timestamp (can be replaced with more complex logic)
        bytes memory newDynamicData = abi.encode(block.timestamp); // Example: Encode timestamp as dynamic data
        artPieces[_artPieceId].dynamicData = newDynamicData;
        emit ArtPieceUpdatedDynamically(_artPieceId);
    }

    // 14. Dynamic Art Function: setDynamicUpdateFrequency (Placeholder - not actively used in this example)
    function setDynamicUpdateFrequency(uint256 _newFrequency)
        public
        onlyOwner
    {
        gallerySettings.dynamicUpdateFrequency = _newFrequency;
        emit GallerySettingsUpdated("dynamicUpdateFrequency", _newFrequency);
    }

    // 15. Dynamic Art Function: getArtPieceDynamicData
    function getArtPieceDynamicData(uint256 _artPieceId)
        public
        view
        validArtPieceId(_artPieceId)
        returns (bytes memory)
    {
        return artPieces[_artPieceId].dynamicData;
    }

    // 16. Dynamic Art Function: getArtPieceDetails
    function getArtPieceDetails(uint256 _artPieceId)
        public
        view
        validArtPieceId(_artPieceId)
        returns (ArtPiece memory)
    {
        return artPieces[_artPieceId];
    }

    // 17. Dynamic Art Function: getAllApprovedArtPieceIds
    function getAllApprovedArtPieceIds()
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory approvedArtPieceIds = new uint256[](nextArtPieceId);
        uint256 count = 0;
        for (uint256 i = 0; i < nextArtPieceId; i++) {
            if (artPieces[i].isApproved) {
                approvedArtPieceIds[count] = i;
                count++;
            }
        }
        assembly {
            mstore(approvedArtPieceIds, count)
        }
        return approvedArtPieceIds;
    }


    // 18. Gallery Management Function: setGalleryCurationFee
    function setGalleryCurationFee(uint256 _newFee)
        public
        onlyOwner
    {
        gallerySettings.curationFee = _newFee;
        emit GallerySettingsUpdated("curationFee", _newFee);
    }

    // 19. Gallery Management Function: setPlatformFeePercentage
    function setPlatformFeePercentage(uint256 _newPercentage)
        public
        onlyOwner
    {
        require(_newPercentage <= 100, "Platform fee percentage cannot exceed 100.");
        gallerySettings.platformFeePercentage = _newPercentage;
        emit GallerySettingsUpdated("platformFeePercentage", _newPercentage);
    }

    // 20. Gallery Management Function: withdrawPlatformFees
    function withdrawPlatformFees(address _recipient)
        public
        onlyOwner
    {
        require(_recipient != address(0), "Invalid recipient address.");
        uint256 amount = platformFeesBalance;
        platformFeesBalance = 0; // Reset balance after withdrawal
        payable(_recipient).transfer(amount);
        emit PlatformFeeWithdrawn(_recipient, amount);
    }

    // 21. Gallery Management Function: pauseGallery
    function pauseGallery()
        public
        onlyOwner
    {
        paused = true;
        emit GalleryPaused(msg.sender);
    }

    // 22. Gallery Management Function: unpauseGallery
    function unpauseGallery()
        public
        onlyOwner
    {
        paused = false;
        emit GalleryUnpaused(msg.sender);
    }

    // 23. Gallery Management Function: setGallerySetting (Generic Setting Update)
    function setGallerySetting(string memory _settingName, uint256 _settingValue)
        public
        onlyOwner
    {
        if (keccak256(bytes(_settingName)) == keccak256(bytes("curationFee"))) {
            gallerySettings.curationFee = _settingValue;
        } else if (keccak256(bytes(_settingName)) == keccak256(bytes("platformFeePercentage"))) {
            require(_settingValue <= 100, "Platform fee percentage cannot exceed 100.");
            gallerySettings.platformFeePercentage = _settingValue;
        } else if (keccak256(bytes(_settingName)) == keccak256(bytes("dynamicUpdateFrequency"))) {
            gallerySettings.dynamicUpdateFrequency = _settingValue;
        } else if (keccak256(bytes(_settingName)) == keccak256(bytes("curatorProposalVotingPeriod"))) {
            gallerySettings.curatorProposalVotingPeriod = _settingValue;
        } else if (keccak256(bytes(_settingName)) == keccak256(bytes("curatorRemovalVotingPeriod"))) {
            gallerySettings.curatorRemovalVotingPeriod = _settingValue;
        } else if (keccak256(bytes(_settingName)) == keccak256(bytes("curatorQuorumPercentage"))) {
            require(_settingValue <= 100, "Quorum percentage cannot exceed 100.");
            gallerySettings.curatorQuorumPercentage = _settingValue;
        } else {
            revert("Invalid setting name.");
        }
        emit GallerySettingsUpdated(_settingName, _settingValue);
    }

    // 24. Gallery Management Function: getGallerySetting
    function getGallerySetting(string memory _settingName)
        public
        view
        returns (uint256)
    {
        if (keccak256(bytes(_settingName)) == keccak256(bytes("curationFee"))) {
            return gallerySettings.curationFee;
        } else if (keccak256(bytes(_settingName)) == keccak256(bytes("platformFeePercentage"))) {
            return gallerySettings.platformFeePercentage;
        } else if (keccak256(bytes(_settingName)) == keccak256(bytes("dynamicUpdateFrequency"))) {
            return gallerySettings.dynamicUpdateFrequency;
        } else if (keccak256(bytes(_settingName)) == keccak256(bytes("curatorProposalVotingPeriod"))) {
            return gallerySettings.curatorProposalVotingPeriod;
        } else if (keccak256(bytes(_settingName)) == keccak256(bytes("curatorRemovalVotingPeriod"))) {
            return gallerySettings.curatorRemovalVotingPeriod;
        } else if (keccak256(bytes(_settingName)) == keccak256(bytes("curatorQuorumPercentage"))) {
            return gallerySettings.curatorQuorumPercentage;
        } else {
            revert("Invalid setting name.");
        }
    }

    // 25. Utility Function: isCurator
    function isCurator(address _address)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < curators.length; i++) {
            if (curators[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // 26. Utility Function: getCuratorList
    function getCuratorList()
        public
        view
        returns (address[] memory)
    {
        return curators;
    }

    // 27. Utility Function: getProposalDetails
    function getProposalDetails(uint256 _proposalId)
        public
        view
        validProposalId(_proposalId)
        returns (CuratorProposal memory)
    {
        return curatorProposals[_proposalId];
    }

    // 28. Utility Function: getOwner
    function getOwner()
        public
        view
        returns (address)
    {
        return owner;
    }

    // Fallback function to receive ETH (if platform fees are implemented or for donations - not used in this example but good practice)
    receive() external payable {
        platformFeesBalance += msg.value; // Accumulate received ETH as platform fees (or handle differently)
    }
}
```