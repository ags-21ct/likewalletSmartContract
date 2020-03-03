pragma solidity ^0.4.19;

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

contract TransferWithMessageTRC20 {
    
    event TransferMessage(address trc20, address _to, uint _value, string message);
    function transferMessage(address trc20, address _to, uint _value, string message) public returns (bool) {
        if(_value > TRC20_Interface(trc20).allowance(msg.sender, address(this))) {  
          revert();  
        }  
        TRC20_Interface(trc20).transferFrom(msg.sender, _to, _value);
        TransferMessage(trc20, _to, _value, message);
        return true;
    }
}