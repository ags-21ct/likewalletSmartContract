pragma solidity ^0.4.19;
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

}
contract ERC20_Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
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

contract LockERC20 is Ownable{
   
    enum statusWithdraw {
        INACTIVE,
        ACTIVE
    }
    struct lockToken  {
        address token;
        uint256 expire;
        uint256 block;
        uint256 start;
        uint256 amount;
        statusWithdraw isWithdraw;
    }
    
    using SafeMath for uint;
    // mapping (address => mapping (address => uint256)) public tokens;

    mapping (address => mapping(address => lockToken)) public tokens;
    mapping (address => uint256) public balanceToken;
    uint256 public isExpire = 1 days;
    
    event DepositToken(address contractAddress, address sender, uint256 amount, uint256 expire);
    event WithdrawToken(address contractAddress, address sender, uint256 amount);
    event AdminWithdrawToken(address contractAddress, address sender, uint256 amount, string message);
    event RequestWithdraw(address contractAddress, address sender);
    function setExpire(uint256 expire) onlyOwner public{
        isExpire = expire;
    }
    function depositToken(address likeAddr, uint amount, uint256 expire) public returns (bool){
        if(amount > ERC20_Interface(likeAddr).allowance(msg.sender, address(this))) {  
          revert();  
        }  
        ERC20_Interface(likeAddr).transferFrom(msg.sender, address(this), amount);

        
        lockToken memory tokenData = tokens[likeAddr][msg.sender];
        tokenData.token = likeAddr;
        tokenData.expire = now.add(expire);
        tokenData.block = block.number;
        tokenData.start = now;
        tokenData.amount = tokenData.amount.add(amount);
        tokenData.isWithdraw = statusWithdraw.INACTIVE;
        tokens[likeAddr][msg.sender] = tokenData;
        balanceToken[likeAddr] = balanceToken[likeAddr].add(amount);
        DepositToken(likeAddr, msg.sender, amount, expire);
        return true;
        
    }
    function requestWithdraw(address likeAddr) public returns (bool){
        lockToken memory tokenData = tokens[likeAddr][msg.sender];
        require(tokenData.isWithdraw == statusWithdraw.INACTIVE);
        require(tokenData.amount > 0);
        tokenData.isWithdraw = statusWithdraw.ACTIVE;
        tokenData.expire = now.add(isExpire);
        tokens[likeAddr][msg.sender] = tokenData;  
        RequestWithdraw(likeAddr, msg.sender);
        return true;
    }
    function withdrawToken(address likeAddr, uint amount) public  returns (bool){
        lockToken memory tokenData = tokens[likeAddr][msg.sender];
        require(now > tokenData.expire);
        require(amount <= tokenData.amount);
        require(tokenData.isWithdraw == statusWithdraw.ACTIVE);
        tokenData.amount = tokenData.amount.sub(amount);
        tokenData.isWithdraw = statusWithdraw.INACTIVE;
        tokens[likeAddr][msg.sender] = tokenData;      
        balanceToken[likeAddr]= balanceToken[likeAddr].sub(amount);
        ERC20_Interface(likeAddr).transfer(msg.sender, amount);
        WithdrawToken(likeAddr, msg.sender, amount);
        return true;
        
    }
    function getLock(address likeAddr, address _sender) public view returns (uint256){
          return tokens[likeAddr][_sender].amount;
    }
    function getWithdraw(address likeAddr, address _sender) public view returns (statusWithdraw) {
        return tokens[likeAddr][_sender].isWithdraw;
    }
    function getAmount(address likeAddr, address _sender) public view returns (uint256) {
        return tokens[likeAddr][_sender].amount;
    }
    function getDepositTime(address likeAddr, address _sender) public view returns (uint256) {
        return tokens[likeAddr][_sender].start;
    }
    function adminWithdrawToken(address likeAddr, uint amount, string  message) onlyOwner public {
        require(amount <= balanceToken[likeAddr]);
        balanceToken[likeAddr] = balanceToken[likeAddr].sub(amount);
        ERC20_Interface(likeAddr).transfer(msg.sender, amount);    
        AdminWithdrawToken(likeAddr, msg.sender, amount, message);
    }
    
    
}