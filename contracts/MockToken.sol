pragma solidity 0.8.5;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@4.3.0/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() ERC20("Token", "TK") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}
