pragma solidity ^0.4.18;

contract Owned {
    address public currentAdmin;
    event AdminshipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        currentAdmin = msg.sender;
    }

    modifier onlyAdmin {
        require(msg.sender == currentAdmin);
        _;
    }
	
	//オーナー権譲渡
    function _changeAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));                  
        currentAdmin = newAdmin;                           
        emit AdminshipTransferred(currentAdmin, newAdmin); 
    }
}

