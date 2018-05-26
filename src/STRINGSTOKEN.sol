pragma solidity ^0.4.18;

import "./SafeMath.sol";
import "./ERC20interface.sol";
import "./Owned.sol";

contract STRINGSTOKEN is ERC20Interface, Owned {
    using SafeMath for uint;
    string public constant symbol = "STR";
    string public constant name = "STRINGSTOKEN";           
    uint8 public constant decimals = 0;                     
    uint public totalSupply = 1000;                         
    uint public contractBalance;                            
    string public lastNodeString;                           
    uint public lastNodeNumber;                             
    mapping(uint => address) addresses;                     
    mapping(address => uint) balances;                      
    mapping(address => mapping(address => uint)) allowed;   
    mapping(address => bool) public restrictedAddresses;    

    event Transfer(address indexed from, address indexed to, uint amount, string message);  
    event Genesis(uint indexed nodeNumber, string words, uint indexed unixTime);            
    event AddNode(uint indexed nodeNumber, string words, uint indexed baseNodeNumber, uint indexed unixTime);
    event Praise(uint indexed unixTime, address indexed to, uint weiAmount, string message);
    event Donate(uint indexed unixTime, address indexed from, uint amount);                 
    event RestrictControl(address indexed target, bool indexed control);                    

    constructor() public {
        contractBalance = totalSupply;                          
        lastNodeString = "Node 0";                              
        lastNodeNumber = 0;                                     
        addresses[lastNodeNumber] = msg.sender;                 
        emit Genesis(lastNodeNumber, lastNodeString, now);      
        emit Transfer(address(0), address(this), totalSupply);  
    }
    //ゲット（総流通枚数）
    function totalSupply() public view returns (uint){
        return totalSupply;
    }
    //ゲット（指定アドレスのバランス）
    function balanceOf(address ethAddress) public view returns (uint) {
        return balances[ethAddress];
    }
    //ゲット（転送許可アドレス・枚数）
    function allowance(address from, address proxy) public view returns (uint) {
        return allowed[from][proxy];
    }
    //送金
    function transfer(address to, uint amount) public returns (bool result) {
        require(
            to != address(0) &&                                     
            amount > 0 &&                                           
            balances[msg.sender] >= amount                      
        );
        balances[msg.sender] = balances[msg.sender].sub(amount);    
        if(to == address(this)){                                    
            contractBalance = contractBalance.add(amount);          
        }else{                                                      
            balances[to] = balances[to].add(amount);                
        }
        emit Transfer(msg.sender, to, amount);                      
        return true;
    }
    //送信（文字列付き）
    function transferWithMessage(address to, uint amount, string message) public returns (bool result) {
        bytes memory buf = bytes(message);                          
        require(
            to != address(0) &&                                     
            amount > 0 &&                                           
            balances[msg.sender] >= amount &&                       
            buf.length != 0                                         
        );
        balances[msg.sender] = balances[msg.sender].sub(amount);    
        if(to == address(this)){                                    
            contractBalance = contractBalance.add(amount);          
        }else{                                                      
            balances[to] = balances[to].add(amount);                
        }
        emit Transfer(msg.sender, to, amount, message);             
        return true;
    }
    //転送の許可
    function approve(address proxy, uint amount) public returns (bool result) {
        require(
            proxy != address(0) &&                                  
            amount > 0                                              
        );
        allowed[msg.sender][proxy] = amount;                        
        emit Approval(msg.sender, proxy, amount);                   
        return true;
    }
    //転送
    function transferFrom(address from, address to, uint amount) public returns (bool result) {
        require(
            from != address(0) &&                                   
            to != address(0) &&                                     
            amount > 0 &&                                           
            amount <= allowed[from][to] &&                          
            balances[from] >= amount &&                             
            balances[from].add(amount) >= balances[from]            
        );
        balances[from] = balances[from].sub(amount);                        
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);  
        if(to == address(this)){                                            
            contractBalance = contractBalance.add(amount);                  
        }else{                                                              
            balances[to] = balances[to].add(amount);                        
        }
        emit Transfer(from, to, amount);                                    
        return true;
    }
    //送金
    function sendWeiToNode(uint nodeNumber, uint weiAmount, string message)public payable returns (bool result){
        require(
            nodeNumber >= 0 &&                                      
            nodeNumber <= lastNodeNumber &&                         
            weiAmount > 0 &&                                        
            restrictedAddresses[addresses[nodeNumber]] == false     
        );
        address to = addresses[nodeNumber];                         
        to.transfer(weiAmount);                                     
        emit Praise(now, to, weiAmount, message);                   
        return true;
    }
    //ノード投稿
    function addNode(uint baseNode, string WORDS) public returns (bool result){
        require(
            balances[msg.sender] > 0 &&                         
            baseNode >= 0 &&                                    
            baseNode <= lastNodeNumber &&               
            restrictedAddresses[msg.sender] == false            
        );
        
        //送金＆投稿処理
        lastNodeNumber = lastNodeNumber.add(1);                 
        addresses[lastNodeNumber]=msg.sender;                   
        balances[msg.sender] = balances[msg.sender].sub(1);     
        if(restrictedAddresses[addresses[baseNode]] == true){   
            contractBalance = contractBalance.add(1);           
        }else{                                                  
            balances[addresses[baseNode]]=balances[addresses[baseNode]].add(1); 
        }
        lastNodeString = WORDS;                               
        emit AddNode(lastNodeNumber,WORDS,baseNode,now);        
        emit Transfer(msg.sender,addresses[baseNode],1);        
        return true;
    }
    //配布
    function _distribute(address[] to, uint amount) public onlyAdmin returns (bool result){
        require(
            to.length > 0 &&                                            
            amount > 0                                                  
        );
        uint totalAmount = amount.mul(to.length);                       
        require(contractBalance >= totalAmount);                        

        for (uint i = 0; i < to.length; i++) {                          
            require(
                to[i] != address(0) &&                                  
                restrictedAddresses[to[i]] == false                     
            );                      
            balances[to[i]] = balances[to[i]].add(amount);              
            emit Transfer(address(this), to[i], amount);                
        }
        contractBalance = contractBalance.sub(totalAmount);             
        return true;
    }
    //制限
    function _restrict(address[] to, bool freezeOrNot) onlyAdmin public {
        require(
            to.length > 0
        );                          
        for (uint i = 0; i < to.length; i++) {          
            require(to[i] != address(0));               
            restrictedAddresses[to[i]] = freezeOrNot;   
            emit RestrictControl(to[i], freezeOrNot);   
        }
    }
    //ETH受信
    function () public payable {
        require(
            msg.value > 0                           
        );
        currentAdmin.transfer(msg.value);           
        emit Donate(now,msg.sender,msg.value);      
    }
}