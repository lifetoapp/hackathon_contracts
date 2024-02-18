// SPDX-License-Identifier: ULINCENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Players.sol";

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

    Players public playersContract;

    uint public easyRatingStake;
    uint public normalRatingStake;
    uint public hardRatingStake;

    // player => current/last battle
    mapping(address => BattleData) battles;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address playersContract_,
        uint easyRatingStake_,
        uint normalRatingStake_,
        uint hardRatingStake_
    ) initializer public {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        playersContract = Players(playersContract_);
        easyRatingStake_ = easyRatingStake;
        normalRatingStake = normalRatingStake_;
        hardRatingStake = hardRatingStake_;
    }

    function initiateBattle() external {
        address player = _msgSender();
        require(
            battles[player].status == BattleStatus.COMPLETED || 
            (battles[player].status != BattleStatus.STARTED && isBattleExpired(player)),
            "LifeHackatonBattles: invalid battle status"
        );

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

    // TODO: SETTERS!
    // function setURI(string memory newURI) external onlyOwner() {
    //     _setURI(newURI);
    // }

    function isBattleExpired(address player) public view returns (bool) {
        uint randomSourceBlockNumber = battles[player].randomSourceBlockNumber;

        require(randomSourceBlockNumber != 0, "LifeHackatonBattles: battle not found");

        return blockhash(randomSourceBlockNumber) == 0;
    }

    function getEnemyForBattle(address player) public view returns (address, BattleDifficulty) {
        require(
            battles[player].status == BattleStatus.INITIATED || !isBattleExpired(player),
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
            battle.status == BattleStatus.STARTED || !isBattleExpired(player),
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