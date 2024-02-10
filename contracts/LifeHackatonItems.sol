// // SPDX-License-Identifier: ULINCENSED
// pragma solidity ^0.8.19;

// import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// contract UjamaaERC1155 is
//     Initializable,
//     AccessControlUpgradeable,
//     PausableUpgradeable,
//     ERC1155BurnableUpgradeable,
//     ERC1155FanTokensUpgradeable,
//     TokenBasedERC20RoyaltiesUpgradeable,
//     UUPSUpgradeable
// {
//     using SafeERC20Upgradeable for IERC20Upgradeable;

//     bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
//     bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
//     bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
//     bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
//     bytes32 public constant AUCTION_ROLE = keccak256("AUCTION_ROLE");

//     uint256 public constant DEFAULT_ROYALTY_RATE = 400;
//     uint256 public constant MAX_ROYALTY_RATE = 5000;

//     uint256 private constant NEW_ARTIST = type(uint64).max;

//     mapping (uint64 => uint256) public artistRoyaltyRates;
//     mapping (address => mapping(uint256 => bool)) public artworkLiked;

//     event ArtistRoyaltyRateSet(uint64 artistId, uint256 royaltyRate);

//     /// @custom:oz-upgrades-unsafe-allow constructor
//     constructor() initializer {}

//     function initialize(
//         string memory metadataUri
//     )
//         initializer
//         public
//     {
//         __ERC1155FanToken_init(metadataUri);
//         __TokenBasedERC20Royalties_init();
//         __AccessControl_init();
//         __Pausable_init();
//         __ERC1155Burnable_init();
//         __UUPSUpgradeable_init();

//         _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
//         _grantRole(URI_SETTER_ROLE, msg.sender);
//         _grantRole(PAUSER_ROLE, msg.sender);
//         _grantRole(MINTER_ROLE, msg.sender);
//         _grantRole(UPGRADER_ROLE, msg.sender);
//     }

//     function setArtistRoyaltyRate(uint64 artistId, uint256 newRate) external {
//         require(
//             this.balanceOf(_msgSender(), getArtistTokenId(artistId)) > 0,
//             "UjamaaERC1155: caller must own artist token"
//         );
//         require(newRate >= DEFAULT_ROYALTY_RATE, "UjamaaERC1155: new rate is too high");
//         require(newRate <= MAX_ROYALTY_RATE, "UjamaaERC1155: new rate is too high");

//         uint256 rateToSet = newRate;
//         if (newRate == DEFAULT_ROYALTY_RATE) {
//             rateToSet = 0;
//         }
//         artistRoyaltyRates[artistId] = rateToSet;

//         emit ArtistRoyaltyRateSet(artistId, newRate);
//     }

//     function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
//         _setURI(newuri);
//     }

//     function pause() public onlyRole(PAUSER_ROLE) {
//         _pause();
//     }

//     function unpause() public onlyRole(PAUSER_ROLE) {
//         _unpause();
//     }

//     function newArtist() external onlyRole(MINTER_ROLE) {
//         _newArtist();
//     }

//     function mintArtistToken(
//         uint64 artistId,
//         address artistWallet
//     )
//         external
//         onlyRole(MINTER_ROLE)
//     {
//         if (artistId == NEW_ARTIST) {
//             artistId = _newArtist();
//         }

//         _mintArtistToken(artistId, artistWallet);
//     }

//     function mintArtworkToken(uint64 artistId, address to) external onlyRole(MINTER_ROLE) {
//         if (artistId == NEW_ARTIST) {
//             artistId = _newArtist();
//         }

//         _mintArtworkToken(artistId, to);
//     }

//     function mintArtistFanTokens(
//         uint64 artistId,
//         address to,
//         uint256 amount
//     )
//         external
//         onlyRole(MINTER_ROLE)
//     {
//         _mintArtistFanTokens(artistId, to, amount);
//     }

//     //TODO check logic for likes/unlikes
//     function likeFor(uint256 id, address account) external onlyRole(MINTER_ROLE) {
//         require(isArtworkToken(id), "UjamaaERC1155: invalid token id");
//         require(!artworkLiked[account][id], "UjamaaERC1155: artwork already liked by account");

//         artworkLiked[account][id] = true;

//         _mintArtworkFanToken(_getArtistId(id), _getArtworkId(id), account);
//     }

//     //TODO check logic for likes/unlikes
//     function unlike(
//         uint256 artworkFanTokenId,
//         address account
//     )
//         external
//         onlyRole(MINTER_ROLE)
//     {
//         require(isArtworkFanToken(artworkFanTokenId), "UjamaaERC1155: invalid fan token id");

//         uint64 artistId = _getArtistId(artworkFanTokenId);
//         uint64 artworkId = _getArtworkId(artworkFanTokenId);
//         uint256 artworkTokenId = getArtworkTokenId(artistId, artworkId);

//         require(
//             artworkLiked[account][artworkTokenId],
//             "UjamaaERC1155: artwork not liked by account"
//         );

//         artworkLiked[account][artworkTokenId] = false;

//         _burn(account, artworkFanTokenId, 1);
//     }

//     function convertFanToken(uint256 id) external {
//         _convertFanToken(id, _msgSender());
//     }

//     function convertFanTokenBatch(uint256[] memory ids) external {
//         _convertFanTokenBatch(ids, _msgSender());
//     }

//     function registerRoyaltiesFor(
//         uint256 id,
//         address currency,
//         uint256 amount
//     )
//         external
//         onlyRole(AUCTION_ROLE)
//     {
//         _registerRoyaltiesFor(id, currency, amount);
//     }

//     function getRoyaltyTokenId(uint256 id) public view virtual override returns (uint256) {
//         if (isArtworkFanToken(id)) {
//             return getArtworkTokenId(_getArtistId(id), _getArtworkId(id));
//         } else if (isArtworkToken(id)) {
//             return getArtistTokenId(_getArtistId(id));
//         } else {
//             revert("UjamaaERC1155: no royalty token for this id");
//         }
//     }

//     function getRoyaltyRateFor(uint256 id, address) external view returns (uint256) {
//         if (isArtworkFanToken(id)) {
//             return DEFAULT_ROYALTY_RATE;
//         } else if (isArtworkToken(id)) {
//             uint artistRoyaltyRate = artistRoyaltyRates[_getArtistId(id)];
            
//             if (artistRoyaltyRate == 0) {
//                 return DEFAULT_ROYALTY_RATE;
//             } else {
//                 return artistRoyaltyRate;
//             }
//         } else {
//             return 0;
//         }
//     }

//     function getArtistId(uint256 id) external pure returns (uint64) {
//         return _getArtistId(id);
//     }

//     function getArtworkId(uint256 id) external pure returns (uint64) {
//         require(
//             isArtworkToken(id) || isArtworkFanToken(id),
//             "UjamaaERC1155: token does not have artwork ID"
//         );
        
//         return _getArtworkId(id);
//     }

//     function getFanId(uint256 id) external pure returns (uint64) {
//         require(
//             isArtworkFanToken(id),
//             "UjamaaERC1155: token does not have fan ID"
//         );
        
//         return _getFanId(id);
//     }

//     function _beforeTokenTransfer(
//         address operator,
//         address from,
//         address to,
//         uint256[] memory ids,
//         uint256[] memory amounts,
//         bytes memory data
//     )
//         internal
//         whenNotPaused
//         override
//     {
//         super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
//     }

//     function _authorizeUpgrade(address newImplementation)
//         internal
//         onlyRole(UPGRADER_ROLE)
//         override
//     {}

//     // The following functions are overrides required by Solidity.

//     function supportsInterface(bytes4 interfaceId)
//         public
//         view
//         override(ERC1155Upgradeable, AccessControlUpgradeable)
//         returns (bool)
//     {
//         return super.supportsInterface(interfaceId);
//     }
// }
