pragma solidity ^0.4.19;


contract Ownable {
  address public owner;
  address public waitNewOwner;
    
  event transferOwner(address newOwner);
  
  function Ownable() public{
      owner = msg.sender;
  }
  
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   * and safe new contract new owner will be accept owner
   */
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      waitNewOwner = newOwner;
    }
  }
  /**
   * this function accept when transfer to new owner and new owner will be accept owner for safe contract free owner
   */
   
  function acceptOwnership() public {
      if(waitNewOwner == msg.sender) {
          owner = msg.sender;
           transferOwner(msg.sender);
      }else{
          revert();
      }
  }

}

contract KickbackResturant is Ownable {
    
    struct onwerToken  {
        address token;
        address shop;
        uint256 amount;
    }
    
    mapping(address => uint) public totalBalance;
    mapping (address => mapping(address => onwerToken)) public tokens;
    
    //tokens[trc20][shopaddr]
    
    
    event KickbackMsg(address trc20,address _sender, address _to, uint _value,uint _return_like, string _msg);
    event DepositMsg(address trc20,address _sender, uint _value, string _msg );
    event WithdrawToken(address trc20,address _sender, uint _value,string _msg);
    
    //for call outside
    function kickback(address trc20,address _to, uint _value, string _msg) public returns (bool){
        //check balance for sender
        if(_value > TRC20_Interface(trc20).allowance(msg.sender, address(this))) {  
          revert();  
        }
        
        //transfer
        TRC20_Interface(trc20).transferFrom(msg.sender, _to, _value);
        
        uint return_like = _value/30;
        
        //check amount
        require(tokens[trc20][_to].amount>=return_like);
        
        //return_like to sneder
        TRC20_Interface(trc20).transfer(msg.sender, return_like);
        
        //set totalBalance all like in smart contract
        totalBalance[trc20] -= return_like;
        
        onwerToken memory tokenData = tokens[trc20][_to];
        tokenData.amount -= return_like;
        tokens[trc20][_to] = tokenData;
        
        //anounce to outside
        KickbackMsg(trc20,msg.sender, _to, _value,return_like,_msg);
    }
    
    
    // function transferMessage(address trc20, address _to, uint _value, string message) public returns (bool) {
    //     if(_value > TRC20_Interface(trc20).allowance(msg.sender, address(this))) {  
    //       revert();  
    //     }  
    //     TRC20_Interface(trc20).transferFrom(msg.sender, _to, _value);
    //     TransferMessage(trc20, _to, _value, message);
    //     return true;
    // }
    
    function depositToken(address trc20, uint amount, address shopaddr, string _msg) public {
        //check amount of deposit not > TRC20_Interface.approve
        if(amount > TRC20_Interface(trc20).allowance(msg.sender, address(this))) {  
          revert();  
        }
        
        //deposit likepoint to smart contract
        TRC20_Interface(trc20).transferFrom(msg.sender, address(this), amount);

        //set totalBalance all like in smart contract
        totalBalance[trc20] += amount;

        //set balance for shopaddr
        onwerToken memory tokenData = tokens[trc20][shopaddr];
        tokenData.token = trc20;
        tokenData.amount += amount;
        tokenData.shop = shopaddr;
        tokens[trc20][shopaddr] = tokenData;
        
      //anounce event
        DepositMsg(trc20,shopaddr,amount,_msg);
        
    }
    
    function withdrawToken(address trc20, uint amount,string _msg) onlyOwner public {
        onwerToken memory tokenData = tokens[trc20][msg.sender];
        //require(now > tokenData.expire);
        require(amount <= tokenData.amount);
        tokenData.amount -= amount;
        tokens[trc20][msg.sender] = tokenData;
        //balanceToken[trc20]= balanceToken[trc20].sub(amount);
        totalBalance[trc20] -= amount;
        TRC20_Interface(trc20).transfer(msg.sender, amount);
        WithdrawToken(trc20, msg.sender, amount,_msg);
        
    }
}


contract TRC20_Interface  {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


