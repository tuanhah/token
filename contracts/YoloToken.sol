// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract YoloToken is ERC20("Yolo Token", "YOLO"), Ownable {
    uint public buyTax;
    uint public sellTax;
    address public sentTo;

    mapping(address => bool) public pools;
    mapping(address => bool) public excludes;
    uint256 public Y_ONE = 1e3;

    constructor(address _sentTo) {
        sentTo = _sentTo;

        // 100 Milion
        _mint(msg.sender, 1e7 * 1e18);

        excludes[msg.sender] = true;
        excludes[address(this)] = true;
    }

    // 10% = 100, 1% = 10, 100% = 1000
    function setInfo(uint _bTax, uint _sTax) external onlyOwner {
        buyTax = _bTax;
        sellTax = _sTax;
    }

    function setSentTo(address _sentTo) external onlyOwner {
        sentTo = _sentTo;
    }

    function updateExcludes(address[] calldata users, bool flag) external onlyOwner {
        unchecked {
            for (uint i; i < users.length; ++i) {
                excludes[users[i]] = flag;
            }
        }
    }

    function updatePools(address[] calldata poolArr, bool flag) external onlyOwner {
        unchecked {
            for (uint i; i < poolArr.length; ++i) {
                pools[poolArr[i]] = flag;
            }
        }
    }

    function _transfer(address from, address to, uint amount) internal override {
        // only excluded addresses can send token before trading started
        if (!excludes[from] && !excludes[to]) {
            uint taxAmt;
            unchecked {
                // if buy
                if (pools[from]) {
                    taxAmt = (amount * buyTax) / Y_ONE;
                }
                // if sell
                else if (pools[to]) {
                    taxAmt = (amount * sellTax) / Y_ONE;
                }

                if (taxAmt != 0) {
                    amount -= taxAmt;
                    super._transfer(from, sentTo, taxAmt);
                }
            }
        }

        super._transfer(from, to, amount);
    }
}
