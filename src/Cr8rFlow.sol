// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Cr8Flow - Programmable Royalty Engine for Creators
/// @notice Enables creators to mint NFT content with automated royalty splits, real-time payouts, and tiered fan access
/// @dev Built for Mantle Cookathon 3, leveraging Mantle's low-cost, high-speed L2 infrastructure
contract Cr8rFlow is ERC721, Ownable {
    uint256 private _tokenIdCounter;
    uint256 public nextProjectId;

    /// @notice Struct for royalty splits
    struct RoyaltySplit {
        address recipient; // Wallet receiving the split
        uint256 percentage; // Basis points (e.g., 1000 = 10.00%)
    }

    /// @notice Struct for tiered fan access perks
    struct Tier {
        string perkDescription; // e.g., "Bonus Track Access"
        uint256 minHoldings; // Minimum NFTs to hold for access
        bool isActive; // Whether the perk is active
    }

    /// @notice Struct for projects grouping related NFTs
    struct Project {
        string name; // Project name (e.g., "Album X")
        address owner; // Project creator
        uint256[] tokenIds; // Array of NFT token IDs in this project
        bool exists; // Flag to confirm project existence
    }

    // Mappings
    mapping(uint256 => Project) public projects; // Project ID to Project details
    mapping(uint256 => RoyaltySplit[]) public tokenRoyaltySplits; // Token ID to royalty splits
    mapping(uint256 => Tier[]) public tokenTiers; // Token ID to tiered perks
    mapping(address => uint256) public fanEngagement; // Fan address to engagement score
    mapping(uint256 => string) private _tokenURIs; // Token ID to metadata URI

    // Events for all state changes
    event ProjectCreated(uint256 indexed projectId, string name, address indexed owner);
    event ContentMinted(
        uint256 indexed projectId, uint256 indexed tokenId, address indexed creator, string metadataURI
    );
    event FundsReceived(uint256 indexed tokenId, address indexed sender, uint256 amount);
    event RevenueDistributed(uint256 indexed tokenId, address indexed recipient, uint256 amount);
    event PerkUnlocked(address indexed fan, uint256 indexed tokenId, string perk);
    event EngagementTracked(address indexed fan, uint256 newEngagementScore);

    /// @notice Constructor initializing ERC721 with name "Cr8Flow" and symbol "CR8"
    constructor() ERC721("Cr8Flow", "CR8") Ownable(msg.sender) {}

    /// @notice Create a new project to group NFTs
    /// @param name Project name (e.g., "Album X")
    /// @param contributorWallets Array of contributor addresses
    /// @param percentages Array of royalty percentages (basis points)
    /// @return projectId The ID of the created project
    function createProject(string memory name, address[] memory contributorWallets, uint256[] memory percentages)
        public
        returns (uint256)
    {
        require(contributorWallets.length == percentages.length, "Mismatched input lengths");
        RoyaltySplit[] memory splits = new RoyaltySplit[](contributorWallets.length);
        for (uint256 i = 0; i < contributorWallets.length; i++) {
            require(contributorWallets[i] != address(0), "Invalid contributor address");
            splits[i] = RoyaltySplit(contributorWallets[i], percentages[i]);
        }
        require(_validateSplits(splits), "Invalid royalty splits");

        uint256 projectId = nextProjectId;
        Project storage p = projects[projectId];
        p.name = name;
        p.owner = msg.sender;
        p.exists = true;

        emit ProjectCreated(projectId, name, msg.sender);
        nextProjectId++;
        return projectId;
    }

    /// @notice Mint a new NFT content drop under a project
    /// @param projectId The project to associate the NFT with
    /// @param metadataURI IPFS or other URI for content metadata
    /// @param contributorWallets Array of contributor addresses
    /// @param percentages Array of royalty percentages (basis points)
    /// @param tiers Array of tiered perks for fans
    /// @return tokenId The ID of the minted NFT
    function mintContent(
        uint256 projectId,
        string memory metadataURI,
        address[] memory contributorWallets,
        uint256[] memory percentages,
        Tier[] memory tiers
    ) public returns (uint256) {
        require(projects[projectId].exists, "Invalid project");
        require(projects[projectId].owner == msg.sender, "Not project owner");
        require(contributorWallets.length == percentages.length, "Mismatched input lengths");
        require(bytes(metadataURI).length > 0, "Invalid metadata URI");

        RoyaltySplit[] memory splits = new RoyaltySplit[](contributorWallets.length);
        for (uint256 i = 0; i < contributorWallets.length; i++) {
            require(contributorWallets[i] != address(0), "Invalid contributor address");
            splits[i] = RoyaltySplit(contributorWallets[i], percentages[i]);
        }
        require(_validateSplits(splits), "Invalid royalty splits");

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, metadataURI);

        projects[projectId].tokenIds.push(tokenId);
        for (uint256 i = 0; i < splits.length; i++) {
            tokenRoyaltySplits[tokenId].push(splits[i]);
        }
        for (uint256 i = 0; i < tiers.length; i++) {
            require(bytes(tiers[i].perkDescription).length > 0, "Invalid perk description");
            tokenTiers[tokenId].push(tiers[i]);
        }

        emit ContentMinted(projectId, tokenId, msg.sender, metadataURI);
        return tokenId;
    }

    /// @notice Distribute revenue for a specific NFT
    /// @param tokenId The NFT token ID
    function distributeRevenue(uint256 tokenId) public payable onlyTokenOwner(tokenId) {
        require(msg.value > 0, "No funds sent");
        require(_ownerOf(tokenId) != address(0), "Token does not exist");

        RoyaltySplit[] memory splits = tokenRoyaltySplits[tokenId];
        require(splits.length > 0, "No royalty splits defined");

        emit FundsReceived(tokenId, msg.sender, msg.value);

        for (uint256 i = 0; i < splits.length; i++) {
            uint256 amount = (msg.value * splits[i].percentage) / 10000;
            require(amount > 0, "Calculated amount is zero");
            (bool sent,) = splits[i].recipient.call{value: amount}("");
            require(sent, "Failed to send Ether");
            emit RevenueDistributed(tokenId, splits[i].recipient, amount);
        }
    }

    /// @notice Unlock a perk for a fan based on NFT holdings
    /// @param tokenId The NFT token ID
    /// @param tierIndex The index of the tier to unlock
    function unlockPerk(uint256 tokenId, uint256 tierIndex) public {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        require(tierIndex < tokenTiers[tokenId].length, "Invalid tier index");
        Tier memory tier = tokenTiers[tokenId][tierIndex];
        require(tier.isActive, "Perk is not active");

        uint256 fanBalance = balanceOf(msg.sender);
        require(fanBalance >= tier.minHoldings, "Insufficient NFT holdings");

        emit PerkUnlocked(msg.sender, tokenId, tier.perkDescription);
    }

    /// @notice Track fan engagement (e.g., interactions with content)
    /// @param fan The fan's address
    function trackEngagement(address fan) public onlyOwner {
        require(fan != address(0), "Invalid fan address");
        fanEngagement[fan] += 1;
        emit EngagementTracked(fan, fanEngagement[fan]);
    }

    /// @notice Validate royalty splits sum to 100% (10,000 basis points)
    /// @param splits Array of royalty splits
    /// @return bool True if valid
    function _validateSplits(RoyaltySplit[] memory splits) internal pure returns (bool) {
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < splits.length; i++) {
            totalPercentage += splits[i].percentage;
        }
        return totalPercentage == 10000; // 100.00%
    }

    /// @notice Set token URI for metadata
    /// @param tokenId The NFT token ID
    /// @param _uri The metadata URI
    function _setTokenURI(uint256 tokenId, string memory _uri) internal {
        _tokenURIs[tokenId] = _uri;
    }

    /// @notice Get token URI for metadata
    /// @param tokenId The NFT token ID
    /// @return The metadata URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return _tokenURIs[tokenId];
    }

    /// @notice Modifier to restrict actions to the token owner
    /// @param tokenId The NFT token ID
    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        _;
    }

    /// @notice Get project name by ID
    /// @param projectId The project ID
    /// @return The project name
    function getProjectName(uint256 projectId) public view returns (string memory) {
        return projects[projectId].name;
    }

    /// @notice Get project owner by ID
    /// @param projectId The project ID
    /// @return The project owner
    function getProjectOwner(uint256 projectId) public view returns (address) {
        return projects[projectId].owner;
    }

    /// @notice Get project token IDs by ID
    /// @param projectId The project ID
    /// @return The array of token IDs
    function getProjectTokenIds(uint256 projectId) public view returns (uint256[] memory) {
        return projects[projectId].tokenIds;
    }

    /// @notice Check if a project exists
    /// @param projectId The project ID
    /// @return True if the project exists
    function getProjectExists(uint256 projectId) public view returns (bool) {
        return projects[projectId].exists;
    }

    /// @notice Get the number of royalty splits for a token
    /// @param tokenId The NFT token ID
    /// @return The length of the royalty splits array
    function getTokenRoyaltySplitsLength(uint256 tokenId) public view returns (uint256) {
        return tokenRoyaltySplits[tokenId].length;
    }

    /// @notice Get the number of tiers for a token
    /// @param tokenId The NFT token ID
    /// @return The length of the tiers array
    function getTokenTiersLength(uint256 tokenId) public view returns (uint256) {
        return tokenTiers[tokenId].length;
    }

    /// @notice Fallback function to receive Ether
    receive() external payable {
        revert("Use distributeRevenue to send funds");
    }
}
