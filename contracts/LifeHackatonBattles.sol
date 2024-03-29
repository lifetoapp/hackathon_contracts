// SPDX-License-Identifier: ULINCENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./LifeHackatonPlayers.sol";
import "./interface/IERC20Mintable.sol";

contract LifeHackatonBattles is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    enum BattleStatus { COMPLETED, INITIATED, STARTED }
    enum BattleDifficulty { NORMAL, EASY, HARD }
    enum BattleAction { TOUGH, SMART, DEVIOUS }

    uint public constant PLAYER_ACTIONS_COUNT = 3;

    struct BattleData {
        BattleStatus status;
        BattleDifficulty difficulty;
        BattleAction[3] playerActions;
        uint randomSourceBlockNumber;
        uint playerCoolness;
        uint enemyCoolness;
        address enemy;
    }

    LifeHackatonPlayers public playersContract;
    IERC20Mintable public rewardToken;

    uint public rewardAmount;

    uint public smallRatingChange;
    uint public normalRatingChange;
    uint public bigRatingChange;

    // player => current/last battle
    mapping(address => BattleData) public battles;

    event BattleCompleted(bool battleWon, uint ratingChange, uint rewardAmount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address playersContract_,
        address rewardToken_,
        uint rewardAmount_,
        uint smallRatingChange_,
        uint normalRatingChange_,
        uint bigRatingChange_
    ) initializer public {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        playersContract = LifeHackatonPlayers(playersContract_);
        rewardToken = IERC20Mintable(rewardToken_);
        rewardAmount = rewardAmount_;
        smallRatingChange = smallRatingChange_;
        normalRatingChange = normalRatingChange_;
        bigRatingChange = bigRatingChange_;
    }

    function initiateBattle() external {
        address player = _msgSender();
        require(
            playersContract.isPlayerRegistered(player),
            "LifeHackatonBattles: player is not registered"
        );
        require(
            battles[player].status != BattleStatus.STARTED || isBattleExpired(player),
            "LifeHackatonBattles: invalid battle status"
        );

        playersContract.consumeEnergy(player);
        battles[player] = BattleData(
            BattleStatus.INITIATED,
            BattleDifficulty.NORMAL,
            [BattleAction.TOUGH, BattleAction.TOUGH, BattleAction.TOUGH],
            block.number + 1,
            playersContract.getPlayerCoolness(player),
            0,
            address(0)
        );
    }

    function startBattle(BattleAction[3] memory actions) external {
        address player = _msgSender();
        BattleData storage battle = battles[player];

        (address enemy, BattleDifficulty difficulty) = getEnemyForBattle(player);
        battle.enemy = enemy;
        battle.enemyCoolness = playersContract.getPlayerCoolness(enemy);
        battle.difficulty = difficulty;

        battle.playerActions = actions;
        battle.randomSourceBlockNumber = block.number + 1;
        battle.status = BattleStatus.STARTED;
    }

    function completeBattle() external {
        address player = _msgSender();
        BattleData storage battle = battles[player];
        BattleDifficulty difficulty = battle.difficulty;
        uint ratingChange;
        
        bool battleWon = isBattleWon(player);
        if (battleWon) {
            if (difficulty == BattleDifficulty.NORMAL) {
                ratingChange = normalRatingChange;
            } else if (difficulty == BattleDifficulty.EASY) {
                ratingChange = smallRatingChange;
            } else {
                ratingChange = bigRatingChange;
            }

            playersContract.increasePlayerRating(player, ratingChange);
            rewardToken.mint(player, rewardAmount);
        } else {
            if (difficulty == BattleDifficulty.NORMAL) {
                ratingChange = normalRatingChange;
            } else if (difficulty == BattleDifficulty.EASY) {
                ratingChange = bigRatingChange;
            } else {
                ratingChange = smallRatingChange;
            }

            playersContract.decreasePlayerRating(player, ratingChange);
        }

        battle.status = BattleStatus.COMPLETED;

        emit BattleCompleted(battleWon, ratingChange, rewardAmount);
    }

    // TODO: SETTERS!

    function isBattleExpired(address player) public view returns (bool) {
        uint randomSourceBlockNumber = battles[player].randomSourceBlockNumber;

        require(randomSourceBlockNumber != 0, "LifeHackatonBattles: battle not found");

        return blockhash(randomSourceBlockNumber) == 0;
    }

    function getEnemyForBattle(address player) public view returns (address, BattleDifficulty) {
        require(
            battles[player].status == BattleStatus.INITIATED && !isBattleExpired(player),
            "LifeHackatonBattles: invalid battle status"
        );

        uint enemyLeague = playersContract.getPlayerLeague(player);
        uint enemyLeaguePlayerCount = playersContract.getLeaguePlayersCount(enemyLeague);
        BattleDifficulty difficulty = BattleDifficulty.NORMAL;

        // TODO: better logic?
        if (enemyLeaguePlayerCount < 2) {
            if (enemyLeague > 0) {
                enemyLeague -= 1;
                enemyLeaguePlayerCount = playersContract.getLeaguePlayersCount(enemyLeague);

                if (enemyLeaguePlayerCount < 2) {
                    enemyLeague += 2;
                    enemyLeaguePlayerCount = playersContract.getLeaguePlayersCount(enemyLeague);
                }
            } else {
                enemyLeague += 1;
                enemyLeaguePlayerCount = playersContract.getLeaguePlayersCount(enemyLeague);
            }
        }

        return (
            getRandomEnemySafe(enemyLeague, enemyLeaguePlayerCount, player),
            difficulty
        );
    }

    function getRandomEnemySafe(
        uint enemyLeague,
        uint enemyLeaguePlayerCount,
        address player
    ) public view returns (address) {
        require(enemyLeaguePlayerCount >= 2, "LifeHackatonBattles: can't find an enemy");

        uint randomEnemyIndex = getBattleRandom(player) % enemyLeaguePlayerCount;
        address randomEnemy = playersContract.getLeaguePlayerByIndex(
            enemyLeague,
            randomEnemyIndex
        );

        if (randomEnemy == player) {
            if (randomEnemyIndex < enemyLeaguePlayerCount - 1) {
                randomEnemyIndex += 1;
            } else {
                randomEnemyIndex -= 1;
            }
            randomEnemy = playersContract.getLeaguePlayerByIndex(enemyLeague,randomEnemyIndex);
        }

        return randomEnemy;
    }

    function isBattleWon(address player) public view returns (bool) {
        BattleData storage battle = battles[player];
        require(
            battle.status != BattleStatus.INITIATED && !isBattleExpired(player),
            "LifeHackatonBattles: invalid battle status"
        );

        uint playerCoolness = battle.playerCoolness;
        uint playerBaseDamage = playerCoolness / 10;
        uint enemyCoolness = battle.enemyCoolness;
        uint enemyBaseDamage = enemyCoolness / 10;
        uint random = getBattleRandom(player);
        uint playerActionIndex = 0;

        while (true) {
            BattleAction playerAction = battle.playerActions[playerActionIndex++ % PLAYER_ACTIONS_COUNT];
            BattleAction enemyAction = getRandomEnemyAction(random);
            random = uint(keccak256(abi.encodePacked(random)));

            uint playerDamage;
            uint enemyDamage;

            if (playerAction == enemyAction) {
                playerDamage = playerBaseDamage;
                enemyDamage = enemyBaseDamage;
            } else if (
                uint(playerAction) + 1 == uint(enemyAction) ||
                (playerAction == BattleAction.DEVIOUS && enemyAction == BattleAction.TOUGH)
            ) {
                // player has an upper hand
                playerDamage = playerBaseDamage * 2;
                enemyDamage = enemyBaseDamage / 2;
            } else {
                // enemy has an upper hand
                playerDamage = playerBaseDamage / 2;
                enemyDamage = enemyBaseDamage * 2;
            }

            if (enemyCoolness > playerDamage) {
                unchecked { enemyCoolness -= playerDamage; }
            } else {
                return true;
            }

            if (playerCoolness > enemyDamage) {
                unchecked { playerCoolness -= enemyDamage; }
            } else {
                return false;
            }
        }
    }

    function getRandomEnemyAction(uint random) public pure returns (BattleAction) {
        uint randomActionIndex = random % 3;

        // TODO: better way?
        if (randomActionIndex == 0) {
            return BattleAction.TOUGH;
        } else if (randomActionIndex == 1) {
            return BattleAction.SMART;
        } else {
            return BattleAction.DEVIOUS;
        }
    }

    function getEnemyActionQueue(address player) public view returns (BattleAction[] memory) {
        BattleStatus status = battles[player].status;
        require(
            (status == BattleStatus.STARTED || status == BattleStatus.COMPLETED) &&
                !isBattleExpired(player),
            "LifeHackatonBattles: invalid battle status"
        );

        uint returnSize = 20;
        uint random = getBattleRandom(player);
        BattleAction[] memory actions = new BattleAction[](returnSize);

        for (uint i = 0; i < returnSize; i++) {
            actions[i] = getRandomEnemyAction(random);
            random = uint(keccak256(abi.encodePacked(random)));
        }
        return actions;
    }

    function getBattleRandom(address player) public view returns (uint) {
        uint randomSeed = uint(blockhash(battles[player].randomSourceBlockNumber));

        return uint(keccak256(abi.encodePacked(randomSeed, player)));
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner()
        override
    {}
}