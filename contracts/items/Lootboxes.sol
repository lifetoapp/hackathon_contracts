// SPDX-License-Identifier: ULINCENSED
pragma solidity ^0.8.19;

import "./ItemBase.sol";
import "./Equipment.sol";
import "./EquipmentParts.sol";

abstract contract LootboxBase is ItemBase {

    uint64 public constant LOOTBOX_TYPE = uint64(uint256(keccak256("LOOTBOX_TYPE")));

    // user => lootbox => block number
    mapping(address => mapping(uint256 => uint256)) public lootboxOpenedBlocks;
    mapping(address => mapping(uint256 => uint256)) public nonces;

    function isLootbox(uint item) public pure returns (bool) {
        return getItemType(item) == LOOTBOX_TYPE;
    }

    function isOpenedLootboxExpired(address owner, uint lootbox) public view returns (bool) {
        uint lootboxOpenedBlock = lootboxOpenedBlocks[owner][lootbox];

        require(lootboxOpenedBlock != 0, "Lootboxes: no opened lootbox");

        return blockhash(lootboxOpenedBlock) == 0;
    }

    function getOpenedLootboxRandom(address owner, uint lootbox)
        public
        view
        returns (uint)
    {
        uint randomSeed;

        if (isOpenedLootboxExpired(owner, lootbox)) {
            randomSeed = block.prevrandao;
        } else {
            randomSeed = uint(blockhash(lootboxOpenedBlocks[owner][lootbox]));
        }

        return uint(keccak256(abi.encodePacked(randomSeed, owner, nonces[owner][lootbox])));
    }

    function _mintLootbox(
        address to,
        uint64 subType,
        uint64 itemId
    ) internal {
        _mintItem(to, LOOTBOX_TYPE, subType, itemId, 0);
    }

    function _openLootbox(address owner, uint lootbox) internal {
        require(isLootbox(lootbox), "Lootboxes: not a lootbox");
        require(balanceOf(owner, lootbox) > 0, "Lootboxes: zero lootboxes owned");
        require(lootboxOpenedBlocks[owner][lootbox] == 0, "Lootboxes: unclaimed reward pending");

        _burn(owner, lootbox, 1);
        lootboxOpenedBlocks[owner][lootbox] = block.number;
        nonces[owner][lootbox] += 1;
    }

    function _claimLootboxReward(address owner, uint lootbox) internal virtual;

    function _finalizeLootboxRewardClaim(address owner, uint lootbox) internal {
        lootboxOpenedBlocks[owner][lootbox] = 0;
    }
}

abstract contract RegularLootbox is LootboxBase, Equipment, EquipmentParts {

    uint64 public constant REGULAR_LOOTBOX_SUBTYPE = uint64(
        uint256(keccak256("REGULAR_LOOTBOX_SUBTYPE"))
    );

    function isRegularLootbox(uint item) public pure returns (bool) {
        return isLootbox(item) && getItemSubtype(item) == REGULAR_LOOTBOX_SUBTYPE;
    }

    function _mintRegularLootbox(address to) internal {
        _mintLootbox(to, REGULAR_LOOTBOX_SUBTYPE, 1);
    }

    function _claimRegularLootboxReward(address owner, uint lootbox) internal {
        uint randomIn10000 = getOpenedLootboxRandom(owner, lootbox) % 10000;

        if (isOpenedLootboxExpired(owner, lootbox)) {
            // random can be manipulated in this case, only parts as a reward
            if (randomIn10000 < 2500) {
                _mintPhonePart(owner);
            } else if (randomIn10000 < 5000) {
                _mintEarbudsPart(owner);
            } else if (randomIn10000 < 7500) {
                _mintPowerbankPart(owner);
            } else {
                _mintLaptopPart(owner);
            }
        } else {
            if (randomIn10000 < 2475) {
                _mintPhonePart(owner);
            } else if (randomIn10000 < 4950) {
                _mintEarbudsPart(owner);
            } else if (randomIn10000 < 7425) {
                _mintPowerbankPart(owner);
            } else if (randomIn10000 < 9900) {
                _mintLaptopPart(owner);
            } else if (randomIn10000 < 9925) {
                _mintPhone(owner, 1);
            } else if (randomIn10000 < 9950) {
                _mintEarbuds(owner, 1);
            } else if (randomIn10000 < 9975) {
                _mintPowerbank(owner, 1);
            } else {
                _mintLaptop(owner, 1);
            }
        }
    }
}

abstract contract PremiumLootbox is LootboxBase {

    uint64 public constant PREMIUM_LOOTBOX_SUBTYPE = uint64(
        uint256(keccak256("PREMIUM_LOOTBOX_SUBTYPE"))
    );

    function isPremiumLootbox(uint item) public pure returns (bool) {
        return isLootbox(item) && getItemSubtype(item) == PREMIUM_LOOTBOX_SUBTYPE;
    }

    function _mintPremiumLootbox(address to) internal {
        _mintLootbox(to, PREMIUM_LOOTBOX_SUBTYPE, 0);
    }

    function _claimPremiumLootboxReward(address owner, uint lootbox) internal {
        // TODO: implement
    }
}

abstract contract Lootboxes is RegularLootbox, PremiumLootbox {

    function _claimLootboxReward(address owner, uint lootbox) internal override {
        if (isRegularLootbox(lootbox)) {
            _claimRegularLootboxReward(owner, lootbox);
        } else if (isPremiumLootbox(lootbox)) {
            _claimPremiumLootboxReward(owner, lootbox);
        } else {
            revert("Lootboxes: not a lootbox");
        }
    }
}