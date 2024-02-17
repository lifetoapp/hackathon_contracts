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

// Interfaces.
interface LifeHackatonItems is IERC1155 {
  function getEquipmentCoolness(uint256 item) external pure returns (uint256);
}

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
   * @param currentRating The current rating of the player.
   */
  struct PlayerInfo {
    mapping(uint64 => uint256) selectedObjects;
    uint256 currentLeague;
    uint256 currentRating;
  }

  /**
   * @notice The struct of the league.
   * @param name The name of the league.
   * @param minRating The minimum rating of the league.
   * @param maxRating The maximum rating of the league.
   * @param lootBoxes The number of loot boxes.
   */
  struct League {
    string name;
    uint256 minRating;
    uint256 maxRating;
    uint256 lootBoxes;
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
  uint256 public constant MAX_LEAGUE = 9;

  /// @notice The mapping of player info per address.
  mapping(address => PlayerInfo) public playerInfo;
  /// @notice The mapping of authorized operators.
  mapping(address => bool) public authorizedOperators;
  /// @notice The mapping of the league to the players.
  mapping(uint256 => EnumerableSet.AddressSet) private leaguePlayers;
  /// @notice The NFT smart contract.
  LifeHackatonItems public nftItems;
  /// @notice The array of leagues.
  League[MAX_LEAGUE] public leagues;
  /// @notice Received lootboxes per user per league.
  mapping(address => mapping(uint256 => bool)) public hasReceivedLootbox;

  // Events.
  /// @notice The event emitted when the player's objects are updated.
  event PlayerObjectsUpdate(address indexed user, uint256 phoneTokenId, uint256 earbudsTokenId, uint256 powerbankTokenId, uint256 laptopTokenId);
  /// @notice The event emitted when the player's league is updated.
  event PlayerLeagueUpdate(address indexed user, uint256 league);
  /// @notice The event emitted when the player's rating is updated.
  event PlayerRatingUpdate(address indexed user, uint256 rating);
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
    nftItems = LifeHackatonItems(nftItemsAddress);
    leagues[0] = League('Training', 0, 99, 0);
    leagues[1] = League('Iron', 100, 249, 1);
    leagues[2] = League('Bronze', 250, 699, 2);
    leagues[3] = League('Silver', 700, 1299, 3);
    leagues[4] = League('Gold', 1300, 1899, 4);
    leagues[5] = League('Platinum', 1900, 2499, 5);
    leagues[6] = League('Diamond', 2500, 3099, 6);
    leagues[7] = League('Master', 3100, 3699, 7);
    leagues[8] = League('Elite', 3700, type(uint256).max, 10); // max rating for Elite
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
   * @notice The function increases the user's rating.
   * @param user The address of the user.
   * @param by The rating to increase by.
   */
  function increaseUserRating(address user, uint256 by) external onlyAuthorizedOperator {
    uint256 rating = playerInfo[user].currentRating + by;
    playerInfo[user].currentRating = rating;
    _updateLeague(user);
    emit PlayerRatingUpdate(user, rating);
  }

  /**
   * @notice The function decreases the user's rating.
   * @param user The address of the user.
   * @param by The rating to decrease by.
   */
  function decreaseUserRating(address user, uint256 by) external onlyAuthorizedOperator {
    uint256 rating;

    if (playerInfo[user].currentRating > by) {
      rating = playerInfo[user].currentRating - by;
    } else {
      rating = 0;
    }

    playerInfo[user].currentRating = rating;
    _updateLeague(user);
    emit PlayerRatingUpdate(user, rating);
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
    nftItems = LifeHackatonItems(nftItemsAddress);
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
   * @notice The function returns the coolness of the user.
   * @param user The address of the user.
   * @return The coolness of the user.
   */
  function getUserCoolness(address user) external view returns (uint256) {
    return
      nftItems.getEquipmentCoolness(playerInfo[user].selectedObjects[PHONE_SUBTYPE]) +
      nftItems.getEquipmentCoolness(playerInfo[user].selectedObjects[EARBUDS_SUBTYPE]) +
      nftItems.getEquipmentCoolness(playerInfo[user].selectedObjects[POWERBANK_SUBTYPE]) +
      nftItems.getEquipmentCoolness(playerInfo[user].selectedObjects[LAPTOP_SUBTYPE]);
  }

  /**
   * @notice The function returns the number of users in the league.
   * @param league The league number.
   * @return The number of users in the league.
   */
  function getLeaguePlayersCount(uint256 league) external view returns (uint256) {
    return leaguePlayers[league].length();
  }

  /**
   * @notice The function returns the user by index in the league.
   * @param league The league number.
   * @param index The index of the user in the league.
   * @return The user in the league.
   */
  function getLeaguePlayerByIndex(uint256 league, uint256 index) external view returns (address) {
    return leaguePlayers[league].at(index);
  }

  /**
   * @notice The version of the smart contract.
   * @return The version of the smart contract.
   */
  function version() external pure returns (string memory) {
    return '1.0.0';
  }

  function _updateLeague(address user) internal {
    uint256 userRating = playerInfo[user].currentRating;
    uint256 userLeague = playerInfo[user].currentLeague;

    for (uint i = 0; i < leagues.length; i++) {
      if (userRating >= leagues[i].minRating && userRating <= leagues[i].maxRating) {
        if (userLeague != i) {
          leaguePlayers[userLeague].remove(user);
          leaguePlayers[i].add(user);
          playerInfo[user].currentLeague = i;
          uint256 lootBoxes = leagues[i].lootBoxes;

          if (!hasReceivedLootbox[user][i] && lootBoxes > 0) {
            hasReceivedLootbox[user][i] = true;
            _rewardLootBoxes(user, lootBoxes);
          }
        }
        break;
      }
    }
  }

  function _rewardLootBoxes(address user, uint256 lootBoxes) internal {
    // TODO: Reward loot boxes to the user.
  }

  /**
   * @notice Handles authorization of the upgrade.
   * @dev Only the contract owner is authorized to upgrade the contract.
   */
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
