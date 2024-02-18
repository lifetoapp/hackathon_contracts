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
import {LifeHackatonItems} from './LifeHackatonItems.sol';

// Errors.
error InvalidLeague();
error NotAnAuthorizedOperator();
error NotTheOwnerOfTheToken();
error PlayerAlreadyInTheLeague();
error InvalidLeagueChange();
error InvalidNftItemsAddress();
error InvalidPhoneTokenType();
error InvalidEarbudsTokenType();
error InvalidPowerbankTokenType();
error InvalidLaptopTokenType();

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
   * @param rewardLootBoxAmount The number of loot boxes.
   */
  struct League {
    string name; // TODO: do we need the name in contracts?
    uint256 minRating;
    uint256 maxRating;
    uint256 rewardLootBoxAmount;
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
  /// @notice Received reward lootboxes per player per league.
  mapping(address => mapping(uint256 => bool)) public hasReceivedReward;

  // Events.
  /// @notice The event emitted when the player's objects are updated.
  event PlayerObjectsUpdate(address indexed player, uint256 phoneTokenId, uint256 earbudsTokenId, uint256 powerbankTokenId, uint256 laptopTokenId);
  /// @notice The event emitted when the player's league is updated.
  event PlayerLeagueUpdate(address indexed player, uint256 league);
  /// @notice The event emitted when the player's rating is updated.
  event PlayerRatingUpdate(address indexed player, uint256 rating);
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
   * @notice The function to update the player's selected objects.
   * @param phoneTokenId The ID of the phone token.
   * @param earbudsTokenId The ID of the earbuds token.
   * @param powerbankTokenId The ID of the power bank token.
   * @param laptopTokenId The ID of the laptop token.
   */
  function updatePlayerSelectedObjects(uint256 phoneTokenId, uint256 earbudsTokenId, uint256 powerbankTokenId, uint256 laptopTokenId) external {
    bool hasPhone = phoneTokenId != 0;
    bool hasEarbuds = earbudsTokenId != 0;
    bool hasPowerbank = powerbankTokenId != 0;
    bool hasLaptop = laptopTokenId != 0;
    // Verifying ownership of each token.
    if (hasPhone && nftItems.balanceOf(msg.sender, phoneTokenId) == 0) revert NotTheOwnerOfTheToken();
    if (hasEarbuds && nftItems.balanceOf(msg.sender, earbudsTokenId) == 0) revert NotTheOwnerOfTheToken();
    if (hasPowerbank && nftItems.balanceOf(msg.sender, powerbankTokenId) == 0) revert NotTheOwnerOfTheToken();
    if (hasLaptop && nftItems.balanceOf(msg.sender, laptopTokenId) == 0) revert NotTheOwnerOfTheToken();
    // Check for validity of the objects.
    if (hasPhone && nftItems.getItemSubtype(phoneTokenId) != PHONE_SUBTYPE) revert InvalidPhoneTokenType();
    if (hasEarbuds && nftItems.getItemSubtype(earbudsTokenId) != EARBUDS_SUBTYPE) revert InvalidEarbudsTokenType();
    if (hasPowerbank && nftItems.getItemSubtype(powerbankTokenId) != POWERBANK_SUBTYPE) revert InvalidPowerbankTokenType();
    if (hasLaptop && nftItems.getItemSubtype(laptopTokenId) != LAPTOP_SUBTYPE) revert InvalidLaptopTokenType();
    // Set the selected objects.
    playerInfo[msg.sender].selectedObjects[PHONE_SUBTYPE] = phoneTokenId;
    playerInfo[msg.sender].selectedObjects[EARBUDS_SUBTYPE] = earbudsTokenId;
    playerInfo[msg.sender].selectedObjects[POWERBANK_SUBTYPE] = powerbankTokenId;
    playerInfo[msg.sender].selectedObjects[LAPTOP_SUBTYPE] = laptopTokenId;
    // Emit the event.
    emit PlayerObjectsUpdate(msg.sender, phoneTokenId, earbudsTokenId, powerbankTokenId, laptopTokenId);
  }

  /**
   * @notice The function increases the player's rating.
   * @param player The address of the player.
   * @param by The rating to increase by.
   */
  function increasePlayerRating(address player, uint256 by) external onlyAuthorizedOperator {
    uint256 rating = playerInfo[player].currentRating + by;
    playerInfo[player].currentRating = rating;
    _updateLeague(player);
    emit PlayerRatingUpdate(player, rating);
  }

  /**
   * @notice The function decreases the player's rating.
   * @param player The address of the player.
   * @param by The rating to decrease by.
   */
  function decreasePlayerRating(address player, uint256 by) external onlyAuthorizedOperator {
    uint256 rating;

    if (playerInfo[player].currentRating > by) {
      rating = playerInfo[player].currentRating - by;
    } else {
      rating = 0;
    }

    playerInfo[player].currentRating = rating;
    _updateLeague(player);
    emit PlayerRatingUpdate(player, rating);
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
   * @notice The function returns the player-selected objects.
   * @param player The address of the player.
   * @return The player-selected objects.
   */
  function getPlayerSelectedObjects(address player) public view returns (uint256[4] memory) {
    uint256[] memory tokenIds = new uint256[](4);
    tokenIds[0] = playerInfo[player].selectedObjects[PHONE_SUBTYPE];
    tokenIds[1] = playerInfo[player].selectedObjects[EARBUDS_SUBTYPE];
    tokenIds[2] = playerInfo[player].selectedObjects[POWERBANK_SUBTYPE];
    tokenIds[3] = playerInfo[player].selectedObjects[LAPTOP_SUBTYPE];

    address[] memory playerAddresses = new address[](4);
    playerAddresses[0] = player;
    playerAddresses[1] = player;
    playerAddresses[2] = player;
    playerAddresses[3] = player;

    uint256[] memory balances = nftItems.balanceOfBatch(playerAddresses, tokenIds);

    return [
      balances[0] > 0 ? tokenIds[0] : 0, // Phone
      balances[1] > 0 ? tokenIds[1] : 0, // Earbuds
      balances[2] > 0 ? tokenIds[2] : 0, // Powerbank
      balances[3] > 0 ? tokenIds[3] : 0 // Laptop
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
   * @notice The function returns the number of players in the league.
   * @param league The league number.
   * @return The number of players in the league.
   */
  function getLeaguePlayersCount(uint256 league) external view returns (uint256) {
    return leaguePlayers[league].length();
  }

  /**
   * @notice The function returns the player by index in the league.
   * @param league The league number.
   * @param index The index of the player in the league.
   * @return The player in the league.
   */
  function getLeaguePlayerByIndex(uint256 league, uint256 index) external view returns (address) {
    return leaguePlayers[league].at(index);
  }

  function getPlayerLeague(address player) external view returns (uint) {
    return playerInfo[player].currentLeague;
  }

  /**
   * @notice The function returns the coolness of the player.
   * @param player The address of the player.
   * @return The coolness of the player.
   */
  function getPlayerCoolness(address player) external view returns (uint256) {
    uint256 coolness;
    uint256[4] memory selectedObjects = getPlayerSelectedObjects(player);

    for (uint256 i; i < selectedObjects.length; i++) {
      if (selectedObjects[i] != 0) {
        coolness += nftItems.getEquipmentCoolness(selectedObjects[i]);
      }
    }

    return coolness;
  }

  /**
   * @notice The version of the smart contract.
   * @return The version of the smart contract.
   */
  function version() external pure returns (string memory) {
    return '1.0.0';
  }

  function _updateLeague(address player) internal {
    uint256 playerRating = playerInfo[player].currentRating;
    uint256 playerLeague = playerInfo[player].currentLeague;

    if (playerLeague == 0 && leaguePlayers[0].contains(player) == false) {
      leaguePlayers[0].add(player);
      playerInfo[player].currentLeague = 0;
    }

    // TODO: make function more effective, no need to check leagues one by one
    for (uint256 i; i < leagues.length; i++) {
      if (playerRating >= leagues[i].minRating && playerRating <= leagues[i].maxRating) {
        if (playerLeague != i) {
          leaguePlayers[playerLeague].remove(player);
          leaguePlayers[i].add(player);
          playerInfo[player].currentLeague = i;
          uint256 rewardLootBoxAmount = leagues[i].rewardLootBoxAmount;

          if (!hasReceivedReward[player][i] && rewardLootBoxAmount > 0) {
            hasReceivedReward[player][i] = true;
            _rewardLootBoxes(player, rewardLootBoxAmount);
          }
        }
        break;
      }
    }
  }

  function _rewardLootBoxes(address player, uint256 amount) internal {
    nftItems.giveRegularLootboxes(player, amount);
  }

  /**
   * @notice Handles authorization of the upgrade.
   * @dev Only the contract owner is authorized to upgrade the contract.
   */
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
