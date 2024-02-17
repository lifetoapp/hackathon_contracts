// SPDX-License-Identifier: UNLICENSED

/*
 *  ██      ██ ███████ ███████ ██████   █████  ██████  ██████
 *  ██      ██ ██      ██           ██ ██   ██ ██   ██ ██   ██
 *  ██      ██ █████   █████    █████  ███████ ██████  ██████
 *  ██      ██ ██      ██      ██      ██   ██ ██      ██
 *  ███████ ██ ██      ███████ ███████ ██   ██ ██      ██
 */

pragma solidity 0.8.23;

// Imports.
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {UUPSUpgradeable} from '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {IERC1155} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import {ERC1155} from '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

// Errors.
error InvalidLeague();
error NotAnAuthorizedOperator();
error NotTheOwnerOfTheToken();
error UserAlreadyInTheLeague();
error InvalidLeagueChange();
error InvalidNftItemsAddress();

/**
 * @title The Players smart contract.
 * @author Life2App
 * @notice The Players smart contract is used to manage the players of the game.
 * @dev The Players smart contract is used to manage the players of the game.
 */
contract Players is Initializable, UUPSUpgradeable, OwnableUpgradeable {

  using EnumerableSet for EnumerableSet.AddressSet;

  /**
   * @notice The struct of the player info.
   * @param selectedObjects The array of selected objects.
   * @param currentLeague The current league of the player.
   * @param currentCoolness The current coolness of the player.
   * @param currentExperience The current experience of the player.
   * @param currentRating The current rating of the player.
   */
  struct PlayerInfo {
    mapping(uint64 => uint256) selectedObjects;
    uint256 currentLeague;
    uint256 currentCoolness;
    uint256 currentExperience;
    uint256 currentRating;
  }

  /// @notice The ID of the phone subtype.
  uint64 public constant PHONE_SUBTYPE = uint64(uint256(keccak256('PHONE_SUBTYPE')));
  /// @notice The ID of the earbuds subtype.
  uint64 public constant EARBUDS_SUBTYPE = uint64(uint256(keccak256('EARBUDS_SUBTYPE')));
  /// @notice The ID of the power bank subtype.
  uint64 public constant POWERBANK_SUBTYPE = uint64(uint256(keccak256('POWERBANK_SUBTYPE')));
  /// @notice The ID of the laptop subtype.
  uint64 public constant LAPTOP_SUBTYPE = uint64(uint256(keccak256('LAPTOP_SUBTYPE')));
  /// @notice The maximum number of leagues.
  uint256 public constant MAX_LEAGUE = 10;

  /// @notice The mapping of player info per address.
  mapping(address => PlayerInfo) public playerInfo;
  /// @notice The mapping of authorized operators.
  mapping(address => bool) public authorizedOperators;
  /// @notice The mapping of the league to the players.
  mapping(uint256 => EnumerableSet.AddressSet) private leaguePlayers;
  /// @notice The NFT smart contract.
  IERC1155 public nftItems;

  // Events.
  /// @notice The event emitted when the player's objects are updated.
  event PlayerObjectsUpdate(address indexed user, uint256 phoneTokenId, uint256 earbudsTokenId, uint256 powerbankTokenId, uint256 laptopTokenId);
  /// @notice The event emitted when the player's league is updated.
  event PlayerLeagueUpdate(address indexed user, uint256 league);
  /// @notice The event emitted when the player's rating and experience are updated.
  event PlayerRatingAndExperienceUpdate(address indexed user, uint256 rating, uint256 experience);
  /// @notice The event emitted when the authorized operator is set.
  event AuthorizedOperatorSet(address authorizedOperator, bool authorize);
  /// @notice The event emitted when the NFT items smart contract is set.
  event NftItemsSet(address nftItems);

  /**
   * @notice The modifier to check if the sender is an authorized operator.
   */
  modifier onlyAuthorizedOperator() {
    if (authorizedOperators[msg.sender] == false) revert NotAnAuthorizedOperator();
    _;
  }

  /**
   * @notice The constructor of the contract.
   * @dev This constructor is used to disable the initializers of the inherited contracts.
   */
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice The smart contract initializer.
   * @param nftItemsAddress The address of the smart contract of the NFT items.
   */
  function initialize(address nftItemsAddress) public initializer {
    __Ownable_init(msg.sender);
    nftItems = IERC1155(nftItemsAddress);
  }

  /**
   * @notice The function to update the user's selected objects.
   * @param phoneTokenId The ID of the phone token.
   * @param earbudsTokenId The ID of the earbuds token.
   * @param powerbankTokenId The ID of the power bank token.
   * @param laptopTokenId The ID of the laptop token.
   */
  function updateUserSelectedObjects(uint256 phoneTokenId, uint256 earbudsTokenId, uint256 powerbankTokenId, uint256 laptopTokenId) external {
    // Verifying ownership of each token.
    if (phoneTokenId != 0 && nftItems.balanceOf(msg.sender, phoneTokenId) == 0) revert NotTheOwnerOfTheToken();
    if (earbudsTokenId != 0 && nftItems.balanceOf(msg.sender, earbudsTokenId) == 0) revert NotTheOwnerOfTheToken();
    if (powerbankTokenId != 0 && nftItems.balanceOf(msg.sender, powerbankTokenId) == 0) revert NotTheOwnerOfTheToken();
    if (laptopTokenId != 0 && nftItems.balanceOf(msg.sender, laptopTokenId) == 0) revert NotTheOwnerOfTheToken();
    // Set the selected objects.
    playerInfo[msg.sender].selectedObjects[PHONE_SUBTYPE] = phoneTokenId;
    playerInfo[msg.sender].selectedObjects[EARBUDS_SUBTYPE] = earbudsTokenId;
    playerInfo[msg.sender].selectedObjects[POWERBANK_SUBTYPE] = powerbankTokenId;
    playerInfo[msg.sender].selectedObjects[LAPTOP_SUBTYPE] = laptopTokenId;
    // Set coolness based on the selected objects.
    // TODO: Set the coolness based on the selected objects.
    // Emit the event.
    emit PlayerObjectsUpdate(msg.sender, phoneTokenId, earbudsTokenId, powerbankTokenId, laptopTokenId);
  }

  /**
   * @notice The function updates the user's current league.
   * @param user The address of the user.
   * @param league The league number.
   */
  function updateUserCurrentLeague(address user, uint256 league) external onlyAuthorizedOperator {
    // Check if the user is already in the league.
    if (leaguePlayers[league].contains(user)) revert UserAlreadyInTheLeague();
    // Check the league validity.
    if (league >= MAX_LEAGUE) revert InvalidLeague();
    // League can be only changed by one level.
    uint256 currentLeague = playerInfo[user].currentLeague;
    if (league > currentLeague + 1 || league < currentLeague - 1) revert InvalidLeagueChange();
    // Remove the user from the current league.
    leaguePlayers[currentLeague].remove(user);
    // Add the user to the new league.
    leaguePlayers[league].add(user);
    // Update the user's current league.
    playerInfo[user].currentLeague = league;
    // Emit the event.
    emit PlayerLeagueUpdate(user, league);
  }

  /**
   * @notice The function updates the user's rating and experience.
   * @param user The address of the user.
   * @param rating The rating of the user.
   * @param experience The experience of the user.
   */
  function updateUserRatingAndExperience(address user, uint256 rating, uint256 experience) external onlyAuthorizedOperator {
    // Update the user's rating and experience.
    playerInfo[user].currentRating = rating;
    playerInfo[user].currentExperience = experience;
    // Emit the event.
    emit PlayerRatingAndExperienceUpdate(user, rating, experience);
  }

  /**
   * @notice The function to set the authorized operator.
   * @param authorizedOperator_ The address of the authorized operator.
   * @param authorize The authorization status.
   */
  function setAuthorizedOperator(address authorizedOperator_, bool authorize) external onlyOwner {
    authorizedOperators[authorizedOperator_] = authorize;
    emit AuthorizedOperatorSet(authorizedOperator_, authorize);
  }

  /**
   * @notice The function to set the NFT items smart contract.
   * @param nftItemsAddress The address of the NFT items smart contract.
   */
  function setNftItems(address nftItemsAddress) external onlyOwner {
    if (nftItemsAddress == address(0)) revert InvalidNftItemsAddress();
    nftItems = IERC1155(nftItemsAddress);
    emit NftItemsSet(nftItemsAddress);
  }

  /**
   * @notice The function returns the user-selected objects.
   * @param user The address of the user.
   * @return The user-selected objects.
   */
  function getUserSelectedObjects(address user) external view returns (uint256[4] memory) {
    return [
      playerInfo[user].selectedObjects[PHONE_SUBTYPE],
      playerInfo[user].selectedObjects[EARBUDS_SUBTYPE],
      playerInfo[user].selectedObjects[POWERBANK_SUBTYPE],
      playerInfo[user].selectedObjects[LAPTOP_SUBTYPE]
    ];
  }

  /**
   * @notice Gets all the players of the league.
   * @param league The league number.
   * @return The players of the league.
   */
  function getLeaguePlayers(uint256 league) external view returns (address[] memory) {
    return leaguePlayers[league].values();
  }

  /**
   * @notice The version of the smart contract.
   * @return The version of the smart contract.
   */
  function version() external pure returns (string memory) {
    return '1.0.0';
  }

  /**
   * @notice Handles authorization of the upgrade.
   * @dev Only the contract owner is authorized to upgrade the contract.
   */
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
